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

  private override init() {
    super.init()
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
          peripheralsByDeviceId[deviceId]?.state == .connected
    else {
      completion(.failure(BleErrorMapping.notConnected()))
      return
    }
    completion(.failure(BleErrorMapping.notSupported("Service discovery is not implemented in this slice")))
  }

  func readCharacteristic(
    target: CharacteristicTargetMessage,
    strictRead: Bool,
    completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void
  ) {
    completion(.failure(BleErrorMapping.notSupported("Characteristic read is not implemented in this slice")))
  }

  func writeCharacteristic(
    target: CharacteristicTargetMessage,
    value: FlutterStandardTypedData,
    withResponse: Bool,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    completion(.failure(BleErrorMapping.notSupported("Characteristic write is not implemented in this slice")))
  }

  func setNotify(
    target: CharacteristicTargetMessage,
    type: NotifyTypeMessage,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    completion(.failure(BleErrorMapping.notSupported("Notify is not implemented in this slice")))
  }

  func readDescriptor(
    target: DescriptorTargetMessage,
    completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void
  ) {
    completion(.failure(BleErrorMapping.notSupported("Descriptor read is not implemented in this slice")))
  }

  func writeDescriptor(
    target: DescriptorTargetMessage,
    value: FlutterStandardTypedData,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    completion(.failure(BleErrorMapping.notSupported("Descriptor write is not implemented in this slice")))
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
    completion(.failure(BleErrorMapping.notSupported("RSSI read is not implemented in this slice")))
  }

  func dispose() {
    stopScan()
    peripheralsByDeviceId.forEach { entry in
      if let epoch = state.currentEpoch(deviceId: entry.key) {
        _ = state.disconnectRequested(deviceId: entry.key, epoch: epoch)
      }
      central?.cancelPeripheralConnection(entry.value)
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
    emitConnectionState(
      deviceId: deviceId,
      epoch: epoch,
      state: .disconnected,
      reason: error == nil ? .userRequested : .connectionLost
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
