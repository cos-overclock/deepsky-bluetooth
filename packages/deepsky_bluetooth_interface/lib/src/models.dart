import 'dart:typed_data';

import 'package:deepsky_bluetooth_util/deepsky_bluetooth_util.dart';

enum BleConnectionState {
  connecting,
  connected,
  disconnecting,
  disconnected,
  reconnecting,
}

enum BleDisconnectReason {
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

enum BleNotifyType { disable, notify, indicate }

enum BleAdapterState { poweredOn, poweredOff, unavailable }

class ReconnectPolicy {
  const ReconnectPolicy({this.delay = const Duration(seconds: 5)});

  final Duration delay;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReconnectPolicy && delay == other.delay;

  @override
  int get hashCode => delay.hashCode;
}

class BleConnectionEvent {
  const BleConnectionEvent({required this.state, this.reason})
    : assert(
        state == BleConnectionState.disconnected
            ? reason != null
            : reason == null,
        'Only disconnected events must have a reason.',
      );

  final BleConnectionState state;
  final BleDisconnectReason? reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleConnectionEvent &&
          state == other.state &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(state, reason);
}

class DeepskyScanFilterManufacturerData {
  const DeepskyScanFilterManufacturerData({
    required this.manufacturerId,
    required this.data,
  });

  final int manufacturerId;
  final Uint8List data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeepskyScanFilterManufacturerData &&
          manufacturerId == other.manufacturerId &&
          _bytesEqual(data, other.data);

  @override
  int get hashCode => Object.hash(manufacturerId, _bytesHash(data));
}

class DeepskyScanFilterServiceData {
  const DeepskyScanFilterServiceData({required this.uuid, required this.data});

  final DeepskyUuid uuid;
  final Uint8List data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeepskyScanFilterServiceData &&
          uuid == other.uuid &&
          _bytesEqual(data, other.data);

  @override
  int get hashCode => Object.hash(uuid, _bytesHash(data));
}

class DeepskyScanFilter {
  const DeepskyScanFilter({
    this.deviceIds = const [],
    this.names = const [],
    this.manufacturerData = const [],
    this.serviceData = const [],
    this.serviceUuids = const [],
  });

  final List<DeepskyDeviceId> deviceIds;
  final List<String> names;
  final List<DeepskyScanFilterManufacturerData> manufacturerData;
  final List<DeepskyScanFilterServiceData> serviceData;
  final List<DeepskyUuid> serviceUuids;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeepskyScanFilter &&
          _listEqual(deviceIds, other.deviceIds) &&
          _listEqual(names, other.names) &&
          _listEqual(manufacturerData, other.manufacturerData) &&
          _listEqual(serviceData, other.serviceData) &&
          _listEqual(serviceUuids, other.serviceUuids);

  @override
  int get hashCode => Object.hash(
    _listHash(deviceIds),
    _listHash(names),
    _listHash(manufacturerData),
    _listHash(serviceData),
    _listHash(serviceUuids),
  );
}

enum DeepskyAndroidScanMode { lowPower, balanced, lowLatency, opportunistic }

enum DeepskyAndroidScanCallbackType {
  allMatches,
  firstMatch,
  matchLost,
  firstMatchAndMatchLost,
}

enum DeepskyAndroidScanMatchMode { aggressive, sticky }

enum DeepskyAndroidScanNumOfMatch {
  oneAdvertisement,
  fewAdvertisement,
  maxAdvertisement,
}

enum DeepskyAndroidScanPhy { le1m, leCoded, allSupported }

class DeepskyAndroidScanSetting {
  const DeepskyAndroidScanSetting({
    this.mode = DeepskyAndroidScanMode.lowLatency,
    this.callbackType = DeepskyAndroidScanCallbackType.allMatches,
    this.onlyLegacy = true,
    this.matchMode = DeepskyAndroidScanMatchMode.aggressive,
    this.numOfMatch = DeepskyAndroidScanNumOfMatch.maxAdvertisement,
    this.reportDelay = Duration.zero,
    this.phy = DeepskyAndroidScanPhy.allSupported,
  });

  final DeepskyAndroidScanMode mode;
  final DeepskyAndroidScanCallbackType callbackType;
  final bool onlyLegacy;
  final DeepskyAndroidScanMatchMode matchMode;
  final DeepskyAndroidScanNumOfMatch numOfMatch;
  final Duration reportDelay;
  final DeepskyAndroidScanPhy phy;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeepskyAndroidScanSetting &&
          mode == other.mode &&
          callbackType == other.callbackType &&
          onlyLegacy == other.onlyLegacy &&
          matchMode == other.matchMode &&
          numOfMatch == other.numOfMatch &&
          reportDelay == other.reportDelay &&
          phy == other.phy;

  @override
  int get hashCode => Object.hash(
    mode,
    callbackType,
    onlyLegacy,
    matchMode,
    numOfMatch,
    reportDelay,
    phy,
  );
}

class DeepskyDarwinScanSetting {
  const DeepskyDarwinScanSetting({
    this.allowDuplicates = false,
    this.solicitedServiceUuids = const [],
  });

  final bool allowDuplicates;
  final List<DeepskyUuid> solicitedServiceUuids;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeepskyDarwinScanSetting &&
          allowDuplicates == other.allowDuplicates &&
          _listEqual(solicitedServiceUuids, other.solicitedServiceUuids);

  @override
  int get hashCode =>
      Object.hash(allowDuplicates, _listHash(solicitedServiceUuids));
}

class DeepskyScanOptions {
  const DeepskyScanOptions({
    this.android = const DeepskyAndroidScanSetting(),
    this.darwin = const DeepskyDarwinScanSetting(),
  });

  final DeepskyAndroidScanSetting android;
  final DeepskyDarwinScanSetting darwin;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeepskyScanOptions &&
          android == other.android &&
          darwin == other.darwin;

  @override
  int get hashCode => Object.hash(android, darwin);
}

class BleScanResult {
  const BleScanResult({
    required this.deviceId,
    required this.rssi,
    required this.serviceUuids,
    this.name,
    this.manufacturerData,
    this.raw,
  });

  final DeepskyDeviceId deviceId;
  final String? name;
  final int rssi;
  final List<DeepskyUuid> serviceUuids;
  final Uint8List? manufacturerData;
  final Uint8List? raw;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleScanResult &&
          deviceId == other.deviceId &&
          name == other.name &&
          rssi == other.rssi &&
          _listEqual(serviceUuids, other.serviceUuids) &&
          _nullableBytesEqual(manufacturerData, other.manufacturerData) &&
          _nullableBytesEqual(raw, other.raw);

  @override
  int get hashCode => Object.hash(
    deviceId,
    name,
    rssi,
    _listHash(serviceUuids),
    _nullableBytesHash(manufacturerData),
    _nullableBytesHash(raw),
  );
}

class BleCharacteristicProperties {
  const BleCharacteristicProperties({
    this.broadcast = false,
    this.read = false,
    this.writeWithoutResponse = false,
    this.writeWithResponse = false,
    this.notify = false,
    this.indicate = false,
    this.authenticatedSignedWrites = false,
    this.extendedProperties = false,
  });

  final bool broadcast;
  final bool read;
  final bool writeWithoutResponse;
  final bool writeWithResponse;
  final bool notify;
  final bool indicate;
  final bool authenticatedSignedWrites;
  final bool extendedProperties;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleCharacteristicProperties &&
          broadcast == other.broadcast &&
          read == other.read &&
          writeWithoutResponse == other.writeWithoutResponse &&
          writeWithResponse == other.writeWithResponse &&
          notify == other.notify &&
          indicate == other.indicate &&
          authenticatedSignedWrites == other.authenticatedSignedWrites &&
          extendedProperties == other.extendedProperties;

  @override
  int get hashCode => Object.hash(
    broadcast,
    read,
    writeWithoutResponse,
    writeWithResponse,
    notify,
    indicate,
    authenticatedSignedWrites,
    extendedProperties,
  );
}

class BleServiceInfo {
  const BleServiceInfo({
    required this.handle,
    required this.uuid,
    this.characteristics = const [],
  }) : assert(handle >= 0, 'handle must be non-negative');

  final int handle;
  final DeepskyUuid uuid;
  final List<BleCharacteristicInfo> characteristics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleServiceInfo &&
          handle == other.handle &&
          uuid == other.uuid &&
          _listEqual(characteristics, other.characteristics);

  @override
  int get hashCode => Object.hash(handle, uuid, _listHash(characteristics));
}

class BleCharacteristicInfo {
  const BleCharacteristicInfo({
    required this.handle,
    required this.serviceHandle,
    required this.uuid,
    required this.properties,
    this.descriptors = const [],
  }) : assert(handle >= 0, 'handle must be non-negative'),
       assert(serviceHandle >= 0, 'serviceHandle must be non-negative');

  final int handle;
  final int serviceHandle;
  final DeepskyUuid uuid;
  final BleCharacteristicProperties properties;
  final List<BleDescriptorInfo> descriptors;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleCharacteristicInfo &&
          handle == other.handle &&
          serviceHandle == other.serviceHandle &&
          uuid == other.uuid &&
          properties == other.properties &&
          _listEqual(descriptors, other.descriptors);

  @override
  int get hashCode => Object.hash(
    handle,
    serviceHandle,
    uuid,
    properties,
    _listHash(descriptors),
  );
}

class BleDescriptorInfo {
  const BleDescriptorInfo({required this.handle, required this.uuid})
    : assert(handle >= 0, 'handle must be non-negative');

  final int handle;
  final DeepskyUuid uuid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleDescriptorInfo &&
          handle == other.handle &&
          uuid == other.uuid;

  @override
  int get hashCode => Object.hash(handle, uuid);
}

class BleCharacteristicTarget {
  const BleCharacteristicTarget({
    required this.deviceId,
    required this.connectionEpoch,
    required this.characteristicHandle,
  }) : assert(connectionEpoch >= 0, 'connectionEpoch must be non-negative'),
       assert(characteristicHandle >= 0, 'handle must be non-negative');

  final DeepskyDeviceId deviceId;
  final int connectionEpoch;
  final int characteristicHandle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleCharacteristicTarget &&
          deviceId == other.deviceId &&
          connectionEpoch == other.connectionEpoch &&
          characteristicHandle == other.characteristicHandle;

  @override
  int get hashCode =>
      Object.hash(deviceId, connectionEpoch, characteristicHandle);
}

class BleDescriptorTarget {
  const BleDescriptorTarget({
    required this.deviceId,
    required this.connectionEpoch,
    required this.characteristicHandle,
    required this.descriptorHandle,
  }) : assert(connectionEpoch >= 0, 'connectionEpoch must be non-negative'),
       assert(characteristicHandle >= 0, 'handle must be non-negative'),
       assert(descriptorHandle >= 0, 'handle must be non-negative');

  final DeepskyDeviceId deviceId;
  final int connectionEpoch;
  final int characteristicHandle;
  final int descriptorHandle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleDescriptorTarget &&
          deviceId == other.deviceId &&
          connectionEpoch == other.connectionEpoch &&
          characteristicHandle == other.characteristicHandle &&
          descriptorHandle == other.descriptorHandle;

  @override
  int get hashCode => Object.hash(
    deviceId,
    connectionEpoch,
    characteristicHandle,
    descriptorHandle,
  );
}

class ConnectionAttempt {
  const ConnectionAttempt({required this.connectionEpoch})
    : assert(connectionEpoch >= 0, 'connectionEpoch must be non-negative');

  final int connectionEpoch;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionAttempt && connectionEpoch == other.connectionEpoch;

  @override
  int get hashCode => connectionEpoch.hashCode;
}

class BlePlatformConnectionEvent {
  const BlePlatformConnectionEvent({
    required this.deviceId,
    required this.connectionEpoch,
    required this.state,
    this.reason,
  }) : assert(
         state == BleConnectionState.disconnected
             ? reason != null
             : reason == null,
         'Only disconnected events must have a reason.',
       ),
       assert(
         connectionEpoch == null || connectionEpoch >= 0,
         'connectionEpoch must be non-negative',
       );

  final DeepskyDeviceId deviceId;
  final int? connectionEpoch;
  final BleConnectionState state;
  final BleDisconnectReason? reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlePlatformConnectionEvent &&
          deviceId == other.deviceId &&
          connectionEpoch == other.connectionEpoch &&
          state == other.state &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(deviceId, connectionEpoch, state, reason);
}

class BleNotifyEvent {
  const BleNotifyEvent({
    required this.deviceId,
    required this.connectionEpoch,
    required this.characteristicHandle,
    required this.value,
  }) : assert(connectionEpoch >= 0, 'connectionEpoch must be non-negative'),
       assert(characteristicHandle >= 0, 'handle must be non-negative');

  final DeepskyDeviceId deviceId;
  final int connectionEpoch;
  final int characteristicHandle;
  final Uint8List value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleNotifyEvent &&
          deviceId == other.deviceId &&
          connectionEpoch == other.connectionEpoch &&
          characteristicHandle == other.characteristicHandle &&
          _bytesEqual(value, other.value);

  @override
  int get hashCode => Object.hash(
    deviceId,
    connectionEpoch,
    characteristicHandle,
    _bytesHash(value),
  );
}

class BleOperationTimeout {
  const BleOperationTimeout({
    required this.deviceId,
    required this.connectionEpoch,
  }) : assert(connectionEpoch >= 0, 'connectionEpoch must be non-negative');

  final DeepskyDeviceId deviceId;
  final int connectionEpoch;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleOperationTimeout &&
          deviceId == other.deviceId &&
          connectionEpoch == other.connectionEpoch;

  @override
  int get hashCode => Object.hash(deviceId, connectionEpoch);
}

class BleCompanionEvent {
  const BleCompanionEvent({required this.deviceId, required this.appeared});

  final DeepskyDeviceId deviceId;
  final bool appeared;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleCompanionEvent &&
          deviceId == other.deviceId &&
          appeared == other.appeared;

  @override
  int get hashCode => Object.hash(deviceId, appeared);
}

class BleStateSnapshot {
  const BleStateSnapshot({
    required this.deviceId,
    required this.connectionEpoch,
    required this.state,
    this.disconnectReason,
    this.activeNotifyHandles = const [],
    this.services,
    this.restored = false,
  }) : assert(connectionEpoch >= 0, 'connectionEpoch must be non-negative'),
       assert(
         state == BleConnectionState.disconnected
             ? disconnectReason != null
             : disconnectReason == null,
         'Only disconnected snapshots must have a reason.',
       );

  final DeepskyDeviceId deviceId;
  final int connectionEpoch;
  final BleConnectionState state;
  final BleDisconnectReason? disconnectReason;
  final List<int> activeNotifyHandles;
  final List<BleServiceInfo>? services;
  final bool restored;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleStateSnapshot &&
          deviceId == other.deviceId &&
          connectionEpoch == other.connectionEpoch &&
          state == other.state &&
          disconnectReason == other.disconnectReason &&
          _listEqual(activeNotifyHandles, other.activeNotifyHandles) &&
          _nullableListEqual(services, other.services) &&
          restored == other.restored;

  @override
  int get hashCode => Object.hash(
    deviceId,
    connectionEpoch,
    state,
    disconnectReason,
    _listHash(activeNotifyHandles),
    _nullableListHash(services),
    restored,
  );
}

class BleStateResync {
  const BleStateResync({required this.snapshotId, this.devices = const []});

  final String snapshotId;
  final List<BleStateSnapshot> devices;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleStateResync &&
          snapshotId == other.snapshotId &&
          _listEqual(devices, other.devices);

  @override
  int get hashCode => Object.hash(snapshotId, _listHash(devices));
}

bool _listEqual<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

bool _nullableListEqual<T>(List<T>? left, List<T>? right) {
  if (left == null || right == null) {
    return left == right;
  }
  return _listEqual(left, right);
}

int _listHash<T>(List<T> values) => Object.hashAll(values);

int _nullableListHash<T>(List<T>? values) {
  if (values == null) {
    return 0;
  }
  return _listHash(values);
}

bool _bytesEqual(Uint8List left, Uint8List right) => _listEqual(left, right);

bool _nullableBytesEqual(Uint8List? left, Uint8List? right) {
  if (left == null || right == null) {
    return left == right;
  }
  return _bytesEqual(left, right);
}

int _bytesHash(Uint8List value) => Object.hashAll(value);

int _nullableBytesHash(Uint8List? value) {
  if (value == null) {
    return 0;
  }
  return _bytesHash(value);
}
