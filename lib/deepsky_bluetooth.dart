export 'package:deepsky_bluetooth_android_bridge/deepsky_bluetooth_android_bridge.dart'
    show DeepskyBluetoothAndroidObserver;
export 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart'
    show DeepskyBluetoothCommonObserver;
export 'package:deepsky_bluetooth_ios_bridge/deepsky_bluetooth_ios_bridge.dart'
    show DeepskyBluetoothIosObserver;
export 'package:deepsky_bluetooth_macos_bridge/deepsky_bluetooth_macos_bridge.dart'
    show DeepskyBluetoothMacosObserver;

export 'src/observers.dart';

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}
