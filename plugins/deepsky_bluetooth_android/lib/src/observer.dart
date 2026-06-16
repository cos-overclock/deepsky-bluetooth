/// Android-specific native observer.
///
/// Users extend this class when they need diagnostics from the Android plugin
/// layer, such as native owner state, GATT queue progress, epoch updates, or
/// CompanionDevice events.
class DeepskyBluetoothAndroidObserver {
  const DeepskyBluetoothAndroidObserver();

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

  void onConnectionStateChanged(
    String deviceId,
    int? connectionEpoch,
    String state,
    String? reason,
  ) {}
  void onScanResult(String deviceId) {}
  void onScanFailed(int errorCode) {}
  void onCharacteristicNotified(
    String deviceId,
    int connectionEpoch,
    int characteristicHandle,
  ) {}
  void onOperationTimeout(String deviceId, int connectionEpoch) {}
  void onAdapterStateChanged(String state) {}
  void onCompanionDeviceAppeared(String deviceId) {}
  void onCompanionDeviceDisappeared(String deviceId) {}

  void onSinkHandoverStart(String engineToken) {}
  void onSinkHandoverEnd(String engineToken, Object? error) {}
  void onStateResync(String snapshotId) {}
}
