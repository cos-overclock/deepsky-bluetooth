import 'package:deepsky_bluetooth_android_bridge/deepsky_bluetooth_android_bridge.dart'
    show DeepskyBluetoothAndroidObserver;
import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart'
    show DeepskyBluetoothCommonObserver;
import 'package:deepsky_bluetooth_ios_bridge/deepsky_bluetooth_ios_bridge.dart'
    show DeepskyBluetoothIosObserver;
import 'package:deepsky_bluetooth_macos_bridge/deepsky_bluetooth_macos_bridge.dart'
    show DeepskyBluetoothMacosObserver;

/// Observer bundle accepted by the root package.
///
/// All lists are invoked in list order. Runtime platform selection uses the
/// matching native observer list and ignores the others.
class DeepskyBluetoothObservers {
  const DeepskyBluetoothObservers({
    this.common = const [],
    this.android = const [],
    this.ios = const [],
    this.macos = const [],
  });

  final List<DeepskyBluetoothCommonObserver> common;
  final List<DeepskyBluetoothAndroidObserver> android;
  final List<DeepskyBluetoothIosObserver> ios;
  final List<DeepskyBluetoothMacosObserver> macos;
}
