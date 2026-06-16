import 'package:deepsky_bluetooth_util/deepsky_bluetooth_util.dart';
import 'package:test/test.dart';

void main() {
  test('operation errors are exhaustively switchable', () {
    String initialize(InitializeError error) => switch (error) {
      BackgroundNotSupported() => 'backgroundNotSupported',
      BackgroundConfigMissing() => 'backgroundConfigMissing',
      AlreadyInitialized() => 'alreadyInitialized',
      UnsupportedPlatform() => 'unsupportedPlatform',
      InitializeFailed() => 'failed',
    };

    String scan(ScanError error) => switch (error) {
      ScanPermissionDenied() => 'permissionDenied',
      ScanBluetoothOff() => 'bluetoothOff',
      ScanBluetoothUnavailable() => 'bluetoothUnavailable',
      ScanAlreadyScanning() => 'alreadyScanning',
      ScanFailed() => 'failed',
    };

    String connect(ConnectError error) => switch (error) {
      ConnectPermissionDenied() => 'permissionDenied',
      ConnectBluetoothOff() => 'bluetoothOff',
      ConnectBluetoothUnavailable() => 'bluetoothUnavailable',
      ConnectDeviceNotFound() => 'deviceNotFound',
      ConnectTimeout() => 'timeout',
      ConnectFailed() => 'failed',
    };

    String disconnect(DisconnectError error) => switch (error) {
      DisconnectNotConnected() => 'notConnected',
      DisconnectFailed() => 'failed',
    };

    String discoverServices(DiscoverServicesError error) => switch (error) {
      DiscoverServicesNotConnected() => 'notConnected',
      DiscoverServicesFailed() => 'failed',
    };

    String read(CharacteristicReadError error) => switch (error) {
      CharacteristicReadNotConnected() => 'notConnected',
      CharacteristicReadNotFound() => 'notFound',
      CharacteristicReadNotSupported() => 'notSupported',
      CharacteristicReadAmbiguousWhileNotifying() => 'ambiguous',
      CharacteristicReadFailed() => 'failed',
    };

    String write(CharacteristicWriteError error) => switch (error) {
      CharacteristicWriteNotConnected() => 'notConnected',
      CharacteristicWriteNotFound() => 'notFound',
      CharacteristicWriteNotSupported() => 'notSupported',
      CharacteristicWriteBufferFull() => 'bufferFull',
      CharacteristicWriteFailed() => 'failed',
    };

    String notify(NotifyError error) => switch (error) {
      NotifyNotConnected() => 'notConnected',
      NotifyNotFound() => 'notFound',
      NotifyNotSupported() => 'notSupported',
      NotifyFailed() => 'failed',
    };

    String descriptorRead(DescriptorReadError error) => switch (error) {
      DescriptorReadNotConnected() => 'notConnected',
      DescriptorReadNotFound() => 'notFound',
      DescriptorReadFailed() => 'failed',
    };

    String descriptorWrite(DescriptorWriteError error) => switch (error) {
      DescriptorWriteNotConnected() => 'notConnected',
      DescriptorWriteNotFound() => 'notFound',
      DescriptorWriteFailed() => 'failed',
    };

    String mtu(MtuError error) => switch (error) {
      MtuNotConnected() => 'notConnected',
      MtuFailed() => 'failed',
    };

    String rssi(RssiError error) => switch (error) {
      RssiNotConnected() => 'notConnected',
      RssiFailed() => 'failed',
    };

    String associate(AssociateError error) => switch (error) {
      AssociateNotSupported() => 'notSupported',
      AssociateRejected() => 'rejected',
      AssociateFailed() => 'failed',
    };

    String presence(PresenceError error) => switch (error) {
      PresenceNotSupported() => 'notSupported',
      PresenceNotAssociated() => 'notAssociated',
      PresenceFailed() => 'failed',
    };

    String dispose(DisposeError error) => switch (error) {
      DisposeFailed() => 'failed',
    };

    expect(initialize(const AlreadyInitialized()), 'alreadyInitialized');
    expect(scan(const ScanFailed('boom')), 'failed');
    expect(connect(const ConnectTimeout()), 'timeout');
    expect(disconnect(const DisconnectNotConnected()), 'notConnected');
    expect(discoverServices(const DiscoverServicesFailed('boom')), 'failed');
    expect(
      read(const CharacteristicReadAmbiguousWhileNotifying()),
      'ambiguous',
    );
    expect(write(const CharacteristicWriteBufferFull()), 'bufferFull');
    expect(notify(const NotifyNotSupported()), 'notSupported');
    expect(descriptorRead(const DescriptorReadFailed('boom')), 'failed');
    expect(descriptorWrite(const DescriptorWriteNotFound()), 'notFound');
    expect(mtu(const MtuFailed('boom')), 'failed');
    expect(rssi(const RssiNotConnected()), 'notConnected');
    expect(associate(const AssociateRejected()), 'rejected');
    expect(presence(const PresenceNotAssociated()), 'notAssociated');
    expect(dispose(const DisposeFailed('boom')), 'failed');
  });

  test('all errors implement Exception and expose messages', () {
    const Exception exception = CharacteristicWriteBufferFull();

    expect(exception, isA<DeepskyBluetoothError>());
    expect(const ScanFailed('scan failed').message, 'scan failed');
    expect(
      const DisposeFailed('dispose failed').toString(),
      contains('dispose failed'),
    );
  });

  test('BleErrorCode exposes stable native protocol strings', () {
    expect(BleErrorCode.permissionDenied, 'permissionDenied');
    expect(BleErrorCode.bluetoothOff, 'bluetoothOff');
    expect(BleErrorCode.bluetoothUnavailable, 'bluetoothUnavailable');
    expect(BleErrorCode.alreadyScanning, 'alreadyScanning');
    expect(BleErrorCode.notFound, 'notFound');
    expect(BleErrorCode.notConnected, 'notConnected');
    expect(BleErrorCode.notSupported, 'notSupported');
    expect(BleErrorCode.bufferFull, 'bufferFull');
    expect(
      BleErrorCode.readAmbiguousWhileNotifying,
      'readAmbiguousWhileNotifying',
    );
    expect(BleErrorCode.timeout, 'timeout');
    expect(BleErrorCode.rejected, 'rejected');
    expect(BleErrorCode.alreadyInitialized, 'alreadyInitialized');
    expect(BleErrorCode.backgroundNotSupported, 'backgroundNotSupported');
    expect(BleErrorCode.backgroundConfigMissing, 'backgroundConfigMissing');
    expect(BleErrorCode.notAssociated, 'notAssociated');
    expect(BleErrorCode.unsupportedPlatform, 'unsupportedPlatform');
    expect(BleErrorCode.failed, 'failed');
  });
}
