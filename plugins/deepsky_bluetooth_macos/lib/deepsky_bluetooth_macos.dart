import 'src/observer.dart';

export 'src/observer.dart';

class DeepskyBluetoothMacos {
  const DeepskyBluetoothMacos({this.observers = const []});

  final List<DeepskyBluetoothMacosObserver> observers;

  Future<String?> getPlatformVersion() => throw UnimplementedError();
}
