import 'dart:io';

import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'config is a sealed foreground/background choice with value equality',
    () {
      const foreground = DeepskyBluetoothConfig.foreground();
      const background = DeepskyBluetoothConfig.background(
        ios: IosBackgroundConfig(restoreIdentifier: 'com.example.restore'),
        android: AndroidForegroundServiceConfig(
          notification: AndroidNotificationConfig(
            channelId: 'ble',
            channelName: 'BLE',
            title: 'Connected',
            text: 'Maintaining BLE link',
          ),
        ),
        backgroundCallbackHandle: 42,
      );

      final kind = switch (foreground) {
        ForegroundConfig() => 'foreground',
        BackgroundConfig() => 'background',
      };

      expect(kind, 'foreground');
      expect(
        background,
        const DeepskyBluetoothConfig.background(
          ios: IosBackgroundConfig(restoreIdentifier: 'com.example.restore'),
          android: AndroidForegroundServiceConfig(
            notification: AndroidNotificationConfig(
              channelId: 'ble',
              channelName: 'BLE',
              title: 'Connected',
              text: 'Maintaining BLE link',
            ),
          ),
          backgroundCallbackHandle: 42,
        ),
      );
    },
  );

  test('android background strategy is sealed', () {
    const AndroidBackgroundConfig config = AndroidCompanionDeviceConfig();

    final kind = switch (config) {
      AndroidForegroundServiceConfig() => 'foreground-service',
      AndroidCompanionDeviceConfig() => 'companion-device',
    };

    expect(kind, 'companion-device');
  });

  test('config data classes disable generated copyWith', () {
    final sourceFile = File('lib/src/config.dart').existsSync()
        ? File('lib/src/config.dart')
        : File('packages/deepsky_bluetooth_interface/lib/src/config.dart');
    final source = sourceFile.readAsStringSync();

    expect(source, isNot(contains('@freezed')));
    expect(source, contains('@Freezed(copyWith: false)'));
  });
}
