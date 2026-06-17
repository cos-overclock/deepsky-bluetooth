#if os(iOS)
import Flutter
import Foundation

final class IosBleHostApi: BleHostApi {
  private let engineToken: String
  private let owner: IosBleProcessOwner

  init(engineToken: String, owner: IosBleProcessOwner = .shared) {
    self.engineToken = engineToken
    self.owner = owner
  }

  func initialize(request: InitializeRequestMessage) throws -> String {
    _ = owner.initialize(request: request)
    return engineToken
  }

  func notifyDartReady(engineToken: String) throws {
    owner.notifyDartReady(engineToken: engineToken)
  }

  func ackStateResync(engineToken: String, snapshotId: String) throws {
    owner.ackStateResync(engineToken: engineToken, snapshotId: snapshotId)
  }

  func startScan(filter: ScanFilterMessage?, settings: DarwinScanSettingsMessage) throws {
    try owner.startScan(filter: filter, settings: settings)
  }

  func stopScan() throws {
    owner.stopScan()
  }

  func connect(
    deviceId: String,
    completion: @escaping (Result<ConnectionAttemptMessage, Error>) -> Void
  ) {
    owner.connect(deviceId: deviceId, completion: completion)
  }

  func disconnect(
    deviceId: String,
    connectionEpoch: Int64,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    owner.disconnect(deviceId: deviceId, connectionEpoch: connectionEpoch, completion: completion)
  }

  func discoverServices(
    deviceId: String,
    connectionEpoch: Int64,
    completion: @escaping (Result<[ServiceMessage], Error>) -> Void
  ) {
    owner.discoverServices(
      deviceId: deviceId,
      connectionEpoch: connectionEpoch,
      completion: completion
    )
  }

  func readCharacteristic(
    target: CharacteristicTargetMessage,
    strictRead: Bool,
    completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void
  ) {
    owner.readCharacteristic(target: target, strictRead: strictRead, completion: completion)
  }

  func writeCharacteristic(
    target: CharacteristicTargetMessage,
    value: FlutterStandardTypedData,
    withResponse: Bool,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    owner.writeCharacteristic(
      target: target,
      value: value,
      withResponse: withResponse,
      completion: completion
    )
  }

  func setNotify(
    target: CharacteristicTargetMessage,
    type: NotifyTypeMessage,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    owner.setNotify(target: target, type: type, completion: completion)
  }

  func readDescriptor(
    target: DescriptorTargetMessage,
    completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void
  ) {
    owner.readDescriptor(target: target, completion: completion)
  }

  func writeDescriptor(
    target: DescriptorTargetMessage,
    value: FlutterStandardTypedData,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    owner.writeDescriptor(target: target, value: value, completion: completion)
  }

  func getMtu(
    deviceId: String,
    connectionEpoch: Int64,
    completion: @escaping (Result<Int64, Error>) -> Void
  ) {
    owner.getMtu(deviceId: deviceId, connectionEpoch: connectionEpoch, completion: completion)
  }

  func readRssi(
    deviceId: String,
    connectionEpoch: Int64,
    completion: @escaping (Result<Int64, Error>) -> Void
  ) {
    owner.readRssi(deviceId: deviceId, connectionEpoch: connectionEpoch, completion: completion)
  }

  func dispose() throws {
    owner.dispose()
  }
}
#endif
