import 'src/observer.dart';

export 'src/observer.dart';

class DeepskyBluetoothIos {
  const DeepskyBluetoothIos({this.observers = const []});

  final List<DeepskyBluetoothIosObserver> observers;

  Future<String?> getPlatformVersion() => throw UnimplementedError();
}
