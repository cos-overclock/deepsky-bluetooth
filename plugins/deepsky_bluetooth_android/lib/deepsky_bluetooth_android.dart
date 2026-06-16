import 'src/observer.dart';

export 'src/observer.dart';

class DeepskyBluetoothAndroid {
  const DeepskyBluetoothAndroid({this.observers = const []});

  final List<DeepskyBluetoothAndroidObserver> observers;

  Future<String?> getPlatformVersion() => throw UnimplementedError();
}
