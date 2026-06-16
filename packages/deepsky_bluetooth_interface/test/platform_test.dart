import 'dart:typed_data';

import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/steady.dart';

final class _RecordingObserver extends DeepskyBluetoothCommonObserver {
  final calls = <String>[];

  @override
  void onConnectStart(DeepskyDeviceId deviceId) {
    calls.add('connect-start:$deviceId');
  }

  @override
  void onConnectEnd(
    DeepskyDeviceId deviceId,
    Result<ConnectionAttempt, ConnectError> result,
  ) {
    calls.add('connect-end:$deviceId:${result.ok?.connectionEpoch}');
  }

  @override
  void onNotifyEvent(BleNotifyEvent event) {
    calls.add(
      'notify:${event.deviceId}:${event.connectionEpoch}:'
      '${event.characteristicHandle}',
    );
  }
}

final class _FakePlatform extends DeepskyBluetoothPlatform {
  BleCharacteristicTarget? lastCharacteristicTarget;
  BleDescriptorTarget? lastDescriptorTarget;
  int? lastDisconnectEpoch;
  int? lastMtuEpoch;

  @override
  Future<Result<void, InitializeError>> initialize(
    DeepskyBluetoothConfig config,
  ) async {
    return const Result.ok(null);
  }

  @override
  Future<Result<void, InitializeError>> activateCallbacks() async {
    return const Result.ok(null);
  }

  @override
  Future<void> ackStateResync(String snapshotId) async {}

  @override
  Future<Result<void, ScanError>> startScan({
    DeepskyScanFilter? filter,
    DeepskyScanOptions options = const DeepskyScanOptions(),
  }) async {
    return const Result.error(ScanBluetoothOff());
  }

  @override
  Future<Result<void, ScanError>> stopScan() async {
    return const Result.ok(null);
  }

  @override
  Future<Result<ConnectionAttempt, ConnectError>> connect(
    DeepskyDeviceId deviceId,
  ) async {
    return const Result.ok(ConnectionAttempt(connectionEpoch: 7));
  }

  @override
  Future<Result<void, DisconnectError>> disconnect(
    DeepskyDeviceId deviceId,
    int epoch,
  ) async {
    lastDisconnectEpoch = epoch;
    return const Result.ok(null);
  }

  @override
  Future<Result<List<BleServiceInfo>, DiscoverServicesError>> discoverServices(
    DeepskyDeviceId deviceId,
    int epoch,
  ) async {
    return const Result.ok([]);
  }

  @override
  Future<Result<Uint8List, CharacteristicReadError>> readCharacteristic(
    BleCharacteristicTarget target, {
    bool strictRead = false,
  }) async {
    lastCharacteristicTarget = target;
    return Result.ok(Uint8List.fromList([1, 2, 3]));
  }

  @override
  Future<Result<void, CharacteristicWriteError>> writeCharacteristic(
    BleCharacteristicTarget target,
    Uint8List value, {
    required bool withResponse,
  }) async {
    lastCharacteristicTarget = target;
    return const Result.ok(null);
  }

  @override
  Future<Result<void, NotifyError>> setNotify(
    BleCharacteristicTarget target,
    BleNotifyType type,
  ) async {
    lastCharacteristicTarget = target;
    return const Result.ok(null);
  }

  @override
  Future<Result<Uint8List, DescriptorReadError>> readDescriptor(
    BleDescriptorTarget target,
  ) async {
    lastDescriptorTarget = target;
    return Result.ok(Uint8List.fromList([4]));
  }

  @override
  Future<Result<void, DescriptorWriteError>> writeDescriptor(
    BleDescriptorTarget target,
    Uint8List value,
  ) async {
    lastDescriptorTarget = target;
    return const Result.ok(null);
  }

  @override
  Future<Result<int, MtuError>> requestMtu(
    DeepskyDeviceId deviceId,
    int epoch,
    int mtu,
  ) async {
    lastMtuEpoch = epoch;
    return Result.ok(mtu);
  }

  @override
  Future<Result<int, RssiError>> readRssi(
    DeepskyDeviceId deviceId,
    int epoch,
  ) async {
    return const Result.ok(-40);
  }

  @override
  Future<Result<DeepskyDeviceId, AssociateError>> associate({
    DeepskyScanFilter? filter,
  }) async {
    return const Result.error(AssociateNotSupported());
  }

  @override
  Future<Result<void, PresenceError>> setDevicePresenceObservation(
    DeepskyDeviceId deviceId, {
    required bool enabled,
  }) async {
    return const Result.error(PresenceNotSupported());
  }

  @override
  Future<Result<void, DisposeError>> dispose() async {
    return const Result.ok(null);
  }

  @override
  Stream<BleScanResult> get scanResults => const Stream.empty();

  @override
  Stream<ScanError> get scanErrors => const Stream.empty();

  @override
  Stream<BlePlatformConnectionEvent> get connectionEvents {
    return const Stream.empty();
  }

  @override
  Stream<BleNotifyEvent> get notifyEvents => const Stream.empty();

  @override
  Stream<BleOperationTimeout> get operationTimeouts => const Stream.empty();

  @override
  Stream<BleAdapterState> get adapterStates => const Stream.empty();

  @override
  Stream<BleCompanionEvent> get companionEvents => const Stream.empty();

  @override
  Stream<List<DeepskyDeviceId>> get restoredConnections {
    return const Stream.empty();
  }

  @override
  Stream<BleStateResync> get stateResync => const Stream.empty();
}

void main() {
  test('platform contract uses native epochs and handle targets', () async {
    final platform = _FakePlatform();
    const deviceId = DeepskyDeviceId('device-1');
    const characteristicTarget = BleCharacteristicTarget(
      deviceId: deviceId,
      connectionEpoch: 7,
      characteristicHandle: 11,
    );
    const descriptorTarget = BleDescriptorTarget(
      deviceId: deviceId,
      connectionEpoch: 7,
      characteristicHandle: 11,
      descriptorHandle: 12,
    );

    final scan = await platform.startScan();
    final connect = await platform.connect(deviceId);
    final mtu = await platform.requestMtu(deviceId, 7, 247);
    final read = await platform.readCharacteristic(characteristicTarget);
    await platform.disconnect(deviceId, 7);
    await platform.writeDescriptor(descriptorTarget, Uint8List.fromList([9]));

    expect(scan.err, isA<ScanBluetoothOff>());
    expect(connect.ok?.connectionEpoch, 7);
    expect(mtu.ok, 247);
    expect(read.ok, Uint8List.fromList([1, 2, 3]));
    expect(platform.lastDisconnectEpoch, 7);
    expect(platform.lastMtuEpoch, 7);
    expect(platform.lastCharacteristicTarget, characteristicTarget);
    expect(platform.lastDescriptorTarget, descriptorTarget);
  });

  test('platform exposes raw event streams used by lifecycle', () {
    final platform = _FakePlatform();

    expect(platform.scanResults, isA<Stream<BleScanResult>>());
    expect(platform.scanErrors, isA<Stream<ScanError>>());
    expect(
      platform.connectionEvents,
      isA<Stream<BlePlatformConnectionEvent>>(),
    );
    expect(platform.notifyEvents, isA<Stream<BleNotifyEvent>>());
    expect(platform.operationTimeouts, isA<Stream<BleOperationTimeout>>());
    expect(platform.adapterStates, isA<Stream<BleAdapterState>>());
    expect(platform.companionEvents, isA<Stream<BleCompanionEvent>>());
    expect(platform.restoredConnections, isA<Stream<List<DeepskyDeviceId>>>());
    expect(platform.stateResync, isA<Stream<BleStateResync>>());
  });

  test('common observer exposes typed method lifecycle and callback hooks', () {
    final observer = _RecordingObserver();
    final event = BleNotifyEvent(
      deviceId: const DeepskyDeviceId('device-1'),
      connectionEpoch: 7,
      characteristicHandle: 11,
      value: Uint8List.fromList([1]),
    );

    observer.onConnectStart(const DeepskyDeviceId('device-1'));
    observer.onConnectEnd(
      const DeepskyDeviceId('device-1'),
      const Result.ok(ConnectionAttempt(connectionEpoch: 7)),
    );
    observer.onNotifyEvent(event);

    expect(observer.calls, [
      'connect-start:device-1',
      'connect-end:device-1:7',
      'notify:device-1:7:11',
    ]);
  });

  test('common observer default implementation is no-op', () {
    const observer = DeepskyBluetoothCommonObserver();

    observer.onStopScanStart();
    observer.onStopScanEnd(const Result.ok(null));
    observer.onScanError(const ScanBluetoothOff());
  });
}
