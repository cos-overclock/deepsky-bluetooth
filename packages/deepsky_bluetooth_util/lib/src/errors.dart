/// Base type for every deepsky_bluetooth error.
///
/// It implements [Exception] for compatibility with Result types constrained
/// to `E extends Exception`.
sealed class DeepskyBluetoothError implements Exception {
  const DeepskyBluetoothError();

  /// Human-readable diagnostic message.
  String get message;

  @override
  String toString() => '$runtimeType: $message';
}

sealed class InitializeError extends DeepskyBluetoothError {
  const InitializeError();
}

final class BackgroundNotSupported extends InitializeError {
  const BackgroundNotSupported();

  @override
  String get message => 'Background mode is not supported on this platform.';
}

final class BackgroundConfigMissing extends InitializeError {
  const BackgroundConfigMissing();

  @override
  String get message =>
      'Background mode requires a platform-specific background config.';
}

final class AlreadyInitialized extends InitializeError {
  const AlreadyInitialized();

  @override
  String get message => 'This instance is already initialized.';
}

final class UnsupportedPlatform extends InitializeError {
  const UnsupportedPlatform();

  @override
  String get message => 'This platform is not supported.';
}

final class InitializeFailed extends InitializeError {
  const InitializeFailed(this.message);

  @override
  final String message;
}

sealed class ScanError extends DeepskyBluetoothError {
  const ScanError();
}

final class ScanPermissionDenied extends ScanError {
  const ScanPermissionDenied();

  @override
  String get message => 'Bluetooth scan permission is denied.';
}

final class ScanBluetoothOff extends ScanError {
  const ScanBluetoothOff();

  @override
  String get message => 'Bluetooth is powered off.';
}

final class ScanBluetoothUnavailable extends ScanError {
  const ScanBluetoothUnavailable();

  @override
  String get message => 'Bluetooth is unavailable on this device.';
}

final class ScanAlreadyScanning extends ScanError {
  const ScanAlreadyScanning();

  @override
  String get message => 'A scan is already in progress.';
}

final class ScanFailed extends ScanError {
  const ScanFailed(this.message);

  @override
  final String message;
}

sealed class ConnectError extends DeepskyBluetoothError {
  const ConnectError();
}

final class ConnectPermissionDenied extends ConnectError {
  const ConnectPermissionDenied();

  @override
  String get message => 'Bluetooth connect permission is denied.';
}

final class ConnectBluetoothOff extends ConnectError {
  const ConnectBluetoothOff();

  @override
  String get message => 'Bluetooth is powered off.';
}

final class ConnectBluetoothUnavailable extends ConnectError {
  const ConnectBluetoothUnavailable();

  @override
  String get message => 'Bluetooth is unavailable on this device.';
}

final class ConnectDeviceNotFound extends ConnectError {
  const ConnectDeviceNotFound();

  @override
  String get message => 'Device not found.';
}

final class ConnectTimeout extends ConnectError {
  const ConnectTimeout();

  @override
  String get message => 'Connection attempt timed out.';
}

final class ConnectFailed extends ConnectError {
  const ConnectFailed(this.message);

  @override
  final String message;
}

sealed class DisconnectError extends DeepskyBluetoothError {
  const DisconnectError();
}

final class DisconnectNotConnected extends DisconnectError {
  const DisconnectNotConnected();

  @override
  String get message => 'Device is not connected.';
}

final class DisconnectFailed extends DisconnectError {
  const DisconnectFailed(this.message);

  @override
  final String message;
}

sealed class DiscoverServicesError extends DeepskyBluetoothError {
  const DiscoverServicesError();
}

final class DiscoverServicesNotConnected extends DiscoverServicesError {
  const DiscoverServicesNotConnected();

  @override
  String get message => 'Device is not connected.';
}

final class DiscoverServicesFailed extends DiscoverServicesError {
  const DiscoverServicesFailed(this.message);

  @override
  final String message;
}

sealed class CharacteristicReadError extends DeepskyBluetoothError {
  const CharacteristicReadError();
}

final class CharacteristicReadNotConnected extends CharacteristicReadError {
  const CharacteristicReadNotConnected();

  @override
  String get message => 'Device is not connected.';
}

final class CharacteristicReadNotFound extends CharacteristicReadError {
  const CharacteristicReadNotFound();

  @override
  String get message => 'Characteristic not found.';
}

final class CharacteristicReadNotSupported extends CharacteristicReadError {
  const CharacteristicReadNotSupported();

  @override
  String get message => 'This characteristic does not support read.';
}

final class CharacteristicReadAmbiguousWhileNotifying
    extends CharacteristicReadError {
  const CharacteristicReadAmbiguousWhileNotifying();

  @override
  String get message =>
      'read(strictRead: true) is ambiguous while notifications are enabled.';
}

final class CharacteristicReadFailed extends CharacteristicReadError {
  const CharacteristicReadFailed(this.message);

  @override
  final String message;
}

sealed class CharacteristicWriteError extends DeepskyBluetoothError {
  const CharacteristicWriteError();
}

final class CharacteristicWriteNotConnected extends CharacteristicWriteError {
  const CharacteristicWriteNotConnected();

  @override
  String get message => 'Device is not connected.';
}

final class CharacteristicWriteNotFound extends CharacteristicWriteError {
  const CharacteristicWriteNotFound();

  @override
  String get message => 'Characteristic not found.';
}

final class CharacteristicWriteNotSupported extends CharacteristicWriteError {
  const CharacteristicWriteNotSupported();

  @override
  String get message => 'This characteristic does not support write.';
}

final class CharacteristicWriteBufferFull extends CharacteristicWriteError {
  const CharacteristicWriteBufferFull();

  @override
  String get message => 'The write-without-response buffer is full.';
}

final class CharacteristicWriteFailed extends CharacteristicWriteError {
  const CharacteristicWriteFailed(this.message);

  @override
  final String message;
}

sealed class NotifyError extends DeepskyBluetoothError {
  const NotifyError();
}

final class NotifyNotConnected extends NotifyError {
  const NotifyNotConnected();

  @override
  String get message => 'Device is not connected.';
}

final class NotifyNotFound extends NotifyError {
  const NotifyNotFound();

  @override
  String get message => 'Characteristic not found.';
}

final class NotifyNotSupported extends NotifyError {
  const NotifyNotSupported();

  @override
  String get message => 'This characteristic does not support notify/indicate.';
}

final class NotifyFailed extends NotifyError {
  const NotifyFailed(this.message);

  @override
  final String message;
}

sealed class DescriptorReadError extends DeepskyBluetoothError {
  const DescriptorReadError();
}

final class DescriptorReadNotConnected extends DescriptorReadError {
  const DescriptorReadNotConnected();

  @override
  String get message => 'Device is not connected.';
}

final class DescriptorReadNotFound extends DescriptorReadError {
  const DescriptorReadNotFound();

  @override
  String get message => 'Descriptor not found.';
}

final class DescriptorReadFailed extends DescriptorReadError {
  const DescriptorReadFailed(this.message);

  @override
  final String message;
}

sealed class DescriptorWriteError extends DeepskyBluetoothError {
  const DescriptorWriteError();
}

final class DescriptorWriteNotConnected extends DescriptorWriteError {
  const DescriptorWriteNotConnected();

  @override
  String get message => 'Device is not connected.';
}

final class DescriptorWriteNotFound extends DescriptorWriteError {
  const DescriptorWriteNotFound();

  @override
  String get message => 'Descriptor not found.';
}

final class DescriptorWriteFailed extends DescriptorWriteError {
  const DescriptorWriteFailed(this.message);

  @override
  final String message;
}

sealed class MtuError extends DeepskyBluetoothError {
  const MtuError();
}

final class MtuNotConnected extends MtuError {
  const MtuNotConnected();

  @override
  String get message => 'Device is not connected.';
}

final class MtuFailed extends MtuError {
  const MtuFailed(this.message);

  @override
  final String message;
}

sealed class RssiError extends DeepskyBluetoothError {
  const RssiError();
}

final class RssiNotConnected extends RssiError {
  const RssiNotConnected();

  @override
  String get message => 'Device is not connected.';
}

final class RssiFailed extends RssiError {
  const RssiFailed(this.message);

  @override
  final String message;
}

sealed class AssociateError extends DeepskyBluetoothError {
  const AssociateError();
}

final class AssociateNotSupported extends AssociateError {
  const AssociateNotSupported();

  @override
  String get message => 'Companion device association is Android-only.';
}

final class AssociateRejected extends AssociateError {
  const AssociateRejected();

  @override
  String get message => 'Association was rejected or cancelled by the user.';
}

final class AssociateFailed extends AssociateError {
  const AssociateFailed(this.message);

  @override
  final String message;
}

sealed class PresenceError extends DeepskyBluetoothError {
  const PresenceError();
}

final class PresenceNotSupported extends PresenceError {
  const PresenceNotSupported();

  @override
  String get message => 'Device presence observation is Android-only.';
}

final class PresenceNotAssociated extends PresenceError {
  const PresenceNotAssociated();

  @override
  String get message => 'Device is not associated via CompanionDeviceManager.';
}

final class PresenceFailed extends PresenceError {
  const PresenceFailed(this.message);

  @override
  final String message;
}

sealed class DisposeError extends DeepskyBluetoothError {
  const DisposeError();
}

final class DisposeFailed extends DisposeError {
  const DisposeFailed(this.message);

  @override
  final String message;
}
