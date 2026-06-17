import 'dart:typed_data';

import 'package:deepsky_bluetooth_android/deepsky_bluetooth_android.dart';
import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';

// Outbound conversions (interface model -> Pigeon DTO) and inbound conversions
// (Pigeon DTO / callback args -> interface model) for the Android bridge.
//
// Every conversion preserves value types, epoch and handle so that nothing is
// dropped at the Pigeon boundary. Duplicate UUIDs are kept verbatim because the
// handle, not the UUID, identifies a GATT attribute.

// --- scan / config / device id / uuid (outbound + scan result inbound) ---

/// Converts a [DeepskyScanFilter] to its Pigeon DTO, or `null` when no filter
/// is set. UUIDs are emitted in canonical 128-bit lowercase form.
ScanFilterMessage? scanFilterToMessage(DeepskyScanFilter? filter) {
  if (filter == null) {
    return null;
  }
  return ScanFilterMessage(
    addresses: filter.deviceIds.map((d) => d.value).toList(),
    names: List<String>.of(filter.names),
    manufacturerData: filter.manufacturerData
        .map(
          (m) => ManufacturerDataFilterMessage(
            manufacturerId: m.manufacturerId,
            data: m.data,
          ),
        )
        .toList(),
    serviceData: filter.serviceData
        .map(
          (s) => ServiceDataFilterMessage(
            serviceUuid: s.uuid.value,
            data: s.data,
          ),
        )
        .toList(),
    serviceUuids: filter.serviceUuids.map((u) => u.value).toList(),
  );
}

/// Converts Android-specific scan settings to their Pigeon DTO.
AndroidScanSettingsMessage androidScanSettingsToMessage(
  DeepskyAndroidScanSetting setting,
) {
  return AndroidScanSettingsMessage(
    mode: switch (setting.mode) {
      DeepskyAndroidScanMode.lowPower => ScanModeMessage.lowPower,
      DeepskyAndroidScanMode.balanced => ScanModeMessage.balanced,
      DeepskyAndroidScanMode.lowLatency => ScanModeMessage.lowLatency,
      DeepskyAndroidScanMode.opportunistic => ScanModeMessage.opportunistic,
    },
    callbackType: switch (setting.callbackType) {
      DeepskyAndroidScanCallbackType.allMatches =>
        ScanCallbackTypeMessage.allMatches,
      DeepskyAndroidScanCallbackType.firstMatch =>
        ScanCallbackTypeMessage.firstMatch,
      DeepskyAndroidScanCallbackType.matchLost =>
        ScanCallbackTypeMessage.matchLost,
      DeepskyAndroidScanCallbackType.firstMatchAndMatchLost =>
        ScanCallbackTypeMessage.firstMatchAndMatchLost,
    },
    onlyLegacy: setting.onlyLegacy,
    matchMode: switch (setting.matchMode) {
      DeepskyAndroidScanMatchMode.aggressive => ScanMatchModeMessage.aggressive,
      DeepskyAndroidScanMatchMode.sticky => ScanMatchModeMessage.sticky,
    },
    numOfMatch: switch (setting.numOfMatch) {
      DeepskyAndroidScanNumOfMatch.oneAdvertisement => ScanNumOfMatchMessage.one,
      DeepskyAndroidScanNumOfMatch.fewAdvertisement => ScanNumOfMatchMessage.few,
      DeepskyAndroidScanNumOfMatch.maxAdvertisement => ScanNumOfMatchMessage.max,
    },
    reportDelayMillis: setting.reportDelay.inMilliseconds,
    phy: switch (setting.phy) {
      DeepskyAndroidScanPhy.le1m => ScanPhyMessage.le1m,
      DeepskyAndroidScanPhy.leCoded => ScanPhyMessage.leCoded,
      DeepskyAndroidScanPhy.allSupported => ScanPhyMessage.allSupported,
    },
  );
}

/// Converts a scan result DTO to its interface model, normalizing UUIDs.
BleScanResult scanResultFromMessage(ScanResultMessage message) {
  return BleScanResult(
    deviceId: DeepskyDeviceId(message.deviceId),
    name: message.name,
    rssi: message.rssi,
    serviceUuids: message.serviceUuids.map(DeepskyUuid.fromString).toList(),
    manufacturerData: message.manufacturerData,
    raw: message.raw,
  );
}

/// Converts a [DeepskyBluetoothConfig] to the native initialize request.
///
/// A background config without an Android strategy is rejected upstream, so it
/// maps to a strategy-less request rather than being silently dropped.
InitializeRequestMessage configToMessage(DeepskyBluetoothConfig config) {
  return switch (config) {
    ForegroundConfig() => InitializeRequestMessage(isBackground: false),
    BackgroundConfig(:final android, :final backgroundCallbackHandle) =>
      switch (android) {
        AndroidForegroundServiceConfig(:final notification) =>
          InitializeRequestMessage(
            isBackground: true,
            strategy: BackgroundStrategyMessage.foregroundService,
            notification: NotificationConfigMessage(
              channelId: notification.channelId,
              channelName: notification.channelName,
              title: notification.title,
              text: notification.text,
            ),
            backgroundCallbackHandle: backgroundCallbackHandle,
          ),
        AndroidCompanionDeviceConfig() => InitializeRequestMessage(
            isBackground: true,
            strategy: BackgroundStrategyMessage.companionDevice,
            backgroundCallbackHandle: backgroundCallbackHandle,
          ),
        null => InitializeRequestMessage(
            isBackground: true,
            backgroundCallbackHandle: backgroundCallbackHandle,
          ),
      },
  };
}

// --- connection / GATT enums, targets and handles ---

/// Converts a connection state enum to its interface model.
BleConnectionState connectionStateFromMessage(ConnectionStateMessage message) {
  return switch (message) {
    ConnectionStateMessage.connecting => BleConnectionState.connecting,
    ConnectionStateMessage.connected => BleConnectionState.connected,
    ConnectionStateMessage.disconnecting => BleConnectionState.disconnecting,
    ConnectionStateMessage.disconnected => BleConnectionState.disconnected,
    ConnectionStateMessage.reconnecting => BleConnectionState.reconnecting,
  };
}

/// Converts an adapter state enum to its interface model.
BleAdapterState adapterStateFromMessage(AdapterStateMessage message) {
  return switch (message) {
    AdapterStateMessage.poweredOn => BleAdapterState.poweredOn,
    AdapterStateMessage.poweredOff => BleAdapterState.poweredOff,
    AdapterStateMessage.unavailable => BleAdapterState.unavailable,
  };
}

/// Converts a disconnect reason enum to its interface model.
BleDisconnectReason disconnectReasonFromMessage(DisconnectReasonMessage m) {
  return switch (m) {
    DisconnectReasonMessage.userRequested => BleDisconnectReason.userRequested,
    DisconnectReasonMessage.connectionLost => BleDisconnectReason.connectionLost,
    DisconnectReasonMessage.connectFailed => BleDisconnectReason.connectFailed,
    DisconnectReasonMessage.operationTimeout =>
      BleDisconnectReason.operationTimeout,
    DisconnectReasonMessage.permissionDenied =>
      BleDisconnectReason.permissionDenied,
    DisconnectReasonMessage.bluetoothOff => BleDisconnectReason.bluetoothOff,
    DisconnectReasonMessage.bluetoothUnavailable =>
      BleDisconnectReason.bluetoothUnavailable,
    DisconnectReasonMessage.deviceNotFound => BleDisconnectReason.deviceNotFound,
    DisconnectReasonMessage.notAssociated => BleDisconnectReason.notAssociated,
    DisconnectReasonMessage.presenceObservationDisabled =>
      BleDisconnectReason.presenceObservationDisabled,
    DisconnectReasonMessage.unknown => BleDisconnectReason.unknown,
  };
}

/// Converts a notify type to its Pigeon DTO.
NotifyTypeMessage notifyTypeToMessage(BleNotifyType type) {
  return switch (type) {
    BleNotifyType.disable => NotifyTypeMessage.disable,
    BleNotifyType.notify => NotifyTypeMessage.notify,
    BleNotifyType.indicate => NotifyTypeMessage.indicate,
  };
}

/// Converts a connection attempt DTO to its interface model.
ConnectionAttempt connectionAttemptFromMessage(ConnectionAttemptMessage m) {
  return ConnectionAttempt(connectionEpoch: m.connectionEpoch);
}

/// Converts a characteristic target to its Pigeon DTO, keeping epoch and handle.
CharacteristicTargetMessage characteristicTargetToMessage(
  BleCharacteristicTarget target,
) {
  return CharacteristicTargetMessage(
    deviceId: target.deviceId.value,
    connectionEpoch: target.connectionEpoch,
    characteristicHandle: target.characteristicHandle,
  );
}

/// Converts a descriptor target to its Pigeon DTO, keeping epoch and handles.
DescriptorTargetMessage descriptorTargetToMessage(BleDescriptorTarget target) {
  return DescriptorTargetMessage(
    deviceId: target.deviceId.value,
    connectionEpoch: target.connectionEpoch,
    characteristicHandle: target.characteristicHandle,
    descriptorHandle: target.descriptorHandle,
  );
}

// --- service discovery DTOs (handle-bearing, UUID duplicates preserved) ---

/// Converts a discovered service DTO to its interface model.
BleServiceInfo serviceInfoFromMessage(ServiceMessage message) {
  return BleServiceInfo(
    handle: message.handle,
    uuid: DeepskyUuid.fromString(message.uuid),
    characteristics:
        message.characteristics.map(characteristicInfoFromMessage).toList(),
  );
}

/// Converts a discovered characteristic DTO to its interface model.
BleCharacteristicInfo characteristicInfoFromMessage(CharacteristicMessage m) {
  return BleCharacteristicInfo(
    handle: m.handle,
    serviceHandle: m.serviceHandle,
    uuid: DeepskyUuid.fromString(m.uuid),
    properties: _propertiesFromMessage(m),
    descriptors: m.descriptors.map(descriptorInfoFromMessage).toList(),
  );
}

/// Converts a discovered descriptor DTO to its interface model.
BleDescriptorInfo descriptorInfoFromMessage(DescriptorMessage message) {
  return BleDescriptorInfo(
    handle: message.handle,
    uuid: DeepskyUuid.fromString(message.uuid),
  );
}

BleCharacteristicProperties _propertiesFromMessage(CharacteristicMessage m) {
  return BleCharacteristicProperties(
    values: [
      if (m.canRead) BleCharacteristicProperty.read,
      if (m.canWriteWithResponse) BleCharacteristicProperty.writeWithResponse,
      if (m.canWriteWithoutResponse)
        BleCharacteristicProperty.writeWithoutResponse,
      if (m.canNotify) BleCharacteristicProperty.notify,
      if (m.canIndicate) BleCharacteristicProperty.indicate,
    ],
  );
}

// --- callback event converters (callback args -> interface models) ---

/// Builds a raw connection event from `onConnectionStateChanged` arguments.
///
/// The disconnect reason is preserved only for disconnected states so the
/// model invariant holds; a missing reason on disconnect falls back to
/// [BleDisconnectReason.unknown] rather than throwing.
BlePlatformConnectionEvent connectionEventFromMessage(
  String deviceId,
  int? connectionEpoch,
  ConnectionStateMessage state,
  DisconnectReasonMessage? disconnectReason,
) {
  final mappedState = connectionStateFromMessage(state);
  return BlePlatformConnectionEvent(
    deviceId: DeepskyDeviceId(deviceId),
    connectionEpoch: connectionEpoch,
    state: mappedState,
    reason: mappedState == BleConnectionState.disconnected
        ? disconnectReasonFromMessage(
            disconnectReason ?? DisconnectReasonMessage.unknown,
          )
        : null,
  );
}

/// Builds a notify event from `onCharacteristicValue` arguments.
BleNotifyEvent notifyEventFromMessage(
  String deviceId,
  int connectionEpoch,
  int characteristicHandle,
  Uint8List value,
) {
  return BleNotifyEvent(
    deviceId: DeepskyDeviceId(deviceId),
    connectionEpoch: connectionEpoch,
    characteristicHandle: characteristicHandle,
    value: value,
  );
}

/// Builds an operation timeout event from `onOperationTimeout` arguments.
BleOperationTimeout operationTimeoutFromMessage(
  String deviceId,
  int connectionEpoch,
) {
  return BleOperationTimeout(
    deviceId: DeepskyDeviceId(deviceId),
    connectionEpoch: connectionEpoch,
  );
}

/// Builds a companion event from `onDeviceAppeared` / `onDeviceDisappeared`.
BleCompanionEvent companionEventFromMessage(
  String deviceId, {
  required bool appeared,
}) {
  return BleCompanionEvent(
    deviceId: DeepskyDeviceId(deviceId),
    appeared: appeared,
  );
}

// --- state snapshot / resync converters ---

/// Converts a state snapshot DTO to its interface model.
BleStateSnapshot stateSnapshotFromMessage(StateSnapshotMessage message) {
  final mappedState = connectionStateFromMessage(message.state);
  return BleStateSnapshot(
    deviceId: DeepskyDeviceId(message.deviceId),
    connectionEpoch: message.connectionEpoch,
    state: mappedState,
    disconnectReason: mappedState == BleConnectionState.disconnected
        ? disconnectReasonFromMessage(
            message.disconnectReason ?? DisconnectReasonMessage.unknown,
          )
        : null,
    activeNotifyHandles: List<int>.of(message.activeNotifyHandles),
    services: message.services?.map(serviceInfoFromMessage).toList(),
    restored: message.restored,
  );
}

/// Converts a state resync DTO to its interface model.
BleStateResync stateResyncFromMessage(StateResyncMessage message) {
  return BleStateResync(
    snapshotId: message.snapshotId,
    devices: message.devices.map(stateSnapshotFromMessage).toList(),
  );
}
