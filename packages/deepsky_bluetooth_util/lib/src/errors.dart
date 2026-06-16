/// Base type for every deepsky_bluetooth error.
///
/// It implements [Exception] for compatibility with Result types constrained
/// to `E extends Exception`.
sealed class DeepskyBluetoothError implements Exception {
  const DeepskyBluetoothError({this.cause, this.stackTrace});

  /// Original error object that caused this error, when available.
  final Object? cause;

  /// Stack trace captured with [cause], when available.
  final StackTrace? stackTrace;

  /// Human-readable diagnostic message.
  String get message;

  @override
  String toString() => '$runtimeType: $message';
}

sealed class InitializeError extends DeepskyBluetoothError {
  const InitializeError({super.cause, super.stackTrace});
}

final class BackgroundNotSupported extends InitializeError {
  const BackgroundNotSupported({super.cause, super.stackTrace});

  @override
  String get message => 'Background mode is not supported on this platform.';
}

final class BackgroundConfigMissing extends InitializeError {
  const BackgroundConfigMissing({super.cause, super.stackTrace});

  @override
  String get message =>
      'Background mode requires a platform-specific background config.';
}

final class AlreadyInitialized extends InitializeError {
  const AlreadyInitialized({super.cause, super.stackTrace});

  @override
  String get message => 'This instance is already initialized.';
}

final class UnsupportedPlatform extends InitializeError {
  const UnsupportedPlatform({super.cause, super.stackTrace});

  @override
  String get message => 'This platform is not supported.';
}

final class InitializeFailed extends InitializeError {
  const InitializeFailed(this.message, {super.cause, super.stackTrace});

  @override
  final String message;
}

sealed class ScanError extends DeepskyBluetoothError {
  const ScanError({super.cause, super.stackTrace});
}

final class ScanPermissionDenied extends ScanError {
  const ScanPermissionDenied({super.cause, super.stackTrace});

  @override
  String get message => 'Bluetooth scan permission is denied.';
}

final class ScanBluetoothOff extends ScanError {
  const ScanBluetoothOff({super.cause, super.stackTrace});

  @override
  String get message => 'Bluetooth is powered off.';
}

final class ScanBluetoothUnavailable extends ScanError {
  const ScanBluetoothUnavailable({super.cause, super.stackTrace});

  @override
  String get message => 'Bluetooth is unavailable on this device.';
}

final class ScanAlreadyScanning extends ScanError {
  const ScanAlreadyScanning({super.cause, super.stackTrace});

  @override
  String get message => 'A scan is already in progress.';
}

final class ScanFailed extends ScanError {
  const ScanFailed(this.message, {super.cause, super.stackTrace});

  @override
  final String message;
}

sealed class ConnectError extends DeepskyBluetoothError {
  const ConnectError({super.cause, super.stackTrace});
}

final class ConnectPermissionDenied extends ConnectError {
  const ConnectPermissionDenied({super.cause, super.stackTrace});

  @override
  String get message => 'Bluetooth connect permission is denied.';
}

final class ConnectBluetoothOff extends ConnectError {
  const ConnectBluetoothOff({super.cause, super.stackTrace});

  @override
  String get message => 'Bluetooth is powered off.';
}

final class ConnectBluetoothUnavailable extends ConnectError {
  const ConnectBluetoothUnavailable({super.cause, super.stackTrace});

  @override
  String get message => 'Bluetooth is unavailable on this device.';
}

final class ConnectDeviceNotFound extends ConnectError {
  const ConnectDeviceNotFound({super.cause, super.stackTrace});

  @override
  String get message => 'Device not found.';
}

final class ConnectTimeout extends ConnectError {
  const ConnectTimeout({super.cause, super.stackTrace});

  @override
  String get message => 'Connection attempt timed out.';
}

final class ConnectFailed extends ConnectError {
  const ConnectFailed(this.message, {super.cause, super.stackTrace});

  @override
  final String message;
}

sealed class DisconnectError extends DeepskyBluetoothError {
  const DisconnectError({super.cause, super.stackTrace});
}

final class DisconnectNotConnected extends DisconnectError {
  const DisconnectNotConnected({super.cause, super.stackTrace});

  @override
  String get message => 'Device is not connected.';
}

final class DisconnectFailed extends DisconnectError {
  const DisconnectFailed(this.message, {super.cause, super.stackTrace});

  @override
  final String message;
}

sealed class DiscoverServicesError extends DeepskyBluetoothError {
  const DiscoverServicesError({super.cause, super.stackTrace});
}

final class DiscoverServicesNotConnected extends DiscoverServicesError {
  const DiscoverServicesNotConnected({super.cause, super.stackTrace});

  @override
  String get message => 'Device is not connected.';
}

final class DiscoverServicesFailed extends DiscoverServicesError {
  const DiscoverServicesFailed(this.message, {super.cause, super.stackTrace});

  @override
  final String message;
}

sealed class CharacteristicReadError extends DeepskyBluetoothError {
  const CharacteristicReadError({super.cause, super.stackTrace});
}

final class CharacteristicReadNotConnected extends CharacteristicReadError {
  const CharacteristicReadNotConnected({super.cause, super.stackTrace});

  @override
  String get message => 'Device is not connected.';
}

final class CharacteristicReadNotFound extends CharacteristicReadError {
  const CharacteristicReadNotFound({super.cause, super.stackTrace});

  @override
  String get message => 'Characteristic not found.';
}

final class CharacteristicReadNotSupported extends CharacteristicReadError {
  const CharacteristicReadNotSupported({super.cause, super.stackTrace});

  @override
  String get message => 'This characteristic does not support read.';
}

final class CharacteristicReadAmbiguousWhileNotifying
    extends CharacteristicReadError {
  const CharacteristicReadAmbiguousWhileNotifying({
    super.cause,
    super.stackTrace,
  });

  @override
  String get message =>
      'read(strictRead: true) is ambiguous while notifications are enabled.';
}

final class CharacteristicReadFailed extends CharacteristicReadError {
  const CharacteristicReadFailed(this.message, {super.cause, super.stackTrace});

  @override
  final String message;
}

sealed class CharacteristicWriteError extends DeepskyBluetoothError {
  const CharacteristicWriteError({super.cause, super.stackTrace});
}

final class CharacteristicWriteNotConnected extends CharacteristicWriteError {
  const CharacteristicWriteNotConnected({super.cause, super.stackTrace});

  @override
  String get message => 'Device is not connected.';
}

final class CharacteristicWriteNotFound extends CharacteristicWriteError {
  const CharacteristicWriteNotFound({super.cause, super.stackTrace});

  @override
  String get message => 'Characteristic not found.';
}

final class CharacteristicWriteNotSupported extends CharacteristicWriteError {
  const CharacteristicWriteNotSupported({super.cause, super.stackTrace});

  @override
  String get message => 'This characteristic does not support write.';
}

final class CharacteristicWriteBufferFull extends CharacteristicWriteError {
  const CharacteristicWriteBufferFull({super.cause, super.stackTrace});

  @override
  String get message => 'The write-without-response buffer is full.';
}

final class CharacteristicWriteFailed extends CharacteristicWriteError {
  const CharacteristicWriteFailed(
    this.message, {
    super.cause,
    super.stackTrace,
  });

  @override
  final String message;
}

sealed class NotifyError extends DeepskyBluetoothError {
  const NotifyError({super.cause, super.stackTrace});
}

final class NotifyNotConnected extends NotifyError {
  const NotifyNotConnected({super.cause, super.stackTrace});

  @override
  String get message => 'Device is not connected.';
}

final class NotifyNotFound extends NotifyError {
  const NotifyNotFound({super.cause, super.stackTrace});

  @override
  String get message => 'Characteristic not found.';
}

final class NotifyNotSupported extends NotifyError {
  const NotifyNotSupported({super.cause, super.stackTrace});

  @override
  String get message => 'This characteristic does not support notify/indicate.';
}

final class NotifyFailed extends NotifyError {
  const NotifyFailed(this.message, {super.cause, super.stackTrace});

  @override
  final String message;
}

sealed class DescriptorReadError extends DeepskyBluetoothError {
  const DescriptorReadError({super.cause, super.stackTrace});
}

final class DescriptorReadNotConnected extends DescriptorReadError {
  const DescriptorReadNotConnected({super.cause, super.stackTrace});

  @override
  String get message => 'Device is not connected.';
}

final class DescriptorReadNotFound extends DescriptorReadError {
  const DescriptorReadNotFound({super.cause, super.stackTrace});

  @override
  String get message => 'Descriptor not found.';
}

final class DescriptorReadFailed extends DescriptorReadError {
  const DescriptorReadFailed(this.message, {super.cause, super.stackTrace});

  @override
  final String message;
}

sealed class DescriptorWriteError extends DeepskyBluetoothError {
  const DescriptorWriteError({super.cause, super.stackTrace});
}

final class DescriptorWriteNotConnected extends DescriptorWriteError {
  const DescriptorWriteNotConnected({super.cause, super.stackTrace});

  @override
  String get message => 'Device is not connected.';
}

final class DescriptorWriteNotFound extends DescriptorWriteError {
  const DescriptorWriteNotFound({super.cause, super.stackTrace});

  @override
  String get message => 'Descriptor not found.';
}

final class DescriptorWriteFailed extends DescriptorWriteError {
  const DescriptorWriteFailed(this.message, {super.cause, super.stackTrace});

  @override
  final String message;
}

sealed class MtuError extends DeepskyBluetoothError {
  const MtuError({super.cause, super.stackTrace});
}

final class MtuNotConnected extends MtuError {
  const MtuNotConnected({super.cause, super.stackTrace});

  @override
  String get message => 'Device is not connected.';
}

final class MtuFailed extends MtuError {
  const MtuFailed(this.message, {super.cause, super.stackTrace});

  @override
  final String message;
}

sealed class RssiError extends DeepskyBluetoothError {
  const RssiError({super.cause, super.stackTrace});
}

final class RssiNotConnected extends RssiError {
  const RssiNotConnected({super.cause, super.stackTrace});

  @override
  String get message => 'Device is not connected.';
}

final class RssiFailed extends RssiError {
  const RssiFailed(this.message, {super.cause, super.stackTrace});

  @override
  final String message;
}

sealed class AssociateError extends DeepskyBluetoothError {
  const AssociateError({super.cause, super.stackTrace});
}

final class AssociateNotSupported extends AssociateError {
  const AssociateNotSupported({super.cause, super.stackTrace});

  @override
  String get message => 'Companion device association is Android-only.';
}

final class AssociateRejected extends AssociateError {
  const AssociateRejected({super.cause, super.stackTrace});

  @override
  String get message => 'Association was rejected or cancelled by the user.';
}

final class AssociateFailed extends AssociateError {
  const AssociateFailed(this.message, {super.cause, super.stackTrace});

  @override
  final String message;
}

sealed class PresenceError extends DeepskyBluetoothError {
  const PresenceError({super.cause, super.stackTrace});
}

final class PresenceNotSupported extends PresenceError {
  const PresenceNotSupported({super.cause, super.stackTrace});

  @override
  String get message => 'Device presence observation is Android-only.';
}

final class PresenceNotAssociated extends PresenceError {
  const PresenceNotAssociated({super.cause, super.stackTrace});

  @override
  String get message => 'Device is not associated via CompanionDeviceManager.';
}

final class PresenceFailed extends PresenceError {
  const PresenceFailed(this.message, {super.cause, super.stackTrace});

  @override
  final String message;
}

sealed class DisposeError extends DeepskyBluetoothError {
  const DisposeError({super.cause, super.stackTrace});
}

final class DisposeFailed extends DisposeError {
  const DisposeFailed(this.message, {super.cause, super.stackTrace});

  @override
  final String message;
}
