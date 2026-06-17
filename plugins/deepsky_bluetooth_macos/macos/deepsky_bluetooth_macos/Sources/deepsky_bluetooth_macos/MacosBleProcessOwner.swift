#if os(macOS)
import CoreBluetooth
import FlutterMacOS
import Foundation

/// macOS の CBCentralManager owner。
/// Issue #35 の範囲: scan/filter・connect/cancel・adapter state・epoch 採番と
/// callback guard・foreground 再接続に必要な生 event の公開。
/// GATT discovery / read / notify / FIFO queue は後続 Issue (#36-#38) で追加する。
final class MacosBleProcessOwner: NSObject, CBCentralManagerDelegate {
  static let shared = MacosBleProcessOwner()

  private let state = MacosNativeOwnerState()
  private var central: CBCentralManager?
  private var callbacksByEngine: [String: BleCallbacksApi] = [:]
  private var activeEngineToken: String?
  private var scanFilter: ScanFilterMessage?
  private var isScanning = false
  private var peripheralsByDeviceId: [String: CBPeripheral] = [:]

  private override init() {
    super.init()
  }

  // MARK: - Sink / lifecycle

  func registerSink(engineToken: String, callbacks: BleCallbacksApi) {
    callbacksByEngine[engineToken] = callbacks
  }

  func unregisterSink(engineToken: String) {
    callbacksByEngine.removeValue(forKey: engineToken)
    if activeEngineToken == engineToken {
      activeEngineToken = nil
    }
  }

  func notifyDartReady(engineToken: String) {
    activeEngineToken = engineToken
    emitCurrentAdapterState()
  }

  // MARK: - Scan

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

  // MARK: - Connect / disconnect

  func connect(
    deviceId: String,
    completion: @escaping (Result<ConnectionAttemptMessage, Error>) -> Void
  ) {
    ensureCentral()
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
    // poweredOn でないときは pending のまま据え置き、centralManagerDidUpdateState で再開する。
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

  func dispose() {
    stopScan()
    for (deviceId, peripheral) in peripheralsByDeviceId {
      if let epoch = state.currentEpoch(deviceId: deviceId) {
        _ = state.disconnectRequested(deviceId: deviceId, epoch: epoch)
      }
      central?.cancelPeripheralConnection(peripheral)
    }
    peripheralsByDeviceId.removeAll()
    callbacksByEngine.removeAll()
    activeEngineToken = nil
  }

  // MARK: - CBCentralManagerDelegate

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    let adapterState = adapterState(from: central.state)
    state.adapterStateChanged(adapterState)
    emitAdapterState(adapterState)

    guard central.state == .poweredOn else {
      return
    }

    // poweredOn 復帰時に pending な connect を再開する（foreground 再接続の土台）。
    for deviceId in state.pendingDeviceIds {
      if let peripheral = peripheralsByDeviceId[deviceId] {
        central.connect(peripheral, options: nil)
      }
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
    // 接続が確立しないまま失敗した場合は常に connectFailed とする（§6）。
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
    // CBError から切断 reason を導く。圏外・切断は終端理由へ縮退させない（§6）。
    let reason = ManagerStateMapping.disconnectReason(for: connectionFailure(from: error))
    emitConnectionState(
      deviceId: deviceId,
      epoch: epoch,
      state: .disconnected,
      reason: reason
    )
  }

  // MARK: - Central helpers

  private var activeCallbacks: BleCallbacksApi? {
    activeEngineToken.flatMap { callbacksByEngine[$0] }
  }

  private func ensureCentral() {
    guard central == nil else {
      return
    }
    // macOS は CoreBluetooth の state restoration を持たないため restoreIdentifier は使わない。
    central = CBCentralManager(delegate: self, queue: nil)
  }

  private func poweredOnCentral() throws -> CBCentralManager {
    ensureCentral()
    guard let central else {
      throw BleErrorMapping.bluetoothUnavailable("Central manager unavailable")
    }
    // unauthorized / poweredOff / unsupported を区別したガード（§6）。
    if let guardError = ManagerStateMapping.connectGuardError(for: bleManagerState(central.state)) {
      throw bleError(guardError.code, guardError.message)
    }
    return central
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

  private func adapterState(from state: CBManagerState) -> AdapterStateMessage {
    ManagerStateMapping.adapterState(for: bleManagerState(state))
  }

  /// CBManagerState を CoreBluetooth 非依存の純粋判断へ橋渡しする。
  private func bleManagerState(_ state: CBManagerState) -> BleManagerState {
    switch state {
    case .poweredOn: return .poweredOn
    case .poweredOff: return .poweredOff
    case .unsupported: return .unsupported
    case .unauthorized: return .unauthorized
    case .resetting: return .resetting
    case .unknown: return .unknown
    @unknown default: return .unknown
    }
  }

  /// CBError.Code を CoreBluetooth 非依存の失敗種別へ橋渡しする。
  private func connectionFailure(from error: Error?) -> BleConnectionFailure {
    guard let error else { return .none }
    guard let cbError = error as? CBError else { return .other }
    switch cbError.code {
    case .connectionTimeout: return .timeout
    case .peripheralDisconnected: return .peripheralDisconnected
    case .connectionFailed: return .connectionFailed
    case .connectionLimitReached: return .limitReached
    default: return .other
    }
  }

  // MARK: - Scan filter helpers

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
