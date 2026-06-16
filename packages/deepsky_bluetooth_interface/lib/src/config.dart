import 'package:freezed_annotation/freezed_annotation.dart';

part 'config.freezed.dart';

@Freezed(copyWith: false)
sealed class DeepskyBluetoothConfig with _$DeepskyBluetoothConfig {
  const factory DeepskyBluetoothConfig.foreground() = ForegroundConfig;

  const factory DeepskyBluetoothConfig.background({
    IosBackgroundConfig? ios,
    AndroidBackgroundConfig? android,
    int? backgroundCallbackHandle,
  }) = BackgroundConfig;
}

@Freezed(copyWith: false)
abstract class IosBackgroundConfig with _$IosBackgroundConfig {
  const factory IosBackgroundConfig({required String restoreIdentifier}) =
      _IosBackgroundConfig;
}

@Freezed(copyWith: false)
sealed class AndroidBackgroundConfig with _$AndroidBackgroundConfig {
  const factory AndroidBackgroundConfig.foregroundService({
    required AndroidNotificationConfig notification,
  }) = AndroidForegroundServiceConfig;

  const factory AndroidBackgroundConfig.companionDevice() =
      AndroidCompanionDeviceConfig;
}

@Freezed(copyWith: false)
abstract class AndroidNotificationConfig with _$AndroidNotificationConfig {
  const factory AndroidNotificationConfig({
    required String channelId,
    required String channelName,
    required String title,
    required String text,
  }) = _AndroidNotificationConfig;
}
