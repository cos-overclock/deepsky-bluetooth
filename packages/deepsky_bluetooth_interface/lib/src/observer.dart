import 'dart:typed_data';

import 'package:deepsky_bluetooth_util/deepsky_bluetooth_util.dart';
import 'package:steady/steady.dart';

import 'config.dart';
import 'models.dart';

/// Common Dart observer for lifecycle, bridge, and platform-contract events.
///
/// Users extend this class and override only the hooks they need. Hooks are
/// typed per method/callback instead of string-dispatched so callers can keep
/// logging code small and discoverable.
class DeepskyBluetoothCommonObserver {
  const DeepskyBluetoothCommonObserver();

  void onInitializeStart(DeepskyBluetoothConfig config) {}
  void onInitializeEnd(
    DeepskyBluetoothConfig config,
    Result<void, InitializeError> result,
  ) {}

  void onActivateCallbacksStart() {}
  void onActivateCallbacksEnd(Result<void, InitializeError> result) {}

  void onAckStateResyncStart(String snapshotId) {}
  void onAckStateResyncEnd(String snapshotId, Result<void, Exception> result) {}

  void onStartScanStart({
    DeepskyScanFilter? filter,
    DeepskyScanOptions options = const DeepskyScanOptions(),
  }) {}
  void onStartScanEnd(Result<void, ScanError> result) {}

  void onStopScanStart() {}
  void onStopScanEnd(Result<void, ScanError> result) {}

  void onConnectStart(DeepskyDeviceId deviceId) {}
  void onConnectEnd(
    DeepskyDeviceId deviceId,
    Result<ConnectionAttempt, ConnectError> result,
  ) {}

  void onDisconnectStart(DeepskyDeviceId deviceId, int epoch) {}
  void onDisconnectEnd(
    DeepskyDeviceId deviceId,
    int epoch,
    Result<void, DisconnectError> result,
  ) {}

  void onDiscoverServicesStart(DeepskyDeviceId deviceId, int epoch) {}
  void onDiscoverServicesEnd(
    DeepskyDeviceId deviceId,
    int epoch,
    Result<List<BleServiceInfo>, DiscoverServicesError> result,
  ) {}

  void onReadCharacteristicStart(
    BleCharacteristicTarget target, {
    bool strictRead = false,
  }) {}
  void onReadCharacteristicEnd(
    BleCharacteristicTarget target,
    Result<Uint8List, CharacteristicReadError> result, {
    bool strictRead = false,
  }) {}

  void onWriteCharacteristicStart(
    BleCharacteristicTarget target,
    Uint8List value, {
    required bool withResponse,
  }) {}
  void onWriteCharacteristicEnd(
    BleCharacteristicTarget target,
    Result<void, CharacteristicWriteError> result, {
    required bool withResponse,
  }) {}

  void onSetNotifyStart(BleCharacteristicTarget target, BleNotifyType type) {}
  void onSetNotifyEnd(
    BleCharacteristicTarget target,
    BleNotifyType type,
    Result<void, NotifyError> result,
  ) {}

  void onReadDescriptorStart(BleDescriptorTarget target) {}
  void onReadDescriptorEnd(
    BleDescriptorTarget target,
    Result<Uint8List, DescriptorReadError> result,
  ) {}

  void onWriteDescriptorStart(BleDescriptorTarget target, Uint8List value) {}
  void onWriteDescriptorEnd(
    BleDescriptorTarget target,
    Result<void, DescriptorWriteError> result,
  ) {}

  void onRequestMtuStart(DeepskyDeviceId deviceId, int epoch, int mtu) {}
  void onRequestMtuEnd(
    DeepskyDeviceId deviceId,
    int epoch,
    int mtu,
    Result<int, MtuError> result,
  ) {}

  void onReadRssiStart(DeepskyDeviceId deviceId, int epoch) {}
  void onReadRssiEnd(
    DeepskyDeviceId deviceId,
    int epoch,
    Result<int, RssiError> result,
  ) {}

  void onAssociateStart({DeepskyScanFilter? filter}) {}
  void onAssociateEnd(Result<DeepskyDeviceId, AssociateError> result) {}

  void onSetDevicePresenceObservationStart(
    DeepskyDeviceId deviceId, {
    required bool enabled,
  }) {}
  void onSetDevicePresenceObservationEnd(
    DeepskyDeviceId deviceId,
    Result<void, PresenceError> result, {
    required bool enabled,
  }) {}

  void onDisposeStart() {}
  void onDisposeEnd(Result<void, DisposeError> result) {}

  void onScanResult(BleScanResult result) {}
  void onScanError(ScanError error) {}
  void onConnectionEvent(BlePlatformConnectionEvent event) {}
  void onNotifyEvent(BleNotifyEvent event) {}
  void onOperationTimeout(BleOperationTimeout event) {}
  void onAdapterState(BleAdapterState state) {}
  void onCompanionEvent(BleCompanionEvent event) {}
  void onRestoredConnections(List<DeepskyDeviceId> deviceIds) {}
  void onStateResync(BleStateResync snapshot) {}
}
