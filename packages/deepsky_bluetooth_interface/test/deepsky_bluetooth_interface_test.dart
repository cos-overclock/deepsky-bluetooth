import 'package:flutter_test/flutter_test.dart';

import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';

void main() {
  test('reexports util value types', () {
    final uuid = DeepskyUuid.fromString('180F');
    const deviceId = DeepskyDeviceId('device-1');

    expect(uuid.str128, '0000180f-0000-1000-8000-00805f9b34fb');
    expect(cccd, const DeepskyUuid('00002902-0000-1000-8000-00805f9b34fb'));
    expect({deviceId: true}[const DeepskyDeviceId('device-1')], isTrue);
  });
}
