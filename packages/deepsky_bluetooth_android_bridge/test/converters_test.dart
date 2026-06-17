import 'dart:typed_data';

import 'package:deepsky_bluetooth_android/deepsky_bluetooth_android.dart';
import 'package:deepsky_bluetooth_android_bridge/deepsky_bluetooth_android_bridge.dart';
import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('scan / config / device id / uuid converters', () {
    test('scanFilterToMessage returns null for null filter', () {
      expect(scanFilterToMessage(null), isNull);
    });

    test('scanFilterToMessage maps every value field', () {
      final message = scanFilterToMessage(
        DeepskyScanFilter(
          deviceIds: const [DeepskyDeviceId('AA:BB:CC:DD:EE:FF')],
          names: const ['sensor'],
          manufacturerData: [
            DeepskyScanFilterManufacturerData(
              manufacturerId: 76,
              data: Uint8List.fromList([1, 2]),
            ),
          ],
          serviceData: [
            DeepskyScanFilterServiceData(
              uuid: DeepskyUuid.fromString('180d'),
              data: Uint8List.fromList([3, 4]),
            ),
          ],
          serviceUuids: [DeepskyUuid.fromString('180f')],
        ),
      )!;

      expect(message.addresses, ['AA:BB:CC:DD:EE:FF']);
      expect(message.names, ['sensor']);
      expect(message.manufacturerData.single.manufacturerId, 76);
      expect(message.manufacturerData.single.data, [1, 2]);
      expect(
        message.serviceData.single.serviceUuid,
        '0000180d-0000-1000-8000-00805f9b34fb',
      );
      expect(message.serviceData.single.data, [3, 4]);
      expect(message.serviceUuids, ['0000180f-0000-1000-8000-00805f9b34fb']);
    });

    test('androidScanSettingsToMessage maps every enum and value', () {
      final message = androidScanSettingsToMessage(
        const DeepskyAndroidScanSetting(
          mode: DeepskyAndroidScanMode.balanced,
          callbackType: DeepskyAndroidScanCallbackType.firstMatch,
          onlyLegacy: false,
          matchMode: DeepskyAndroidScanMatchMode.sticky,
          numOfMatch: DeepskyAndroidScanNumOfMatch.fewAdvertisement,
          reportDelay: Duration(milliseconds: 250),
          phy: DeepskyAndroidScanPhy.leCoded,
        ),
      );

      expect(message.mode, ScanModeMessage.balanced);
      expect(message.callbackType, ScanCallbackTypeMessage.firstMatch);
      expect(message.onlyLegacy, isFalse);
      expect(message.matchMode, ScanMatchModeMessage.sticky);
      expect(message.numOfMatch, ScanNumOfMatchMessage.few);
      expect(message.reportDelayMillis, 250);
      expect(message.phy, ScanPhyMessage.leCoded);
    });

    test('scanResultFromMessage preserves all values and normalizes uuids', () {
      final result = scanResultFromMessage(
        ScanResultMessage(
          deviceId: 'dev-1',
          name: 'name',
          rssi: -50,
          serviceUuids: ['180D'],
          manufacturerData: Uint8List.fromList([9]),
          raw: Uint8List.fromList([7, 8]),
        ),
      );

      expect(result.deviceId, const DeepskyDeviceId('dev-1'));
      expect(result.name, 'name');
      expect(result.rssi, -50);
      expect(
        result.serviceUuids.single,
        DeepskyUuid.fromString('180d'),
      );
      expect(result.manufacturerData, [9]);
      expect(result.raw, [7, 8]);
    });

    test('configToMessage foreground produces non-background request', () {
      final message = configToMessage(const DeepskyBluetoothConfig.foreground());
      expect(message.isBackground, isFalse);
      expect(message.strategy, isNull);
      expect(message.notification, isNull);
      expect(message.backgroundCallbackHandle, isNull);
    });

    test('configToMessage background foregroundService maps notification', () {
      final message = configToMessage(
        const DeepskyBluetoothConfig.background(
          android: AndroidBackgroundConfig.foregroundService(
            notification: AndroidNotificationConfig(
              channelId: 'cid',
              channelName: 'cname',
              title: 'title',
              text: 'text',
            ),
          ),
          backgroundCallbackHandle: 42,
        ),
      );

      expect(message.isBackground, isTrue);
      expect(message.strategy, BackgroundStrategyMessage.foregroundService);
      expect(message.notification?.channelId, 'cid');
      expect(message.notification?.channelName, 'cname');
      expect(message.notification?.title, 'title');
      expect(message.notification?.text, 'text');
      expect(message.backgroundCallbackHandle, 42);
    });

    test('configToMessage background companionDevice keeps handle', () {
      final message = configToMessage(
        const DeepskyBluetoothConfig.background(
          android: AndroidBackgroundConfig.companionDevice(),
          backgroundCallbackHandle: 7,
        ),
      );

      expect(message.isBackground, isTrue);
      expect(message.strategy, BackgroundStrategyMessage.companionDevice);
      expect(message.notification, isNull);
      expect(message.backgroundCallbackHandle, 7);
    });
  });

  group('connection / GATT enum and epoch/handle converters', () {
    test('connectionStateFromMessage maps every value', () {
      expect(
        connectionStateFromMessage(ConnectionStateMessage.connecting),
        BleConnectionState.connecting,
      );
      expect(
        connectionStateFromMessage(ConnectionStateMessage.connected),
        BleConnectionState.connected,
      );
      expect(
        connectionStateFromMessage(ConnectionStateMessage.disconnecting),
        BleConnectionState.disconnecting,
      );
      expect(
        connectionStateFromMessage(ConnectionStateMessage.disconnected),
        BleConnectionState.disconnected,
      );
      expect(
        connectionStateFromMessage(ConnectionStateMessage.reconnecting),
        BleConnectionState.reconnecting,
      );
    });

    test('adapterStateFromMessage maps every value', () {
      expect(
        adapterStateFromMessage(AdapterStateMessage.poweredOn),
        BleAdapterState.poweredOn,
      );
      expect(
        adapterStateFromMessage(AdapterStateMessage.poweredOff),
        BleAdapterState.poweredOff,
      );
      expect(
        adapterStateFromMessage(AdapterStateMessage.unavailable),
        BleAdapterState.unavailable,
      );
    });

    test('disconnectReasonFromMessage maps every value', () {
      for (final entry in {
        DisconnectReasonMessage.userRequested: BleDisconnectReason.userRequested,
        DisconnectReasonMessage.connectionLost: BleDisconnectReason.connectionLost,
        DisconnectReasonMessage.connectFailed: BleDisconnectReason.connectFailed,
        DisconnectReasonMessage.operationTimeout:
            BleDisconnectReason.operationTimeout,
        DisconnectReasonMessage.permissionDenied:
            BleDisconnectReason.permissionDenied,
        DisconnectReasonMessage.bluetoothOff: BleDisconnectReason.bluetoothOff,
        DisconnectReasonMessage.bluetoothUnavailable:
            BleDisconnectReason.bluetoothUnavailable,
        DisconnectReasonMessage.deviceNotFound: BleDisconnectReason.deviceNotFound,
        DisconnectReasonMessage.notAssociated: BleDisconnectReason.notAssociated,
        DisconnectReasonMessage.presenceObservationDisabled:
            BleDisconnectReason.presenceObservationDisabled,
        DisconnectReasonMessage.unknown: BleDisconnectReason.unknown,
      }.entries) {
        expect(disconnectReasonFromMessage(entry.key), entry.value);
      }
    });

    test('notifyTypeToMessage maps every value', () {
      expect(notifyTypeToMessage(BleNotifyType.disable), NotifyTypeMessage.disable);
      expect(notifyTypeToMessage(BleNotifyType.notify), NotifyTypeMessage.notify);
      expect(
        notifyTypeToMessage(BleNotifyType.indicate),
        NotifyTypeMessage.indicate,
      );
    });

    test('connectionAttemptFromMessage keeps epoch', () {
      expect(
        connectionAttemptFromMessage(
          ConnectionAttemptMessage(connectionEpoch: 5),
        ),
        const ConnectionAttempt(connectionEpoch: 5),
      );
    });

    test('characteristicTargetToMessage keeps epoch and handle', () {
      final message = characteristicTargetToMessage(
        const BleCharacteristicTarget(
          deviceId: DeepskyDeviceId('dev'),
          connectionEpoch: 3,
          characteristicHandle: 11,
        ),
      );
      expect(message.deviceId, 'dev');
      expect(message.connectionEpoch, 3);
      expect(message.characteristicHandle, 11);
    });

    test('descriptorTargetToMessage keeps epoch and both handles', () {
      final message = descriptorTargetToMessage(
        const BleDescriptorTarget(
          deviceId: DeepskyDeviceId('dev'),
          connectionEpoch: 3,
          characteristicHandle: 11,
          descriptorHandle: 12,
        ),
      );
      expect(message.deviceId, 'dev');
      expect(message.connectionEpoch, 3);
      expect(message.characteristicHandle, 11);
      expect(message.descriptorHandle, 12);
    });
  });

  group('service discovery converters', () {
    ServiceMessage serviceMessage({
      required int handle,
      required String uuid,
      required List<CharacteristicMessage> characteristics,
    }) =>
        ServiceMessage(
          handle: handle,
          uuid: uuid,
          characteristics: characteristics,
        );

    test('serviceInfoFromMessage preserves handles, uuids and properties', () {
      final info = serviceInfoFromMessage(
        serviceMessage(
          handle: 1,
          uuid: '180D',
          characteristics: [
            CharacteristicMessage(
              handle: 2,
              serviceHandle: 1,
              uuid: '2A37',
              canRead: true,
              canWriteWithResponse: false,
              canWriteWithoutResponse: true,
              canNotify: true,
              canIndicate: false,
              descriptors: [DescriptorMessage(handle: 3, uuid: '2902')],
            ),
          ],
        ),
      );

      expect(info.handle, 1);
      expect(info.uuid, DeepskyUuid.fromString('180d'));
      final characteristic = info.characteristics.single;
      expect(characteristic.handle, 2);
      expect(characteristic.serviceHandle, 1);
      expect(characteristic.uuid, DeepskyUuid.fromString('2a37'));
      expect(
        characteristic.properties.values,
        containsAll(const [
          BleCharacteristicProperty.read,
          BleCharacteristicProperty.writeWithoutResponse,
          BleCharacteristicProperty.notify,
        ]),
      );
      expect(
        characteristic.properties.values,
        isNot(contains(BleCharacteristicProperty.writeWithResponse)),
      );
      expect(
        characteristic.properties.values,
        isNot(contains(BleCharacteristicProperty.indicate)),
      );
      final descriptor = characteristic.descriptors.single;
      expect(descriptor.handle, 3);
      expect(descriptor.uuid, DeepskyUuid.fromString('2902'));
    });

    test('duplicate uuids are retained with distinct handles', () {
      final info = serviceInfoFromMessage(
        serviceMessage(
          handle: 1,
          uuid: '180D',
          characteristics: [
            CharacteristicMessage(
              handle: 10,
              serviceHandle: 1,
              uuid: '2A37',
              canRead: true,
              canWriteWithResponse: false,
              canWriteWithoutResponse: false,
              canNotify: false,
              canIndicate: false,
              descriptors: [],
            ),
            CharacteristicMessage(
              handle: 11,
              serviceHandle: 1,
              uuid: '2A37',
              canRead: true,
              canWriteWithResponse: false,
              canWriteWithoutResponse: false,
              canNotify: false,
              canIndicate: false,
              descriptors: [],
            ),
          ],
        ),
      );

      expect(info.characteristics, hasLength(2));
      expect(
        info.characteristics.map((c) => c.uuid).toSet(),
        {DeepskyUuid.fromString('2a37')},
      );
      expect(info.characteristics.map((c) => c.handle).toList(), [10, 11]);
    });
  });

  group('callback event converters', () {
    test('connectionEventFromMessage keeps epoch and non-disconnect reason null',
        () {
      final event = connectionEventFromMessage(
        'dev',
        4,
        ConnectionStateMessage.connected,
        null,
      );
      expect(event.deviceId, const DeepskyDeviceId('dev'));
      expect(event.connectionEpoch, 4);
      expect(event.state, BleConnectionState.connected);
      expect(event.reason, isNull);
    });

    test('connectionEventFromMessage maps disconnect reason', () {
      final event = connectionEventFromMessage(
        'dev',
        null,
        ConnectionStateMessage.disconnected,
        DisconnectReasonMessage.connectionLost,
      );
      expect(event.connectionEpoch, isNull);
      expect(event.state, BleConnectionState.disconnected);
      expect(event.reason, BleDisconnectReason.connectionLost);
    });

    test('notifyEventFromMessage keeps epoch, handle and value', () {
      final event = notifyEventFromMessage(
        'dev',
        2,
        9,
        Uint8List.fromList([5, 6]),
      );
      expect(event.deviceId, const DeepskyDeviceId('dev'));
      expect(event.connectionEpoch, 2);
      expect(event.characteristicHandle, 9);
      expect(event.value, [5, 6]);
    });

    test('operationTimeoutFromMessage keeps epoch', () {
      final event = operationTimeoutFromMessage('dev', 8);
      expect(event.deviceId, const DeepskyDeviceId('dev'));
      expect(event.connectionEpoch, 8);
    });

    test('companionEventFromMessage carries appeared flag', () {
      expect(
        companionEventFromMessage('dev', appeared: true).appeared,
        isTrue,
      );
      expect(
        companionEventFromMessage('dev', appeared: false).appeared,
        isFalse,
      );
    });
  });

  group('state snapshot converters', () {
    test('stateSnapshotFromMessage preserves epoch, handles and services', () {
      final snapshot = stateSnapshotFromMessage(
        StateSnapshotMessage(
          deviceId: 'dev',
          connectionEpoch: 6,
          state: ConnectionStateMessage.connected,
          disconnectReason: null,
          activeNotifyHandles: [10, 11],
          services: [
            ServiceMessage(handle: 1, uuid: '180D', characteristics: []),
          ],
          restored: true,
        ),
      );

      expect(snapshot.deviceId, const DeepskyDeviceId('dev'));
      expect(snapshot.connectionEpoch, 6);
      expect(snapshot.state, BleConnectionState.connected);
      expect(snapshot.disconnectReason, isNull);
      expect(snapshot.activeNotifyHandles, [10, 11]);
      expect(snapshot.services?.single.handle, 1);
      expect(snapshot.restored, isTrue);
    });

    test('stateSnapshotFromMessage keeps disconnect reason and null services',
        () {
      final snapshot = stateSnapshotFromMessage(
        StateSnapshotMessage(
          deviceId: 'dev',
          connectionEpoch: 2,
          state: ConnectionStateMessage.disconnected,
          disconnectReason: DisconnectReasonMessage.connectionLost,
          activeNotifyHandles: [],
          services: null,
          restored: false,
        ),
      );

      expect(snapshot.state, BleConnectionState.disconnected);
      expect(snapshot.disconnectReason, BleDisconnectReason.connectionLost);
      expect(snapshot.services, isNull);
    });

    test('stateResyncFromMessage keeps snapshot id and devices', () {
      final resync = stateResyncFromMessage(
        StateResyncMessage(
          snapshotId: 'snap-1',
          devices: [
            StateSnapshotMessage(
              deviceId: 'dev',
              connectionEpoch: 1,
              state: ConnectionStateMessage.connecting,
              disconnectReason: null,
              activeNotifyHandles: [],
              services: null,
              restored: false,
            ),
          ],
        ),
      );

      expect(resync.snapshotId, 'snap-1');
      expect(resync.devices.single.deviceId, const DeepskyDeviceId('dev'));
      expect(resync.devices.single.connectionEpoch, 1);
    });
  });
}
