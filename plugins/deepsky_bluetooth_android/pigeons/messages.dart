import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  kotlinOut:
      'android/src/main/kotlin/com/example/deepsky_bluetooth_android/Messages.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.example.deepsky_bluetooth_android'),
))
enum BackgroundStrategyMessage { foregroundService, companionDevice }

class NotificationConfigMessage {
  NotificationConfigMessage(this.channelId, this.channelName, this.title, this.text);
  String channelId;
  String channelName;
  String title;
  String text;
}

class InitializeRequestMessage {
  InitializeRequestMessage(this.isBackground, this.strategy, this.notification,
      this.backgroundCallbackHandle);
  bool isBackground;
  BackgroundStrategyMessage? strategy;
  NotificationConfigMessage? notification;
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

enum ScanModeMessage { lowPower, balanced, lowLatency, opportunistic }

enum ScanCallbackTypeMessage {
  allMatches,
  firstMatch,
  matchLost,
  firstMatchAndMatchLost,
}

enum ScanMatchModeMessage { aggressive, sticky }

enum ScanNumOfMatchMessage { one, few, max }

enum ScanPhyMessage { le1m, leCoded, allSupported }

class AndroidScanSettingsMessage {
  AndroidScanSettingsMessage(this.mode, this.callbackType, this.onlyLegacy,
      this.matchMode, this.numOfMatch, this.reportDelayMillis, this.phy);
  ScanModeMessage mode;
  ScanCallbackTypeMessage callbackType;
  bool onlyLegacy;
  ScanMatchModeMessage matchMode;
  ScanNumOfMatchMessage numOfMatch;
  int reportDelayMillis;
  ScanPhyMessage phy;
}

@HostApi()
abstract class BleHostApi {
  /// 戻り値はengineごとのopaque token。attach時点では候補sinkのまま。
  String initialize(InitializeRequestMessage request);

  /// FlutterApi.setUp後に呼ぶ。snapshotのackまでは旧sinkをactiveのまま保つ。
  void notifyDartReady(String engineToken);
  void ackStateResync(String engineToken, String snapshotId);
  void startScan(ScanFilterMessage? filter, AndroidScanSettingsMessage settings);
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
  @async
  int requestMtu(String deviceId, int connectionEpoch, int mtu);
  @async
  int readRssi(String deviceId, int connectionEpoch);
  @async
  String associate(ScanFilterMessage? filter);
  void setDevicePresenceObservation(String deviceId, bool enabled);
  void dispose();
}

@FlutterApi()
abstract class BleCallbacksApi {
  void onScanResult(ScanResultMessage result);
  void onScanFailed(String code, String message);
  void onConnectionStateChanged(
      String deviceId, int? connectionEpoch, ConnectionStateMessage state,
      DisconnectReasonMessage? disconnectReason);
  void onAdapterStateChanged(AdapterStateMessage state);
  void onCharacteristicValue(String deviceId, int connectionEpoch,
      int characteristicHandle, Uint8List value);
  void onOperationTimeout(String deviceId, int connectionEpoch);
  void onDeviceAppeared(String deviceId);
  void onDeviceDisappeared(String deviceId);
  void onStateResync(StateResyncMessage snapshot);
}
