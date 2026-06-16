import 'dart:typed_data';

import 'package:deepsky_bluetooth_util/deepsky_bluetooth_util.dart';
import 'package:steady/steady.dart';

import 'config.dart';
import 'models.dart';

/// Platform contract implemented by per-platform bridge packages.
///
/// This layer exposes raw operations and raw event streams only. Connection
/// state machines, reconnect policy, service cache lifetime, and public stream
/// views are owned by the root package lifecycle layer.
abstract class DeepskyBluetoothPlatform {
  Future<Result<void, InitializeError>> initialize(
    DeepskyBluetoothConfig config,
  );

  /// Called after lifecycle has subscribed to every raw event stream.
  Future<Result<void, InitializeError>> activateCallbacks();

  /// Acknowledges that lifecycle rebuilt state from a resync snapshot.
  Future<void> ackStateResync(String snapshotId);

  Future<Result<void, ScanError>> startScan({
    DeepskyScanFilter? filter,
    DeepskyScanOptions options = const DeepskyScanOptions(),
  });

  Future<Result<void, ScanError>> stopScan();

  /// Creates a native connection instance and returns its native-owned epoch.
  Future<Result<ConnectionAttempt, ConnectError>> connect(
    DeepskyDeviceId deviceId,
  );

  Future<Result<void, DisconnectError>> disconnect(
    DeepskyDeviceId deviceId,
    int epoch,
  );

  /// Returns discovered GATT data with epoch-scoped handles assigned.
  Future<Result<List<BleServiceInfo>, DiscoverServicesError>> discoverServices(
    DeepskyDeviceId deviceId,
    int epoch,
  );

  /// Returns read data directly. Notify/indicate values are emitted separately
  /// through [notifyEvents].
  Future<Result<Uint8List, CharacteristicReadError>> readCharacteristic(
    BleCharacteristicTarget target, {
    bool strictRead = false,
  });

  Future<Result<void, CharacteristicWriteError>> writeCharacteristic(
    BleCharacteristicTarget target,
    Uint8List value, {
    required bool withResponse,
  });

  Future<Result<void, NotifyError>> setNotify(
    BleCharacteristicTarget target,
    BleNotifyType type,
  );

  Future<Result<Uint8List, DescriptorReadError>> readDescriptor(
    BleDescriptorTarget target,
  );

  Future<Result<void, DescriptorWriteError>> writeDescriptor(
    BleDescriptorTarget target,
    Uint8List value,
  );

  Future<Result<int, MtuError>> requestMtu(
    DeepskyDeviceId deviceId,
    int epoch,
    int mtu,
  );

  Future<Result<int, RssiError>> readRssi(DeepskyDeviceId deviceId, int epoch);

  Future<Result<DeepskyDeviceId, AssociateError>> associate({
    DeepskyScanFilter? filter,
  });

  Future<Result<void, PresenceError>> setDevicePresenceObservation(
    DeepskyDeviceId deviceId, {
    required bool enabled,
  });

  Future<Result<void, DisposeError>> dispose();

  Stream<BleScanResult> get scanResults;

  Stream<ScanError> get scanErrors;

  /// Raw connection events tagged with device id and, when known, epoch.
  Stream<BlePlatformConnectionEvent> get connectionEvents;

  /// Notify/indicate-only characteristic values tagged by epoch and handle.
  Stream<BleNotifyEvent> get notifyEvents;

  /// GATT operation timeout events tagged by epoch.
  Stream<BleOperationTimeout> get operationTimeouts;

  Stream<BleAdapterState> get adapterStates;

  Stream<BleCompanionEvent> get companionEvents;

  Stream<List<DeepskyDeviceId>> get restoredConnections;

  Stream<BleStateResync> get stateResync;
}
