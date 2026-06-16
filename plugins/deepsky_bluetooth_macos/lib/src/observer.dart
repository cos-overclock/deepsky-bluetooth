/// macOS-specific native observer.
///
/// Users extend this class when they need diagnostics from the macOS plugin
/// layer, such as CoreBluetooth callbacks, GATT operation queue progress,
/// epoch updates, or sink handover.
class DeepskyBluetoothMacosObserver {
  const DeepskyBluetoothMacosObserver();

  void onInitializeStart() {}
  void onInitializeEnd(Object? error) {}

  void onConnectStart(String deviceId) {}
  void onConnectEnd(String deviceId, Object? error) {}

  void onDisconnectStart(String deviceId, int connectionEpoch) {}
  void onDisconnectEnd(String deviceId, int connectionEpoch, Object? error) {}

  void onGattOperationQueued(
    String deviceId,
    int connectionEpoch,
    String operationKind,
  ) {}
  void onGattOperationStart(
    String deviceId,
    int connectionEpoch,
    String operationKind,
  ) {}
  void onGattOperationEnd(
    String deviceId,
    int connectionEpoch,
    String operationKind,
    Object? error,
  ) {}

  void onConnectionEpochChanged(String deviceId, int connectionEpoch) {}
  void onHandleDiscovered(
    String deviceId,
    int connectionEpoch,
    int handle,
    String attributeKind,
    String uuid,
  ) {}

  void onCentralManagerStateChanged(String state) {}
  void onConnectionStateChanged(
    String deviceId,
    int? connectionEpoch,
    String state,
    String? reason,
  ) {}
  void onScanResult(String deviceId) {}
  void onCharacteristicValue(
    String deviceId,
    int connectionEpoch,
    int characteristicHandle,
    bool fromNotify,
  ) {}

  void onSinkHandoverStart(String engineToken) {}
  void onSinkHandoverEnd(String engineToken, Object? error) {}
  void onStateResync(String snapshotId) {}
}
