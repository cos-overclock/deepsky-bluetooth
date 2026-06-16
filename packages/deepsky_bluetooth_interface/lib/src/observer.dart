import 'package:steady/steady.dart';

/// User-defined hooks for method calls and native-to-Dart callbacks.
abstract interface class DeepskyBluetoothObserver {
  void onMethodStart(String methodName, Map<String, Object?> arguments);

  void onMethodEnd(String methodName, Result<Object?, Exception> result);

  void onCallback(String callbackName, Object? payload);
}
