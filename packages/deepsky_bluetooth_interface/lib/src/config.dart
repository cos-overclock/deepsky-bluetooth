import 'package:freezed_annotation/freezed_annotation.dart';

part 'config.freezed.dart';

@freezed
sealed class DeepskyBluetoothConfig with _$DeepskyBluetoothConfig {
  const factory DeepskyBluetoothConfig.foreground() = ForegroundConfig;

  const factory DeepskyBluetoothConfig.background({
    IosBackgroundConfig? ios,
    AndroidBackgroundConfig? android,
    int? backgroundCallbackHandle,
  }) = BackgroundConfig;
}

@freezed
abstract class IosBackgroundConfig with _$IosBackgroundConfig {
  const factory IosBackgroundConfig({required String restoreIdentifier}) =
      _IosBackgroundConfig;
}

@freezed
sealed class AndroidBackgroundConfig with _$AndroidBackgroundConfig {
  const factory AndroidBackgroundConfig.foregroundService({
    required AndroidNotificationConfig notification,
  }) = AndroidForegroundServiceConfig;

  const factory AndroidBackgroundConfig.companionDevice() =
      AndroidCompanionDeviceConfig;
}

@freezed
abstract class AndroidNotificationConfig with _$AndroidNotificationConfig {
  const factory AndroidNotificationConfig({
    required String channelId,
    required String channelName,
    required String title,
    required String text,
  }) = _AndroidNotificationConfig;
}
