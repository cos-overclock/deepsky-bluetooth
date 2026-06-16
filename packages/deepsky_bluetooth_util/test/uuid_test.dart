import 'dart:typed_data';

import 'package:deepsky_bluetooth_util/deepsky_bluetooth_util.dart';
import 'package:test/test.dart';

void main() {
  test('BleUuid normalizes 16, 32, and 128 bit UUID strings', () {
    expect(BleUuid.normalize('180F'), '0000180f-0000-1000-8000-00805f9b34fb');
    expect(
      BleUuid.normalize('0000180F'),
      '0000180f-0000-1000-8000-00805f9b34fb',
    );
    expect(
      BleUuid.normalize('0000180F-0000-1000-8000-00805F9B34FB'),
      '0000180f-0000-1000-8000-00805f9b34fb',
    );
  });

  test('DeepskyUuid normalizes strings and byte arrays to equal values', () {
    final fromString = DeepskyUuid.fromString('180F');
    final fromShortBytes = DeepskyUuid.fromByteArray(
      Uint8List.fromList([0x18, 0x0f]),
    );
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
    expect('$fromString', fromString.value);
  });

  test('DeepskyUuid rejects invalid byte lengths', () {
    expect(
      () => DeepskyUuid.fromByteArray(Uint8List.fromList([1, 2, 3])),
      throwsArgumentError,
    );
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

  test('known UUID constants are normalized', () {
    expect(BleUuid.cccd, '00002902-0000-1000-8000-00805f9b34fb');
  });
}
