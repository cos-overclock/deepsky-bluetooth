/// Native error code strings passed through FlutterError / PlatformException.
///
/// Kotlin and Swift bridge constants must keep these exact values so Dart
/// mappers can avoid string literals.
abstract final class BleErrorCode {
  /// Bluetooth permission required for the operation is denied.
  static const String permissionDenied = 'permissionDenied';

  /// Bluetooth adapter is powered off.
  static const String bluetoothOff = 'bluetoothOff';

  /// Bluetooth is unavailable on the device.
  static const String bluetoothUnavailable = 'bluetoothUnavailable';

  /// A scan operation is already running.
  static const String alreadyScanning = 'alreadyScanning';

  /// Requested device, characteristic, descriptor, or handle was not found.
  static const String notFound = 'notFound';

  /// The target device is not connected for this operation.
  static const String notConnected = 'notConnected';

  /// The platform or target GATT attribute does not support the operation.
  static const String notSupported = 'notSupported';

  /// The write-without-response buffer is currently full.
  static const String bufferFull = 'bufferFull';

  /// CoreBluetooth cannot distinguish a read response from notification data.
  static const String readAmbiguousWhileNotifying =
      'readAmbiguousWhileNotifying';

  /// The operation timed out.
  static const String timeout = 'timeout';

  /// The user rejected or cancelled an association request.
  static const String rejected = 'rejected';

  /// The instance has already been initialized.
  static const String alreadyInitialized = 'alreadyInitialized';

  /// Background mode is unavailable on the platform.
  static const String backgroundNotSupported = 'backgroundNotSupported';

  /// Background mode requires missing platform configuration.
  static const String backgroundConfigMissing = 'backgroundConfigMissing';

  /// CompanionDeviceManager has no association for the device.
  static const String notAssociated = 'notAssociated';

  /// The platform does not support deepsky_bluetooth.
  static const String unsupportedPlatform = 'unsupportedPlatform';

  /// Fallback for operation-specific failures not covered by another code.
  static const String failed = 'failed';
}
