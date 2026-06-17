#if os(iOS)
import CoreBluetooth
import Flutter
import Foundation

final class IosBleProcessOwner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
  static let shared = IosBleProcessOwner()

  private let state = IosNativeOwnerState()
  private var central: CBCentralManager?
  private var callbacksByEngine: [String: BleCallbacksApi] = [:]
  private var activeEngineToken: String?
  private var scanFilter: ScanFilterMessage?
  private var isScanning = false
  private var peripheralsByDeviceId: [String: CBPeripheral] = [:]
  private var restoredDeviceIds: [String] = []
  private let handleRegistry = HandleRegistry()
  private var opQueue: GattOperationQueue!
  private var discoverCompletions: [String: (Result<[ServiceMessage], Error>) -> Void] = [:]
  private var pendingDiscovery: [String: Int] = [:]
  private var readCompletions: [String: (Result<FlutterStandardTypedData, Error>) -> Void] = [:]
  private var writeCompletions: [String: (Result<Void, Error>) -> Void] = [:]
  private var notifyCompletions: [String: (Result<Void, Error>) -> Void] = [:]
  private var descriptorReadCompletions: [String: (Result<FlutterStandardTypedData, Error>) -> Void] = [:]
  private var descriptorWriteCompletions: [String: (Result<Void, Error>) -> Void] = [:]
  private var rssiCompletions: [String: (Result<Int64, Error>) -> Void] = [:]

  private override init() {
    super.init()
    opQueue = GattOperationQueue(onTimeout: { [weak self] deviceId, epoch in
      self?.handleOperationTimeout(deviceId: deviceId, epoch: epoch)
    })
  }

  func registerSink(engineToken: String, callbacks: BleCallbacksApi) {
    callbacksByEngine[engineToken] = callbacks
  }

  func unregisterSink(engineToken: String) {
    callbacksByEngine.removeValue(forKey: engineToken)
    if activeEngineToken == engineToken {
      activeEngineToken = nil
    }
  }

  func initialize(request: InitializeRequestMessage) -> String {
    ensureCentral(restoreIdentifier: request.restoreIdentifier)
    return activeEngineToken ?? ""
  }

  func notifyDartReady(engineToken: String) {
    activeEngineToken = engineToken
    emitCurrentAdapterState()
    emitStateResync()
    if !restoredDeviceIds.isEmpty {
      activeCallbacks?.onRestoredConnections(deviceIds: restoredDeviceIds) { _ in }
    }
  }

  func ackStateResync(engineToken: String, snapshotId: String) {
    if callbacksByEngine[engineToken] != nil {
      activeEngineToken = engineToken
    }
  }

  func startScan(filter: ScanFilterMessage?, settings: DarwinScanSettingsMessage) throws {
    let central = try poweredOnCentral()
    guard !isScanning else {
      throw BleErrorMapping.alreadyScanning()
    }

    scanFilter = filter
    var options: [String: Any] = [
      CBCentralManagerScanOptionAllowDuplicatesKey: settings.allowDuplicates
    ]
    if !settings.solicitedServiceUuids.isEmpty {
      options[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] =
        settings.solicitedServiceUuids.map(CBUUID.init(string:))
    }
    let serviceUuids = filter?.serviceUuids.map(CBUUID.init(string:))
    central.scanForPeripherals(
      withServices: serviceUuids?.isEmpty == true ? nil : serviceUuids,
      options: options
    )
    isScanning = true
  }

  func stopScan() {
    central?.stopScan()
    isScanning = false
    scanFilter = nil
  }

  func connect(
    deviceId: String,
    completion: @escaping (Result<ConnectionAttemptMessage, Error>) -> Void
  ) {
    ensureCentral(restoreIdentifier: nil)
    let attempt = state.connectRequested(deviceId: deviceId)
    let message = ConnectionAttemptMessage(connectionEpoch: attempt.epoch)

    guard let central else {
      _ = state.disconnectRequested(deviceId: deviceId, epoch: attempt.epoch)
      completion(.failure(BleErrorMapping.bluetoothUnavailable("Central manager unavailable")))
      return
    }

    guard let peripheral = peripheral(for: deviceId, central: central) else {
      _ = state.disconnectRequested(deviceId: deviceId, epoch: attempt.epoch)
      completion(.failure(BleErrorMapping.notFound("Unknown peripheral: \(deviceId)")))
      return
    }

    peripheralsByDeviceId[deviceId] = peripheral
    peripheral.delegate = self
    if central.state == .poweredOn {
      central.connect(peripheral, options: nil)
    }
    completion(.success(message))
  }

  func disconnect(
    deviceId: String,
    connectionEpoch: Int64,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard state.disconnectRequested(deviceId: deviceId, epoch: connectionEpoch) else {
      completion(.failure(BleErrorMapping.notConnected()))
      return
    }
    opQueue.cancelAll(deviceId: deviceId, epoch: connectionEpoch)
    failPendingOperations(deviceId: deviceId, error: BleErrorMapping.notConnected())
    handleRegistry.clear(deviceId: deviceId)
    if let peripheral = peripheralsByDeviceId.removeValue(forKey: deviceId) {
      central?.cancelPeripheralConnection(peripheral)
    }
    emitConnectionState(
      deviceId: deviceId,
      epoch: connectionEpoch,
      state: .disconnected,
      reason: .userRequested
    )
    completion(.success(()))
  }

  func discoverServices(
    deviceId: String,
    connectionEpoch: Int64,
    completion: @escaping (Result<[ServiceMessage], Error>) -> Void
  ) {
    guard state.isCurrent(deviceId: deviceId, epoch: connectionEpoch),
          let peripheral = peripheralsByDeviceId[deviceId],
          peripheral.state == .connected
    else {
      completion(.failure(BleErrorMapping.notConnected()))
      return
    }
    let key = discoveryKey(deviceId, connectionEpoch)
    guard opQueue.enqueue(key: key, deviceId: deviceId, epoch: connectionEpoch) else {
      completion(.failure(BleErrorMapping.failed("Service discovery already in progress")))
      return
    }
    discoverCompletions[deviceId] = completion
    peripheral.discoverServices(nil)
  }

  func readCharacteristic(
    target: CharacteristicTargetMessage,
    strictRead: Bool,
    completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void
  ) {
    switch findCharacteristic(target) {
    case .failure(let e):
      completion(.failure(e))
    case .success(let (peripheral, ch)):
      switch GattOperationDecisions.readDecision(
        strictRead: strictRead, capability: capability(of: ch)) {
      case .notSupported:
        completion(.failure(BleErrorMapping.notSupported("Read not supported")))
        return
      case .ambiguousWhileNotifying:
        completion(.failure(BleErrorMapping.readAmbiguousWhileNotifying()))
        return
      case .proceed:
        break
      }
      let key = charKey(target)
      guard opQueue.enqueue(key: key, deviceId: target.deviceId, epoch: target.connectionEpoch) else {
        completion(.failure(BleErrorMapping.failed("A read for this characteristic is already in flight")))
        return
      }
      readCompletions[key] = completion
      peripheral.readValue(for: ch)
    }
  }

  func writeCharacteristic(
    target: CharacteristicTargetMessage,
    value: FlutterStandardTypedData,
    withResponse: Bool,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    switch findCharacteristic(target) {
    case .failure(let e):
      completion(.failure(e))
    case .success(let (peripheral, ch)):
      switch GattOperationDecisions.writeDecision(
        withResponse: withResponse,
        capability: capability(of: ch),
        canSendWithoutResponse: peripheral.canSendWriteWithoutResponse) {
      case .notSupported:
        let message = withResponse
          ? "Write with response not supported"
          : "Write without response not supported"
        completion(.failure(BleErrorMapping.notSupported(message)))
      case .bufferFull:
        completion(.failure(BleErrorMapping.bufferFull()))
      case .proceedWithResponse:
        let key = charKey(target)
        guard opQueue.enqueue(key: key, deviceId: target.deviceId, epoch: target.connectionEpoch) else {
          completion(.failure(BleErrorMapping.failed("A write for this characteristic is already in flight")))
          return
        }
        writeCompletions[key] = completion
        peripheral.writeValue(value.data, for: ch, type: .withResponse)
      case .proceedWithoutResponse:
        peripheral.writeValue(value.data, for: ch, type: .withoutResponse)
        completion(.success(()))
      }
    }
  }

  func setNotify(
    target: CharacteristicTargetMessage,
    type: NotifyTypeMessage,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    switch findCharacteristic(target) {
    case .failure(let e):
      completion(.failure(e))
    case .success(let (peripheral, ch)):
      let enabled = type != .disable
      switch GattOperationDecisions.notifyDecision(capability: capability(of: ch)) {
      case .notSupported:
        completion(.failure(BleErrorMapping.notSupported("Notify/Indicate not supported")))
        return
      case .proceed:
        break
      }
      let key = charKey(target)
      guard opQueue.enqueue(key: key, deviceId: target.deviceId, epoch: target.connectionEpoch) else {
        completion(.failure(BleErrorMapping.failed("A notify state change for this characteristic is already in flight")))
        return
      }
      notifyCompletions[key] = completion
      peripheral.setNotifyValue(enabled, for: ch)
    }
  }

  func readDescriptor(
    target: DescriptorTargetMessage,
    completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void
  ) {
    switch findDescriptor(target) {
    case .failure(let e):
      completion(.failure(e))
    case .success(let (peripheral, d)):
      let key = descKey(target)
      guard opQueue.enqueue(key: key, deviceId: target.deviceId, epoch: target.connectionEpoch) else {
        completion(.failure(BleErrorMapping.failed("A descriptor read is already in flight")))
        return
      }
      descriptorReadCompletions[key] = completion
      peripheral.readValue(for: d)
    }
  }

  func writeDescriptor(
    target: DescriptorTargetMessage,
    value: FlutterStandardTypedData,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    switch findDescriptor(target) {
    case .failure(let e):
      completion(.failure(e))
    case .success(let (peripheral, d)):
      let key = descKey(target)
      guard opQueue.enqueue(key: key, deviceId: target.deviceId, epoch: target.connectionEpoch) else {
        completion(.failure(BleErrorMapping.failed("A descriptor write is already in flight")))
        return
      }
      descriptorWriteCompletions[key] = completion
      peripheral.writeValue(value.data, for: d)
    }
  }

  func getMtu(
    deviceId: String,
    connectionEpoch: Int64,
    completion: @escaping (Result<Int64, Error>) -> Void
  ) {
    guard state.isCurrent(deviceId: deviceId, epoch: connectionEpoch),
          let peripheral = peripheralsByDeviceId[deviceId],
          peripheral.state == .connected
    else {
      completion(.failure(BleErrorMapping.notConnected()))
      return
    }
    completion(.success(Int64(peripheral.maximumWriteValueLength(for: .withResponse) + 3)))
  }

  func readRssi(
    deviceId: String,
    connectionEpoch: Int64,
    completion: @escaping (Result<Int64, Error>) -> Void
  ) {
    guard state.isCurrent(deviceId: deviceId, epoch: connectionEpoch),
          let peripheral = peripheralsByDeviceId[deviceId],
          peripheral.state == .connected
    else {
      completion(.failure(BleErrorMapping.notConnected()))
      return
    }
    let key = rssiKey(deviceId, connectionEpoch)
    guard opQueue.enqueue(key: key, deviceId: deviceId, epoch: connectionEpoch) else {
      completion(.failure(BleErrorMapping.failed("RSSI read already in flight")))
      return
    }
    rssiCompletions[key] = completion
    peripheral.readRSSI()
  }

  func dispose() {
    stopScan()
    for (deviceId, peripheral) in peripheralsByDeviceId {
      if let epoch = state.currentEpoch(deviceId: deviceId) {
        _ = state.disconnectRequested(deviceId: deviceId, epoch: epoch)
        opQueue.cancelAll(deviceId: deviceId, epoch: epoch)
      }
      failPendingOperations(deviceId: deviceId, error: BleErrorMapping.notConnected())
      handleRegistry.clear(deviceId: deviceId)
      central?.cancelPeripheralConnection(peripheral)
    }
    peripheralsByDeviceId.removeAll()
    callbacksByEngine.removeAll()
    activeEngineToken = nil
    restoredDeviceIds.removeAll()
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    let adapterState = adapterState(from: central.state)
    state.adapterStateChanged(adapterState)
    emitAdapterState(adapterState)

    guard central.state == .poweredOn else {
      return
    }

    for deviceId in state.pendingDeviceIds {
      if let peripheral = peripheralsByDeviceId[deviceId] {
        central.connect(peripheral, options: nil)
      }
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    willRestoreState dict: [String: Any]
  ) {
    let restored = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []
    restoredDeviceIds = restored.map(\.identifier.uuidString)
    for peripheral in restored {
      let deviceId = peripheral.identifier.uuidString
      peripheral.delegate = self
      peripheralsByDeviceId[deviceId] = peripheral
      let attempt = state.connectRequested(deviceId: deviceId)
      let connectionState = connectionState(from: peripheral.state)
      _ = state.acceptCallback(deviceId: deviceId, epoch: attempt.epoch, state: connectionState)
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {
    let deviceId = peripheral.identifier.uuidString
    peripheralsByDeviceId[deviceId] = peripheral

    guard matchesScanFilter(
      deviceId: deviceId,
      peripheral: peripheral,
      advertisementData: advertisementData,
      filter: scanFilter
    ) else {
      return
    }

    let result = ScanResultMessage(
      deviceId: deviceId,
      name: advertisedName(peripheral: peripheral, advertisementData: advertisementData),
      rssi: RSSI.int64Value,
      serviceUuids: serviceUuids(advertisementData: advertisementData),
      manufacturerData: manufacturerData(advertisementData: advertisementData),
      raw: nil
    )
    activeCallbacks?.onScanResult(result: result) { _ in }
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    let deviceId = peripheral.identifier.uuidString
    guard let epoch = state.currentEpoch(deviceId: deviceId),
          state.acceptCallback(deviceId: deviceId, epoch: epoch, state: .connected)
    else {
      return
    }
    emitConnectionState(deviceId: deviceId, epoch: epoch, state: .connected, reason: nil)
  }

  func centralManager(
    _ central: CBCentralManager,
    didFailToConnect peripheral: CBPeripheral,
    error: Error?
  ) {
    let deviceId = peripheral.identifier.uuidString
    guard let epoch = state.currentEpoch(deviceId: deviceId),
          state.acceptCallback(deviceId: deviceId, epoch: epoch, state: .disconnected)
    else {
      return
    }
    emitConnectionState(
      deviceId: deviceId,
      epoch: epoch,
      state: .disconnected,
      reason: .connectFailed
    )
  }

  func centralManager(
    _ central: CBCentralManager,
    didDisconnectPeripheral peripheral: CBPeripheral,
    error: Error?
  ) {
    let deviceId = peripheral.identifier.uuidString
    guard state.connectionState(deviceId: deviceId) != .pending,
          let epoch = state.currentEpoch(deviceId: deviceId),
          state.acceptCallback(deviceId: deviceId, epoch: epoch, state: .disconnected)
    else {
      return
    }
    opQueue.cancelAll(deviceId: deviceId, epoch: epoch)
    failPendingOperations(deviceId: deviceId, error: BleErrorMapping.notConnected())
    handleRegistry.clear(deviceId: deviceId)
    emitConnectionState(
      deviceId: deviceId,
      epoch: epoch,
      state: .disconnected,
      reason: error == nil ? .userRequested : .connectionLost
    )
  }

  // MARK: - CBPeripheralDelegate (discovery)

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    let deviceId = peripheral.identifier.uuidString
    guard discoverCompletions[deviceId] != nil else { return }
    if let error {
      if let epoch = state.currentEpoch(deviceId: deviceId) {
        _ = opQueue.complete(key: discoveryKey(deviceId, epoch))
      }
      pendingDiscovery.removeValue(forKey: deviceId)
      discoverCompletions.removeValue(forKey: deviceId)?(
        .failure(BleErrorMapping.failed(error.localizedDescription)))
      return
    }
    let services = peripheral.services ?? []
    if services.isEmpty {
      if let epoch = state.currentEpoch(deviceId: deviceId) {
        _ = opQueue.complete(key: discoveryKey(deviceId, epoch))
      }
      discoverCompletions.removeValue(forKey: deviceId)?(.success([]))
      return
    }
    pendingDiscovery[deviceId] = services.count
    services.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverCharacteristicsFor service: CBService,
    error: Error?
  ) {
    let deviceId = peripheral.identifier.uuidString
    guard discoverCompletions[deviceId] != nil else { return }
    if let error {
      if let epoch = state.currentEpoch(deviceId: deviceId) {
        _ = opQueue.complete(key: discoveryKey(deviceId, epoch))
      }
      pendingDiscovery.removeValue(forKey: deviceId)
      discoverCompletions.removeValue(forKey: deviceId)?(
        .failure(BleErrorMapping.failed(error.localizedDescription)))
      return
    }
    let chars = service.characteristics ?? []
    pendingDiscovery[deviceId, default: 0] += chars.count - 1
    chars.forEach { peripheral.discoverDescriptors(for: $0) }
    finishDiscoveryIfDone(peripheral, deviceId: deviceId)
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverDescriptorsFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    let deviceId = peripheral.identifier.uuidString
    guard discoverCompletions[deviceId] != nil else { return }
    if let error {
      if let epoch = state.currentEpoch(deviceId: deviceId) {
        _ = opQueue.complete(key: discoveryKey(deviceId, epoch))
      }
      pendingDiscovery.removeValue(forKey: deviceId)
      discoverCompletions.removeValue(forKey: deviceId)?(
        .failure(BleErrorMapping.failed(error.localizedDescription)))
      return
    }
    pendingDiscovery[deviceId, default: 0] -= 1
    finishDiscoveryIfDone(peripheral, deviceId: deviceId)
  }

  private func finishDiscoveryIfDone(_ peripheral: CBPeripheral, deviceId: String) {
    guard pendingDiscovery[deviceId] == 0,
          let epoch = state.currentEpoch(deviceId: deviceId),
          let completion = discoverCompletions.removeValue(forKey: deviceId)
    else { return }
    pendingDiscovery.removeValue(forKey: deviceId)
    let services = rebuildHandles(peripheral: peripheral)
    _ = opQueue.complete(key: discoveryKey(deviceId, epoch))
    completion(.success(services))
  }

  // MARK: - CBPeripheralDelegate (GATT operations)

  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateValueFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    guard let key = charKey(peripheral, characteristic) else { return }
    let data = characteristic.value ?? Data()
    let hasPendingRead = readCompletions[key] != nil
    switch GattOperationDecisions.readCallbackRouting(
      hasPendingRead: hasPendingRead, hasError: error != nil) {
    case .completeReadSuccessThenEmit:
      _ = opQueue.complete(key: key)
      readCompletions.removeValue(forKey: key)?(.success(FlutterStandardTypedData(bytes: data)))
      // Review guide §10: 通常 read は戻り値完了に加えて同じ値を values にも流す。
      emitCharacteristicValue(peripheral, characteristic, data: data)
    case .completeReadFailure:
      _ = opQueue.complete(key: key)
      readCompletions.removeValue(forKey: key)?(
        .failure(BleErrorMapping.failed(error!.localizedDescription)))
    case .emitNotify:
      emitCharacteristicValue(peripheral, characteristic, data: data)
    case .ignore:
      break
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didWriteValueFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    guard let key = charKey(peripheral, characteristic),
          let completion = writeCompletions.removeValue(forKey: key) else { return }
    _ = opQueue.complete(key: key)
    if let error {
      completion(.failure(BleErrorMapping.failed(error.localizedDescription)))
    } else {
      completion(.success(()))
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateNotificationStateFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    guard let key = charKey(peripheral, characteristic),
          let completion = notifyCompletions.removeValue(forKey: key) else { return }
    _ = opQueue.complete(key: key)
    if let error {
      completion(.failure(BleErrorMapping.failed(error.localizedDescription)))
    } else {
      completion(.success(()))
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateValueFor descriptor: CBDescriptor,
    error: Error?
  ) {
    guard let key = descKey(peripheral, descriptor),
          let completion = descriptorReadCompletions.removeValue(forKey: key) else { return }
    _ = opQueue.complete(key: key)
    if let error {
      completion(.failure(BleErrorMapping.failed(error.localizedDescription)))
    } else {
      let data: Data
      if let bytes = descriptor.value as? Data {
        data = bytes
      } else if let string = descriptor.value as? String {
        data = Data(string.utf8)
      } else {
        data = Data()
      }
      completion(.success(FlutterStandardTypedData(bytes: data)))
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didWriteValueFor descriptor: CBDescriptor,
    error: Error?
  ) {
    guard let key = descKey(peripheral, descriptor),
          let completion = descriptorWriteCompletions.removeValue(forKey: key) else { return }
    _ = opQueue.complete(key: key)
    if let error {
      completion(.failure(BleErrorMapping.failed(error.localizedDescription)))
    } else {
      completion(.success(()))
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
    let deviceId = peripheral.identifier.uuidString
    guard let epoch = state.currentEpoch(deviceId: deviceId) else { return }
    let key = rssiKey(deviceId, epoch)
    guard let completion = rssiCompletions.removeValue(forKey: key) else { return }
    _ = opQueue.complete(key: key)
    if let error {
      completion(.failure(BleErrorMapping.failed(error.localizedDescription)))
    } else {
      completion(.success(RSSI.int64Value))
    }
  }

  private func emitCharacteristicValue(
    _ peripheral: CBPeripheral,
    _ ch: CBCharacteristic,
    data: Data
  ) {
    let deviceId = peripheral.identifier.uuidString
    guard let epoch = state.currentEpoch(deviceId: deviceId),
          let handle = handleRegistry.handle(for: ch) else { return }
    activeCallbacks?.onCharacteristicValue(
      deviceId: deviceId,
      connectionEpoch: epoch,
      characteristicHandle: handle,
      value: FlutterStandardTypedData(bytes: data)
    ) { _ in }
  }

  // MARK: - GATT ヘルパー

  private func fullUuid(_ uuid: CBUUID) -> String {
    let s = uuid.uuidString.lowercased()
    switch s.count {
    case 4: return "0000\(s)-0000-1000-8000-00805f9b34fb"
    case 8: return "\(s)-0000-1000-8000-00805f9b34fb"
    default: return s
    }
  }

  private func charKey(_ target: CharacteristicTargetMessage) -> String {
    "\(target.deviceId)|\(target.connectionEpoch)|\(target.characteristicHandle)"
  }

  private func charKey(_ peripheral: CBPeripheral, _ ch: CBCharacteristic) -> String? {
    let deviceId = peripheral.identifier.uuidString
    guard let epoch = state.currentEpoch(deviceId: deviceId),
          let handle = handleRegistry.handle(for: ch) else { return nil }
    return "\(deviceId)|\(epoch)|\(handle)"
  }

  private func descKey(_ target: DescriptorTargetMessage) -> String {
    "\(target.deviceId)|\(target.connectionEpoch)|\(target.characteristicHandle)|\(target.descriptorHandle)"
  }

  private func descKey(_ peripheral: CBPeripheral, _ d: CBDescriptor) -> String? {
    guard let ch = d.characteristic else { return nil }
    let deviceId = peripheral.identifier.uuidString
    guard let epoch = state.currentEpoch(deviceId: deviceId),
          let charHandle = handleRegistry.handle(for: ch),
          let descHandle = handleRegistry.handle(for: d) else { return nil }
    return "\(deviceId)|\(epoch)|\(charHandle)|\(descHandle)"
  }

  private func rssiKey(_ deviceId: String, _ epoch: Int64) -> String {
    "\(deviceId)|\(epoch)|rssi"
  }

  private func discoveryKey(_ deviceId: String, _ epoch: Int64) -> String {
    "\(deviceId)|\(epoch)|discovery"
  }

  private func capability(of ch: CBCharacteristic) -> CharacteristicCapability {
    CharacteristicCapability(
      canRead: ch.properties.contains(.read),
      canWriteWithResponse: ch.properties.contains(.write),
      canWriteWithoutResponse: ch.properties.contains(.writeWithoutResponse),
      canNotify: ch.properties.contains(.notify),
      canIndicate: ch.properties.contains(.indicate),
      isNotifying: ch.isNotifying
    )
  }

  private func findCharacteristic(
    _ target: CharacteristicTargetMessage
  ) -> Result<(CBPeripheral, CBCharacteristic), Error> {
    guard state.isCurrent(deviceId: target.deviceId, epoch: target.connectionEpoch),
          let peripheral = peripheralsByDeviceId[target.deviceId],
          peripheral.state == .connected
    else {
      return .failure(BleErrorMapping.notConnected())
    }
    guard let ch = handleRegistry.characteristic(
      handle: target.characteristicHandle, deviceId: target.deviceId) as? CBCharacteristic
    else {
      return .failure(BleErrorMapping.notFound(
        "Characteristic handle \(target.characteristicHandle) not found"))
    }
    return .success((peripheral, ch))
  }

  private func findDescriptor(
    _ target: DescriptorTargetMessage
  ) -> Result<(CBPeripheral, CBDescriptor), Error> {
    guard state.isCurrent(deviceId: target.deviceId, epoch: target.connectionEpoch),
          let peripheral = peripheralsByDeviceId[target.deviceId],
          peripheral.state == .connected
    else {
      return .failure(BleErrorMapping.notConnected())
    }
    guard let d = handleRegistry.descriptor(
      handle: target.descriptorHandle, deviceId: target.deviceId) as? CBDescriptor
    else {
      return .failure(BleErrorMapping.notFound(
        "Descriptor handle \(target.descriptorHandle) not found"))
    }
    return .success((peripheral, d))
  }

  private func rebuildHandles(peripheral: CBPeripheral) -> [ServiceMessage] {
    let deviceId = peripheral.identifier.uuidString
    handleRegistry.clear(deviceId: deviceId)
    return (peripheral.services ?? []).map { service in
      let svcHandle = handleRegistry.allocate(service, kind: .service, deviceId: deviceId)
      let characteristics = (service.characteristics ?? []).map { ch -> CharacteristicMessage in
        let charHandle = handleRegistry.allocate(ch, kind: .characteristic, deviceId: deviceId)
        let descriptors = (ch.descriptors ?? []).map { d -> DescriptorMessage in
          let descHandle = handleRegistry.allocate(d, kind: .descriptor, deviceId: deviceId)
          return DescriptorMessage(handle: descHandle, uuid: fullUuid(d.uuid))
        }
        return CharacteristicMessage(
          handle: charHandle,
          serviceHandle: svcHandle,
          uuid: fullUuid(ch.uuid),
          canRead: ch.properties.contains(.read),
          canWriteWithResponse: ch.properties.contains(.write),
          canWriteWithoutResponse: ch.properties.contains(.writeWithoutResponse),
          canNotify: ch.properties.contains(.notify),
          canIndicate: ch.properties.contains(.indicate),
          descriptors: descriptors
        )
      }
      return ServiceMessage(handle: svcHandle, uuid: fullUuid(service.uuid),
                            characteristics: characteristics)
    }
  }

  // MARK: - タイムアウト

  private func failPendingOperations(deviceId: String, error: Error) {
    let err = error
    discoverCompletions.removeValue(forKey: deviceId)?(.failure(err))
    pendingDiscovery.removeValue(forKey: deviceId)
    for key in Array(readCompletions.keys) where key.hasPrefix("\(deviceId)|") {
      readCompletions.removeValue(forKey: key)?(.failure(err))
    }
    for key in Array(writeCompletions.keys) where key.hasPrefix("\(deviceId)|") {
      writeCompletions.removeValue(forKey: key)?(.failure(err))
    }
    for key in Array(notifyCompletions.keys) where key.hasPrefix("\(deviceId)|") {
      notifyCompletions.removeValue(forKey: key)?(.failure(err))
    }
    for key in Array(descriptorReadCompletions.keys) where key.hasPrefix("\(deviceId)|") {
      descriptorReadCompletions.removeValue(forKey: key)?(.failure(err))
    }
    for key in Array(descriptorWriteCompletions.keys) where key.hasPrefix("\(deviceId)|") {
      descriptorWriteCompletions.removeValue(forKey: key)?(.failure(err))
    }
    for key in Array(rssiCompletions.keys) where key.hasPrefix("\(deviceId)|") {
      rssiCompletions.removeValue(forKey: key)?(.failure(err))
    }
  }

  private func handleOperationTimeout(deviceId: String, epoch: Int64) {
    activeCallbacks?.onOperationTimeout(deviceId: deviceId, connectionEpoch: epoch) { _ in }
    failPendingOperations(deviceId: deviceId, error: BleErrorMapping.operationTimeout())
    opQueue.cancelAll(deviceId: deviceId, epoch: epoch)
    _ = state.disconnectRequested(deviceId: deviceId, epoch: epoch)
    if let peripheral = peripheralsByDeviceId[deviceId] {
      central?.cancelPeripheralConnection(peripheral)
    }
    handleRegistry.clear(deviceId: deviceId)
    emitConnectionState(
      deviceId: deviceId, epoch: epoch,
      state: .disconnected, reason: .operationTimeout
    )
  }

  private var activeCallbacks: BleCallbacksApi? {
    activeEngineToken.flatMap { callbacksByEngine[$0] }
  }

  private func ensureCentral(restoreIdentifier: String?) {
    guard central == nil else {
      return
    }
    var options: [String: Any] = [:]
    if let restoreIdentifier {
      options[CBCentralManagerOptionRestoreIdentifierKey] = restoreIdentifier
    }
    central = CBCentralManager(delegate: self, queue: nil, options: options)
  }

  private func poweredOnCentral() throws -> CBCentralManager {
    ensureCentral(restoreIdentifier: nil)
    guard let central else {
      throw BleErrorMapping.bluetoothUnavailable("Central manager unavailable")
    }
    switch central.state {
    case .poweredOn:
      return central
    case .poweredOff:
      throw BleErrorMapping.bluetoothOff()
    case .unsupported, .unauthorized:
      throw BleErrorMapping.bluetoothUnavailable("Bluetooth LE unavailable")
    case .unknown, .resetting:
      throw BleErrorMapping.bluetoothUnavailable("Bluetooth is not ready")
    @unknown default:
      throw BleErrorMapping.bluetoothUnavailable("Unknown Bluetooth state")
    }
  }

  private func peripheral(for deviceId: String, central: CBCentralManager) -> CBPeripheral? {
    if let peripheral = peripheralsByDeviceId[deviceId] {
      return peripheral
    }
    guard let uuid = UUID(uuidString: deviceId) else {
      return nil
    }
    return central.retrievePeripherals(withIdentifiers: [uuid]).first
  }

  private func emitCurrentAdapterState() {
    let adapterState = adapterState(from: central?.state ?? .unknown)
    state.adapterStateChanged(adapterState)
    emitAdapterState(adapterState)
  }

  private func emitAdapterState(_ adapterState: AdapterStateMessage) {
    activeCallbacks?.onAdapterStateChanged(state: adapterState) { _ in }
  }

  private func emitConnectionState(
    deviceId: String,
    epoch: Int64,
    state: ConnectionStateMessage,
    reason: DisconnectReasonMessage?
  ) {
    activeCallbacks?.onConnectionStateChanged(
      deviceId: deviceId,
      connectionEpoch: epoch,
      state: state,
      disconnectReason: reason
    ) { _ in }
  }

  private func emitStateResync() {
    let devices = state.snapshots.map { snapshot in
      StateSnapshotMessage(
        deviceId: snapshot.deviceId,
        connectionEpoch: snapshot.epoch,
        state: connectionStateMessage(from: snapshot.state),
        disconnectReason: nil,
        activeNotifyHandles: [],
        services: nil,
        restored: restoredDeviceIds.contains(snapshot.deviceId)
      )
    }
    let snapshot = StateResyncMessage(
      snapshotId: UUID().uuidString,
      devices: devices
    )
    activeCallbacks?.onStateResync(snapshot: snapshot) { _ in }
  }

  private func adapterState(from state: CBManagerState) -> AdapterStateMessage {
    switch state {
    case .poweredOn:
      return .poweredOn
    case .poweredOff:
      return .poweredOff
    case .unsupported, .unauthorized:
      return .unavailable
    case .unknown, .resetting:
      return .unavailable
    @unknown default:
      return .unavailable
    }
  }

  private func connectionState(from state: CBPeripheralState) -> ConnectionStateMessage {
    switch state {
    case .connected:
      return .connected
    case .connecting:
      return .reconnecting
    case .disconnected, .disconnecting:
      return .disconnected
    @unknown default:
      return .disconnected
    }
  }

  private func connectionStateMessage(
    from state: IosConnectionLifecycleState
  ) -> ConnectionStateMessage {
    switch state {
    case .pending:
      return .reconnecting
    case .connected:
      return .connected
    case .disconnected:
      return .disconnected
    }
  }

  private func matchesScanFilter(
    deviceId: String,
    peripheral: CBPeripheral,
    advertisementData: [String: Any],
    filter: ScanFilterMessage?
  ) -> Bool {
    guard let filter else {
      return true
    }
    if filter.addresses.isEmpty &&
      filter.names.isEmpty &&
      filter.manufacturerData.isEmpty &&
      filter.serviceData.isEmpty &&
      filter.serviceUuids.isEmpty {
      return true
    }
    if filter.addresses.contains(where: { $0.caseInsensitiveCompare(deviceId) == .orderedSame }) {
      return true
    }
    let name = advertisedName(peripheral: peripheral, advertisementData: advertisementData)
    if let name, filter.names.contains(name) {
      return true
    }
    let advertisedServices = Set(serviceUuids(advertisementData: advertisementData).map { $0.uppercased() })
    if filter.serviceUuids.contains(where: { advertisedServices.contains($0.uppercased()) }) {
      return true
    }
    if matchesManufacturerData(filter.manufacturerData, advertisementData: advertisementData) {
      return true
    }
    if matchesServiceData(filter.serviceData, advertisementData: advertisementData) {
      return true
    }
    return false
  }

  private func advertisedName(
    peripheral: CBPeripheral,
    advertisementData: [String: Any]
  ) -> String? {
    advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name
  }

  private func serviceUuids(advertisementData: [String: Any]) -> [String] {
    let serviceUuids = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
    let overflow = advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID] ?? []
    return (serviceUuids + overflow).map(\.uuidString)
  }

  private func manufacturerData(advertisementData: [String: Any]) -> FlutterStandardTypedData? {
    guard let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
      return nil
    }
    return FlutterStandardTypedData(bytes: data)
  }

  private func matchesManufacturerData(
    _ filters: [ManufacturerDataFilterMessage],
    advertisementData: [String: Any]
  ) -> Bool {
    guard !filters.isEmpty,
          let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
          data.count >= 2
    else {
      return false
    }
    let manufacturerId = Int(data[0]) | (Int(data[1]) << 8)
    let payload = data.dropFirst(2)
    return filters.contains { filter in
      filter.manufacturerId == Int64(manufacturerId) &&
        payload.starts(with: filter.data.data)
    }
  }

  private func matchesServiceData(
    _ filters: [ServiceDataFilterMessage],
    advertisementData: [String: Any]
  ) -> Bool {
    guard !filters.isEmpty,
          let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data]
    else {
      return false
    }
    return filters.contains { filter in
      serviceData.contains { uuid, data in
        uuid.uuidString.caseInsensitiveCompare(filter.serviceUuid) == .orderedSame &&
          data.starts(with: filter.data.data)
      }
    }
  }
}
#endif
