import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  swiftOut:
      'ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/Messages.g.swift',
))
class InitializeRequestMessage {
  InitializeRequestMessage(
      this.isBackground, this.restoreIdentifier, this.backgroundCallbackHandle);
  bool isBackground;
  String? restoreIdentifier;
  int? backgroundCallbackHandle;
}

class ManufacturerDataFilterMessage {
  ManufacturerDataFilterMessage(this.manufacturerId, this.data);
  int manufacturerId;
  Uint8List data;
}

class ServiceDataFilterMessage {
  ServiceDataFilterMessage(this.serviceUuid, this.data);
  String serviceUuid;
  Uint8List data;
}

/// 各エントリはOR条件。serviceUuidsはFromByteArray/FromString両形式を
/// bridgeが正規化済み文字列へ統合したもの。
class ScanFilterMessage {
  ScanFilterMessage(this.addresses, this.names, this.manufacturerData,
      this.serviceData, this.serviceUuids);
  List<String> addresses;
  List<String> names;
  List<ManufacturerDataFilterMessage> manufacturerData;
  List<ServiceDataFilterMessage> serviceData;
  List<String> serviceUuids;
}

class ScanResultMessage {
  ScanResultMessage(this.deviceId, this.name, this.rssi, this.serviceUuids,
      this.manufacturerData, this.raw);
  String deviceId;
  String? name;
  int rssi;
  List<String> serviceUuids;
  Uint8List? manufacturerData;

  /// アドバタイズ生バイト列。Androidのみ。iOS/macOSはnull。
  Uint8List? raw;
}

enum ConnectionStateMessage {
  connecting,
  connected,
  disconnecting,
  disconnected,
  reconnecting,
}

enum AdapterStateMessage { poweredOn, poweredOff, unavailable }

enum NotifyTypeMessage { disable, notify, indicate }

class CharacteristicTargetMessage {
  CharacteristicTargetMessage(
      this.deviceId, this.connectionEpoch, this.characteristicHandle);
  String deviceId;
  int connectionEpoch;
  int characteristicHandle;
}

class DescriptorTargetMessage {
  DescriptorTargetMessage(this.deviceId, this.connectionEpoch,
      this.characteristicHandle, this.descriptorHandle);
  String deviceId;
  int connectionEpoch;
  int characteristicHandle;
  int descriptorHandle;
}

class DescriptorMessage {
  DescriptorMessage(this.handle, this.uuid);
  int handle;
  String uuid;
}

class CharacteristicMessage {
  CharacteristicMessage(this.handle, this.serviceHandle, this.uuid,
      this.canRead, this.canWriteWithResponse,
      this.canWriteWithoutResponse, this.canNotify, this.canIndicate,
      this.descriptors);
  int handle;
  int serviceHandle;
  String uuid;
  bool canRead;
  bool canWriteWithResponse;
  bool canWriteWithoutResponse;
  bool canNotify;
  bool canIndicate;
  List<DescriptorMessage> descriptors;
}

class ServiceMessage {
  ServiceMessage(this.handle, this.uuid, this.characteristics);
  int handle;
  String uuid;
  List<CharacteristicMessage> characteristics;
}

class ConnectionAttemptMessage {
  ConnectionAttemptMessage(this.connectionEpoch);
  int connectionEpoch;
}

class StateSnapshotMessage {
  StateSnapshotMessage(this.deviceId, this.connectionEpoch, this.state,
      this.disconnectReason, this.activeNotifyHandles, this.services, this.restored);
  String deviceId;
  int connectionEpoch;
  ConnectionStateMessage state;
  DisconnectReasonMessage? disconnectReason;
  List<int> activeNotifyHandles;
  List<ServiceMessage>? services;
  bool restored;
}

class StateResyncMessage {
  StateResyncMessage(this.snapshotId, this.devices);
  String snapshotId;
  List<StateSnapshotMessage> devices;
}

enum DisconnectReasonMessage {
  userRequested,
  connectionLost,
  connectFailed,
  operationTimeout,
  permissionDenied,
  bluetoothOff,
  bluetoothUnavailable,
  deviceNotFound,
  notAssociated,
  presenceObservationDisabled,
  unknown,
}

// disconnected callback/state snapshotでのみ使用する。
class DarwinScanSettingsMessage {
  DarwinScanSettingsMessage(this.allowDuplicates, this.solicitedServiceUuids);
  bool allowDuplicates;
  List<String> solicitedServiceUuids;
}

@HostApi()
abstract class BleHostApi {
  String initialize(InitializeRequestMessage request);
  void notifyDartReady(String engineToken);
  void ackStateResync(String engineToken, String snapshotId);
  void startScan(ScanFilterMessage? filter, DarwinScanSettingsMessage settings);
  void stopScan();
  @async
  ConnectionAttemptMessage connect(String deviceId);
  @async
  void disconnect(String deviceId, int connectionEpoch);
  @async
  List<ServiceMessage> discoverServices(String deviceId, int connectionEpoch);
  @async
  Uint8List readCharacteristic(CharacteristicTargetMessage target, bool strictRead);
  @async
  void writeCharacteristic(
      CharacteristicTargetMessage target, Uint8List value, bool withResponse);
  @async
  void setNotify(CharacteristicTargetMessage target, NotifyTypeMessage type);
  @async
  Uint8List readDescriptor(DescriptorTargetMessage target);
  @async
  void writeDescriptor(DescriptorTargetMessage target, Uint8List value);

  /// iOSはMTU要求不可のため現在値(maximumWriteValueLength+3)を返す。
  @async
  int getMtu(String deviceId, int connectionEpoch);
  @async
  int readRssi(String deviceId, int connectionEpoch);
  void dispose();
}

@FlutterApi()
abstract class BleCallbacksApi {
  void onScanResult(ScanResultMessage result);
  void onConnectionStateChanged(
      String deviceId, int? connectionEpoch, ConnectionStateMessage state,
      DisconnectReasonMessage? disconnectReason);
  void onAdapterStateChanged(AdapterStateMessage state);
  void onCharacteristicValue(String deviceId, int connectionEpoch,
      int characteristicHandle, Uint8List value);
  void onOperationTimeout(String deviceId, int connectionEpoch);
  void onStateResync(StateResyncMessage snapshot);
  void onRestoredConnections(List<String> deviceIds);
}
