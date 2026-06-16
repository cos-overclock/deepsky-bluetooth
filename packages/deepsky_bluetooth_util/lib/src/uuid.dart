import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'uuid.freezed.dart';

const String _bluetoothBaseSuffix = '-0000-1000-8000-00805f9b34fb';
const String _emptyUuid = '00000000-0000-0000-0000-000000000000';

/// Value object for a BLE UUID.
///
/// The const constructor stores a canonical lowercase 128-bit UUID string.
/// Use [DeepskyUuid.fromString] or [DeepskyUuid.fromBytes] when input needs
/// parsing or BLE 16/32-bit expansion.
@Freezed(toStringOverride: false)
abstract class DeepskyUuid with _$DeepskyUuid {
  const DeepskyUuid._();

  /// Creates a UUID value from an already-normalized 128-bit UUID string.
  const factory DeepskyUuid(String value) = _DeepskyUuid;

  /// Creates an all-zero UUID value.
  factory DeepskyUuid.empty() => const DeepskyUuid(_emptyUuid);

  /// Creates a UUID value from a 16-bit, 32-bit, or 128-bit UUID string.
  factory DeepskyUuid.fromString(String input) {
    if (input.isEmpty) {
      return DeepskyUuid.empty();
    }

    return DeepskyUuid(_normalizeHexString(input));
  }

  /// Creates a UUID value from big-endian 16-bit, 32-bit, or 128-bit bytes.
  factory DeepskyUuid.fromBytes(List<int> bytes) {
    return DeepskyUuid(_normalizeBytes(bytes));
  }

  /// Creates a UUID value from big-endian 16-bit, 32-bit, or 128-bit bytes.
  factory DeepskyUuid.fromByteArray(Uint8List bytes) {
    return DeepskyUuid.fromBytes(bytes);
  }

  /// Parses a nullable UUID string.
  static DeepskyUuid? parse(String? input) {
    if (input == null || input.isEmpty) {
      return null;
    }

    return DeepskyUuid.fromString(input);
  }

  /// Lowercase 128-bit UUID string.
  String get str128 => value;

  /// Shortest UUID string representation.
  String get str {
    if (str128.endsWith(_bluetoothBaseSuffix)) {
      if (str128.startsWith('0000')) {
        return str128.substring(4, 8);
      }

      return str128.substring(0, 8);
    }

    return str128;
  }

  /// 128-bit UUID bytes.
  List<int> get bytes => _hexDecode(str128.replaceAll('-', ''));
}

/// Client Characteristic Configuration Descriptor UUID.
const DeepskyUuid cccd = DeepskyUuid('00002902-0000-1000-8000-00805f9b34fb');

String _normalizeHexString(String input) {
  final hex = input.replaceAll('-', '').toLowerCase();
  final bytes = _tryHexDecode(hex);
  if (bytes == null) {
    throw FormatException('UUID is not hex format: $input');
  }

  return _normalizeBytes(bytes);
}

String _normalizeBytes(List<int> bytes) {
  _checkByteLength(bytes.length);

  final hex = _hexEncode(bytes);
  return switch (bytes.length) {
    2 => '0000$hex$_bluetoothBaseSuffix',
    4 => '$hex$_bluetoothBaseSuffix',
    16 =>
      '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
          '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
          '${hex.substring(20)}',
    _ => throw StateError('unreachable'),
  };
}

void _checkByteLength(int length) {
  if (length != 2 && length != 4 && length != 16) {
    throw FormatException(
      'UUID must be 16, 32, or 128 bit, yours: ${length * 8}-bit',
    );
  }
}

String _hexEncode(List<int> numbers) {
  return numbers.map((number) {
    return (number & 0xff).toRadixString(16).padLeft(2, '0');
  }).join();
}

List<int> _hexDecode(String hex) {
  final bytes = _tryHexDecode(hex);
  if (bytes == null) {
    throw FormatException('UUID is not hex format: $hex');
  }

  _checkByteLength(bytes.length);
  return bytes;
}

List<int>? _tryHexDecode(String hex) {
  if (hex.length.isOdd) {
    return null;
  }

  final numbers = <int>[];
  for (var index = 0; index < hex.length; index += 2) {
    final byte = int.tryParse(hex.substring(index, index + 2), radix: 16);
    if (byte == null) {
      return null;
    }

    numbers.add(byte);
  }

  return numbers;
}

/// Value object for a platform device identifier.
///
/// The value is intentionally not normalized. Android uses MAC-like addresses,
/// while Apple platforms use CoreBluetooth UUID strings.
@freezed
abstract class DeepskyDeviceId with _$DeepskyDeviceId {
  /// Creates a device id value from the platform identifier string.
  const factory DeepskyDeviceId(String value) = _DeepskyDeviceId;

  const DeepskyDeviceId._();

  @override
  String toString() => value;
}
