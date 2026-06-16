import 'dart:typed_data';

import 'package:deepsky_bluetooth_util/deepsky_bluetooth_util.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';

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

@Freezed(copyWith: false)
abstract class ReconnectPolicy with _$ReconnectPolicy {
  const factory ReconnectPolicy({
    @Default(Duration(seconds: 5)) Duration delay,
  }) = _ReconnectPolicy;
}

@Freezed(copyWith: false)
abstract class BleConnectionEvent with _$BleConnectionEvent {
  @Assert(
    'state == BleConnectionState.disconnected ? reason != null : reason == null',
    'Only disconnected events must have a reason.',
  )
  const factory BleConnectionEvent({
    required BleConnectionState state,
    BleDisconnectReason? reason,
  }) = _BleConnectionEvent;
}

@Freezed(copyWith: false)
abstract class DeepskyScanFilterManufacturerData
    with _$DeepskyScanFilterManufacturerData {
  const factory DeepskyScanFilterManufacturerData({
    required int manufacturerId,
    required Uint8List data,
  }) = _DeepskyScanFilterManufacturerData;
}

@Freezed(copyWith: false)
abstract class DeepskyScanFilterServiceData
    with _$DeepskyScanFilterServiceData {
  const factory DeepskyScanFilterServiceData({
    required DeepskyUuid uuid,
    required Uint8List data,
  }) = _DeepskyScanFilterServiceData;
}

@Freezed(copyWith: false)
abstract class DeepskyScanFilter with _$DeepskyScanFilter {
  const factory DeepskyScanFilter({
    @Default(<DeepskyDeviceId>[]) List<DeepskyDeviceId> deviceIds,
    @Default(<String>[]) List<String> names,
    @Default(<DeepskyScanFilterManufacturerData>[])
    List<DeepskyScanFilterManufacturerData> manufacturerData,
    @Default(<DeepskyScanFilterServiceData>[])
    List<DeepskyScanFilterServiceData> serviceData,
    @Default(<DeepskyUuid>[]) List<DeepskyUuid> serviceUuids,
  }) = _DeepskyScanFilter;
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

@Freezed(copyWith: false)
abstract class DeepskyAndroidScanSetting with _$DeepskyAndroidScanSetting {
  const factory DeepskyAndroidScanSetting({
    @Default(DeepskyAndroidScanMode.lowLatency) DeepskyAndroidScanMode mode,
    @Default(DeepskyAndroidScanCallbackType.allMatches)
    DeepskyAndroidScanCallbackType callbackType,
    @Default(true) bool onlyLegacy,
    @Default(DeepskyAndroidScanMatchMode.aggressive)
    DeepskyAndroidScanMatchMode matchMode,
    @Default(DeepskyAndroidScanNumOfMatch.maxAdvertisement)
    DeepskyAndroidScanNumOfMatch numOfMatch,
    @Default(Duration.zero) Duration reportDelay,
    @Default(DeepskyAndroidScanPhy.allSupported) DeepskyAndroidScanPhy phy,
  }) = _DeepskyAndroidScanSetting;
}

@Freezed(copyWith: false)
abstract class DeepskyDarwinScanSetting with _$DeepskyDarwinScanSetting {
  const factory DeepskyDarwinScanSetting({
    @Default(false) bool allowDuplicates,
    @Default(<DeepskyUuid>[]) List<DeepskyUuid> solicitedServiceUuids,
  }) = _DeepskyDarwinScanSetting;
}

@Freezed(copyWith: false)
abstract class DeepskyScanOptions with _$DeepskyScanOptions {
  const factory DeepskyScanOptions({
    @Default(DeepskyAndroidScanSetting()) DeepskyAndroidScanSetting android,
    @Default(DeepskyDarwinScanSetting()) DeepskyDarwinScanSetting darwin,
  }) = _DeepskyScanOptions;
}

@Freezed(copyWith: false)
abstract class BleScanResult with _$BleScanResult {
  const factory BleScanResult({
    required DeepskyDeviceId deviceId,
    required int rssi,
    required List<DeepskyUuid> serviceUuids,
    String? name,
    Uint8List? manufacturerData,
    Uint8List? raw,
  }) = _BleScanResult;
}

enum BleCharacteristicProperty {
  broadcast,
  read,
  writeWithoutResponse,
  writeWithResponse,
  notify,
  indicate,
  authenticatedSignedWrites,
  extendedProperties,
}

@Freezed(copyWith: false)
abstract class BleCharacteristicProperties with _$BleCharacteristicProperties {
  const factory BleCharacteristicProperties({
    @Default(<BleCharacteristicProperty>[])
    List<BleCharacteristicProperty> values,
  }) = _BleCharacteristicProperties;
}

@Freezed(copyWith: false)
abstract class BleServiceInfo with _$BleServiceInfo {
  @Assert('handle >= 0', 'handle must be non-negative')
  const factory BleServiceInfo({
    required int handle,
    required DeepskyUuid uuid,
    @Default(<BleCharacteristicInfo>[])
    List<BleCharacteristicInfo> characteristics,
  }) = _BleServiceInfo;
}

@Freezed(copyWith: false)
abstract class BleCharacteristicInfo with _$BleCharacteristicInfo {
  @Assert('handle >= 0', 'handle must be non-negative')
  @Assert('serviceHandle >= 0', 'serviceHandle must be non-negative')
  const factory BleCharacteristicInfo({
    required int handle,
    required int serviceHandle,
    required DeepskyUuid uuid,
    required BleCharacteristicProperties properties,
    @Default(<BleDescriptorInfo>[]) List<BleDescriptorInfo> descriptors,
  }) = _BleCharacteristicInfo;
}

@Freezed(copyWith: false)
abstract class BleDescriptorInfo with _$BleDescriptorInfo {
  @Assert('handle >= 0', 'handle must be non-negative')
  const factory BleDescriptorInfo({
    required int handle,
    required DeepskyUuid uuid,
  }) = _BleDescriptorInfo;
}

@Freezed(copyWith: false)
abstract class BleCharacteristicTarget with _$BleCharacteristicTarget {
  @Assert('connectionEpoch >= 0', 'connectionEpoch must be non-negative')
  @Assert('characteristicHandle >= 0', 'handle must be non-negative')
  const factory BleCharacteristicTarget({
    required DeepskyDeviceId deviceId,
    required int connectionEpoch,
    required int characteristicHandle,
  }) = _BleCharacteristicTarget;
}

@Freezed(copyWith: false)
abstract class BleDescriptorTarget with _$BleDescriptorTarget {
  @Assert('connectionEpoch >= 0', 'connectionEpoch must be non-negative')
  @Assert('characteristicHandle >= 0', 'handle must be non-negative')
  @Assert('descriptorHandle >= 0', 'handle must be non-negative')
  const factory BleDescriptorTarget({
    required DeepskyDeviceId deviceId,
    required int connectionEpoch,
    required int characteristicHandle,
    required int descriptorHandle,
  }) = _BleDescriptorTarget;
}

@Freezed(copyWith: false)
abstract class ConnectionAttempt with _$ConnectionAttempt {
  @Assert('connectionEpoch >= 0', 'connectionEpoch must be non-negative')
  const factory ConnectionAttempt({required int connectionEpoch}) =
      _ConnectionAttempt;
}

@Freezed(copyWith: false)
abstract class BlePlatformConnectionEvent with _$BlePlatformConnectionEvent {
  @Assert(
    'state == BleConnectionState.disconnected ? reason != null : reason == null',
    'Only disconnected events must have a reason.',
  )
  @Assert(
    'connectionEpoch == null || connectionEpoch >= 0',
    'connectionEpoch must be non-negative',
  )
  const factory BlePlatformConnectionEvent({
    required DeepskyDeviceId deviceId,
    required int? connectionEpoch,
    required BleConnectionState state,
    BleDisconnectReason? reason,
  }) = _BlePlatformConnectionEvent;
}

@Freezed(copyWith: false)
abstract class BleNotifyEvent with _$BleNotifyEvent {
  @Assert('connectionEpoch >= 0', 'connectionEpoch must be non-negative')
  @Assert('characteristicHandle >= 0', 'handle must be non-negative')
  const factory BleNotifyEvent({
    required DeepskyDeviceId deviceId,
    required int connectionEpoch,
    required int characteristicHandle,
    required Uint8List value,
  }) = _BleNotifyEvent;
}

@Freezed(copyWith: false)
abstract class BleOperationTimeout with _$BleOperationTimeout {
  @Assert('connectionEpoch >= 0', 'connectionEpoch must be non-negative')
  const factory BleOperationTimeout({
    required DeepskyDeviceId deviceId,
    required int connectionEpoch,
  }) = _BleOperationTimeout;
}

@Freezed(copyWith: false)
abstract class BleCompanionEvent with _$BleCompanionEvent {
  const factory BleCompanionEvent({
    required DeepskyDeviceId deviceId,
    required bool appeared,
  }) = _BleCompanionEvent;
}

@Freezed(copyWith: false)
abstract class BleStateSnapshot with _$BleStateSnapshot {
  @Assert('connectionEpoch >= 0', 'connectionEpoch must be non-negative')
  @Assert(
    'state == BleConnectionState.disconnected ? disconnectReason != null : disconnectReason == null',
    'Only disconnected snapshots must have a reason.',
  )
  const factory BleStateSnapshot({
    required DeepskyDeviceId deviceId,
    required int connectionEpoch,
    required BleConnectionState state,
    BleDisconnectReason? disconnectReason,
    @Default(<int>[]) List<int> activeNotifyHandles,
    List<BleServiceInfo>? services,
    @Default(false) bool restored,
  }) = _BleStateSnapshot;
}

@Freezed(copyWith: false)
abstract class BleStateResync with _$BleStateResync {
  const factory BleStateResync({
    required String snapshotId,
    @Default(<BleStateSnapshot>[]) List<BleStateSnapshot> devices,
  }) = _BleStateResync;
}
