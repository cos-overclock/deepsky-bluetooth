import 'package:deepsky_bluetooth/deepsky_bluetooth.dart';
import 'package:flutter_test/flutter_test.dart';

final class _CommonObserver extends DeepskyBluetoothCommonObserver {}

final class _AndroidObserver extends DeepskyBluetoothAndroidObserver {}

final class _IosObserver extends DeepskyBluetoothIosObserver {}

final class _MacosObserver extends DeepskyBluetoothMacosObserver {}

void main() {
  test('root observer bundle accepts multiple common and native observers', () {
    final firstCommon = _CommonObserver();
    final secondCommon = _CommonObserver();
    final android = _AndroidObserver();
    final ios = _IosObserver();
    final macos = _MacosObserver();

    final observers = DeepskyBluetoothObservers(
      common: [firstCommon, secondCommon],
      android: [android],
      ios: [ios],
      macos: [macos],
    );

    expect(observers.common, [firstCommon, secondCommon]);
    expect(observers.android, [android]);
    expect(observers.ios, [ios]);
    expect(observers.macos, [macos]);
  });

  test('root observer bundle defaults to empty lists', () {
    const observers = DeepskyBluetoothObservers();

    expect(observers.common, isEmpty);
    expect(observers.android, isEmpty);
    expect(observers.ios, isEmpty);
    expect(observers.macos, isEmpty);
  });
}
