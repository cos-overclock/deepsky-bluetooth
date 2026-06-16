import 'dart:typed_data';

/// BLE UUID utilities.
///
/// Dart-facing UUID values are normalized to lowercase 128-bit UUID strings.
abstract final class BleUuid {
  static const String _base = '-0000-1000-8000-00805f9b34fb';

  /// Client Characteristic Configuration Descriptor UUID.
  static const String cccd = '00002902-0000-1000-8000-00805f9b34fb';

  /// Normalizes 16-bit, 32-bit, and full 128-bit UUID strings.
  static String normalize(String uuid) {
    final normalized = uuid.toLowerCase();
    return switch (normalized.length) {
      4 => '0000$normalized$_base',
      8 => '$normalized$_base',
      _ => normalized,
    };
  }
}

/// Value object for a BLE UUID.
final class DeepskyUuid {
  /// Creates a UUID value from a string.
  DeepskyUuid.fromString(String uuid) : value = BleUuid.normalize(uuid);

  /// Creates a UUID value from big-endian 16-bit, 32-bit, or 128-bit bytes.
  DeepskyUuid.fromByteArray(Uint8List bytes) : value = _fromBytes(bytes);

  /// Lowercase 128-bit UUID string.
  final String value;

  static String _fromBytes(Uint8List bytes) {
    final hex = bytes.map((byte) {
      return byte.toRadixString(16).padLeft(2, '0');
    }).join();

    return switch (bytes.length) {
      2 || 4 => BleUuid.normalize(hex),
      16 =>
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
            '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
            '${hex.substring(20)}',
      _ => throw ArgumentError.value(
        bytes,
        'bytes',
        'UUID byte length must be 2, 4, or 16',
      ),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is DeepskyUuid && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Value object for a platform device identifier.
///
/// The value is intentionally not normalized. Android uses MAC-like addresses,
/// while Apple platforms use CoreBluetooth UUID strings.
final class DeepskyDeviceId {
  /// Creates a device id value from the platform identifier string.
  const DeepskyDeviceId(this.value);

  /// Original platform identifier string.
  final String value;

  @override
  bool operator ==(Object other) {
    return other is DeepskyDeviceId && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
