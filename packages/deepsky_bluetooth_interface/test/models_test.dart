import 'dart:typed_data';
import 'dart:io';

import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'scan models use device id and uuid value types with value equality',
    () {
      final first = BleScanResult(
        deviceId: const DeepskyDeviceId('device-1'),
        name: 'Thermo',
        rssi: -51,
        serviceUuids: [DeepskyUuid.fromString('180F')],
        manufacturerData: Uint8List.fromList([1, 2, 3]),
        raw: Uint8List.fromList([2, 1, 6]),
      );
      final second = BleScanResult(
        deviceId: const DeepskyDeviceId('device-1'),
        name: 'Thermo',
        rssi: -51,
        serviceUuids: [DeepskyUuid.fromString('180f')],
        manufacturerData: Uint8List.fromList([1, 2, 3]),
        raw: Uint8List.fromList([2, 1, 6]),
      );

      expect(first, second);
      expect(first.deviceId, const DeepskyDeviceId('device-1'));
      expect(first.serviceUuids.single, DeepskyUuid.fromString('180F'));
    },
  );

  test('scan filter and options expose stable defaults', () {
    const filter = DeepskyScanFilter();
    const options = DeepskyScanOptions();

    expect(filter.deviceIds, isEmpty);
    expect(filter.names, isEmpty);
    expect(filter.manufacturerData, isEmpty);
    expect(filter.serviceData, isEmpty);
    expect(filter.serviceUuids, isEmpty);
    expect(options.android.mode, DeepskyAndroidScanMode.lowLatency);
    expect(options.android.onlyLegacy, isTrue);
    expect(options.darwin.allowDuplicates, isFalse);
  });

  test(
    'disconnected is the only connection event state with a required reason',
    () {
      const disconnected = BleConnectionEvent(
        state: BleConnectionState.disconnected,
        reason: BleDisconnectReason.connectionLost,
      );

      expect(disconnected.reason, BleDisconnectReason.connectionLost);
      expect(
        () => BleConnectionEvent(state: BleConnectionState.disconnected),
        throwsAssertionError,
      );
      expect(
        () => BleConnectionEvent(
          state: BleConnectionState.connected,
          reason: BleDisconnectReason.connectionLost,
        ),
        throwsAssertionError,
      );
    },
  );

  test('connection lifecycle enums include reconnect and notify modes', () {
    expect(BleConnectionState.values, [
      BleConnectionState.connecting,
      BleConnectionState.connected,
      BleConnectionState.disconnecting,
      BleConnectionState.disconnected,
      BleConnectionState.reconnecting,
    ]);
    expect(BleNotifyType.values, [
      BleNotifyType.disable,
      BleNotifyType.notify,
      BleNotifyType.indicate,
    ]);
    expect(BleCharacteristicProperty.values, [
      BleCharacteristicProperty.broadcast,
      BleCharacteristicProperty.read,
      BleCharacteristicProperty.writeWithoutResponse,
      BleCharacteristicProperty.writeWithResponse,
      BleCharacteristicProperty.notify,
      BleCharacteristicProperty.indicate,
      BleCharacteristicProperty.authenticatedSignedWrites,
      BleCharacteristicProperty.extendedProperties,
    ]);
  });

  test('GATT info DTOs use uuid values and epoch scoped handles', () {
    final descriptor = BleDescriptorInfo(
      handle: 3,
      uuid: DeepskyUuid.fromString('2902'),
    );
    final characteristic = BleCharacteristicInfo(
      handle: 2,
      serviceHandle: 1,
      uuid: DeepskyUuid.fromString('2A19'),
      properties: const BleCharacteristicProperties(
        values: [
          BleCharacteristicProperty.read,
          BleCharacteristicProperty.notify,
        ],
      ),
      descriptors: [descriptor],
    );
    final service = BleServiceInfo(
      handle: 1,
      uuid: DeepskyUuid.fromString('180F'),
      characteristics: [characteristic],
    );
    const target = BleDescriptorTarget(
      deviceId: DeepskyDeviceId('device-1'),
      connectionEpoch: 7,
      characteristicHandle: 2,
      descriptorHandle: 3,
    );

    expect(service.characteristics.single.serviceHandle, service.handle);
    expect(characteristic.descriptors.single, descriptor);
    expect(characteristic.properties.values, [
      BleCharacteristicProperty.read,
      BleCharacteristicProperty.notify,
    ]);
    expect(target.connectionEpoch, 7);
    expect(target.descriptorHandle, descriptor.handle);
    expect(
      () => BleServiceInfo(handle: -1, uuid: DeepskyUuid.empty()),
      throwsAssertionError,
    );
  });

  test(
    'snapshot and platform carriers keep device id, epoch, handles, and values',
    () {
      final notify = BleNotifyEvent(
        deviceId: const DeepskyDeviceId('device-1'),
        connectionEpoch: 7,
        characteristicHandle: 2,
        value: Uint8List.fromList([9]),
      );
      final snapshot = BleStateSnapshot(
        deviceId: const DeepskyDeviceId('device-1'),
        connectionEpoch: 7,
        state: BleConnectionState.connected,
        activeNotifyHandles: const [2],
        restored: true,
        services: [
          BleServiceInfo(handle: 1, uuid: DeepskyUuid.fromString('180F')),
        ],
      );
      final resync = BleStateResync(snapshotId: 'snap-1', devices: [snapshot]);

      expect(notify.value, Uint8List.fromList([9]));
      expect(resync.devices.single.activeNotifyHandles, [2]);
      expect(snapshot.services!.single.uuid, DeepskyUuid.fromString('180f'));
    },
  );

  test('reconnect policy has a value default', () {
    const policy = ReconnectPolicy();

    expect(policy.delay, const Duration(seconds: 5));
    expect(policy, const ReconnectPolicy(delay: Duration(seconds: 5)));
  });

  test('model data classes disable generated copyWith', () {
    final sourceFile = File('lib/src/models.dart').existsSync()
        ? File('lib/src/models.dart')
        : File('packages/deepsky_bluetooth_interface/lib/src/models.dart');
    final source = sourceFile.readAsStringSync();

    expect(source, isNot(contains('@freezed')));
    expect(source, contains('@Freezed(copyWith: false)'));
  });
}
