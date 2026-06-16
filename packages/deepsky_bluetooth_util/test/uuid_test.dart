import 'dart:typed_data';

import 'package:deepsky_bluetooth_util/deepsky_bluetooth_util.dart';
import 'package:test/test.dart';

void main() {
  test('DeepskyUuid normalizes 16, 32, and 128 bit UUID strings', () {
    expect(
      DeepskyUuid.fromString('180F').str128,
      '0000180f-0000-1000-8000-00805f9b34fb',
    );
    expect(
      DeepskyUuid.fromString('0000180F').str128,
      '0000180f-0000-1000-8000-00805f9b34fb',
    );
    expect(
      DeepskyUuid.fromString('0000180F-0000-1000-8000-00805F9B34FB').str128,
      '0000180f-0000-1000-8000-00805f9b34fb',
    );
  });

  test('DeepskyUuid normalizes strings and byte arrays to equal values', () {
    final fromString = DeepskyUuid.fromString('180F');
    final fromShortBytes = DeepskyUuid.fromBytes([0x18, 0x0f]);
    final fromFullBytes = DeepskyUuid.fromByteArray(
      Uint8List.fromList([
        0x00,
        0x00,
        0x18,
        0x0f,
        0x00,
        0x00,
        0x10,
        0x00,
        0x80,
        0x00,
        0x00,
        0x80,
        0x5f,
        0x9b,
        0x34,
        0xfb,
      ]),
    );

    expect(fromString.value, '0000180f-0000-1000-8000-00805f9b34fb');
    expect(fromShortBytes, fromString);
    expect(fromFullBytes, fromString);
    expect(fromString.hashCode, fromShortBytes.hashCode);
    expect(fromString.bytes, [
      0x00,
      0x00,
      0x18,
      0x0f,
      0x00,
      0x00,
      0x10,
      0x00,
      0x80,
      0x00,
      0x00,
      0x80,
      0x5f,
      0x9b,
      0x34,
      0xfb,
    ]);
  });

  test('DeepskyUuid parses nullable strings and rejects malformed input', () {
    expect(DeepskyUuid.parse(null), isNull);
    expect(DeepskyUuid.parse(''), isNull);
    expect(DeepskyUuid.parse('180f'), DeepskyUuid.fromString('180f'));
    expect(() => DeepskyUuid.fromString('not-a-uuid'), throwsFormatException);
    expect(() => DeepskyUuid.fromString('123'), throwsFormatException);
    expect(
      () => DeepskyUuid.fromByteArray(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
  });

  test('DeepskyUuid exposes shortest and 128-bit string forms', () {
    final uuid16 = DeepskyUuid.fromString('180F');
    final uuid32 = DeepskyUuid.fromString('12345678');
    final vendorUuid = DeepskyUuid.fromString(
      '11111111-2222-3333-4444-555555555555',
    );

    expect(uuid16.str, '180f');
    expect('$uuid16', '180f');
    expect(uuid16.str128, '0000180f-0000-1000-8000-00805f9b34fb');
    expect(uuid32.str, '12345678');
    expect(vendorUuid.str, '11111111-2222-3333-4444-555555555555');
  });

  test('DeepskyUuid is a freezed immutable data class', () {
    const uuid = DeepskyUuid('0000180f-0000-1000-8000-00805f9b34fb');
    final copied = uuid.copyWith(value: '00002a00-0000-1000-8000-00805f9b34fb');

    expect(uuid.value, '0000180f-0000-1000-8000-00805f9b34fb');
    expect(copied.value, '00002a00-0000-1000-8000-00805f9b34fb');
    expect(copied, isNot(uuid));
  });

  test('cccd is a global const DeepskyUuid', () {
    const expected = DeepskyUuid('00002902-0000-1000-8000-00805f9b34fb');

    expect(cccd, expected);
    expect(cccd.str, '2902');
  });

  test('DeepskyDeviceId uses exact platform id value equality', () {
    const first = DeepskyDeviceId('AA:BB:CC:DD:EE:FF');
    const same = DeepskyDeviceId('AA:BB:CC:DD:EE:FF');
    const differentCase = DeepskyDeviceId('aa:bb:cc:dd:ee:ff');

    expect(first, same);
    expect(first.hashCode, same.hashCode);
    expect(first, isNot(differentCase));
    expect('$first', 'AA:BB:CC:DD:EE:FF');
    expect({first: 'known'}[same], 'known');
  });
}
