sealed class DeepskyBluetoothConfig {
  const DeepskyBluetoothConfig();

  const factory DeepskyBluetoothConfig.foreground() = ForegroundConfig;

  const factory DeepskyBluetoothConfig.background({
    IosBackgroundConfig? ios,
    AndroidBackgroundConfig? android,
    int? backgroundCallbackHandle,
  }) = BackgroundConfig;
}

final class ForegroundConfig extends DeepskyBluetoothConfig {
  const ForegroundConfig();

  @override
  bool operator ==(Object other) => other is ForegroundConfig;

  @override
  int get hashCode => 0x0f09e601;
}

final class BackgroundConfig extends DeepskyBluetoothConfig {
  const BackgroundConfig({
    this.ios,
    this.android,
    this.backgroundCallbackHandle,
  });

  final IosBackgroundConfig? ios;
  final AndroidBackgroundConfig? android;
  final int? backgroundCallbackHandle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackgroundConfig &&
          ios == other.ios &&
          android == other.android &&
          backgroundCallbackHandle == other.backgroundCallbackHandle;

  @override
  int get hashCode => Object.hash(ios, android, backgroundCallbackHandle);
}

class IosBackgroundConfig {
  const IosBackgroundConfig({required this.restoreIdentifier});

  final String restoreIdentifier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IosBackgroundConfig &&
          restoreIdentifier == other.restoreIdentifier;

  @override
  int get hashCode => restoreIdentifier.hashCode;
}

sealed class AndroidBackgroundConfig {
  const AndroidBackgroundConfig();
}

final class AndroidForegroundServiceConfig extends AndroidBackgroundConfig {
  const AndroidForegroundServiceConfig({required this.notification});

  final AndroidNotificationConfig notification;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AndroidForegroundServiceConfig &&
          notification == other.notification;

  @override
  int get hashCode => notification.hashCode;
}

final class AndroidCompanionDeviceConfig extends AndroidBackgroundConfig {
  const AndroidCompanionDeviceConfig();

  @override
  bool operator ==(Object other) => other is AndroidCompanionDeviceConfig;

  @override
  int get hashCode => 0x0acd0c01;
}

class AndroidNotificationConfig {
  const AndroidNotificationConfig({
    required this.channelId,
    required this.channelName,
    required this.title,
    required this.text,
  });

  final String channelId;
  final String channelName;
  final String title;
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AndroidNotificationConfig &&
          channelId == other.channelId &&
          channelName == other.channelName &&
          title == other.title &&
          text == other.text;

  @override
  int get hashCode => Object.hash(channelId, channelName, title, text);
}
