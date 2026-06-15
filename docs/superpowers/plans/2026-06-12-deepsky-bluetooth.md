# deepsky_bluetooth 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Foreground/Backgroundを明示的に分けたBLE Centralライブラリ(Android/iOS/macOS対応、Pigeon + steady Result型 + sealedエラー + Observer)を構築する。

**Architecture:** federatedプラグイン風の構成。最下層の `packages/deepsky_bluetooth_util`(純Dart・依存なし)がsealedエラー型・エラーコード定数・UUIDユーティリティを提供する。`packages/deepsky_bluetooth_interface` が抽象(モデル・Observer・Platform抽象クラス。エラー型はutilを再export)を定義し、`plugins/deepsky_bluetooth_{android,ios,macos}` がPigeon定義+ネイティブ実装(Kotlin/Swift)を持ち、`packages/deepsky_bluetooth_*_bridge` がPigeon生成型をinterface型へ変換しPlatformExceptionをsealedエラーへマップする。ルートの `deepsky_bluetooth` が公開APIで、`Platform` 判定でbridgeを選択する。pluginsはutil/interfaceのどちらにも依存しない(Pigeon生成物のみ)。

**Tech Stack:** Flutter (pub workspace), Pigeon, steady 1.2.0 (Result型), Kotlin (BluetoothGatt / ForegroundService / CompanionDeviceManager+Service), Swift (CoreBluetooth + State Restoration)。

---

## 確定済みの設計判断(ユーザー回答)

| 項目 | 決定 |
| --- | --- |
| BLE機能範囲 | スキャン+接続管理、GATT基本操作(探索/Read/Write/Notify/Indicate)、拡張操作(MTU/RSSI/ディスクリプタ)。ボンディングは対象外 |
| CompanionDevice | `associate()`(デバイス選択ダイアログ)もライブラリAPIとして提供 |
| Android minSdk | **31**(両バックグラウンド方式が常に利用可能) |
| CDSプロセス復活 | ヘッドレスFlutterEngineでアプリの `main()` を実行(iOS State Restorationと対称) |
| テスト範囲 | Dart側のみ(Pigeon APIはモック)。ネイティブはexampleアプリで実機確認 |

## 設計ルール

- **インスタンス化API:** 利用者は `DeepskyBluetooth.foreground({observer})` / `DeepskyBluetooth.background({ios, android, observer})` で生成する(モードはメソッド名で明示)。`DeepskyBluetoothConfig` は本体→bridge→ネイティブ間の内部転送型であり、利用者が直接組み立てるのは `IosBackgroundConfig` / `AndroidBackgroundConfig`(FGS/CompanionDeviceのsealed)のみ。
- **ライフサイクル(1エンジン1インスタンス):** 同時に生成できるインスタンスは1つ。2つ目の生成はネイティブの `initialized` フラグにより `AlreadyInitialized` を返す。`background` インスタンスはフォアグラウンドでも全API(接続・GATT・OTAのような大量Write)をそのまま使えるため、FG+BGの同時保持は不要(「普段はBG監視、随時フォアグラウンドでOTA」は単一のbackgroundインスタンスで賄う)。`dispose()` はネイティブの `initialized` をリセットしDart側のチャネル登録も解除するため、dispose後はモード変更を含め再生成できる。**コールバックチャネル登録(`BleCallbacksApi.setUp`)はinitialize成功後に行う**(失敗した生成試行が稼働中インスタンスのチャネルを奪わないため)。
- **Result型:** 全公開メソッドは `Future<Result<T, XxxError>>` を返す。`try-catch` はPigeon境界(PlatformException→Result変換ヘルパー)のみ許可。Kotlin側は `kotlin.Result`、Swift側は `Swift.Result`(いずれもPigeonの@asyncコールバック形式)で統一。
- **sealedエラー:** メソッドごとにsealedクラス(`ScanError`, `ConnectError`, ...)を **`deepsky_bluetooth_util`** に定義し、バリアントをswitchで網羅列挙できる。全エラーは `Exception` を実装(steadyの `E extends Exception` 制約)。interfaceはutilを再exportするため、利用側はinterfaceのimportだけでエラー型に届く。
- **エラーコードプロトコル:** ネイティブは `FlutterError(code, message, null)` を投げ、bridgeが下表のcodeをsealedバリアントへマップする。Dart側のcode文字列定数は util の `BleErrorCode` に定義し、bridgeのエラーマッパーはリテラルではなく定数を参照する。

| code | 意味 |
| --- | --- |
| `permissionDenied` | 権限なし |
| `bluetoothOff` | アダプタ/電源オフ |
| `alreadyScanning` | スキャン重複 |
| `notFound` | デバイス/キャラクタリスティック等が見つからない |
| `notConnected` | 未接続 |
| `notSupported` | 操作非対応 |
| `timeout` | タイムアウト |
| `rejected` | ユーザーによる拒否(associate) |
| `alreadyInitialized` | 二重初期化 |
| `backgroundNotSupported` | バックグラウンド非対応(macOS) |
| `backgroundConfigMissing` | バックグラウンド設定不足 |
| `notAssociated` | CDM未関連付け |
| `failed` | その他(messageに詳細) |

- **UUID表記:** Dart境界では128bit完全形式・小文字の文字列に統一。正規化ロジックは util の `BleUuid.normalize`(16/32bit短縮形の展開+小文字化)に置き、bridgeのconvertersがネイティブへ渡す前に適用する。CCCD等の既知UUID定数も `BleUuid` に置く。Kotlinは `UUID.toString()` がそのまま準拠。SwiftはCBUUIDの短縮形を128bitへ展開するヘルパーを通す。
- **Observer:** interfaceパッケージにDartの `DeepskyBluetoothObserver`(onMethodStart/onMethodEnd/onCallback)を定義。bridgeと本体パッケージはそれを受け取りフックを呼ぶ。各プラグインはネイティブObserver(Kotlin interface / Swiftプロトコル、デフォルトはLogcat/os_log実装、静的レジストリで差し替え可能)を定義する。
- **スキャンフィルタ/オプション:** フィルタは `DeepskyScanFilter`(address / name / manufactureData / serviceData / serviceUuid×2形式の各リスト)。**各エントリはOR条件**(いずれか1つにマッチで通過、全リスト空ならフィルタなし)で、AndroidのScanFilterリスト(1エントリ=1 ScanFilter)に1:1対応する。Androidは全カテゴリをネイティブフィルタで実施。iOS/macOSはserviceUuidのみネイティブ対応(かつserviceUuid単独指定時のみ適用)で、**非対応カテゴリはネイティブ側didDiscover内のソフトウェアフィルタ**で判定する。manufactureData/serviceDataのdata照合は前方一致(Androidのmask省略時挙動に合わせる)。スキャン設定は `DeepskyScanOptions`(`android`: ScanSettings相当 / `darwin`: allowDuplicates・solicitedServiceUuids)として `startScan` に渡す。`DeepskyAndroidScanType`(active/passive)はAndroidの公開APIに存在しない(hidden API)ため対象外。
- **権限要求はアプリ責務:** ライブラリは権限チェックのみ行い `permissionDenied` を返す。要求UIは出さない。
- **コールバック→Dart:** Pigeon `@FlutterApi` でネイティブ→Dartへpush。bridgeが `Stream` として公開。ネイティブはDartの準備完了(`notifyDartReady`)までイベントをバッファする(iOS復元イベント、Android CDSイベント)。
- **Isolate/エンジン方針:** 専用バックグラウンドIsolateは設けず、イベントは常に「その時点で生きているFlutterEngineのルートIsolate」へ配信する。Androidのエンジンライフサイクルは次の3規則で一本化する: (1) **CDSイベント時またはFGS稼働中のエンジン消失時**(タスクスワイプ除去等)にヘッドレスエンジンで `main()` を再実行して復活させる。(2) **UIエンジンがActivityにattachしたらヘッドレスエンジンは破棄**し、常に1エンジンに収束させる(接続は引き継がず、アプリの `main()`/初期化ロジックが再接続する)。(3) エンジン破棄時はそのエンジンのGATT接続をcloseしsinkを解除するが、**FGSは止めない**(明示的な `dispose()` のみがFGSを停止する)。

## 検証環境の制約(重要)

開発機はWindows。**Androidはビルド検証可、iOS/macOSはビルド不可**。iOS/macOSタスクの検証は「Pigeon生成成功 + `flutter analyze`(Dart側のみ)」までをWindowsで行い、SwiftのコンパイルはmacOSホストでのチェックポイント(タスク内に明記)とする。Swiftコードはコンパイル確認なしで書くため、macOS検証時に微修正が発生し得る。

## パッケージ依存グラフ

```tree
deepsky_bluetooth (ルート / 公開API)
 ├─ deepsky_bluetooth_interface (モデル・Observer・Platform抽象。utilを再export)
 │    └─ deepsky_bluetooth_util (純Dart・依存なし: sealedエラー・BleErrorCode・BleUuid)
 ├─ deepsky_bluetooth_android_bridge ─→ deepsky_bluetooth_android (Pigeon+Kotlin)
 ├─ deepsky_bluetooth_ios_bridge     ─→ deepsky_bluetooth_ios     (Pigeon+Swift)
 └─ deepsky_bluetooth_macos_bridge   ─→ deepsky_bluetooth_macos   (Pigeon+Swift)
      (各bridgeは interface と util にも依存。plugins はどのpackageにも依存しない)
```

## ファイル構成(作成・変更対象の全体マップ)

```tree
packages/deepsky_bluetooth_util/lib/
  deepsky_bluetooth_util.dart             # exportのみ
  src/errors.dart  src/error_codes.dart  src/uuid.dart
packages/deepsky_bluetooth_interface/lib/
  deepsky_bluetooth_interface.dart        # exportのみ(utilを再export)
  src/models.dart  src/config.dart  src/observer.dart  src/platform.dart
plugins/deepsky_bluetooth_android/
  pigeons/messages.dart                   # Pigeon定義
  lib/deepsky_bluetooth_android.dart      # export 'src/messages.g.dart'
  lib/src/messages.g.dart                 # 生成物
  android/src/main/kotlin/com/example/deepsky_bluetooth_android/
    Messages.g.kt(生成物) DeepskyBluetoothAndroidPlugin.kt BleCentralManager.kt
    GattConnection.kt BleErrorCodes.kt DeepskyBluetoothAndroidObserver.kt
    ObservingBleHostApi.kt DeepskyForegroundService.kt DeepskyCompanionDeviceService.kt
    HeadlessEngineLauncher.kt PendingCompanionEvents.kt
  android/src/main/AndroidManifest.xml    # 権限+Service宣言
plugins/deepsky_bluetooth_ios/
  pigeons/messages.dart  lib/deepsky_bluetooth_ios.dart  lib/src/messages.g.dart
  ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/
    Messages.g.swift(生成物) DeepskyBluetoothIosPlugin.swift BleCentralController.swift
    DeepskyBluetoothIosObserver.swift
plugins/deepsky_bluetooth_macos/ (iOSと同構成、State Restorationなし)
packages/deepsky_bluetooth_android_bridge/lib/
  deepsky_bluetooth_android_bridge.dart  src/bridge.dart  src/converters.dart  src/error_mapper.dart
packages/deepsky_bluetooth_ios_bridge/ (同構成)
packages/deepsky_bluetooth_macos_bridge/ (同構成)
lib/deepsky_bluetooth.dart  lib/src/deepsky_bluetooth.dart  lib/src/platform_resolver.dart
example/ (新規 flutter create)
```

---

### Task 1: Git初期化・utilパッケージ作成・依存関係の配線

**Files:**

- Modify: `pubspec.yaml`(ルート)
- Create: `packages/deepsky_bluetooth_util/pubspec.yaml`
- Create: `packages/deepsky_bluetooth_util/analysis_options.yaml`
- Modify: `packages/deepsky_bluetooth_interface/pubspec.yaml`
- Modify: `packages/deepsky_bluetooth_android_bridge/pubspec.yaml`(ios/macos bridgeも同様)
- Modify: `plugins/deepsky_bluetooth_android/pubspec.yaml`(ios/macosも同様)

- [ ] **Step 1: git初期化と初回コミット**

```powershell
git init && git add -A && git commit -m "chore: initial workspace scaffold"
```

- [ ] **Step 2: utilパッケージ(純Dart・依存なし)を作成**

`packages/deepsky_bluetooth_util/pubspec.yaml` 全文(Flutter非依存の最下層パッケージ。interfaceがプラグイン関連へ依存しないための分離先):

```yaml
name: deepsky_bluetooth_util
description: "Shared sealed error types, error codes and UUID utilities for deepsky_bluetooth."
version: 0.0.1
publish_to: 'none'
resolution: workspace

environment:
  sdk: ^3.12.2

dev_dependencies:
  lints: ^6.0.0
  test: ^1.26.0
```

`packages/deepsky_bluetooth_util/analysis_options.yaml` 全文:

```yaml
include: package:lints/recommended.yaml
```

ルート `pubspec.yaml` の `workspace:` リストの先頭に追記:

```yaml
  - packages/deepsky_bluetooth_util
```

- [ ] **Step 3: interfaceパッケージにsteadyとutilを追加**

`packages/deepsky_bluetooth_interface/pubspec.yaml` の `dependencies:` を以下にする:

```yaml
dependencies:
  flutter:
    sdk: flutter
  steady: ^1.2.0
  deepsky_bluetooth_util:
    path: ../deepsky_bluetooth_util
```

- [ ] **Step 4: 3つのbridgeパッケージに依存を追加**

`packages/deepsky_bluetooth_android_bridge/pubspec.yaml` の `dependencies:` を以下にする(ios/macosは `deepsky_bluetooth_android` の部分をそれぞれ `deepsky_bluetooth_ios` / `deepsky_bluetooth_macos` に読み替えて同様に編集):

```yaml
dependencies:
  flutter:
    sdk: flutter
  steady: ^1.2.0
  deepsky_bluetooth_util:
    path: ../deepsky_bluetooth_util
  deepsky_bluetooth_interface:
    path: ../deepsky_bluetooth_interface
  deepsky_bluetooth_android:
    path: ../../plugins/deepsky_bluetooth_android
```

- [ ] **Step 5: 3つのプラグインにpigeonをdev依存として追加**

```powershell
cd plugins/deepsky_bluetooth_android && flutter pub add --dev pigeon
cd ../deepsky_bluetooth_ios && flutter pub add --dev pigeon
cd ../deepsky_bluetooth_macos && flutter pub add --dev pigeon
```

- [ ] **Step 6: ルートパッケージに依存を追加**

ルート `pubspec.yaml` の `dependencies:` に追記:

```yaml
  deepsky_bluetooth_interface:
    path: packages/deepsky_bluetooth_interface
  deepsky_bluetooth_android_bridge:
    path: packages/deepsky_bluetooth_android_bridge
  deepsky_bluetooth_ios_bridge:
    path: packages/deepsky_bluetooth_ios_bridge
  deepsky_bluetooth_macos_bridge:
    path: packages/deepsky_bluetooth_macos_bridge
```

- [ ] **Step 7: 解決確認**

Run: ルートで `flutter pub get`
Expected: `Got dependencies!`(workspace一括解決が成功)

- [ ] **Step 8: コミット**

```powershell
git add pubspec.yaml packages plugins && git commit -m "chore: add util package and wire workspace dependencies"
```

---

### Task 2: util — sealedエラー型・エラーコード定数・UUIDユーティリティ

**Files:**

- Create: `packages/deepsky_bluetooth_util/lib/src/errors.dart`
- Create: `packages/deepsky_bluetooth_util/lib/src/error_codes.dart`
- Create: `packages/deepsky_bluetooth_util/lib/src/uuid.dart`
- Create: `packages/deepsky_bluetooth_util/lib/deepsky_bluetooth_util.dart`
- Create: `packages/deepsky_bluetooth_util/test/errors_test.dart`
- Create: `packages/deepsky_bluetooth_util/test/uuid_test.dart`

- [ ] **Step 1: 失敗するテストを書く**

`test/errors_test.dart`:

```dart
import 'package:deepsky_bluetooth_util/deepsky_bluetooth_util.dart';
import 'package:test/test.dart';

void main() {
  test('ScanError variants are exhaustively switchable', () {
    String describe(ScanError e) => switch (e) {
          ScanPermissionDenied() => 'permission',
          ScanBluetoothOff() => 'off',
          ScanAlreadyScanning() => 'already',
          ScanFailed() => 'failed',
        };
    expect(describe(const ScanPermissionDenied()), 'permission');
    expect(describe(const ScanFailed('x')), 'failed');
  });

  test('ConnectError variants are exhaustively switchable', () {
    String describe(ConnectError e) => switch (e) {
          ConnectPermissionDenied() => 'permission',
          ConnectBluetoothOff() => 'off',
          ConnectDeviceNotFound() => 'notFound',
          ConnectTimeout() => 'timeout',
          ConnectFailed() => 'failed',
        };
    expect(describe(const ConnectTimeout()), 'timeout');
  });

  test('errors implement Exception and carry a message', () {
    const Exception e = BackgroundNotSupported();
    expect(e, isA<Exception>());
    expect(const ScanFailed('boom').message, 'boom');
    expect(const ScanFailed('boom').toString(), contains('boom'));
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `packages/deepsky_bluetooth_util` で `dart test test/errors_test.dart`
Expected: コンパイルエラー(`ScanError` 未定義)で FAIL

- [ ] **Step 3: errors.dart を実装**

`lib/src/errors.dart`(全文。命名規則: 各メソッドのsealed基底 + `final class` バリアント。可変メッセージを持つのは `*Failed` のみ):

```dart
/// 全エラーの基底。steadyの `Result<T, E extends Exception>` 制約のため
/// [Exception] を実装する。
sealed class DeepskyBluetoothError implements Exception {
  const DeepskyBluetoothError();
  String get message;
  @override
  String toString() => '$runtimeType: $message';
}

// --- initialize ---
sealed class InitializeError extends DeepskyBluetoothError {
  const InitializeError();
}

final class BackgroundNotSupported extends InitializeError {
  const BackgroundNotSupported();
  @override
  String get message => 'Background mode is not supported on this platform.';
}

final class BackgroundConfigMissing extends InitializeError {
  const BackgroundConfigMissing();
  @override
  String get message =>
      'Background mode requires a platform-specific background config.';
}

final class AlreadyInitialized extends InitializeError {
  const AlreadyInitialized();
  @override
  String get message => 'This instance is already initialized.';
}

final class UnsupportedPlatform extends InitializeError {
  const UnsupportedPlatform();
  @override
  String get message => 'This platform is not supported.';
}

final class InitializeFailed extends InitializeError {
  const InitializeFailed(this.message);
  @override
  final String message;
}

// --- startScan / stopScan ---
sealed class ScanError extends DeepskyBluetoothError {
  const ScanError();
}

final class ScanPermissionDenied extends ScanError {
  const ScanPermissionDenied();
  @override
  String get message => 'Bluetooth scan permission is denied.';
}

final class ScanBluetoothOff extends ScanError {
  const ScanBluetoothOff();
  @override
  String get message => 'Bluetooth is powered off.';
}

final class ScanAlreadyScanning extends ScanError {
  const ScanAlreadyScanning();
  @override
  String get message => 'A scan is already in progress.';
}

final class ScanFailed extends ScanError {
  const ScanFailed(this.message);
  @override
  final String message;
}

// --- connect ---
sealed class ConnectError extends DeepskyBluetoothError {
  const ConnectError();
}

final class ConnectPermissionDenied extends ConnectError {
  const ConnectPermissionDenied();
  @override
  String get message => 'Bluetooth connect permission is denied.';
}

final class ConnectBluetoothOff extends ConnectError {
  const ConnectBluetoothOff();
  @override
  String get message => 'Bluetooth is powered off.';
}

final class ConnectDeviceNotFound extends ConnectError {
  const ConnectDeviceNotFound();
  @override
  String get message => 'Device not found.';
}

final class ConnectTimeout extends ConnectError {
  const ConnectTimeout();
  @override
  String get message => 'Connection attempt timed out.';
}

final class ConnectFailed extends ConnectError {
  const ConnectFailed(this.message);
  @override
  final String message;
}

// --- disconnect ---
sealed class DisconnectError extends DeepskyBluetoothError {
  const DisconnectError();
}

final class DisconnectNotConnected extends DisconnectError {
  const DisconnectNotConnected();
  @override
  String get message => 'Device is not connected.';
}

final class DisconnectFailed extends DisconnectError {
  const DisconnectFailed(this.message);
  @override
  final String message;
}

// --- discoverServices ---
sealed class DiscoverServicesError extends DeepskyBluetoothError {
  const DiscoverServicesError();
}

final class DiscoverServicesNotConnected extends DiscoverServicesError {
  const DiscoverServicesNotConnected();
  @override
  String get message => 'Device is not connected.';
}

final class DiscoverServicesFailed extends DiscoverServicesError {
  const DiscoverServicesFailed(this.message);
  @override
  final String message;
}

// --- readCharacteristic ---
sealed class CharacteristicReadError extends DeepskyBluetoothError {
  const CharacteristicReadError();
}

final class CharacteristicReadNotConnected extends CharacteristicReadError {
  const CharacteristicReadNotConnected();
  @override
  String get message => 'Device is not connected.';
}

final class CharacteristicReadNotFound extends CharacteristicReadError {
  const CharacteristicReadNotFound();
  @override
  String get message => 'Characteristic not found.';
}

final class CharacteristicReadNotSupported extends CharacteristicReadError {
  const CharacteristicReadNotSupported();
  @override
  String get message => 'This characteristic does not support read.';
}

final class CharacteristicReadFailed extends CharacteristicReadError {
  const CharacteristicReadFailed(this.message);
  @override
  final String message;
}

// --- writeCharacteristic ---
sealed class CharacteristicWriteError extends DeepskyBluetoothError {
  const CharacteristicWriteError();
}

final class CharacteristicWriteNotConnected extends CharacteristicWriteError {
  const CharacteristicWriteNotConnected();
  @override
  String get message => 'Device is not connected.';
}

final class CharacteristicWriteNotFound extends CharacteristicWriteError {
  const CharacteristicWriteNotFound();
  @override
  String get message => 'Characteristic not found.';
}

final class CharacteristicWriteNotSupported extends CharacteristicWriteError {
  const CharacteristicWriteNotSupported();
  @override
  String get message => 'This characteristic does not support write.';
}

final class CharacteristicWriteFailed extends CharacteristicWriteError {
  const CharacteristicWriteFailed(this.message);
  @override
  final String message;
}

// --- setNotify ---
sealed class NotifyError extends DeepskyBluetoothError {
  const NotifyError();
}

final class NotifyNotConnected extends NotifyError {
  const NotifyNotConnected();
  @override
  String get message => 'Device is not connected.';
}

final class NotifyNotFound extends NotifyError {
  const NotifyNotFound();
  @override
  String get message => 'Characteristic not found.';
}

final class NotifyNotSupported extends NotifyError {
  const NotifyNotSupported();
  @override
  String get message => 'This characteristic does not support notify/indicate.';
}

final class NotifyFailed extends NotifyError {
  const NotifyFailed(this.message);
  @override
  final String message;
}

// --- readDescriptor ---
sealed class DescriptorReadError extends DeepskyBluetoothError {
  const DescriptorReadError();
}

final class DescriptorReadNotConnected extends DescriptorReadError {
  const DescriptorReadNotConnected();
  @override
  String get message => 'Device is not connected.';
}

final class DescriptorReadNotFound extends DescriptorReadError {
  const DescriptorReadNotFound();
  @override
  String get message => 'Descriptor not found.';
}

final class DescriptorReadFailed extends DescriptorReadError {
  const DescriptorReadFailed(this.message);
  @override
  final String message;
}

// --- writeDescriptor ---
sealed class DescriptorWriteError extends DeepskyBluetoothError {
  const DescriptorWriteError();
}

final class DescriptorWriteNotConnected extends DescriptorWriteError {
  const DescriptorWriteNotConnected();
  @override
  String get message => 'Device is not connected.';
}

final class DescriptorWriteNotFound extends DescriptorWriteError {
  const DescriptorWriteNotFound();
  @override
  String get message => 'Descriptor not found.';
}

final class DescriptorWriteFailed extends DescriptorWriteError {
  const DescriptorWriteFailed(this.message);
  @override
  final String message;
}

// --- requestMtu ---
sealed class MtuError extends DeepskyBluetoothError {
  const MtuError();
}

final class MtuNotConnected extends MtuError {
  const MtuNotConnected();
  @override
  String get message => 'Device is not connected.';
}

final class MtuFailed extends MtuError {
  const MtuFailed(this.message);
  @override
  final String message;
}

// --- readRssi ---
sealed class RssiError extends DeepskyBluetoothError {
  const RssiError();
}

final class RssiNotConnected extends RssiError {
  const RssiNotConnected();
  @override
  String get message => 'Device is not connected.';
}

final class RssiFailed extends RssiError {
  const RssiFailed(this.message);
  @override
  final String message;
}

// --- associate (Android CompanionDeviceのみ) ---
sealed class AssociateError extends DeepskyBluetoothError {
  const AssociateError();
}

final class AssociateNotSupported extends AssociateError {
  const AssociateNotSupported();
  @override
  String get message => 'Companion device association is Android-only.';
}

final class AssociateRejected extends AssociateError {
  const AssociateRejected();
  @override
  String get message => 'Association was rejected or cancelled by the user.';
}

final class AssociateFailed extends AssociateError {
  const AssociateFailed(this.message);
  @override
  final String message;
}

// --- setDevicePresenceObservation (Android CompanionDeviceのみ) ---
sealed class PresenceError extends DeepskyBluetoothError {
  const PresenceError();
}

final class PresenceNotSupported extends PresenceError {
  const PresenceNotSupported();
  @override
  String get message => 'Device presence observation is Android-only.';
}

final class PresenceNotAssociated extends PresenceError {
  const PresenceNotAssociated();
  @override
  String get message => 'Device is not associated via CompanionDeviceManager.';
}

final class PresenceFailed extends PresenceError {
  const PresenceFailed(this.message);
  @override
  final String message;
}

// --- dispose ---
sealed class DisposeError extends DeepskyBluetoothError {
  const DisposeError();
}

final class DisposeFailed extends DisposeError {
  const DisposeFailed(this.message);
  @override
  final String message;
}
```

- [ ] **Step 4: UUIDユーティリティの失敗するテストを書く**

`test/uuid_test.dart`:

```dart
import 'dart:typed_data';

import 'package:deepsky_bluetooth_util/deepsky_bluetooth_util.dart';
import 'package:test/test.dart';

void main() {
  test('normalize expands 16-bit short form', () {
    expect(BleUuid.normalize('180F'), '0000180f-0000-1000-8000-00805f9b34fb');
  });

  test('DeepskyUuid normalizes from string and byte array equally', () {
    expect(DeepskyUuid.fromString('180F').value,
        '0000180f-0000-1000-8000-00805f9b34fb');
    expect(DeepskyUuid.fromByteArray(Uint8List.fromList([0x18, 0x0f])),
        DeepskyUuid.fromString('180f'));
    expect(() => DeepskyUuid.fromByteArray(Uint8List.fromList([1, 2, 3])),
        throwsArgumentError);
  });

  test('normalize expands 32-bit short form', () {
    expect(BleUuid.normalize('0000180F'),
        '0000180f-0000-1000-8000-00805f9b34fb');
  });

  test('normalize lowercases full 128-bit uuid', () {
    expect(BleUuid.normalize('0000180F-0000-1000-8000-00805F9B34FB'),
        '0000180f-0000-1000-8000-00805f9b34fb');
  });

  test('cccd constant is the normalized CCCD uuid', () {
    expect(BleUuid.cccd, '00002902-0000-1000-8000-00805f9b34fb');
  });

  test('error codes are stable strings', () {
    expect(BleErrorCode.permissionDenied, 'permissionDenied');
    expect(BleErrorCode.failed, 'failed');
  });
}
```

Run: `dart test test/uuid_test.dart` → コンパイルエラーで FAIL

- [ ] **Step 5: uuid.dart と error_codes.dart を実装**

`lib/src/uuid.dart` 全文:

```dart
import 'dart:typed_data';

/// BLE UUIDユーティリティ。Dart境界では128bit完全形式・小文字に統一する。
abstract final class BleUuid {
  static const String base = '-0000-1000-8000-00805f9b34fb';

  /// Client Characteristic Configuration Descriptor。
  static const String cccd = '00002902-0000-1000-8000-00805f9b34fb';

  /// 16bit/32bit短縮形・大文字混在を128bit完全形式(小文字)へ正規化する。
  static String normalize(String uuid) {
    final s = uuid.toLowerCase();
    return switch (s.length) {
      4 => '0000$s$base',
      8 => '$s$base',
      _ => s,
    };
  }
}

/// 値としてのBLE UUID。生成時に128bit完全形式(小文字)へ正規化される。
final class DeepskyUuid {
  DeepskyUuid.fromString(String uuid) : value = BleUuid.normalize(uuid);

  /// ビッグエンディアンのバイト配列から生成する。
  /// 長さは 2(16bit) / 4(32bit) / 16(128bit) のいずれか。
  /// それ以外は [ArgumentError](プログラミングエラーのためResultにしない)。
  DeepskyUuid.fromByteArray(Uint8List bytes) : value = _fromBytes(bytes);

  /// 128bit完全形式・小文字の文字列表現。
  final String value;

  static String _fromBytes(Uint8List bytes) {
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return switch (bytes.length) {
      2 || 4 => BleUuid.normalize(hex),
      16 => '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
          '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
          '${hex.substring(20)}',
      _ => throw ArgumentError.value(
          bytes, 'bytes', 'UUID byte length must be 2, 4, or 16'),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is DeepskyUuid && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
```

`lib/src/error_codes.dart` 全文(ネイティブの `FlutterError.code` と対になるDart側定数):

```dart
/// ネイティブが投げる FlutterError / PlatformException の code 文字列。
/// 各プラグインのネイティブ定数(Kotlin/SwiftのBleErrorCode)と一致させること。
abstract final class BleErrorCode {
  static const String permissionDenied = 'permissionDenied';
  static const String bluetoothOff = 'bluetoothOff';
  static const String alreadyScanning = 'alreadyScanning';
  static const String notFound = 'notFound';
  static const String notConnected = 'notConnected';
  static const String notSupported = 'notSupported';
  static const String timeout = 'timeout';
  static const String rejected = 'rejected';
  static const String alreadyInitialized = 'alreadyInitialized';
  static const String backgroundNotSupported = 'backgroundNotSupported';
  static const String backgroundConfigMissing = 'backgroundConfigMissing';
  static const String notAssociated = 'notAssociated';
  static const String failed = 'failed';
}
```

- [ ] **Step 6: exportファイルを作成**

`lib/deepsky_bluetooth_util.dart` 全文:

```dart
library;

export 'src/error_codes.dart';
export 'src/errors.dart';
export 'src/uuid.dart';
```

- [ ] **Step 7: テストが通ることを確認**

Run: `packages/deepsky_bluetooth_util` で `dart test`
Expected: All tests passed

- [ ] **Step 8: コミット**

```powershell
git add packages/deepsky_bluetooth_util pubspec.yaml && git commit -m "feat(util): sealed error types, error codes and uuid utilities"
```

---

### Task 3: interface — モデル

**Files:**

- Create: `packages/deepsky_bluetooth_interface/lib/src/models.dart`
- Modify: `packages/deepsky_bluetooth_interface/lib/deepsky_bluetooth_interface.dart`(テンプレート全置換)
- Create: `packages/deepsky_bluetooth_interface/test/models_test.dart`
- Delete: `packages/deepsky_bluetooth_interface/test/deepsky_bluetooth_interface_test.dart`(テンプレート)

- [ ] **Step 1: 失敗するテストを書く**

`test/models_test.dart`:

```dart
import 'dart:typed_data';

import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BleScanResult holds advertisement data', () {
    final r = BleScanResult(
      deviceId: 'AA:BB:CC:DD:EE:FF',
      name: 'Thermo',
      rssi: -50,
      serviceUuids: const ['0000180f-0000-1000-8000-00805f9b34fb'],
      manufacturerData: Uint8List.fromList([1, 2]),
      raw: Uint8List.fromList([2, 1, 6]),
    );
    expect(r.name, 'Thermo');
    expect(r.rssi, -50);
    expect(r.raw, isNotNull);
  });

  test('DeepskyScanFilter defaults to no criteria', () {
    const f = DeepskyScanFilter();
    expect(f.address, isEmpty);
    expect(f.name, isEmpty);
    expect(f.manufactureData, isEmpty);
    expect(f.serviceData, isEmpty);
    expect(f.serviceUuidFromByteArray, isEmpty);
    expect(f.serviceUuidFromString, isEmpty);
  });

  test('DeepskyScanOptions has platform defaults', () {
    const o = DeepskyScanOptions();
    expect(o.android.mode, DeepskyAndroidScanMode.scanModeLowLatency);
    expect(o.android.onlyLegacy, isTrue);
    expect(o.darwin.allowDuplicates, isFalse);
  });

  test('BleConnectionState covers BLE lifecycle', () {
    expect(BleConnectionState.values, [
      BleConnectionState.connecting,
      BleConnectionState.connected,
      BleConnectionState.disconnecting,
      BleConnectionState.disconnected,
    ]);
  });

  test('BleCharacteristicTarget keeps the full path to a characteristic', () {
    const t = BleCharacteristicTarget(
      deviceId: 'id',
      serviceUuid: 's',
      characteristicUuid: 'c',
    );
    expect(t.serviceUuid, 's');
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/models_test.dart`
Expected: コンパイルエラーで FAIL

- [ ] **Step 3: models.dart を実装**

`lib/src/models.dart` 全文:

```dart
import 'dart:typed_data';

import 'package:deepsky_bluetooth_util/deepsky_bluetooth_util.dart';

enum BleConnectionState { connecting, connected, disconnecting, disconnected }

// --- スキャンフィルタ ---
// 各エントリはOR条件(いずれか1つにマッチで通過)。全リスト空ならフィルタなし。
// Androidは全カテゴリネイティブ、iOS/macOSはserviceUuid以外ソフトウェアフィルタ。

class DeepskyScanFilterManufactureData {
  const DeepskyScanFilterManufactureData({
    required this.manufacturerId,
    required this.data,
  });
  final int manufacturerId;

  /// 前方一致で照合される。
  final Uint8List data;
}

class DeepskyScanFilterServiceData {
  const DeepskyScanFilterServiceData({required this.uuid, required this.data});
  final DeepskyUuid uuid;

  /// 前方一致で照合される。
  final Uint8List data;
}

class DeepskyScanFilterServiceUuidFromByteArray {
  const DeepskyScanFilterServiceUuidFromByteArray({required this.uuid});
  final DeepskyUuid uuid;
}

class DeepskyScanFilterServiceUuidFromString {
  const DeepskyScanFilterServiceUuidFromString({required this.uuid});
  final DeepskyUuid uuid;
}

class DeepskyScanFilter {
  const DeepskyScanFilter({
    this.address = const [],
    this.name = const [],
    this.manufactureData = const [],
    this.serviceData = const [],
    this.serviceUuidFromByteArray = const [],
    this.serviceUuidFromString = const [],
  });

  /// Android: MACアドレス / iOS,macOS: CBPeripheral.identifier(ソフトウェアフィルタ)。
  final List<String> address;

  /// 完全一致。iOS/macOSはソフトウェアフィルタ。
  final List<String> name;

  /// iOS/macOSはソフトウェアフィルタ。
  final List<DeepskyScanFilterManufactureData> manufactureData;

  /// iOS/macOSはソフトウェアフィルタ。
  final List<DeepskyScanFilterServiceData> serviceData;

  final List<DeepskyScanFilterServiceUuidFromByteArray>
  serviceUuidFromByteArray;
  final List<DeepskyScanFilterServiceUuidFromString> serviceUuidFromString;
}

// --- スキャン設定(プラットフォーム別) ---

enum DeepskyAndroidScanMode {
  scanModeLowPower,
  scanModeBalanced,
  scanModeLowLatency,
  scanModeOpportunistic,
}

enum DeepskyAndroidScanCallbackType {
  callBackTypeAllMatches,
  callBackTypeFirstMatch,
  callBackTypeMatchLost,
  callBackTypeFirstMatchAndMatchLost,
}

enum DeepskyAndroidScanMatchMode { matchModeAggressive, matchModeSticky }

enum DeepskyAndroidScanNumOfMatch {
  matchNumOneAdvertisement,
  matchNumFewAdvertisement,
  matchNumMaxAdvertisement,
}

enum DeepskyAndroidScanPhy { phyLe1m, phyLeCoded, phyLeAllSupported }

class DeepskyAndroidScanSetting {
  const DeepskyAndroidScanSetting({
    this.mode = DeepskyAndroidScanMode.scanModeLowLatency,
    this.callbackType = DeepskyAndroidScanCallbackType.callBackTypeAllMatches,
    this.onlyLegacy = true,
    this.matchMode = DeepskyAndroidScanMatchMode.matchModeAggressive,
    this.numOfMatch = DeepskyAndroidScanNumOfMatch.matchNumMaxAdvertisement,
    this.reportDelay = 0,
    this.phy = DeepskyAndroidScanPhy.phyLeAllSupported,
  });

  final DeepskyAndroidScanMode mode;
  final DeepskyAndroidScanCallbackType callbackType;
  final bool onlyLegacy;
  final DeepskyAndroidScanMatchMode matchMode;
  final DeepskyAndroidScanNumOfMatch numOfMatch;

  /// バッチ報告の遅延(ミリ秒)。0で即時コールバック。
  final int reportDelay;

  /// onlyLegacy=false のときのみ有効。
  final DeepskyAndroidScanPhy phy;
}

class DeepskyDarwinScanSetting {
  const DeepskyDarwinScanSetting({
    this.allowDuplicates = false,
    this.solicitedServiceUuids = const [],
  });

  /// CBCentralManagerScanOptionAllowDuplicatesKey。
  /// trueで広告ごとにscanResultsへ流れる(iOSバックグラウンドでは無効化される)。
  final bool allowDuplicates;

  /// CBCentralManagerScanOptionSolicitedServiceUUIDsKey。
  final List<DeepskyUuid> solicitedServiceUuids;
}

class DeepskyScanOptions {
  const DeepskyScanOptions({
    this.android = const DeepskyAndroidScanSetting(),
    this.darwin = const DeepskyDarwinScanSetting(),
  });
  final DeepskyAndroidScanSetting android;
  final DeepskyDarwinScanSetting darwin;
}

class BleScanResult {
  const BleScanResult({
    required this.deviceId,
    required this.rssi,
    required this.serviceUuids,
    this.name,
    this.manufacturerData,
    this.raw,
  });
  final String deviceId;
  final String? name;
  final int rssi;
  final List<String> serviceUuids;
  final Uint8List? manufacturerData;

  /// アドバタイズの生バイト列。Androidのみ(ScanRecord.getBytes())。
  /// iOS/macOSはCoreBluetoothが生データを公開しないためnull。
  final Uint8List? raw;
}

class BleConnectionEvent {
  const BleConnectionEvent({required this.deviceId, required this.state});
  final String deviceId;
  final BleConnectionState state;
}

class BleCharacteristicProperties {
  const BleCharacteristicProperties({
    required this.read,
    required this.writeWithResponse,
    required this.writeWithoutResponse,
    required this.notify,
    required this.indicate,
  });
  final bool read;
  final bool writeWithResponse;
  final bool writeWithoutResponse;
  final bool notify;
  final bool indicate;
}

class BleDescriptor {
  const BleDescriptor({required this.uuid});
  final String uuid;
}

class BleCharacteristic {
  const BleCharacteristic({
    required this.uuid,
    required this.properties,
    this.descriptors = const [],
  });
  final String uuid;
  final BleCharacteristicProperties properties;
  final List<BleDescriptor> descriptors;
}

class BleService {
  const BleService({required this.uuid, this.characteristics = const []});
  final String uuid;
  final List<BleCharacteristic> characteristics;
}

class BleCharacteristicTarget {
  const BleCharacteristicTarget({
    required this.deviceId,
    required this.serviceUuid,
    required this.characteristicUuid,
  });
  final String deviceId;
  final String serviceUuid;
  final String characteristicUuid;
}

class BleDescriptorTarget {
  const BleDescriptorTarget({
    required this.deviceId,
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.descriptorUuid,
  });
  final String deviceId;
  final String serviceUuid;
  final String characteristicUuid;
  final String descriptorUuid;
}

class BleCharacteristicValue {
  const BleCharacteristicValue({required this.target, required this.value});
  final BleCharacteristicTarget target;
  final Uint8List value;
}

/// Android CompanionDeviceService の onDeviceAppeared / onDeviceDisappeared。
class BleCompanionEvent {
  const BleCompanionEvent({required this.deviceId, required this.appeared});
  final String deviceId;
  final bool appeared;
}
```

- [ ] **Step 4: exportファイルをテンプレートから置換し、テンプレートテストを削除**

`lib/deepsky_bluetooth_interface.dart` 全文(エラー型はutilの再exportで提供する。interface自体にエラー定義は置かない):

```dart
library;

export 'package:deepsky_bluetooth_util/deepsky_bluetooth_util.dart';

export 'src/models.dart';
```

```powershell
git rm packages/deepsky_bluetooth_interface/test/deepsky_bluetooth_interface_test.dart
```

(以降のタスクで `src/config.dart` などのexportを追記していく)

- [ ] **Step 5: テストが通ることを確認**

Run: `flutter test`
Expected: All tests passed

- [ ] **Step 6: コミット**

```powershell
git add packages/deepsky_bluetooth_interface && git commit -m "feat(interface): add BLE domain models"
```

---

### Task 4: interface — 設定(Foreground/Background Config)

**Files:**

- Create: `packages/deepsky_bluetooth_interface/lib/src/config.dart`
- Modify: `packages/deepsky_bluetooth_interface/lib/deepsky_bluetooth_interface.dart`
- Create: `packages/deepsky_bluetooth_interface/test/config_test.dart`

- [ ] **Step 1: 失敗するテストを書く**

`test/config_test.dart`:

```dart
import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('config is a sealed foreground/background choice', () {
    const DeepskyBluetoothConfig fg = DeepskyBluetoothConfig.foreground();
    const DeepskyBluetoothConfig bg = DeepskyBluetoothConfig.background(
      ios: IosBackgroundConfig(restoreIdentifier: 'com.example.restore'),
      android: AndroidForegroundServiceConfig(
        notification: AndroidNotificationConfig(
          channelId: 'ble',
          channelName: 'BLE',
          title: 'Connected',
          text: 'Maintaining BLE link',
        ),
      ),
    );
    final kind = switch (fg) {
      ForegroundConfig() => 'fg',
      BackgroundConfig() => 'bg',
    };
    expect(kind, 'fg');
    expect((bg as BackgroundConfig).ios?.restoreIdentifier, 'com.example.restore');
  });

  test('android background strategy is sealed', () {
    const AndroidBackgroundConfig cdm = AndroidCompanionDeviceConfig();
    final kind = switch (cdm) {
      AndroidForegroundServiceConfig() => 'fgs',
      AndroidCompanionDeviceConfig() => 'cdm',
    };
    expect(kind, 'cdm');
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/config_test.dart` → コンパイルエラーで FAIL

- [ ] **Step 3: config.dart を実装**

`lib/src/config.dart` 全文:

```dart
/// FG/BGモードを本体→bridge→ネイティブへ運ぶ内部転送用の型。
/// ライブラリ利用者はこれを直接使わず、
/// `DeepskyBluetooth.foreground()` / `DeepskyBluetooth.background()` で生成する。
sealed class DeepskyBluetoothConfig {
  const DeepskyBluetoothConfig();
  const factory DeepskyBluetoothConfig.foreground() = ForegroundConfig;
  const factory DeepskyBluetoothConfig.background({
    IosBackgroundConfig? ios,
    AndroidBackgroundConfig? android,
  }) = BackgroundConfig;
}

final class ForegroundConfig extends DeepskyBluetoothConfig {
  const ForegroundConfig();
}

final class BackgroundConfig extends DeepskyBluetoothConfig {
  const BackgroundConfig({this.ios, this.android});

  /// iOSでバックグラウンドを使う場合は必須(State Restoration識別子)。
  final IosBackgroundConfig? ios;

  /// Androidでバックグラウンドを使う場合は必須。
  final AndroidBackgroundConfig? android;
}

class IosBackgroundConfig {
  const IosBackgroundConfig({required this.restoreIdentifier});
  final String restoreIdentifier;
}

sealed class AndroidBackgroundConfig {
  const AndroidBackgroundConfig();
}

final class AndroidForegroundServiceConfig extends AndroidBackgroundConfig {
  const AndroidForegroundServiceConfig({required this.notification});
  final AndroidNotificationConfig notification;
}

final class AndroidCompanionDeviceConfig extends AndroidBackgroundConfig {
  const AndroidCompanionDeviceConfig();
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
}
```

- [ ] **Step 4: export追記 → テスト確認**

`export 'src/config.dart';` を追加し `flutter test` → All tests passed

- [ ] **Step 5: コミット**

```powershell
git add packages/deepsky_bluetooth_interface && git commit -m "feat(interface): add foreground/background config types"
```

---

### Task 5: interface — Observer と Platform 抽象クラス

**Files:**

- Create: `packages/deepsky_bluetooth_interface/lib/src/observer.dart`
- Create: `packages/deepsky_bluetooth_interface/lib/src/platform.dart`
- Modify: `packages/deepsky_bluetooth_interface/lib/deepsky_bluetooth_interface.dart`
- Create: `packages/deepsky_bluetooth_interface/test/platform_test.dart`

- [ ] **Step 1: 失敗するテストを書く**

`test/platform_test.dart`(抽象クラスを実装できること・Observerフックの形を確認):

```dart
import 'dart:typed_data';

import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/steady.dart';

final class _RecordingObserver implements DeepskyBluetoothObserver {
  final calls = <String>[];
  @override
  void onMethodStart(String methodName, Map<String, Object?> arguments) =>
      calls.add('start:$methodName');
  @override
  void onMethodEnd(String methodName, Result<Object?, Exception> result) =>
      calls.add('end:$methodName:${result.isOk}');
  @override
  void onCallback(String callbackName, Object? payload) =>
      calls.add('cb:$callbackName');
}

final class _FakePlatform extends DeepskyBluetoothPlatform {
  @override
  Future<Result<void, InitializeError>> initialize(
          DeepskyBluetoothConfig config) async =>
      const Result.ok(null);
  @override
  Future<Result<void, ScanError>> startScan(
          {DeepskyScanFilter? filter,
          DeepskyScanOptions options = const DeepskyScanOptions()}) async =>
      const Result.error(ScanBluetoothOff());
  @override
  Future<Result<void, ScanError>> stopScan() async => const Result.ok(null);
  @override
  Future<Result<void, ConnectError>> connect(String deviceId) async =>
      const Result.ok(null);
  @override
  Future<Result<void, DisconnectError>> disconnect(String deviceId) async =>
      const Result.ok(null);
  @override
  Future<Result<List<BleService>, DiscoverServicesError>> discoverServices(
          String deviceId) async =>
      const Result.ok([]);
  @override
  Future<Result<Uint8List, CharacteristicReadError>> readCharacteristic(
          BleCharacteristicTarget target) async =>
      Result.ok(Uint8List(0));
  @override
  Future<Result<void, CharacteristicWriteError>> writeCharacteristic(
          BleCharacteristicTarget target, Uint8List value,
          {required bool withResponse}) async =>
      const Result.ok(null);
  @override
  Future<Result<void, NotifyError>> setNotify(BleCharacteristicTarget target,
          {required bool enabled}) async =>
      const Result.ok(null);
  @override
  Future<Result<Uint8List, DescriptorReadError>> readDescriptor(
          BleDescriptorTarget target) async =>
      Result.ok(Uint8List(0));
  @override
  Future<Result<void, DescriptorWriteError>> writeDescriptor(
          BleDescriptorTarget target, Uint8List value) async =>
      const Result.ok(null);
  @override
  Future<Result<int, MtuError>> requestMtu(String deviceId, int mtu) async =>
      const Result.ok(23);
  @override
  Future<Result<int, RssiError>> readRssi(String deviceId) async =>
      const Result.ok(-40);
  @override
  Future<Result<String, AssociateError>> associate(
          {DeepskyScanFilter? filter}) async =>
      const Result.error(AssociateNotSupported());
  @override
  Future<Result<void, PresenceError>> setDevicePresenceObservation(
          String deviceId,
          {required bool enabled}) async =>
      const Result.error(PresenceNotSupported());
  @override
  Future<Result<void, DisposeError>> dispose() async => const Result.ok(null);
  @override
  Stream<BleScanResult> get scanResults => const Stream.empty();
  @override
  Stream<ScanError> get scanErrors => const Stream.empty();
  @override
  Stream<BleConnectionEvent> get connectionEvents => const Stream.empty();
  @override
  Stream<BleCharacteristicValue> get characteristicValues =>
      const Stream.empty();
  @override
  Stream<BleCompanionEvent> get companionEvents => const Stream.empty();
  @override
  Stream<List<String>> get restoredConnections => const Stream.empty();
}

void main() {
  test('platform abstract class can be implemented and returns Results',
      () async {
    final p = _FakePlatform();
    expect((await p.startScan()).err, isA<ScanBluetoothOff>());
    expect((await p.requestMtu('id', 247)).ok, 23);
  });

  test('observer hooks record lifecycle', () {
    final o = _RecordingObserver();
    o.onMethodStart('connect', {'deviceId': 'x'});
    o.onMethodEnd('connect', const Result.ok(null));
    o.onCallback('scanResults', null);
    expect(o.calls, ['start:connect', 'end:connect:true', 'cb:scanResults']);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/platform_test.dart` → コンパイルエラーで FAIL

- [ ] **Step 3: observer.dart を実装**

`lib/src/observer.dart` 全文:

```dart
import 'package:steady/steady.dart';

/// 各メソッドの開始・終了と、ネイティブ→Dartコールバックの発火タイミングで
/// 呼び出されるユーザー定義フック。
abstract interface class DeepskyBluetoothObserver {
  void onMethodStart(String methodName, Map<String, Object?> arguments);
  void onMethodEnd(String methodName, Result<Object?, Exception> result);
  void onCallback(String callbackName, Object? payload);
}
```

- [ ] **Step 4: platform.dart を実装**

`lib/src/platform.dart` 全文:

```dart
import 'dart:typed_data';

import 'package:deepsky_bluetooth_util/deepsky_bluetooth_util.dart';
import 'package:steady/steady.dart';

import 'config.dart';
import 'models.dart';

/// 各bridgeパッケージが実装するプラットフォーム抽象。
abstract class DeepskyBluetoothPlatform {
  Future<Result<void, InitializeError>> initialize(
      DeepskyBluetoothConfig config);

  Future<Result<void, ScanError>> startScan(
      {DeepskyScanFilter? filter,
      DeepskyScanOptions options = const DeepskyScanOptions()});
  Future<Result<void, ScanError>> stopScan();

  Future<Result<void, ConnectError>> connect(String deviceId);
  Future<Result<void, DisconnectError>> disconnect(String deviceId);

  Future<Result<List<BleService>, DiscoverServicesError>> discoverServices(
      String deviceId);

  Future<Result<Uint8List, CharacteristicReadError>> readCharacteristic(
      BleCharacteristicTarget target);
  Future<Result<void, CharacteristicWriteError>> writeCharacteristic(
      BleCharacteristicTarget target, Uint8List value,
      {required bool withResponse});
  Future<Result<void, NotifyError>> setNotify(BleCharacteristicTarget target,
      {required bool enabled});

  Future<Result<Uint8List, DescriptorReadError>> readDescriptor(
      BleDescriptorTarget target);
  Future<Result<void, DescriptorWriteError>> writeDescriptor(
      BleDescriptorTarget target, Uint8List value);

  /// iOSではOSが自動ネゴシエートするため要求値は無視され、現在のMTUを返す。
  Future<Result<int, MtuError>> requestMtu(String deviceId, int mtu);
  Future<Result<int, RssiError>> readRssi(String deviceId);

  /// Android(CompanionDeviceモード)のみ。他プラットフォームは
  /// [AssociateNotSupported] を返す。
  /// CDMのデバイスフィルタには [DeepskyScanFilter] の name / serviceUuid系の
  /// 先頭エントリのみが使われる。
  Future<Result<String, AssociateError>> associate({DeepskyScanFilter? filter});
  Future<Result<void, PresenceError>> setDevicePresenceObservation(
      String deviceId,
      {required bool enabled});

  /// スキャン停止・全接続解放・(Androidの)Foreground Service停止。
  Future<Result<void, DisposeError>> dispose();

  Stream<BleScanResult> get scanResults;

  /// Androidの onScanFailed 等、開始後に非同期で発生したスキャン失敗。
  Stream<ScanError> get scanErrors;
  Stream<BleConnectionEvent> get connectionEvents;
  Stream<BleCharacteristicValue> get characteristicValues;

  /// Android CompanionDeviceService の出現/消失イベント。
  Stream<BleCompanionEvent> get companionEvents;

  /// iOS State Restoration で復元された接続済みdeviceIdのリスト。
  Stream<List<String>> get restoredConnections;
}
```

- [ ] **Step 5: export追記 → テスト確認**

`export 'src/observer.dart';` と `export 'src/platform.dart';` を追加し、`flutter test` → All tests passed

- [ ] **Step 6: コミット**

```powershell
git add packages/deepsky_bluetooth_interface && git commit -m "feat(interface): add observer contract and platform abstract class"
```

---

### Task 6: deepsky_bluetooth_android — Pigeon定義と生成

**Files:**
- Create: `plugins/deepsky_bluetooth_android/pigeons/messages.dart`
- Modify: `plugins/deepsky_bluetooth_android/lib/deepsky_bluetooth_android.dart`(テンプレート全置換)
- Generate: `plugins/deepsky_bluetooth_android/lib/src/messages.g.dart`
- Generate: `plugins/deepsky_bluetooth_android/android/src/main/kotlin/com/example/deepsky_bluetooth_android/Messages.g.kt`

- [ ] **Step 1: Pigeon定義を書く**

`pigeons/messages.dart` 全文:

```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  kotlinOut:
      'android/src/main/kotlin/com/example/deepsky_bluetooth_android/Messages.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.example.deepsky_bluetooth_android'),
))
enum BackgroundStrategyMessage { foregroundService, companionDevice }

class NotificationConfigMessage {
  NotificationConfigMessage(this.channelId, this.channelName, this.title, this.text);
  String channelId;
  String channelName;
  String title;
  String text;
}

class InitializeRequestMessage {
  InitializeRequestMessage(this.isBackground, this.strategy, this.notification);
  bool isBackground;
  BackgroundStrategyMessage? strategy;
  NotificationConfigMessage? notification;
}

class ManufacturerDataFilterMessage {
  ManufacturerDataFilterMessage(this.manufacturerId, this.data);
  int manufacturerId;
  Uint8List data;
}

class ServiceDataFilterMessage {
  ServiceDataFilterMessage(this.serviceUuid, this.data);
  String serviceUuid;
  Uint8List data;
}

/// 各エントリはOR条件。serviceUuidsはFromByteArray/FromString両形式を
/// bridgeが正規化済み文字列へ統合したもの。
class ScanFilterMessage {
  ScanFilterMessage(this.addresses, this.names, this.manufacturerData,
      this.serviceData, this.serviceUuids);
  List<String> addresses;
  List<String> names;
  List<ManufacturerDataFilterMessage> manufacturerData;
  List<ServiceDataFilterMessage> serviceData;
  List<String> serviceUuids;
}

class ScanResultMessage {
  ScanResultMessage(this.deviceId, this.name, this.rssi, this.serviceUuids,
      this.manufacturerData, this.raw);
  String deviceId;
  String? name;
  int rssi;
  List<String> serviceUuids;
  Uint8List? manufacturerData;

  /// アドバタイズ生バイト列。Androidのみ。iOS/macOSはnull。
  Uint8List? raw;
}

enum ConnectionStateMessage { connecting, connected, disconnecting, disconnected }

class CharacteristicTargetMessage {
  CharacteristicTargetMessage(
      this.deviceId, this.serviceUuid, this.characteristicUuid);
  String deviceId;
  String serviceUuid;
  String characteristicUuid;
}

class DescriptorTargetMessage {
  DescriptorTargetMessage(this.deviceId, this.serviceUuid,
      this.characteristicUuid, this.descriptorUuid);
  String deviceId;
  String serviceUuid;
  String characteristicUuid;
  String descriptorUuid;
}

class DescriptorMessage {
  DescriptorMessage(this.uuid);
  String uuid;
}

class CharacteristicMessage {
  CharacteristicMessage(this.uuid, this.canRead, this.canWriteWithResponse,
      this.canWriteWithoutResponse, this.canNotify, this.canIndicate,
      this.descriptors);
  String uuid;
  bool canRead;
  bool canWriteWithResponse;
  bool canWriteWithoutResponse;
  bool canNotify;
  bool canIndicate;
  List<DescriptorMessage> descriptors;
}

class ServiceMessage {
  ServiceMessage(this.uuid, this.characteristics);
  String uuid;
  List<CharacteristicMessage> characteristics;
}

enum ScanModeMessage { lowPower, balanced, lowLatency, opportunistic }

enum ScanCallbackTypeMessage {
  allMatches,
  firstMatch,
  matchLost,
  firstMatchAndMatchLost,
}

enum ScanMatchModeMessage { aggressive, sticky }

enum ScanNumOfMatchMessage { one, few, max }

enum ScanPhyMessage { le1m, leCoded, allSupported }

class AndroidScanSettingsMessage {
  AndroidScanSettingsMessage(this.mode, this.callbackType, this.onlyLegacy,
      this.matchMode, this.numOfMatch, this.reportDelayMillis, this.phy);
  ScanModeMessage mode;
  ScanCallbackTypeMessage callbackType;
  bool onlyLegacy;
  ScanMatchModeMessage matchMode;
  ScanNumOfMatchMessage numOfMatch;
  int reportDelayMillis;
  ScanPhyMessage phy;
}

@HostApi()
abstract class BleHostApi {
  void initialize(InitializeRequestMessage request);

  /// Dart側のコールバック受信準備完了。バッファ済みイベントをflushする。
  void notifyDartReady();
  void startScan(ScanFilterMessage? filter, AndroidScanSettingsMessage settings);
  void stopScan();
  @async
  void connect(String deviceId);
  @async
  void disconnect(String deviceId);
  @async
  List<ServiceMessage> discoverServices(String deviceId);
  @async
  Uint8List readCharacteristic(CharacteristicTargetMessage target);
  @async
  void writeCharacteristic(
      CharacteristicTargetMessage target, Uint8List value, bool withResponse);
  @async
  void setNotify(CharacteristicTargetMessage target, bool enabled);
  @async
  Uint8List readDescriptor(DescriptorTargetMessage target);
  @async
  void writeDescriptor(DescriptorTargetMessage target, Uint8List value);
  @async
  int requestMtu(String deviceId, int mtu);
  @async
  int readRssi(String deviceId);
  @async
  String associate(ScanFilterMessage? filter);
  void setDevicePresenceObservation(String deviceId, bool enabled);
  void dispose();
}

@FlutterApi()
abstract class BleCallbacksApi {
  void onScanResult(ScanResultMessage result);
  void onScanFailed(String code, String message);
  void onConnectionStateChanged(String deviceId, ConnectionStateMessage state);
  void onCharacteristicValue(CharacteristicTargetMessage target, Uint8List value);
  void onDeviceAppeared(String deviceId);
  void onDeviceDisappeared(String deviceId);
}
```

- [ ] **Step 2: コード生成を実行**

Run: `plugins/deepsky_bluetooth_android` で `dart run pigeon --input pigeons/messages.dart`
Expected: 終了コード0。`lib/src/messages.g.dart` と `android/.../Messages.g.kt` が生成される

- [ ] **Step 3: プラグインのlibを生成物のexportに置換**

`lib/deepsky_bluetooth_android.dart` 全文:

```dart
library;

export 'src/messages.g.dart';
```

- [ ] **Step 4: 解析確認**

Run: ルートで `flutter analyze plugins/deepsky_bluetooth_android`
Expected: No issues found

- [ ] **Step 5: コミット**

```powershell
git add plugins/deepsky_bluetooth_android && git commit -m "feat(android): define pigeon messages and generate bindings"
```

---

### Task 7: deepsky_bluetooth_ios — Pigeon定義と生成

**Files:**
- Create: `plugins/deepsky_bluetooth_ios/pigeons/messages.dart`
- Modify: `plugins/deepsky_bluetooth_ios/lib/deepsky_bluetooth_ios.dart`(テンプレート全置換)
- Generate: `plugins/deepsky_bluetooth_ios/lib/src/messages.g.dart`
- Generate: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/Messages.g.swift`

- [ ] **Step 1: Pigeon定義を書く**

`pigeons/messages.dart` 全文(Androidとの差分: `InitializeRequestMessage` が `restoreIdentifier` を持つ / `associate`・presence・strategy・notificationなし / `requestMtu` の代わりに `getMtu` / FlutterApiに `onStateRestored` 追加):

```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  swiftOut:
      'ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/Messages.g.swift',
))
class InitializeRequestMessage {
  InitializeRequestMessage(this.isBackground, this.restoreIdentifier);
  bool isBackground;
  String? restoreIdentifier;
}

class ManufacturerDataFilterMessage {
  ManufacturerDataFilterMessage(this.manufacturerId, this.data);
  int manufacturerId;
  Uint8List data;
}

class ServiceDataFilterMessage {
  ServiceDataFilterMessage(this.serviceUuid, this.data);
  String serviceUuid;
  Uint8List data;
}

/// 各エントリはOR条件。serviceUuidsはFromByteArray/FromString両形式を
/// bridgeが正規化済み文字列へ統合したもの。
class ScanFilterMessage {
  ScanFilterMessage(this.addresses, this.names, this.manufacturerData,
      this.serviceData, this.serviceUuids);
  List<String> addresses;
  List<String> names;
  List<ManufacturerDataFilterMessage> manufacturerData;
  List<ServiceDataFilterMessage> serviceData;
  List<String> serviceUuids;
}

class ScanResultMessage {
  ScanResultMessage(this.deviceId, this.name, this.rssi, this.serviceUuids,
      this.manufacturerData, this.raw);
  String deviceId;
  String? name;
  int rssi;
  List<String> serviceUuids;
  Uint8List? manufacturerData;

  /// アドバタイズ生バイト列。Androidのみ。iOS/macOSはnull。
  Uint8List? raw;
}

enum ConnectionStateMessage { connecting, connected, disconnecting, disconnected }

class CharacteristicTargetMessage {
  CharacteristicTargetMessage(
      this.deviceId, this.serviceUuid, this.characteristicUuid);
  String deviceId;
  String serviceUuid;
  String characteristicUuid;
}

class DescriptorTargetMessage {
  DescriptorTargetMessage(this.deviceId, this.serviceUuid,
      this.characteristicUuid, this.descriptorUuid);
  String deviceId;
  String serviceUuid;
  String characteristicUuid;
  String descriptorUuid;
}

class DescriptorMessage {
  DescriptorMessage(this.uuid);
  String uuid;
}

class CharacteristicMessage {
  CharacteristicMessage(this.uuid, this.canRead, this.canWriteWithResponse,
      this.canWriteWithoutResponse, this.canNotify, this.canIndicate,
      this.descriptors);
  String uuid;
  bool canRead;
  bool canWriteWithResponse;
  bool canWriteWithoutResponse;
  bool canNotify;
  bool canIndicate;
  List<DescriptorMessage> descriptors;
}

class ServiceMessage {
  ServiceMessage(this.uuid, this.characteristics);
  String uuid;
  List<CharacteristicMessage> characteristics;
}

class DarwinScanSettingsMessage {
  DarwinScanSettingsMessage(this.allowDuplicates, this.solicitedServiceUuids);
  bool allowDuplicates;
  List<String> solicitedServiceUuids;
}

@HostApi()
abstract class BleHostApi {
  void initialize(InitializeRequestMessage request);
  void notifyDartReady();
  void startScan(ScanFilterMessage? filter, DarwinScanSettingsMessage settings);
  void stopScan();
  @async
  void connect(String deviceId);
  @async
  void disconnect(String deviceId);
  @async
  List<ServiceMessage> discoverServices(String deviceId);
  @async
  Uint8List readCharacteristic(CharacteristicTargetMessage target);
  @async
  void writeCharacteristic(
      CharacteristicTargetMessage target, Uint8List value, bool withResponse);
  @async
  void setNotify(CharacteristicTargetMessage target, bool enabled);
  @async
  Uint8List readDescriptor(DescriptorTargetMessage target);
  @async
  void writeDescriptor(DescriptorTargetMessage target, Uint8List value);

  /// iOSはMTU要求不可のため現在値(maximumWriteValueLength+3)を返す。
  @async
  int getMtu(String deviceId);
  @async
  int readRssi(String deviceId);
  void dispose();
}

@FlutterApi()
abstract class BleCallbacksApi {
  void onScanResult(ScanResultMessage result);
  void onConnectionStateChanged(String deviceId, ConnectionStateMessage state);
  void onCharacteristicValue(CharacteristicTargetMessage target, Uint8List value);

  /// State Restorationで復元された接続済みデバイスID。
  void onStateRestored(List<String> connectedDeviceIds);
}
```

- [ ] **Step 2: コード生成を実行**

Run: `plugins/deepsky_bluetooth_ios` で `dart run pigeon --input pigeons/messages.dart`
Expected: 終了コード0。`lib/src/messages.g.dart` と `Messages.g.swift` が生成される

- [ ] **Step 3: プラグインのlibを生成物のexportに置換**

`lib/deepsky_bluetooth_ios.dart` 全文:

```dart
library;

export 'src/messages.g.dart';
```

- [ ] **Step 4: 解析確認**

Run: `flutter analyze plugins/deepsky_bluetooth_ios`
Expected: No issues found

- [ ] **Step 5: コミット**

```powershell
git add plugins/deepsky_bluetooth_ios && git commit -m "feat(ios): define pigeon messages and generate bindings"
```

---

### Task 8: deepsky_bluetooth_macos — Pigeon定義と生成

**Files:**
- Create: `plugins/deepsky_bluetooth_macos/pigeons/messages.dart`
- Modify: `plugins/deepsky_bluetooth_macos/lib/deepsky_bluetooth_macos.dart`(テンプレート全置換)
- Generate: `plugins/deepsky_bluetooth_macos/lib/src/messages.g.dart`
- Generate: `plugins/deepsky_bluetooth_macos/macos/deepsky_bluetooth_macos/Sources/deepsky_bluetooth_macos/Messages.g.swift`

- [ ] **Step 1: Pigeon定義を書く**

`pigeons/messages.dart` 全文(iOSとの差分: `initialize(bool isBackground)` のみ / `onStateRestored` なし):

```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  swiftOut:
      'macos/deepsky_bluetooth_macos/Sources/deepsky_bluetooth_macos/Messages.g.swift',
))
class ManufacturerDataFilterMessage {
  ManufacturerDataFilterMessage(this.manufacturerId, this.data);
  int manufacturerId;
  Uint8List data;
}

class ServiceDataFilterMessage {
  ServiceDataFilterMessage(this.serviceUuid, this.data);
  String serviceUuid;
  Uint8List data;
}

/// 各エントリはOR条件。serviceUuidsはFromByteArray/FromString両形式を
/// bridgeが正規化済み文字列へ統合したもの。
class ScanFilterMessage {
  ScanFilterMessage(this.addresses, this.names, this.manufacturerData,
      this.serviceData, this.serviceUuids);
  List<String> addresses;
  List<String> names;
  List<ManufacturerDataFilterMessage> manufacturerData;
  List<ServiceDataFilterMessage> serviceData;
  List<String> serviceUuids;
}

class ScanResultMessage {
  ScanResultMessage(this.deviceId, this.name, this.rssi, this.serviceUuids,
      this.manufacturerData, this.raw);
  String deviceId;
  String? name;
  int rssi;
  List<String> serviceUuids;
  Uint8List? manufacturerData;

  /// アドバタイズ生バイト列。Androidのみ。iOS/macOSはnull。
  Uint8List? raw;
}

enum ConnectionStateMessage { connecting, connected, disconnecting, disconnected }

class CharacteristicTargetMessage {
  CharacteristicTargetMessage(
      this.deviceId, this.serviceUuid, this.characteristicUuid);
  String deviceId;
  String serviceUuid;
  String characteristicUuid;
}

class DescriptorTargetMessage {
  DescriptorTargetMessage(this.deviceId, this.serviceUuid,
      this.characteristicUuid, this.descriptorUuid);
  String deviceId;
  String serviceUuid;
  String characteristicUuid;
  String descriptorUuid;
}

class DescriptorMessage {
  DescriptorMessage(this.uuid);
  String uuid;
}

class CharacteristicMessage {
  CharacteristicMessage(this.uuid, this.canRead, this.canWriteWithResponse,
      this.canWriteWithoutResponse, this.canNotify, this.canIndicate,
      this.descriptors);
  String uuid;
  bool canRead;
  bool canWriteWithResponse;
  bool canWriteWithoutResponse;
  bool canNotify;
  bool canIndicate;
  List<DescriptorMessage> descriptors;
}

class ServiceMessage {
  ServiceMessage(this.uuid, this.characteristics);
  String uuid;
  List<CharacteristicMessage> characteristics;
}

class DarwinScanSettingsMessage {
  DarwinScanSettingsMessage(this.allowDuplicates, this.solicitedServiceUuids);
  bool allowDuplicates;
  List<String> solicitedServiceUuids;
}

@HostApi()
abstract class BleHostApi {
  /// バックグラウンド指定(isBackground=true)は backgroundNotSupported エラー。
  /// 第一防衛線はmacos_bridge側のガード。
  void initialize(bool isBackground);
  void notifyDartReady();
  void startScan(ScanFilterMessage? filter, DarwinScanSettingsMessage settings);
  void stopScan();
  @async
  void connect(String deviceId);
  @async
  void disconnect(String deviceId);
  @async
  List<ServiceMessage> discoverServices(String deviceId);
  @async
  Uint8List readCharacteristic(CharacteristicTargetMessage target);
  @async
  void writeCharacteristic(
      CharacteristicTargetMessage target, Uint8List value, bool withResponse);
  @async
  void setNotify(CharacteristicTargetMessage target, bool enabled);
  @async
  Uint8List readDescriptor(DescriptorTargetMessage target);
  @async
  void writeDescriptor(DescriptorTargetMessage target, Uint8List value);
  @async
  int getMtu(String deviceId);
  @async
  int readRssi(String deviceId);
  void dispose();
}

@FlutterApi()
abstract class BleCallbacksApi {
  void onScanResult(ScanResultMessage result);
  void onConnectionStateChanged(String deviceId, ConnectionStateMessage state);
  void onCharacteristicValue(CharacteristicTargetMessage target, Uint8List value);
}
```

- [ ] **Step 2: コード生成を実行**

Run: `plugins/deepsky_bluetooth_macos` で `dart run pigeon --input pigeons/messages.dart`
Expected: 終了コード0、両生成物が出力される

- [ ] **Step 3: プラグインのlibを生成物のexportに置換**

`lib/deepsky_bluetooth_macos.dart` 全文:

```dart
library;

export 'src/messages.g.dart';
```

- [ ] **Step 4: 解析確認**

Run: `flutter analyze plugins/deepsky_bluetooth_macos`
Expected: No issues found

- [ ] **Step 5: コミット**

```powershell
git add plugins/deepsky_bluetooth_macos && git commit -m "feat(macos): define pigeon messages and generate bindings"
```

---

### Task 9: Androidネイティブ — Observer・GATT中核・プラグイン配線

**Files:**
- Modify: `plugins/deepsky_bluetooth_android/android/build.gradle.kts`(minSdk 31)
- Modify: `plugins/deepsky_bluetooth_android/android/src/main/AndroidManifest.xml`
- Create: `.../kotlin/com/example/deepsky_bluetooth_android/BleErrorCodes.kt`
- Create: `.../DeepskyBluetoothAndroidObserver.kt`
- Create: `.../ObservingBleHostApi.kt`
- Create: `.../GattConnection.kt`
- Create: `.../BleCentralManager.kt`
- Create: `.../PendingCompanionEvents.kt`
- Modify: `.../DeepskyBluetoothAndroidPlugin.kt`(テンプレート全置換)
- Delete: `plugins/deepsky_bluetooth_android/android/src/test/kotlin/.../DeepskyBluetoothAndroidPluginTest.kt`(テンプレート。ネイティブテストはスコープ外)
- Modify: `plugins/deepsky_bluetooth_android/example/android/app/build.gradle.kts`(minSdk 31)

注: Kotlinの非同期メソッドはPigeon生成の `(kotlin.Result<T>) -> Unit` コールバックで完了させる(=ネイティブ側もResult型)。`try-catch` はPigeon同期メソッド境界(`FlutterError` throw)とObserverデコレータのみ。
API 33で非推奨になった `BluetoothGatt` の旧シグネチャ(`ch.value` 代入等)を `@Suppress("DEPRECATION")` で使用する(minSdk 31対応のため)。実機検証後にAPI 33+の新シグネチャ併用を検討する。

- [ ] **Step 1: minSdkを31にする**

`plugins/deepsky_bluetooth_android/android/build.gradle.kts` 内 `defaultConfig` の `minSdk` を `31` に変更。
`plugins/deepsky_bluetooth_android/example/android/app/build.gradle.kts` の `minSdk` も `31` に変更(`flutter.minSdkVersion` 指定の場合はリテラル31へ)。

- [ ] **Step 2: Manifestに権限を追加**

`android/src/main/AndroidManifest.xml` 全文:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN"
        android:usesPermissionFlags="neverForLocation" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />
    <uses-permission android:name="android.permission.REQUEST_OBSERVE_COMPANION_DEVICE_PRESENCE" />
</manifest>
```

(Service宣言はTask 10/11で追加)

- [ ] **Step 3: エラーコード定数**

`BleErrorCodes.kt` 全文:

```kotlin
package com.example.deepsky_bluetooth_android

object BleErrorCode {
    const val PERMISSION_DENIED = "permissionDenied"
    const val BLUETOOTH_OFF = "bluetoothOff"
    const val ALREADY_SCANNING = "alreadyScanning"
    const val NOT_FOUND = "notFound"
    const val NOT_CONNECTED = "notConnected"
    const val NOT_SUPPORTED = "notSupported"
    const val TIMEOUT = "timeout"
    const val REJECTED = "rejected"
    const val ALREADY_INITIALIZED = "alreadyInitialized"
    const val BACKGROUND_CONFIG_MISSING = "backgroundConfigMissing"
    const val NOT_ASSOCIATED = "notAssociated"
    const val FAILED = "failed"
}

fun bleError(code: String, message: String): FlutterError =
    FlutterError(code, message, null)
```

(`FlutterError` はPigeon生成の `Messages.g.kt` に定義される)

- [ ] **Step 4: ネイティブObserver**

`DeepskyBluetoothAndroidObserver.kt` 全文:

```kotlin
package com.example.deepsky_bluetooth_android

import android.util.Log

/** ネイティブ側のメソッド開始/終了・コールバック発火フック。 */
interface DeepskyBluetoothAndroidObserver {
    fun onMethodStart(method: String, arguments: Map<String, Any?>)
    fun onMethodEnd(method: String, error: Throwable?)
    fun onCallback(callback: String, payload: Any?)
}

class LogcatObserver : DeepskyBluetoothAndroidObserver {
    override fun onMethodStart(method: String, arguments: Map<String, Any?>) {
        Log.d(TAG, "start $method $arguments")
    }

    override fun onMethodEnd(method: String, error: Throwable?) {
        Log.d(TAG, "end $method error=$error")
    }

    override fun onCallback(callback: String, payload: Any?) {
        Log.d(TAG, "callback $callback $payload")
    }

    private companion object {
        const val TAG = "DeepskyBluetooth"
    }
}

/** ホストアプリのネイティブコードから差し替え可能なレジストリ。 */
object DeepskyBluetoothAndroidObserverRegistry {
    @Volatile
    var observer: DeepskyBluetoothAndroidObserver = LogcatObserver()
}
```

- [ ] **Step 5: Observerデコレータ**

`ObservingBleHostApi.kt` 全文:

```kotlin
package com.example.deepsky_bluetooth_android

class ObservingBleHostApi(
    private val inner: BleCentralManager,
    private val observer: () -> DeepskyBluetoothAndroidObserver,
) : BleHostApi {
    private inline fun <T> observed(name: String, args: Map<String, Any?>, body: () -> T): T {
        observer().onMethodStart(name, args)
        return try {
            body().also { observer().onMethodEnd(name, null) }
        } catch (t: Throwable) {
            observer().onMethodEnd(name, t)
            throw t
        }
    }

    private fun <T> observedAsync(
        name: String,
        args: Map<String, Any?>,
        callback: (Result<T>) -> Unit,
        body: ((Result<T>) -> Unit) -> Unit,
    ) {
        observer().onMethodStart(name, args)
        body { r ->
            observer().onMethodEnd(name, r.exceptionOrNull())
            callback(r)
        }
    }

    override fun initialize(request: InitializeRequestMessage) =
        observed("initialize", mapOf("isBackground" to request.isBackground, "strategy" to request.strategy?.name)) {
            inner.initialize(request)
        }

    override fun notifyDartReady() =
        observed("notifyDartReady", emptyMap()) { inner.notifyDartReady() }

    override fun startScan(filter: ScanFilterMessage?, settings: AndroidScanSettingsMessage) =
        observed("startScan", mapOf(
            "serviceUuids" to filter?.serviceUuids,
            "names" to filter?.names,
            "mode" to settings.mode.name,
        )) {
            inner.startScan(filter, settings)
        }

    override fun stopScan() = observed("stopScan", emptyMap()) { inner.stopScan() }

    override fun connect(deviceId: String, callback: (Result<Unit>) -> Unit) =
        observedAsync("connect", mapOf("deviceId" to deviceId), callback) { inner.connect(deviceId, it) }

    override fun disconnect(deviceId: String, callback: (Result<Unit>) -> Unit) =
        observedAsync("disconnect", mapOf("deviceId" to deviceId), callback) { inner.disconnect(deviceId, it) }

    override fun discoverServices(deviceId: String, callback: (Result<List<ServiceMessage>>) -> Unit) =
        observedAsync("discoverServices", mapOf("deviceId" to deviceId), callback) { inner.discoverServices(deviceId, it) }

    override fun readCharacteristic(target: CharacteristicTargetMessage, callback: (Result<ByteArray>) -> Unit) =
        observedAsync("readCharacteristic", targetArgs(target), callback) { inner.readCharacteristic(target, it) }

    override fun writeCharacteristic(
        target: CharacteristicTargetMessage,
        value: ByteArray,
        withResponse: Boolean,
        callback: (Result<Unit>) -> Unit,
    ) = observedAsync("writeCharacteristic", targetArgs(target) + ("withResponse" to withResponse), callback) {
        inner.writeCharacteristic(target, value, withResponse, it)
    }

    override fun setNotify(target: CharacteristicTargetMessage, enabled: Boolean, callback: (Result<Unit>) -> Unit) =
        observedAsync("setNotify", targetArgs(target) + ("enabled" to enabled), callback) {
            inner.setNotify(target, enabled, it)
        }

    override fun readDescriptor(target: DescriptorTargetMessage, callback: (Result<ByteArray>) -> Unit) =
        observedAsync("readDescriptor", mapOf("deviceId" to target.deviceId, "descriptorUuid" to target.descriptorUuid), callback) {
            inner.readDescriptor(target, it)
        }

    override fun writeDescriptor(target: DescriptorTargetMessage, value: ByteArray, callback: (Result<Unit>) -> Unit) =
        observedAsync("writeDescriptor", mapOf("deviceId" to target.deviceId, "descriptorUuid" to target.descriptorUuid), callback) {
            inner.writeDescriptor(target, value, it)
        }

    override fun requestMtu(deviceId: String, mtu: Long, callback: (Result<Long>) -> Unit) =
        observedAsync("requestMtu", mapOf("deviceId" to deviceId, "mtu" to mtu), callback) {
            inner.requestMtu(deviceId, mtu, it)
        }

    override fun readRssi(deviceId: String, callback: (Result<Long>) -> Unit) =
        observedAsync("readRssi", mapOf("deviceId" to deviceId), callback) { inner.readRssi(deviceId, it) }

    override fun associate(filter: ScanFilterMessage?, callback: (Result<String>) -> Unit) =
        observedAsync("associate", mapOf("names" to filter?.names), callback) { inner.associate(filter, it) }

    override fun setDevicePresenceObservation(deviceId: String, enabled: Boolean) =
        observed("setDevicePresenceObservation", mapOf("deviceId" to deviceId, "enabled" to enabled)) {
            inner.setDevicePresenceObservation(deviceId, enabled)
        }

    override fun dispose() = observed("dispose", emptyMap()) { inner.dispose() }

    private fun targetArgs(target: CharacteristicTargetMessage) = mapOf(
        "deviceId" to target.deviceId,
        "serviceUuid" to target.serviceUuid,
        "characteristicUuid" to target.characteristicUuid,
    )
}
```

- [ ] **Step 6: 保留CompanionイベントのバッファI**

`PendingCompanionEvents.kt` 全文:

```kotlin
package com.example.deepsky_bluetooth_android

/**
 * CompanionDeviceServiceのイベントを、Dart側の準備完了(notifyDartReady)まで
 * バッファするシングルトン。sink接続後は即時配信。
 */
object PendingCompanionEvents {
    private val buffered = mutableListOf<Pair<String, Boolean>>()
    private var sink: ((deviceId: String, appeared: Boolean) -> Unit)? = null

    @Synchronized
    fun emit(deviceId: String, appeared: Boolean) {
        val s = sink
        if (s != null) s(deviceId, appeared) else buffered.add(deviceId to appeared)
    }

    @Synchronized
    fun attachSink(s: (deviceId: String, appeared: Boolean) -> Unit) {
        sink = s
        buffered.forEach { (id, appeared) -> s(id, appeared) }
        buffered.clear()
    }

    @Synchronized
    fun detachSink() {
        sink = null
    }
}
```

- [ ] **Step 7: GATT接続(操作キュー付き)**

`GattConnection.kt` 全文:

```kotlin
package com.example.deepsky_bluetooth_android

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.os.Handler
import android.os.Looper
import java.util.UUID

private val CCCD_UUID: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

sealed class GattOperation {
    abstract fun fail(error: Throwable)

    class ReadCharacteristic(
        val serviceUuid: String, val characteristicUuid: String,
        val callback: (Result<ByteArray>) -> Unit,
    ) : GattOperation() {
        override fun fail(error: Throwable) = callback(Result.failure(error))
    }

    class WriteCharacteristic(
        val serviceUuid: String, val characteristicUuid: String,
        val value: ByteArray, val withResponse: Boolean,
        val callback: (Result<Unit>) -> Unit,
    ) : GattOperation() {
        override fun fail(error: Throwable) = callback(Result.failure(error))
    }

    class SetNotify(
        val serviceUuid: String, val characteristicUuid: String,
        val enabled: Boolean, val callback: (Result<Unit>) -> Unit,
    ) : GattOperation() {
        override fun fail(error: Throwable) = callback(Result.failure(error))
    }

    class ReadDescriptor(
        val serviceUuid: String, val characteristicUuid: String,
        val descriptorUuid: String, val callback: (Result<ByteArray>) -> Unit,
    ) : GattOperation() {
        override fun fail(error: Throwable) = callback(Result.failure(error))
    }

    class WriteDescriptor(
        val serviceUuid: String, val characteristicUuid: String,
        val descriptorUuid: String, val value: ByteArray,
        val callback: (Result<Unit>) -> Unit,
    ) : GattOperation() {
        override fun fail(error: Throwable) = callback(Result.failure(error))
    }

    class RequestMtu(val mtu: Int, val callback: (Result<Long>) -> Unit) : GattOperation() {
        override fun fail(error: Throwable) = callback(Result.failure(error))
    }

    class ReadRssi(val callback: (Result<Long>) -> Unit) : GattOperation() {
        override fun fail(error: Throwable) = callback(Result.failure(error))
    }
}

@SuppressLint("MissingPermission")
class GattConnection(
    private val context: Context,
    private val device: BluetoothDevice,
    private val callbacks: BleCallbacksApi,
    private val observer: () -> DeepskyBluetoothAndroidObserver,
) : BluetoothGattCallback() {
    private val main = Handler(Looper.getMainLooper())
    private var gatt: BluetoothGatt? = null
    private var connectCallback: ((Result<Unit>) -> Unit)? = null
    private var disconnectCallback: ((Result<Unit>) -> Unit)? = null
    private var discoverCallback: ((Result<List<ServiceMessage>>) -> Unit)? = null
    private val operations = ArrayDeque<GattOperation>()
    private var current: GattOperation? = null

    var isConnected = false
        private set

    fun connect(callback: (Result<Unit>) -> Unit) {
        connectCallback = callback
        emitState(ConnectionStateMessage.CONNECTING)
        gatt = device.connectGatt(context, false, this, BluetoothDevice.TRANSPORT_LE)
    }

    fun disconnect(callback: (Result<Unit>) -> Unit) {
        val g = gatt
        if (g == null || !isConnected) {
            callback(Result.failure(bleError(BleErrorCode.NOT_CONNECTED, "Not connected")))
            return
        }
        disconnectCallback = callback
        emitState(ConnectionStateMessage.DISCONNECTING)
        g.disconnect()
    }

    fun discoverServices(callback: (Result<List<ServiceMessage>>) -> Unit) {
        val g = gatt
        if (g == null || !isConnected) {
            callback(Result.failure(bleError(BleErrorCode.NOT_CONNECTED, "Not connected")))
            return
        }
        discoverCallback = callback
        if (!g.discoverServices()) {
            discoverCallback = null
            callback(Result.failure(bleError(BleErrorCode.FAILED, "discoverServices() returned false")))
        }
    }

    fun enqueue(op: GattOperation) {
        main.post {
            if (!isConnected) {
                op.fail(bleError(BleErrorCode.NOT_CONNECTED, "Not connected"))
                return@post
            }
            operations.add(op)
            driveQueue()
        }
    }

    fun close() {
        gatt?.close()
        gatt = null
        isConnected = false
    }

    // --- キュー駆動 ---

    private fun driveQueue() {
        if (current != null) return
        val op = operations.removeFirstOrNull() ?: return
        current = op
        if (!execute(op)) {
            current = null
            op.fail(bleError(BleErrorCode.FAILED, "Failed to start GATT operation"))
            driveQueue()
        }
    }

    private fun abortCurrent(op: GattOperation, code: String, message: String): Boolean {
        current = null
        op.fail(bleError(code, message))
        main.post { driveQueue() }
        return true
    }

    private fun finish(complete: (GattOperation) -> Unit) {
        main.post {
            val op = current ?: return@post
            current = null
            complete(op)
            driveQueue()
        }
    }

    @Suppress("DEPRECATION")
    private fun execute(op: GattOperation): Boolean {
        val g = gatt ?: return false
        return when (op) {
            is GattOperation.ReadCharacteristic -> {
                val ch = findCharacteristic(op.serviceUuid, op.characteristicUuid)
                    ?: return abortCurrent(op, BleErrorCode.NOT_FOUND, "Characteristic not found")
                if (ch.properties and BluetoothGattCharacteristic.PROPERTY_READ == 0)
                    return abortCurrent(op, BleErrorCode.NOT_SUPPORTED, "Read not supported")
                g.readCharacteristic(ch)
            }
            is GattOperation.WriteCharacteristic -> {
                val ch = findCharacteristic(op.serviceUuid, op.characteristicUuid)
                    ?: return abortCurrent(op, BleErrorCode.NOT_FOUND, "Characteristic not found")
                ch.writeType = if (op.withResponse) BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                else BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                ch.value = op.value
                g.writeCharacteristic(ch)
            }
            is GattOperation.SetNotify -> {
                val ch = findCharacteristic(op.serviceUuid, op.characteristicUuid)
                    ?: return abortCurrent(op, BleErrorCode.NOT_FOUND, "Characteristic not found")
                val canSubscribe = ch.properties and
                    (BluetoothGattCharacteristic.PROPERTY_NOTIFY or BluetoothGattCharacteristic.PROPERTY_INDICATE) != 0
                if (!canSubscribe) return abortCurrent(op, BleErrorCode.NOT_SUPPORTED, "Notify/indicate not supported")
                if (!g.setCharacteristicNotification(ch, op.enabled)) return false
                val cccd = ch.getDescriptor(CCCD_UUID)
                    ?: return abortCurrent(op, BleErrorCode.NOT_FOUND, "CCCD descriptor not found")
                val isIndicate = ch.properties and BluetoothGattCharacteristic.PROPERTY_INDICATE != 0
                cccd.value = when {
                    !op.enabled -> BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
                    isIndicate -> BluetoothGattDescriptor.ENABLE_INDICATION_VALUE
                    else -> BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                }
                g.writeDescriptor(cccd)
            }
            is GattOperation.ReadDescriptor -> {
                val d = findDescriptor(op.serviceUuid, op.characteristicUuid, op.descriptorUuid)
                    ?: return abortCurrent(op, BleErrorCode.NOT_FOUND, "Descriptor not found")
                g.readDescriptor(d)
            }
            is GattOperation.WriteDescriptor -> {
                val d = findDescriptor(op.serviceUuid, op.characteristicUuid, op.descriptorUuid)
                    ?: return abortCurrent(op, BleErrorCode.NOT_FOUND, "Descriptor not found")
                d.value = op.value
                g.writeDescriptor(d)
            }
            is GattOperation.RequestMtu -> g.requestMtu(op.mtu)
            is GattOperation.ReadRssi -> g.readRemoteRssi()
        }
    }

    private fun findCharacteristic(serviceUuid: String, characteristicUuid: String): BluetoothGattCharacteristic? =
        gatt?.getService(UUID.fromString(serviceUuid))?.getCharacteristic(UUID.fromString(characteristicUuid))

    private fun findDescriptor(serviceUuid: String, characteristicUuid: String, descriptorUuid: String): BluetoothGattDescriptor? =
        findCharacteristic(serviceUuid, characteristicUuid)?.getDescriptor(UUID.fromString(descriptorUuid))

    private fun failAllPending(error: Throwable) {
        current?.fail(error)
        current = null
        while (operations.isNotEmpty()) operations.removeFirst().fail(error)
        discoverCallback?.invoke(Result.failure(error))
        discoverCallback = null
    }

    private fun emitState(state: ConnectionStateMessage) {
        observer().onCallback("onConnectionStateChanged", "${device.address} ${state.name}")
        callbacks.onConnectionStateChanged(device.address, state) {}
    }

    // --- BluetoothGattCallback ---

    override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
        main.post {
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    isConnected = true
                    connectCallback?.invoke(Result.success(Unit))
                    connectCallback = null
                    emitState(ConnectionStateMessage.CONNECTED)
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    isConnected = false
                    connectCallback?.invoke(
                        Result.failure(bleError(BleErrorCode.FAILED, "Connect failed (status=$status)")))
                    connectCallback = null
                    disconnectCallback?.invoke(Result.success(Unit))
                    disconnectCallback = null
                    failAllPending(bleError(BleErrorCode.NOT_CONNECTED, "Disconnected"))
                    emitState(ConnectionStateMessage.DISCONNECTED)
                    close()
                }
            }
        }
    }

    override fun onServicesDiscovered(g: BluetoothGatt, status: Int) {
        main.post {
            val cb = discoverCallback ?: return@post
            discoverCallback = null
            if (status != BluetoothGatt.GATT_SUCCESS) {
                cb(Result.failure(bleError(BleErrorCode.FAILED, "Service discovery failed (status=$status)")))
            } else {
                cb(Result.success(g.services.map { it.toMessage() }))
            }
        }
    }

    @Deprecated("Deprecated in API 33")
    @Suppress("DEPRECATION")
    override fun onCharacteristicRead(g: BluetoothGatt, ch: BluetoothGattCharacteristic, status: Int) {
        val value = ch.value ?: ByteArray(0)
        finish { op ->
            if (op is GattOperation.ReadCharacteristic) {
                if (status == BluetoothGatt.GATT_SUCCESS) op.callback(Result.success(value))
                else op.fail(bleError(BleErrorCode.FAILED, "Read failed (status=$status)"))
            }
        }
    }

    override fun onCharacteristicWrite(g: BluetoothGatt, ch: BluetoothGattCharacteristic, status: Int) {
        finish { op ->
            if (op is GattOperation.WriteCharacteristic) {
                if (status == BluetoothGatt.GATT_SUCCESS) op.callback(Result.success(Unit))
                else op.fail(bleError(BleErrorCode.FAILED, "Write failed (status=$status)"))
            }
        }
    }

    @Deprecated("Deprecated in API 33")
    @Suppress("DEPRECATION")
    override fun onDescriptorRead(g: BluetoothGatt, d: BluetoothGattDescriptor, status: Int) {
        val value = d.value ?: ByteArray(0)
        finish { op ->
            if (op is GattOperation.ReadDescriptor) {
                if (status == BluetoothGatt.GATT_SUCCESS) op.callback(Result.success(value))
                else op.fail(bleError(BleErrorCode.FAILED, "Descriptor read failed (status=$status)"))
            }
        }
    }

    override fun onDescriptorWrite(g: BluetoothGatt, d: BluetoothGattDescriptor, status: Int) {
        finish { op ->
            val ok = status == BluetoothGatt.GATT_SUCCESS
            when (op) {
                is GattOperation.SetNotify ->
                    if (ok) op.callback(Result.success(Unit))
                    else op.fail(bleError(BleErrorCode.FAILED, "CCCD write failed (status=$status)"))
                is GattOperation.WriteDescriptor ->
                    if (ok) op.callback(Result.success(Unit))
                    else op.fail(bleError(BleErrorCode.FAILED, "Descriptor write failed (status=$status)"))
                else -> Unit
            }
        }
    }

    override fun onMtuChanged(g: BluetoothGatt, mtu: Int, status: Int) {
        finish { op ->
            if (op is GattOperation.RequestMtu) {
                if (status == BluetoothGatt.GATT_SUCCESS) op.callback(Result.success(mtu.toLong()))
                else op.fail(bleError(BleErrorCode.FAILED, "MTU request failed (status=$status)"))
            }
        }
    }

    override fun onReadRemoteRssi(g: BluetoothGatt, rssi: Int, status: Int) {
        finish { op ->
            if (op is GattOperation.ReadRssi) {
                if (status == BluetoothGatt.GATT_SUCCESS) op.callback(Result.success(rssi.toLong()))
                else op.fail(bleError(BleErrorCode.FAILED, "RSSI read failed (status=$status)"))
            }
        }
    }

    @Deprecated("Deprecated in API 33")
    @Suppress("DEPRECATION")
    override fun onCharacteristicChanged(g: BluetoothGatt, ch: BluetoothGattCharacteristic) {
        val value = ch.value ?: ByteArray(0)
        val target = CharacteristicTargetMessage(
            deviceId = device.address,
            serviceUuid = ch.service.uuid.toString(),
            characteristicUuid = ch.uuid.toString(),
        )
        main.post {
            observer().onCallback("onCharacteristicValue", "${target.deviceId}/${target.characteristicUuid}")
            callbacks.onCharacteristicValue(target, value) {}
        }
    }
}

private fun BluetoothGattService.toMessage(): ServiceMessage = ServiceMessage(
    uuid = uuid.toString(),
    characteristics = characteristics.map { c ->
        CharacteristicMessage(
            uuid = c.uuid.toString(),
            canRead = c.properties and BluetoothGattCharacteristic.PROPERTY_READ != 0,
            canWriteWithResponse = c.properties and BluetoothGattCharacteristic.PROPERTY_WRITE != 0,
            canWriteWithoutResponse = c.properties and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE != 0,
            canNotify = c.properties and BluetoothGattCharacteristic.PROPERTY_NOTIFY != 0,
            canIndicate = c.properties and BluetoothGattCharacteristic.PROPERTY_INDICATE != 0,
            descriptors = c.descriptors.map { DescriptorMessage(uuid = it.uuid.toString()) },
        )
    },
)
```

- [ ] **Step 8: BleCentralManager(HostApi本体)**

`BleCentralManager.kt` 全文(`associate` / `setDevicePresenceObservation` / `handleActivityResult` はTask 11で完全実装に置き換える前提の暫定エラー実装):

```kotlin
package com.example.deepsky_bluetooth_android

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid

@SuppressLint("MissingPermission")
class BleCentralManager(
    private val context: Context,
    private val callbacks: BleCallbacksApi,
    private val observer: () -> DeepskyBluetoothAndroidObserver,
) {
    private val main = Handler(Looper.getMainLooper())
    private val adapter: BluetoothAdapter?
        get() = (context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter
    private val connections = mutableMapOf<String, GattConnection>()
    private var scanCallback: ScanCallback? = null
    private var initialized = false

    var activityProvider: () -> Activity? = { null }

    fun initialize(request: InitializeRequestMessage) {
        if (initialized) throw bleError(BleErrorCode.ALREADY_INITIALIZED, "Already initialized")
        if (request.isBackground) {
            when (request.strategy) {
                null -> throw bleError(
                    BleErrorCode.BACKGROUND_CONFIG_MISSING, "Android background strategy is required")
                BackgroundStrategyMessage.FOREGROUND_SERVICE -> {
                    val n = request.notification ?: throw bleError(
                        BleErrorCode.BACKGROUND_CONFIG_MISSING, "Notification config is required")
                    DeepskyForegroundService.start(context, n)
                }
                BackgroundStrategyMessage.COMPANION_DEVICE -> Unit // ServiceはManifest宣言済み
            }
        }
        initialized = true
    }

    fun notifyDartReady() {
        PendingCompanionEvents.attachSink { deviceId, appeared ->
            main.post {
                observer().onCallback(if (appeared) "onDeviceAppeared" else "onDeviceDisappeared", deviceId)
                if (appeared) callbacks.onDeviceAppeared(deviceId) {}
                else callbacks.onDeviceDisappeared(deviceId) {}
            }
        }
    }

    // Androidは全フィルタカテゴリをネイティブのScanFilterで実施する
    // (1エントリ=1 ScanFilter、リスト全体でOR)。
    fun startScan(filter: ScanFilterMessage?, settings: AndroidScanSettingsMessage) {
        if (!hasPermission(Manifest.permission.BLUETOOTH_SCAN))
            throw bleError(BleErrorCode.PERMISSION_DENIED, "BLUETOOTH_SCAN denied")
        val a = adapter ?: throw bleError(BleErrorCode.BLUETOOTH_OFF, "No Bluetooth adapter")
        if (!a.isEnabled) throw bleError(BleErrorCode.BLUETOOTH_OFF, "Bluetooth is off")
        if (scanCallback != null) throw bleError(BleErrorCode.ALREADY_SCANNING, "Scan already running")

        val cb = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                val msg = result.toMessage()
                observer().onCallback("onScanResult", msg.deviceId)
                callbacks.onScanResult(msg) {}
            }

            // reportDelayMillis > 0 の場合はバッチで届く
            override fun onBatchScanResults(results: List<ScanResult>) {
                results.forEach { onScanResult(0, it) }
            }

            override fun onScanFailed(errorCode: Int) {
                scanCallback = null
                observer().onCallback("onScanFailed", errorCode)
                callbacks.onScanFailed(BleErrorCode.FAILED, "Scan failed (errorCode=$errorCode)") {}
            }
        }
        a.bluetoothLeScanner.startScan(filter.toScanFilters(), settings.toScanSettings(), cb)
        scanCallback = cb
    }

    private fun ScanFilterMessage?.toScanFilters(): List<ScanFilter> {
        if (this == null) return emptyList()
        val filters = mutableListOf<ScanFilter>()
        addresses.forEach {
            filters.add(ScanFilter.Builder().setDeviceAddress(it.uppercase()).build())
        }
        names.forEach { filters.add(ScanFilter.Builder().setDeviceName(it).build()) }
        manufacturerData.forEach {
            filters.add(ScanFilter.Builder()
                .setManufacturerData(it.manufacturerId.toInt(), it.data).build())
        }
        serviceData.forEach {
            filters.add(ScanFilter.Builder()
                .setServiceData(ParcelUuid.fromString(it.serviceUuid), it.data).build())
        }
        serviceUuids.forEach {
            filters.add(ScanFilter.Builder().setServiceUuid(ParcelUuid.fromString(it)).build())
        }
        return filters
    }

    private fun AndroidScanSettingsMessage.toScanSettings(): ScanSettings {
        val builder = ScanSettings.Builder()
            .setScanMode(when (mode) {
                ScanModeMessage.LOW_POWER -> ScanSettings.SCAN_MODE_LOW_POWER
                ScanModeMessage.BALANCED -> ScanSettings.SCAN_MODE_BALANCED
                ScanModeMessage.LOW_LATENCY -> ScanSettings.SCAN_MODE_LOW_LATENCY
                ScanModeMessage.OPPORTUNISTIC -> ScanSettings.SCAN_MODE_OPPORTUNISTIC
            })
            .setCallbackType(when (callbackType) {
                ScanCallbackTypeMessage.ALL_MATCHES -> ScanSettings.CALLBACK_TYPE_ALL_MATCHES
                ScanCallbackTypeMessage.FIRST_MATCH -> ScanSettings.CALLBACK_TYPE_FIRST_MATCH
                ScanCallbackTypeMessage.MATCH_LOST -> ScanSettings.CALLBACK_TYPE_MATCH_LOST
                ScanCallbackTypeMessage.FIRST_MATCH_AND_MATCH_LOST ->
                    ScanSettings.CALLBACK_TYPE_FIRST_MATCH or ScanSettings.CALLBACK_TYPE_MATCH_LOST
            })
            .setLegacy(onlyLegacy)
            .setMatchMode(when (matchMode) {
                ScanMatchModeMessage.AGGRESSIVE -> ScanSettings.MATCH_MODE_AGGRESSIVE
                ScanMatchModeMessage.STICKY -> ScanSettings.MATCH_MODE_STICKY
            })
            .setNumOfMatches(when (numOfMatch) {
                ScanNumOfMatchMessage.ONE -> ScanSettings.MATCH_NUM_ONE_ADVERTISEMENT
                ScanNumOfMatchMessage.FEW -> ScanSettings.MATCH_NUM_FEW_ADVERTISEMENT
                ScanNumOfMatchMessage.MAX -> ScanSettings.MATCH_NUM_MAX_ADVERTISEMENT
            })
            .setReportDelay(reportDelayMillis)
        if (!onlyLegacy) {
            builder.setPhy(when (phy) {
                ScanPhyMessage.LE1M -> BluetoothDevice.PHY_LE_1M
                ScanPhyMessage.LE_CODED -> BluetoothDevice.PHY_LE_CODED
                ScanPhyMessage.ALL_SUPPORTED -> ScanSettings.PHY_LE_ALL_SUPPORTED
            })
        }
        return builder.build()
    }

    private fun ScanResult.toMessage(): ScanResultMessage = ScanResultMessage(
        deviceId = device.address,
        name = scanRecord?.deviceName,
        rssi = rssi.toLong(),
        serviceUuids = scanRecord?.serviceUuids?.map { it.toString() } ?: emptyList(),
        manufacturerData = firstManufacturerData(this),
        raw = scanRecord?.bytes,
    )

    fun stopScan() {
        val cb = scanCallback ?: return
        scanCallback = null
        adapter?.bluetoothLeScanner?.stopScan(cb)
    }

    fun connect(deviceId: String, callback: (Result<Unit>) -> Unit) {
        if (!hasPermission(Manifest.permission.BLUETOOTH_CONNECT)) {
            callback(Result.failure(bleError(BleErrorCode.PERMISSION_DENIED, "BLUETOOTH_CONNECT denied")))
            return
        }
        val a = adapter
        if (a == null || !a.isEnabled) {
            callback(Result.failure(bleError(BleErrorCode.BLUETOOTH_OFF, "Bluetooth is off")))
            return
        }
        val device = try {
            a.getRemoteDevice(deviceId)
        } catch (e: IllegalArgumentException) {
            callback(Result.failure(bleError(BleErrorCode.NOT_FOUND, "Invalid device id: $deviceId")))
            return
        }
        val connection = GattConnection(context, device, callbacks, observer)
        connections[deviceId] = connection
        connection.connect(callback)
    }

    fun disconnect(deviceId: String, callback: (Result<Unit>) -> Unit) {
        val c = connections[deviceId]
        if (c == null) {
            callback(Result.failure(bleError(BleErrorCode.NOT_CONNECTED, "Not connected")))
            return
        }
        c.disconnect(callback)
    }

    fun discoverServices(deviceId: String, callback: (Result<List<ServiceMessage>>) -> Unit) {
        connectionOr(deviceId, callback)?.discoverServices(callback)
    }

    fun readCharacteristic(target: CharacteristicTargetMessage, callback: (Result<ByteArray>) -> Unit) {
        connectionOr(target.deviceId, callback)?.enqueue(
            GattOperation.ReadCharacteristic(target.serviceUuid, target.characteristicUuid, callback))
    }

    fun writeCharacteristic(
        target: CharacteristicTargetMessage, value: ByteArray, withResponse: Boolean,
        callback: (Result<Unit>) -> Unit,
    ) {
        connectionOr(target.deviceId, callback)?.enqueue(
            GattOperation.WriteCharacteristic(
                target.serviceUuid, target.characteristicUuid, value, withResponse, callback))
    }

    fun setNotify(target: CharacteristicTargetMessage, enabled: Boolean, callback: (Result<Unit>) -> Unit) {
        connectionOr(target.deviceId, callback)?.enqueue(
            GattOperation.SetNotify(target.serviceUuid, target.characteristicUuid, enabled, callback))
    }

    fun readDescriptor(target: DescriptorTargetMessage, callback: (Result<ByteArray>) -> Unit) {
        connectionOr(target.deviceId, callback)?.enqueue(
            GattOperation.ReadDescriptor(
                target.serviceUuid, target.characteristicUuid, target.descriptorUuid, callback))
    }

    fun writeDescriptor(target: DescriptorTargetMessage, value: ByteArray, callback: (Result<Unit>) -> Unit) {
        connectionOr(target.deviceId, callback)?.enqueue(
            GattOperation.WriteDescriptor(
                target.serviceUuid, target.characteristicUuid, target.descriptorUuid, value, callback))
    }

    fun requestMtu(deviceId: String, mtu: Long, callback: (Result<Long>) -> Unit) {
        connectionOr(deviceId, callback)?.enqueue(GattOperation.RequestMtu(mtu.toInt(), callback))
    }

    fun readRssi(deviceId: String, callback: (Result<Long>) -> Unit) {
        connectionOr(deviceId, callback)?.enqueue(GattOperation.ReadRssi(callback))
    }

    // Task 11で完全実装に置き換える
    fun associate(filter: ScanFilterMessage?, callback: (Result<String>) -> Unit) {
        callback(Result.failure(bleError(BleErrorCode.FAILED, "associate not implemented yet")))
    }

    // Task 11で完全実装に置き換える
    fun setDevicePresenceObservation(deviceId: String, enabled: Boolean) {
        throw bleError(BleErrorCode.FAILED, "presence observation not implemented yet")
    }

    // Task 11で完全実装に置き換える
    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean = false

    /**
     * エンジン破棄時の後始末。このエンジンが持つ接続のみ閉じる。
     * FGSは止めない(ヘッドレス復活後のmain()が再初期化・再接続するため)。
     */
    fun onEngineDetached() {
        stopScan()
        connections.values.forEach { it.close() }
        connections.clear()
        PendingCompanionEvents.detachSink()
    }

    /** 利用者による明示的な破棄。FGSもここでのみ停止する。 */
    fun dispose() {
        onEngineDetached()
        DeepskyForegroundService.stop(context)
        initialized = false
    }

    private fun <T> connectionOr(deviceId: String, callback: (Result<T>) -> Unit): GattConnection? {
        val c = connections[deviceId]
        if (c == null || !c.isConnected) {
            callback(Result.failure(bleError(BleErrorCode.NOT_CONNECTED, "Not connected")))
            return null
        }
        return c
    }

    private fun hasPermission(permission: String): Boolean =
        context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun firstManufacturerData(result: ScanResult): ByteArray? {
        val sparse = result.scanRecord?.manufacturerSpecificData ?: return null
        return if (sparse.size() > 0) sparse.valueAt(0) else null
    }
}
```

(注: `DeepskyForegroundService` 参照はTask 10で作成するため、Task 10完了までコンパイルは通らない。Task 9〜10をまとめてビルド検証する)

- [ ] **Step 9: プラグイン本体を置換**

`DeepskyBluetoothAndroidPlugin.kt` 全文:

```kotlin
package com.example.deepsky_bluetooth_android

import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry

class DeepskyBluetoothAndroidPlugin : FlutterPlugin, ActivityAware,
    PluginRegistry.ActivityResultListener {
    private var central: BleCentralManager? = null
    private var activityBinding: ActivityPluginBinding? = null

    /** Activityにattachされた=UIエンジン。ヘッドレスエンジンでは常にfalse。 */
    private var isUiEngine = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val callbacks = BleCallbacksApi(binding.binaryMessenger)
        val manager = BleCentralManager(binding.applicationContext, callbacks) {
            DeepskyBluetoothAndroidObserverRegistry.observer
        }
        central = manager
        BleHostApi.setUp(
            binding.binaryMessenger,
            ObservingBleHostApi(manager) { DeepskyBluetoothAndroidObserverRegistry.observer },
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        BleHostApi.setUp(binding.binaryMessenger, null)
        // このエンジンが持つGATT接続のclose・sink解除のみ。FGSは止めない
        central?.onEngineDetached()
        central = null
        // FGS稼働中にエンジンが消えた場合(タスクスワイプ除去等)はヘッドレスで復活させる
        HeadlessEngineLauncher.onEngineDetached(
            binding.applicationContext, isHeadless = !isUiEngine)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        isUiEngine = true
        // UIエンジンに一本化: 稼働中のヘッドレスエンジンは破棄する
        HeadlessEngineLauncher.onUiEngineAttached()
        activityBinding = binding
        binding.addActivityResultListener(this)
        central?.activityProvider = { activityBinding?.activity }
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean =
        central?.handleActivityResult(requestCode, resultCode, data) ?: false
}
```

(`HeadlessEngineLauncher` はTask 11で作成。Task 9〜11完了後にビルド検証)

- [ ] **Step 10: テンプレートのネイティブテストを削除してコミット**

```powershell
git rm plugins/deepsky_bluetooth_android/android/src/test/kotlin/com/example/deepsky_bluetooth_android/DeepskyBluetoothAndroidPluginTest.kt
git add plugins/deepsky_bluetooth_android && git commit -m "feat(android): native observer, GATT core, plugin wiring (minSdk 31)"
```

---

### Task 10: Androidネイティブ — Foreground Service

**Files:**
- Create: `.../kotlin/com/example/deepsky_bluetooth_android/DeepskyForegroundService.kt`
- Modify: `plugins/deepsky_bluetooth_android/android/src/main/AndroidManifest.xml`

- [ ] **Step 1: Serviceを実装**

`DeepskyForegroundService.kt` 全文:

```kotlin
package com.example.deepsky_bluetooth_android

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.IBinder

/**
 * BLE接続維持のためにプロセスを生かし続けるだけのService。
 * BLE処理自体はプラグインのBleCentralManagerが担う。
 */
class DeepskyForegroundService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        isRunning = true
        val channelId = intent?.getStringExtra(EXTRA_CHANNEL_ID) ?: "deepsky_bluetooth"
        val channelName = intent?.getStringExtra(EXTRA_CHANNEL_NAME) ?: "Bluetooth"
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: ""
        val text = intent?.getStringExtra(EXTRA_TEXT) ?: ""

        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW))
        val notification = Notification.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(applicationInfo.icon)
            .build()
        startForeground(
            NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
        return START_STICKY
    }

    override fun onDestroy() {
        isRunning = false
        super.onDestroy()
    }

    companion object {
        /** エンジン消失時にヘッドレス復活が必要かの判定に使う。 */
        @Volatile
        var isRunning = false
            private set

        private const val NOTIFICATION_ID = 0x0B1E
        private const val EXTRA_CHANNEL_ID = "channelId"
        private const val EXTRA_CHANNEL_NAME = "channelName"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_TEXT = "text"

        fun start(context: Context, config: NotificationConfigMessage) {
            val intent = Intent(context, DeepskyForegroundService::class.java)
                .putExtra(EXTRA_CHANNEL_ID, config.channelId)
                .putExtra(EXTRA_CHANNEL_NAME, config.channelName)
                .putExtra(EXTRA_TITLE, config.title)
                .putExtra(EXTRA_TEXT, config.text)
            context.startForegroundService(intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, DeepskyForegroundService::class.java))
        }
    }
}
```

- [ ] **Step 2: ManifestにServiceを宣言**

`AndroidManifest.xml` の `</manifest>` 直前に追加:

```xml
    <application>
        <service
            android:name=".DeepskyForegroundService"
            android:exported="false"
            android:foregroundServiceType="connectedDevice" />
    </application>
```

- [ ] **Step 3: コミット**

```powershell
git add plugins/deepsky_bluetooth_android && git commit -m "feat(android): foreground service background strategy"
```

---

### Task 11: Androidネイティブ — CompanionDevice(associate + Service + ヘッドレスエンジン)

**Files:**
- Create: `.../kotlin/com/example/deepsky_bluetooth_android/HeadlessEngineLauncher.kt`
- Create: `.../DeepskyCompanionDeviceService.kt`
- Modify: `.../BleCentralManager.kt`(Task 9の暫定実装3メソッドを置換)
- Modify: `plugins/deepsky_bluetooth_android/android/src/main/AndroidManifest.xml`

- [ ] **Step 1: ヘッドレスエンジン起動**

`HeadlessEngineLauncher.kt` 全文:

```kotlin
package com.example.deepsky_bluetooth_android

import android.content.Context
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * エンジン不在時にアプリの main() をヘッドレスFlutterEngineで実行して
 * Dartコールバックを復活させる(iOSのState Restorationリランチと対称の挙動)。
 *
 * 発火点は2つ:
 * - CompanionDeviceServiceのデバイスイベント時(プロセス死後のシステム起動)
 * - Foreground Service稼働中のエンジン消失時(タスクスワイプ除去等)
 *
 * UIエンジンがActivityにattachしたらヘッドレスは破棄し、常に1エンジンへ収束させる。
 */
object HeadlessEngineLauncher {
    @Volatile
    private var hasUiEngine = false

    private var headlessEngine: FlutterEngine? = null

    @Synchronized
    fun ensureEngine(context: Context) {
        if (hasUiEngine || headlessEngine != null) return
        val loader = FlutterInjector.instance().flutterLoader()
        if (!loader.initialized()) {
            loader.startInitialization(context.applicationContext)
            loader.ensureInitializationComplete(context.applicationContext, null)
        }
        val engine = FlutterEngine(context.applicationContext)
        engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        headlessEngine = engine
    }

    /** UIエンジンがActivityにattachされた。ヘッドレスを破棄して一本化する。 */
    @Synchronized
    fun onUiEngineAttached() {
        hasUiEngine = true
        headlessEngine?.destroy()
        headlessEngine = null
    }

    /**
     * エンジン消失時。UIエンジン消失かつFGS稼働中ならヘッドレスで復活させる。
     * (ヘッドレス自身の破棄では何もしない)
     */
    @Synchronized
    fun onEngineDetached(context: Context, isHeadless: Boolean) {
        if (isHeadless) {
            headlessEngine = null
            return
        }
        hasUiEngine = false
        if (DeepskyForegroundService.isRunning) ensureEngine(context)
    }
}
```

- [ ] **Step 2: CompanionDeviceService**

`DeepskyCompanionDeviceService.kt` 全文:

```kotlin
package com.example.deepsky_bluetooth_android

import android.companion.CompanionDeviceService

class DeepskyCompanionDeviceService : CompanionDeviceService() {
    @Deprecated("Deprecated in API 33")
    override fun onDeviceAppeared(address: String) {
        HeadlessEngineLauncher.ensureEngine(applicationContext)
        DeepskyBluetoothAndroidObserverRegistry.observer.onCallback("cds.onDeviceAppeared", address)
        PendingCompanionEvents.emit(address, true)
    }

    @Deprecated("Deprecated in API 33")
    override fun onDeviceDisappeared(address: String) {
        HeadlessEngineLauncher.ensureEngine(applicationContext)
        DeepskyBluetoothAndroidObserverRegistry.observer.onCallback("cds.onDeviceDisappeared", address)
        PendingCompanionEvents.emit(address, false)
    }
}
```

- [ ] **Step 3: ManifestにCDSを宣言**

`AndroidManifest.xml` の `<application>` 内に追加:

```xml
        <service
            android:name=".DeepskyCompanionDeviceService"
            android:exported="true"
            android:permission="android.permission.BIND_COMPANION_DEVICE_SERVICE">
            <intent-filter>
                <action android:name="android.companion.CompanionDeviceService" />
            </intent-filter>
        </service>
```

- [ ] **Step 4: BleCentralManagerの暫定3メソッドを完全実装に置換**

Task 9の `associate` / `setDevicePresenceObservation` / `handleActivityResult` を以下に置き換え、importに `android.bluetooth.BluetoothDevice` / `android.bluetooth.le.BluetoothLeDeviceFilter`(正しくは `android.companion.BluetoothLeDeviceFilter`)/ `android.companion.AssociationRequest` / `android.companion.CompanionDeviceManager` / `android.companion.DeviceNotAssociatedException` / `android.content.IntentSender` / `android.os.Parcelable` / `java.util.regex.Pattern` を追加:

```kotlin
    private var pendingAssociateCallback: ((Result<String>) -> Unit)? = null

    fun associate(filter: ScanFilterMessage?, callback: (Result<String>) -> Unit) {
        val activity = activityProvider()
        if (activity == null) {
            callback(Result.failure(bleError(BleErrorCode.FAILED, "associate() requires a foreground activity")))
            return
        }
        if (pendingAssociateCallback != null) {
            callback(Result.failure(bleError(BleErrorCode.FAILED, "Another association is in progress")))
            return
        }
        val cdm = context.getSystemService(Context.COMPANION_DEVICE_SERVICE) as CompanionDeviceManager
        // CDMのデバイスフィルタはname/serviceUuidの先頭エントリのみ使用(platform.dartのdoc参照)
        val filterBuilder = android.companion.BluetoothLeDeviceFilter.Builder()
        filter?.names?.firstOrNull()?.let {
            filterBuilder.setNamePattern(Pattern.compile(Pattern.quote(it)))
        }
        filter?.serviceUuids?.firstOrNull()?.let {
            filterBuilder.setScanFilter(
                ScanFilter.Builder().setServiceUuid(ParcelUuid.fromString(it)).build())
        }
        val request = AssociationRequest.Builder()
            .addDeviceFilter(filterBuilder.build())
            .build()
        pendingAssociateCallback = callback
        @Suppress("DEPRECATION")
        cdm.associate(request, object : CompanionDeviceManager.Callback() {
            @Deprecated("Deprecated in API 33")
            override fun onDeviceFound(chooserLauncher: IntentSender) {
                activity.startIntentSenderForResult(chooserLauncher, ASSOCIATE_REQUEST_CODE, null, 0, 0, 0)
            }

            override fun onFailure(error: CharSequence?) {
                pendingAssociateCallback?.invoke(
                    Result.failure(bleError(BleErrorCode.FAILED, error?.toString() ?: "Association failed")))
                pendingAssociateCallback = null
            }
        }, main)
    }

    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != ASSOCIATE_REQUEST_CODE) return false
        val cb = pendingAssociateCallback ?: return true
        pendingAssociateCallback = null
        if (resultCode != Activity.RESULT_OK) {
            cb(Result.failure(bleError(BleErrorCode.REJECTED, "Association cancelled by user")))
            return true
        }
        @Suppress("DEPRECATION")
        val parcelable = data?.getParcelableExtra<Parcelable>(CompanionDeviceManager.EXTRA_DEVICE)
        val address = when (parcelable) {
            is ScanResult -> parcelable.device.address
            is BluetoothDevice -> parcelable.address
            else -> null
        }
        if (address == null) {
            cb(Result.failure(bleError(BleErrorCode.FAILED, "No device in association result")))
        } else {
            cb(Result.success(address))
        }
        return true
    }

    fun setDevicePresenceObservation(deviceId: String, enabled: Boolean) {
        val cdm = context.getSystemService(Context.COMPANION_DEVICE_SERVICE) as CompanionDeviceManager
        try {
            @Suppress("DEPRECATION")
            if (enabled) cdm.startObservingDevicePresence(deviceId)
            else cdm.stopObservingDevicePresence(deviceId)
        } catch (e: DeviceNotAssociatedException) {
            throw bleError(BleErrorCode.NOT_ASSOCIATED, "Device $deviceId is not associated")
        }
    }
```

クラス末尾のcompanionも追加:

```kotlin
    private companion object {
        const val ASSOCIATE_REQUEST_CODE = 0x0A55
    }
```

- [ ] **Step 5: Androidビルド検証(Task 9〜11一括)**

Run: `plugins/deepsky_bluetooth_android/example` で `flutter build apk --debug`
Expected: BUILD SUCCESSFUL。Kotlinコンパイルエラーが出た場合はここで修正する

- [ ] **Step 6: コミット**

```powershell
git add plugins/deepsky_bluetooth_android && git commit -m "feat(android): companion device association, service, headless engine relaunch"
```

---

### Task 12: iOSネイティブ — CoreBluetooth + State Restoration + Observer

**Files:**
- Create: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/DeepskyBluetoothIosObserver.swift`
- Create: `.../BleCentralController.swift`
- Create: `.../ObservingBleHostApi.swift`
- Modify: `.../DeepskyBluetoothIosPlugin.swift`(テンプレート全置換)

注: Pigeon Swiftでは `Uint8List` は `FlutterStandardTypedData`、エラーは生成済みの `PigeonError`、非同期メソッドは `completion: (Result<T, Error>) -> Void`(=Swift.Result)。deviceIdはiOSでは `CBPeripheral.identifier.uuidString` の小文字(MACではない)。

- [ ] **Step 1: ネイティブObserver**

`DeepskyBluetoothIosObserver.swift` 全文:

```swift
import Foundation
import os

public protocol DeepskyBluetoothIosObserver {
    func onMethodStart(_ method: String, _ arguments: [String: Any?])
    func onMethodEnd(_ method: String, _ error: Error?)
    func onCallback(_ callback: String, _ payload: Any?)
}

public final class OsLogObserver: DeepskyBluetoothIosObserver {
    private let logger = Logger(subsystem: "deepsky_bluetooth", category: "ble")
    public init() {}

    public func onMethodStart(_ method: String, _ arguments: [String: Any?]) {
        logger.debug("start \(method, privacy: .public) \(String(describing: arguments), privacy: .public)")
    }

    public func onMethodEnd(_ method: String, _ error: Error?) {
        logger.debug("end \(method, privacy: .public) error=\(String(describing: error), privacy: .public)")
    }

    public func onCallback(_ callback: String, _ payload: Any?) {
        logger.debug("callback \(callback, privacy: .public) \(String(describing: payload), privacy: .public)")
    }
}

/// ホストアプリのネイティブコードから差し替え可能なレジストリ。
public enum DeepskyBluetoothIosObserverRegistry {
    public static var observer: DeepskyBluetoothIosObserver = OsLogObserver()
}
```

- [ ] **Step 2: BleCentralController**

`BleCentralController.swift` 全文:

```swift
import CoreBluetooth
import Flutter

enum BleErrorCode {
    static let permissionDenied = "permissionDenied"
    static let bluetoothOff = "bluetoothOff"
    static let alreadyScanning = "alreadyScanning"
    static let notFound = "notFound"
    static let notConnected = "notConnected"
    static let notSupported = "notSupported"
    static let alreadyInitialized = "alreadyInitialized"
    static let backgroundConfigMissing = "backgroundConfigMissing"
    static let failed = "failed"
}

func bleError(_ code: String, _ message: String) -> PigeonError {
    PigeonError(code: code, message: message, details: nil)
}

/// CBUUIDの16/32bit短縮形を128bit完全形式(小文字)へ展開する。
func fullUuid(_ uuid: CBUUID) -> String {
    let s = uuid.uuidString.lowercased()
    switch s.count {
    case 4: return "0000\(s)-0000-1000-8000-00805f9b34fb"
    case 8: return "\(s)-0000-1000-8000-00805f9b34fb"
    default: return s
    }
}

final class BleCentralController: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private let callbacks: BleCallbacksApi
    private var observer: DeepskyBluetoothIosObserver { DeepskyBluetoothIosObserverRegistry.observer }

    private var central: CBCentralManager?
    private var initialized = false
    private var activeFilter: ScanFilterMessage?
    private var peripherals: [String: CBPeripheral] = [:]

    private var connectCompletions: [String: (Result<Void, Error>) -> Void] = [:]
    private var disconnectCompletions: [String: (Result<Void, Error>) -> Void] = [:]
    private var discoverCompletions: [String: (Result<[ServiceMessage], Error>) -> Void] = [:]
    private var pendingDiscovery: [String: Int] = [:]
    private var readCompletions: [String: (Result<FlutterStandardTypedData, Error>) -> Void] = [:]
    private var writeCompletions: [String: (Result<Void, Error>) -> Void] = [:]
    private var notifyCompletions: [String: (Result<Void, Error>) -> Void] = [:]
    private var descriptorReadCompletions: [String: (Result<FlutterStandardTypedData, Error>) -> Void] = [:]
    private var descriptorWriteCompletions: [String: (Result<Void, Error>) -> Void] = [:]
    private var rssiCompletions: [String: (Result<Int64, Error>) -> Void] = [:]
    private var restoredDeviceIds: [String] = []

    init(callbacks: BleCallbacksApi) {
        self.callbacks = callbacks
        super.init()
    }

    // MARK: - HostApi実装(ObservingBleHostApi経由で呼ばれる)

    func initialize(request: InitializeRequestMessage) throws {
        if initialized { throw bleError(BleErrorCode.alreadyInitialized, "Already initialized") }
        var options: [String: Any] = [:]
        if request.isBackground {
            guard let restoreId = request.restoreIdentifier else {
                throw bleError(BleErrorCode.backgroundConfigMissing,
                               "restoreIdentifier is required for background mode")
            }
            options[CBCentralManagerOptionRestoreIdentifierKey] = restoreId
        }
        central = CBCentralManager(delegate: self, queue: .main, options: options)
        initialized = true
    }

    func notifyDartReady() throws {
        if !restoredDeviceIds.isEmpty {
            observer.onCallback("onStateRestored", restoredDeviceIds)
            callbacks.onStateRestored(connectedDeviceIds: restoredDeviceIds) { _ in }
            restoredDeviceIds = []
        }
    }

    func startScan(filter: ScanFilterMessage?, settings: DarwinScanSettingsMessage) throws {
        guard let central else { throw bleError(BleErrorCode.failed, "Not initialized") }
        guard central.state == .poweredOn else {
            let code = central.state == .unauthorized
                ? BleErrorCode.permissionDenied : BleErrorCode.bluetoothOff
            throw bleError(code, "Central state is \(central.state.rawValue)")
        }
        if central.isScanning { throw bleError(BleErrorCode.alreadyScanning, "Scan already running") }
        activeFilter = filter
        // serviceUuidのみ指定された場合はネイティブフィルタ(バックグラウンドスキャン対応)。
        // 他カテゴリ併用時はOR意味論を保つため全件受信し、didDiscover内のソフトウェア
        // フィルタで判定する(CoreBluetoothはserviceUuid以外のフィルタ非対応)。
        var services: [CBUUID]? = nil
        if let f = filter, f.isServiceUuidsOnly {
            services = f.serviceUuids.map { CBUUID(string: $0) }
        }
        var options: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: settings.allowDuplicates,
        ]
        if !settings.solicitedServiceUuids.isEmpty {
            options[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] =
                settings.solicitedServiceUuids.map { CBUUID(string: $0) }
        }
        central.scanForPeripherals(withServices: services, options: options)
    }

    func stopScan() throws {
        central?.stopScan()
        activeFilter = nil
    }

    func connect(deviceId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let central else {
            return completion(.failure(bleError(BleErrorCode.failed, "Not initialized")))
        }
        guard let p = peripherals[deviceId] ?? retrievePeripheral(deviceId) else {
            return completion(.failure(bleError(BleErrorCode.notFound, "Unknown device \(deviceId)")))
        }
        p.delegate = self
        connectCompletions[deviceId] = completion
        emitState(deviceId, .connecting)
        central.connect(p)
    }

    func disconnect(deviceId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let central, let p = peripherals[deviceId], p.state == .connected else {
            return completion(.failure(bleError(BleErrorCode.notConnected, "Not connected")))
        }
        disconnectCompletions[deviceId] = completion
        emitState(deviceId, .disconnecting)
        central.cancelPeripheralConnection(p)
    }

    func discoverServices(deviceId: String,
                          completion: @escaping (Result<[ServiceMessage], Error>) -> Void) {
        guard let p = connectedPeripheral(deviceId) else {
            return completion(.failure(bleError(BleErrorCode.notConnected, "Not connected")))
        }
        discoverCompletions[deviceId] = completion
        p.discoverServices(nil)
    }

    func readCharacteristic(target: CharacteristicTargetMessage,
                            completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void) {
        switch findCharacteristic(target) {
        case .failure(let e): completion(.failure(e))
        case .success(let (p, ch)):
            guard ch.properties.contains(.read) else {
                return completion(.failure(bleError(BleErrorCode.notSupported, "Read not supported")))
            }
            readCompletions[charKey(target)] = completion
            p.readValue(for: ch)
        }
    }

    func writeCharacteristic(target: CharacteristicTargetMessage, value: FlutterStandardTypedData,
                             withResponse: Bool,
                             completion: @escaping (Result<Void, Error>) -> Void) {
        switch findCharacteristic(target) {
        case .failure(let e): completion(.failure(e))
        case .success(let (p, ch)):
            if withResponse {
                writeCompletions[charKey(target)] = completion
                p.writeValue(value.data, for: ch, type: .withResponse)
            } else {
                p.writeValue(value.data, for: ch, type: .withoutResponse)
                completion(.success(()))
            }
        }
    }

    func setNotify(target: CharacteristicTargetMessage, enabled: Bool,
                   completion: @escaping (Result<Void, Error>) -> Void) {
        switch findCharacteristic(target) {
        case .failure(let e): completion(.failure(e))
        case .success(let (p, ch)):
            guard ch.properties.contains(.notify) || ch.properties.contains(.indicate) else {
                return completion(.failure(bleError(BleErrorCode.notSupported, "Notify not supported")))
            }
            notifyCompletions[charKey(target)] = completion
            p.setNotifyValue(enabled, for: ch)
        }
    }

    func readDescriptor(target: DescriptorTargetMessage,
                        completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void) {
        switch findDescriptor(target) {
        case .failure(let e): completion(.failure(e))
        case .success(let (p, d)):
            descriptorReadCompletions[descriptorKey(target)] = completion
            p.readValue(for: d)
        }
    }

    func writeDescriptor(target: DescriptorTargetMessage, value: FlutterStandardTypedData,
                         completion: @escaping (Result<Void, Error>) -> Void) {
        switch findDescriptor(target) {
        case .failure(let e): completion(.failure(e))
        case .success(let (p, d)):
            descriptorWriteCompletions[descriptorKey(target)] = completion
            p.writeValue(value.data, for: d)
        }
    }

    func getMtu(deviceId: String, completion: @escaping (Result<Int64, Error>) -> Void) {
        guard let p = connectedPeripheral(deviceId) else {
            return completion(.failure(bleError(BleErrorCode.notConnected, "Not connected")))
        }
        completion(.success(Int64(p.maximumWriteValueLength(for: .withoutResponse)) + 3))
    }

    func readRssi(deviceId: String, completion: @escaping (Result<Int64, Error>) -> Void) {
        guard let p = connectedPeripheral(deviceId) else {
            return completion(.failure(bleError(BleErrorCode.notConnected, "Not connected")))
        }
        rssiCompletions[deviceId] = completion
        p.readRSSI()
    }

    func dispose() throws {
        central?.stopScan()
        for (_, p) in peripherals where p.state == .connected || p.state == .connecting {
            central?.cancelPeripheralConnection(p)
        }
        peripherals.removeAll()
        central = nil
        initialized = false
    }

    // MARK: - ヘルパー

    private func retrievePeripheral(_ deviceId: String) -> CBPeripheral? {
        guard let central, let uuid = UUID(uuidString: deviceId) else { return nil }
        guard let found = central.retrievePeripherals(withIdentifiers: [uuid]).first else { return nil }
        peripherals[deviceId] = found
        return found
    }

    private func connectedPeripheral(_ deviceId: String) -> CBPeripheral? {
        guard let p = peripherals[deviceId], p.state == .connected else { return nil }
        return p
    }

    private func findCharacteristic(_ target: CharacteristicTargetMessage)
        -> Result<(CBPeripheral, CBCharacteristic), Error> {
        guard let p = connectedPeripheral(target.deviceId) else {
            return .failure(bleError(BleErrorCode.notConnected, "Not connected"))
        }
        for s in p.services ?? [] where fullUuid(s.uuid) == target.serviceUuid {
            for c in s.characteristics ?? [] where fullUuid(c.uuid) == target.characteristicUuid {
                return .success((p, c))
            }
        }
        return .failure(bleError(BleErrorCode.notFound, "Characteristic not found"))
    }

    private func findDescriptor(_ target: DescriptorTargetMessage)
        -> Result<(CBPeripheral, CBDescriptor), Error> {
        let charTarget = CharacteristicTargetMessage(
            deviceId: target.deviceId, serviceUuid: target.serviceUuid,
            characteristicUuid: target.characteristicUuid)
        switch findCharacteristic(charTarget) {
        case .failure(let e): return .failure(e)
        case .success(let (p, ch)):
            for d in ch.descriptors ?? [] where fullUuid(d.uuid) == target.descriptorUuid {
                return .success((p, d))
            }
            return .failure(bleError(BleErrorCode.notFound, "Descriptor not found"))
        }
    }

    private func charKey(_ t: CharacteristicTargetMessage) -> String {
        "\(t.deviceId)|\(t.serviceUuid)|\(t.characteristicUuid)"
    }

    private func charKey(_ p: CBPeripheral, _ c: CBCharacteristic) -> String {
        let deviceId = p.identifier.uuidString.lowercased()
        let serviceUuid = c.service.map { fullUuid($0.uuid) } ?? ""
        return "\(deviceId)|\(serviceUuid)|\(fullUuid(c.uuid))"
    }

    private func descriptorKey(_ t: DescriptorTargetMessage) -> String {
        "\(t.deviceId)|\(t.serviceUuid)|\(t.characteristicUuid)|\(t.descriptorUuid)"
    }

    private func descriptorKey(_ p: CBPeripheral, _ d: CBDescriptor) -> String {
        guard let c = d.characteristic else { return "" }
        let charTarget = charKey(p, c)
        return "\(charTarget)|\(fullUuid(d.uuid))"
    }

    private func emitState(_ deviceId: String, _ state: ConnectionStateMessage) {
        observer.onCallback("onConnectionStateChanged", "\(deviceId) \(state)")
        callbacks.onConnectionStateChanged(deviceId: deviceId, state: state) { _ in }
    }

    private func serviceMessage(_ s: CBService) -> ServiceMessage {
        ServiceMessage(
            uuid: fullUuid(s.uuid),
            characteristics: (s.characteristics ?? []).map { c in
                CharacteristicMessage(
                    uuid: fullUuid(c.uuid),
                    canRead: c.properties.contains(.read),
                    canWriteWithResponse: c.properties.contains(.write),
                    canWriteWithoutResponse: c.properties.contains(.writeWithoutResponse),
                    canNotify: c.properties.contains(.notify),
                    canIndicate: c.properties.contains(.indicate),
                    descriptors: (c.descriptors ?? []).map { DescriptorMessage(uuid: fullUuid($0.uuid)) }
                )
            })
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        observer.onCallback("centralManagerDidUpdateState", central.state.rawValue)
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        guard let restored = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] else { return }
        for p in restored {
            p.delegate = self
            peripherals[p.identifier.uuidString.lowercased()] = p
        }
        restoredDeviceIds = restored.filter { $0.state == .connected }
            .map { $0.identifier.uuidString.lowercased() }
        observer.onCallback("willRestoreState", restoredDeviceIds)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let f = activeFilter,
           !f.matches(peripheral: peripheral, advertisementData: advertisementData) { return }
        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? peripheral.name
        let deviceId = peripheral.identifier.uuidString.lowercased()
        peripherals[deviceId] = peripheral
        let serviceUuids = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?
            .map(fullUuid) ?? []
        let mfg = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        let msg = ScanResultMessage(
            deviceId: deviceId, name: name, rssi: RSSI.int64Value, serviceUuids: serviceUuids,
            manufacturerData: mfg.map { FlutterStandardTypedData(bytes: $0) },
            raw: nil)  // CoreBluetoothは広告の生バイト列を公開しない
        observer.onCallback("onScanResult", deviceId)
        callbacks.onScanResult(result: msg) { _ in }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let deviceId = peripheral.identifier.uuidString.lowercased()
        connectCompletions.removeValue(forKey: deviceId)?(.success(()))
        emitState(deviceId, .connected)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        let deviceId = peripheral.identifier.uuidString.lowercased()
        connectCompletions.removeValue(forKey: deviceId)?(
            .failure(bleError(BleErrorCode.failed, error?.localizedDescription ?? "Connect failed")))
        emitState(deviceId, .disconnected)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        let deviceId = peripheral.identifier.uuidString.lowercased()
        disconnectCompletions.removeValue(forKey: deviceId)?(.success(()))
        emitState(deviceId, .disconnected)
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let deviceId = peripheral.identifier.uuidString.lowercased()
        guard discoverCompletions[deviceId] != nil else { return }
        if let error {
            discoverCompletions.removeValue(forKey: deviceId)?(
                .failure(bleError(BleErrorCode.failed, error.localizedDescription)))
            return
        }
        let services = peripheral.services ?? []
        if services.isEmpty {
            discoverCompletions.removeValue(forKey: deviceId)?(.success([]))
            return
        }
        pendingDiscovery[deviceId] = services.count
        services.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let deviceId = peripheral.identifier.uuidString.lowercased()
        guard discoverCompletions[deviceId] != nil else { return }
        let chars = service.characteristics ?? []
        pendingDiscovery[deviceId, default: 0] += chars.count - 1
        chars.forEach { peripheral.discoverDescriptors(for: $0) }
        finishDiscoveryIfDone(peripheral, deviceId)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        let deviceId = peripheral.identifier.uuidString.lowercased()
        pendingDiscovery[deviceId, default: 0] -= 1
        finishDiscoveryIfDone(peripheral, deviceId)
    }

    private func finishDiscoveryIfDone(_ peripheral: CBPeripheral, _ deviceId: String) {
        guard pendingDiscovery[deviceId] == 0,
              let completion = discoverCompletions[deviceId] else { return }
        discoverCompletions[deviceId] = nil
        pendingDiscovery[deviceId] = nil
        completion(.success((peripheral.services ?? []).map { serviceMessage($0) }))
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let key = charKey(peripheral, characteristic)
        let data = characteristic.value ?? Data()
        if let completion = readCompletions.removeValue(forKey: key) {
            if let error {
                completion(.failure(bleError(BleErrorCode.failed, error.localizedDescription)))
            } else {
                completion(.success(FlutterStandardTypedData(bytes: data)))
            }
            return
        }
        // 保留中のreadがなければNotify/Indicateによる値更新
        guard error == nil, let c = characteristic.service else { return }
        let target = CharacteristicTargetMessage(
            deviceId: peripheral.identifier.uuidString.lowercased(),
            serviceUuid: fullUuid(c.uuid),
            characteristicUuid: fullUuid(characteristic.uuid))
        observer.onCallback("onCharacteristicValue", key)
        callbacks.onCharacteristicValue(target: target, value: FlutterStandardTypedData(bytes: data)) { _ in }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let key = charKey(peripheral, characteristic)
        guard let completion = writeCompletions.removeValue(forKey: key) else { return }
        if let error {
            completion(.failure(bleError(BleErrorCode.failed, error.localizedDescription)))
        } else {
            completion(.success(()))
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        let key = charKey(peripheral, characteristic)
        guard let completion = notifyCompletions.removeValue(forKey: key) else { return }
        if let error {
            completion(.failure(bleError(BleErrorCode.failed, error.localizedDescription)))
        } else {
            completion(.success(()))
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        let key = descriptorKey(peripheral, descriptor)
        guard let completion = descriptorReadCompletions.removeValue(forKey: key) else { return }
        if let error {
            completion(.failure(bleError(BleErrorCode.failed, error.localizedDescription)))
            return
        }
        // ディスクリプタ値はAny?のためDataのみ対応(他型は空データ)
        let data = descriptor.value as? Data ?? Data()
        completion(.success(FlutterStandardTypedData(bytes: data)))
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        let key = descriptorKey(peripheral, descriptor)
        guard let completion = descriptorWriteCompletions.removeValue(forKey: key) else { return }
        if let error {
            completion(.failure(bleError(BleErrorCode.failed, error.localizedDescription)))
        } else {
            completion(.success(()))
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        let deviceId = peripheral.identifier.uuidString.lowercased()
        guard let completion = rssiCompletions.removeValue(forKey: deviceId) else { return }
        if let error {
            completion(.failure(bleError(BleErrorCode.failed, error.localizedDescription)))
        } else {
            completion(.success(RSSI.int64Value))
        }
    }
}

/// CoreBluetoothがネイティブ対応しないフィルタカテゴリのソフトウェア判定。
/// 各エントリはOR条件(Androidのフィルタ意味論と一致させる)。
extension ScanFilterMessage {
    var isServiceUuidsOnly: Bool {
        addresses.isEmpty && names.isEmpty && manufacturerData.isEmpty
            && serviceData.isEmpty && !serviceUuids.isEmpty
    }

    func matches(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool {
        if addresses.isEmpty && names.isEmpty && manufacturerData.isEmpty
            && serviceData.isEmpty && serviceUuids.isEmpty {
            return true  // フィルタなし
        }
        let deviceId = peripheral.identifier.uuidString.lowercased()
        if addresses.contains(where: { $0.lowercased() == deviceId }) { return true }

        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? peripheral.name
        if let name, names.contains(name) { return true }

        // manufacturer data: 先頭2byteがリトルエンディアンのCompany ID、以降が前方一致
        if let mfg = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
           mfg.count >= 2 {
            let companyId = Int64(mfg[mfg.startIndex]) | (Int64(mfg[mfg.startIndex + 1]) << 8)
            let payload = mfg.dropFirst(2)
            if manufacturerData.contains(where: {
                $0.manufacturerId == companyId && payload.starts(with: $0.data.data)
            }) { return true }
        }

        if let serviceDataDict =
            advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] {
            if serviceData.contains(where: { f in
                serviceDataDict.contains {
                    fullUuid($0.key) == f.serviceUuid && $0.value.starts(with: f.data.data)
                }
            }) { return true }
        }

        let advertised = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?
            .map(fullUuid) ?? []
        if serviceUuids.contains(where: advertised.contains) { return true }
        return false
    }
}
```

- [ ] **Step 3: Observerデコレータ(BleHostApi実装)**

`ObservingBleHostApi.swift` 全文:

```swift
import Flutter

final class ObservingBleHostApi: BleHostApi {
    private let inner: BleCentralController
    private var observer: DeepskyBluetoothIosObserver { DeepskyBluetoothIosObserverRegistry.observer }

    init(_ inner: BleCentralController) {
        self.inner = inner
    }

    private func observed<T>(_ name: String, _ args: [String: Any?],
                             _ body: () throws -> T) throws -> T {
        observer.onMethodStart(name, args)
        do {
            let r = try body()
            observer.onMethodEnd(name, nil)
            return r
        } catch {
            observer.onMethodEnd(name, error)
            throw error
        }
    }

    private func observedAsync<T>(_ name: String, _ args: [String: Any?],
                                  _ completion: @escaping (Result<T, Error>) -> Void,
                                  _ body: (@escaping (Result<T, Error>) -> Void) -> Void) {
        observer.onMethodStart(name, args)
        body { r in
            if case .failure(let e) = r {
                self.observer.onMethodEnd(name, e)
            } else {
                self.observer.onMethodEnd(name, nil)
            }
            completion(r)
        }
    }

    func initialize(request: InitializeRequestMessage) throws {
        try observed("initialize", ["isBackground": request.isBackground]) {
            try inner.initialize(request: request)
        }
    }

    func notifyDartReady() throws {
        try observed("notifyDartReady", [:]) { try inner.notifyDartReady() }
    }

    func startScan(filter: ScanFilterMessage?, settings: DarwinScanSettingsMessage) throws {
        try observed("startScan", [
            "serviceUuids": filter?.serviceUuids,
            "allowDuplicates": settings.allowDuplicates,
        ]) {
            try inner.startScan(filter: filter, settings: settings)
        }
    }

    func stopScan() throws {
        try observed("stopScan", [:]) { try inner.stopScan() }
    }

    func connect(deviceId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        observedAsync("connect", ["deviceId": deviceId], completion) {
            inner.connect(deviceId: deviceId, completion: $0)
        }
    }

    func disconnect(deviceId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        observedAsync("disconnect", ["deviceId": deviceId], completion) {
            inner.disconnect(deviceId: deviceId, completion: $0)
        }
    }

    func discoverServices(deviceId: String,
                          completion: @escaping (Result<[ServiceMessage], Error>) -> Void) {
        observedAsync("discoverServices", ["deviceId": deviceId], completion) {
            inner.discoverServices(deviceId: deviceId, completion: $0)
        }
    }

    func readCharacteristic(target: CharacteristicTargetMessage,
                            completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void) {
        observedAsync("readCharacteristic", ["characteristicUuid": target.characteristicUuid], completion) {
            inner.readCharacteristic(target: target, completion: $0)
        }
    }

    func writeCharacteristic(target: CharacteristicTargetMessage, value: FlutterStandardTypedData,
                             withResponse: Bool,
                             completion: @escaping (Result<Void, Error>) -> Void) {
        observedAsync("writeCharacteristic",
                      ["characteristicUuid": target.characteristicUuid, "withResponse": withResponse],
                      completion) {
            inner.writeCharacteristic(target: target, value: value, withResponse: withResponse, completion: $0)
        }
    }

    func setNotify(target: CharacteristicTargetMessage, enabled: Bool,
                   completion: @escaping (Result<Void, Error>) -> Void) {
        observedAsync("setNotify",
                      ["characteristicUuid": target.characteristicUuid, "enabled": enabled], completion) {
            inner.setNotify(target: target, enabled: enabled, completion: $0)
        }
    }

    func readDescriptor(target: DescriptorTargetMessage,
                        completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void) {
        observedAsync("readDescriptor", ["descriptorUuid": target.descriptorUuid], completion) {
            inner.readDescriptor(target: target, completion: $0)
        }
    }

    func writeDescriptor(target: DescriptorTargetMessage, value: FlutterStandardTypedData,
                         completion: @escaping (Result<Void, Error>) -> Void) {
        observedAsync("writeDescriptor", ["descriptorUuid": target.descriptorUuid], completion) {
            inner.writeDescriptor(target: target, value: value, completion: $0)
        }
    }

    func getMtu(deviceId: String, completion: @escaping (Result<Int64, Error>) -> Void) {
        observedAsync("getMtu", ["deviceId": deviceId], completion) {
            inner.getMtu(deviceId: deviceId, completion: $0)
        }
    }

    func readRssi(deviceId: String, completion: @escaping (Result<Int64, Error>) -> Void) {
        observedAsync("readRssi", ["deviceId": deviceId], completion) {
            inner.readRssi(deviceId: deviceId, completion: $0)
        }
    }

    func dispose() throws {
        try observed("dispose", [:]) { try inner.dispose() }
    }
}
```

- [ ] **Step 4: プラグイン登録を置換**

`DeepskyBluetoothIosPlugin.swift` 全文:

```swift
import Flutter
import UIKit

public class DeepskyBluetoothIosPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let callbacks = BleCallbacksApi(binaryMessenger: registrar.messenger())
        let controller = BleCentralController(callbacks: callbacks)
        BleHostApiSetup.setUp(
            binaryMessenger: registrar.messenger(), api: ObservingBleHostApi(controller))
    }
}
```

- [ ] **Step 5: Windowsでの検証 + コミット**

Run: `flutter analyze plugins/deepsky_bluetooth_ios`
Expected: No issues found(SwiftコンパイルはmacOSチェックポイントへ)

```powershell
git add plugins/deepsky_bluetooth_ios && git commit -m "feat(ios): CoreBluetooth controller with state restoration and observer"
```

- [ ] **Step 6: [macOSホスト・チェックポイント]**

macOSマシンで: `cd plugins/deepsky_bluetooth_ios/example && flutter build ios --no-codesign --debug`
Expected: ビルド成功。Swiftコンパイルエラーが出た場合はここで修正してコミット。

---

### Task 13: macOSネイティブ — CoreBluetooth + Observer(バックグラウンドはエラー)

**Files:**
- Create: `plugins/deepsky_bluetooth_macos/macos/deepsky_bluetooth_macos/Sources/deepsky_bluetooth_macos/DeepskyBluetoothMacosObserver.swift`
- Create: `.../BleCentralController.swift`(iOS版をコピーし下記の差分を適用)
- Create: `.../ObservingBleHostApi.swift`(iOS版をコピーし下記の差分を適用)
- Modify: `.../DeepskyBluetoothMacosPlugin.swift`(テンプレート全置換)

macOSのコントローラはiOS版と同一ロジックのため、**iOS版ファイルをコピーして以下の差分を機械的に適用する**。差分はすべて本タスクに完全な形で列挙してある(推測不要)。

- [ ] **Step 1: Observerファイルを作成**

`DeepskyBluetoothMacosObserver.swift`: Task 12 Step 1の `DeepskyBluetoothIosObserver.swift` と同内容で、型名のみ `DeepskyBluetoothIosObserver` → `DeepskyBluetoothMacosObserver`、`DeepskyBluetoothIosObserverRegistry` → `DeepskyBluetoothMacosObserverRegistry` に変更したもの。

- [ ] **Step 2: コントローラをコピーして差分適用**

```powershell
Copy-Item plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/BleCentralController.swift plugins/deepsky_bluetooth_macos/macos/deepsky_bluetooth_macos/Sources/deepsky_bluetooth_macos/BleCentralController.swift
Copy-Item plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/ObservingBleHostApi.swift plugins/deepsky_bluetooth_macos/macos/deepsky_bluetooth_macos/Sources/deepsky_bluetooth_macos/ObservingBleHostApi.swift
```

両ファイルに適用する差分(完全列挙):

1. `import Flutter` → `import FlutterMacOS`(両ファイル)
2. 型名置換(両ファイル): `DeepskyBluetoothIosObserver` → `DeepskyBluetoothMacosObserver`、`DeepskyBluetoothIosObserverRegistry` → `DeepskyBluetoothMacosObserverRegistry`
3. `BleCentralController.swift`: `BleErrorCode` に1定数追加:

```swift
    static let backgroundNotSupported = "backgroundNotSupported"
```

4. `BleCentralController.swift`: `initialize(request:)` メソッド全体を以下に置換(State Restorationなし。バックグラウンドは防御的にエラー):

```swift
    func initialize(isBackground: Bool) throws {
        if initialized { throw bleError(BleErrorCode.alreadyInitialized, "Already initialized") }
        if isBackground {
            throw bleError(BleErrorCode.backgroundNotSupported,
                           "Background mode is not supported on macOS")
        }
        central = CBCentralManager(delegate: self, queue: .main, options: [:])
        initialized = true
    }
```

5. `BleCentralController.swift`: 以下を**削除**: プロパティ `restoredDeviceIds`、`notifyDartReady()` 内の復元通知ブロック(メソッド自体は空実装 `func notifyDartReady() throws {}` として残す)、`centralManager(_:willRestoreState:)` メソッド全体。
6. `ObservingBleHostApi.swift`: `initialize` のラッパーを以下に置換:

```swift
    func initialize(isBackground: Bool) throws {
        try observed("initialize", ["isBackground": isBackground]) {
            try inner.initialize(isBackground: isBackground)
        }
    }
```

(macOS版Pigeonの `BleHostApi.initialize` は `bool isBackground` 単引数のため、`InitializeRequestMessage` 型への参照が両ファイルに残っていないことを確認する)

- [ ] **Step 3: プラグイン登録を置換**

`DeepskyBluetoothMacosPlugin.swift` 全文:

```swift
import Cocoa
import FlutterMacOS

public class DeepskyBluetoothMacosPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let callbacks = BleCallbacksApi(binaryMessenger: registrar.messenger)
        let controller = BleCentralController(callbacks: callbacks)
        BleHostApiSetup.setUp(
            binaryMessenger: registrar.messenger, api: ObservingBleHostApi(controller))
    }
}
```

(注: macOSの `FlutterPluginRegistrar.messenger` はプロパティ。iOSの `messenger()` と異なる)

- [ ] **Step 4: Windowsでの検証 + コミット**

Run: `flutter analyze plugins/deepsky_bluetooth_macos`
Expected: No issues found

```powershell
git add plugins/deepsky_bluetooth_macos && git commit -m "feat(macos): CoreBluetooth controller (background rejected) and observer"
```

- [ ] **Step 5: [macOSホスト・チェックポイント]**

macOSマシンで: `cd plugins/deepsky_bluetooth_macos/example && flutter build macos --debug`
Expected: ビルド成功。エラーがあればここで修正してコミット。

---

### Task 14: deepsky_bluetooth_android_bridge — 変換・エラーマッパー・Bridge本体(TDD)

**Files:**
- Create: `packages/deepsky_bluetooth_android_bridge/lib/src/converters.dart`
- Create: `packages/deepsky_bluetooth_android_bridge/lib/src/error_mapper.dart`
- Create: `packages/deepsky_bluetooth_android_bridge/lib/src/bridge.dart`
- Modify: `packages/deepsky_bluetooth_android_bridge/lib/deepsky_bluetooth_android_bridge.dart`(テンプレート全置換)
- Create: `packages/deepsky_bluetooth_android_bridge/test/error_mapper_test.dart`
- Create: `packages/deepsky_bluetooth_android_bridge/test/bridge_test.dart`
- Delete: `packages/deepsky_bluetooth_android_bridge/test/deepsky_bluetooth_android_bridge_test.dart`(テンプレート)

- [ ] **Step 1: エラーマッパーの失敗するテストを書く**

`test/error_mapper_test.dart`:

```dart
import 'package:deepsky_bluetooth_android_bridge/deepsky_bluetooth_android_bridge.dart';
import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

PlatformException pe(String code) => PlatformException(code: code, message: 'msg');

void main() {
  test('mapInitializeError', () {
    expect(mapInitializeError(pe('alreadyInitialized')), isA<AlreadyInitialized>());
    expect(mapInitializeError(pe('backgroundConfigMissing')), isA<BackgroundConfigMissing>());
    expect(mapInitializeError(pe('unknown')), isA<InitializeFailed>());
  });

  test('mapScanError', () {
    expect(mapScanError(pe('permissionDenied')), isA<ScanPermissionDenied>());
    expect(mapScanError(pe('bluetoothOff')), isA<ScanBluetoothOff>());
    expect(mapScanError(pe('alreadyScanning')), isA<ScanAlreadyScanning>());
    expect(mapScanError(pe('unknown')), isA<ScanFailed>());
  });

  test('mapConnectError', () {
    expect(mapConnectError(pe('permissionDenied')), isA<ConnectPermissionDenied>());
    expect(mapConnectError(pe('bluetoothOff')), isA<ConnectBluetoothOff>());
    expect(mapConnectError(pe('notFound')), isA<ConnectDeviceNotFound>());
    expect(mapConnectError(pe('timeout')), isA<ConnectTimeout>());
    expect(mapConnectError(pe('unknown')), isA<ConnectFailed>());
  });

  test('mapCharacteristicReadError', () {
    expect(mapCharacteristicReadError(pe('notConnected')), isA<CharacteristicReadNotConnected>());
    expect(mapCharacteristicReadError(pe('notFound')), isA<CharacteristicReadNotFound>());
    expect(mapCharacteristicReadError(pe('notSupported')), isA<CharacteristicReadNotSupported>());
    expect(mapCharacteristicReadError(pe('unknown')), isA<CharacteristicReadFailed>());
  });

  test('mapAssociateError', () {
    expect(mapAssociateError(pe('rejected')), isA<AssociateRejected>());
    expect(mapAssociateError(pe('unknown')), isA<AssociateFailed>());
  });

  test('mapPresenceError', () {
    expect(mapPresenceError(pe('notAssociated')), isA<PresenceNotAssociated>());
    expect(mapPresenceError(pe('unknown')), isA<PresenceFailed>());
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `packages/deepsky_bluetooth_android_bridge` で `flutter test test/error_mapper_test.dart`
Expected: コンパイルエラーで FAIL

- [ ] **Step 3: error_mapper.dart を実装**

`lib/src/error_mapper.dart` 全文:

```dart
import 'package:deepsky_bluetooth_util/deepsky_bluetooth_util.dart';
import 'package:flutter/services.dart';

String _msg(PlatformException e) => e.message ?? e.code;

InitializeError mapInitializeError(PlatformException e) => switch (e.code) {
      BleErrorCode.alreadyInitialized => const AlreadyInitialized(),
      BleErrorCode.backgroundConfigMissing => const BackgroundConfigMissing(),
      BleErrorCode.backgroundNotSupported => const BackgroundNotSupported(),
      _ => InitializeFailed(_msg(e)),
    };

ScanError mapScanError(PlatformException e) => switch (e.code) {
      BleErrorCode.permissionDenied => const ScanPermissionDenied(),
      BleErrorCode.bluetoothOff => const ScanBluetoothOff(),
      BleErrorCode.alreadyScanning => const ScanAlreadyScanning(),
      _ => ScanFailed(_msg(e)),
    };

ConnectError mapConnectError(PlatformException e) => switch (e.code) {
      BleErrorCode.permissionDenied => const ConnectPermissionDenied(),
      BleErrorCode.bluetoothOff => const ConnectBluetoothOff(),
      BleErrorCode.notFound => const ConnectDeviceNotFound(),
      BleErrorCode.timeout => const ConnectTimeout(),
      _ => ConnectFailed(_msg(e)),
    };

DisconnectError mapDisconnectError(PlatformException e) => switch (e.code) {
      BleErrorCode.notConnected => const DisconnectNotConnected(),
      _ => DisconnectFailed(_msg(e)),
    };

DiscoverServicesError mapDiscoverServicesError(PlatformException e) =>
    switch (e.code) {
      BleErrorCode.notConnected => const DiscoverServicesNotConnected(),
      _ => DiscoverServicesFailed(_msg(e)),
    };

CharacteristicReadError mapCharacteristicReadError(PlatformException e) =>
    switch (e.code) {
      BleErrorCode.notConnected => const CharacteristicReadNotConnected(),
      BleErrorCode.notFound => const CharacteristicReadNotFound(),
      BleErrorCode.notSupported => const CharacteristicReadNotSupported(),
      _ => CharacteristicReadFailed(_msg(e)),
    };

CharacteristicWriteError mapCharacteristicWriteError(PlatformException e) =>
    switch (e.code) {
      BleErrorCode.notConnected => const CharacteristicWriteNotConnected(),
      BleErrorCode.notFound => const CharacteristicWriteNotFound(),
      BleErrorCode.notSupported => const CharacteristicWriteNotSupported(),
      _ => CharacteristicWriteFailed(_msg(e)),
    };

NotifyError mapNotifyError(PlatformException e) => switch (e.code) {
      BleErrorCode.notConnected => const NotifyNotConnected(),
      BleErrorCode.notFound => const NotifyNotFound(),
      BleErrorCode.notSupported => const NotifyNotSupported(),
      _ => NotifyFailed(_msg(e)),
    };

DescriptorReadError mapDescriptorReadError(PlatformException e) =>
    switch (e.code) {
      BleErrorCode.notConnected => const DescriptorReadNotConnected(),
      BleErrorCode.notFound => const DescriptorReadNotFound(),
      _ => DescriptorReadFailed(_msg(e)),
    };

DescriptorWriteError mapDescriptorWriteError(PlatformException e) =>
    switch (e.code) {
      BleErrorCode.notConnected => const DescriptorWriteNotConnected(),
      BleErrorCode.notFound => const DescriptorWriteNotFound(),
      _ => DescriptorWriteFailed(_msg(e)),
    };

MtuError mapMtuError(PlatformException e) => switch (e.code) {
      BleErrorCode.notConnected => const MtuNotConnected(),
      _ => MtuFailed(_msg(e)),
    };

RssiError mapRssiError(PlatformException e) => switch (e.code) {
      BleErrorCode.notConnected => const RssiNotConnected(),
      _ => RssiFailed(_msg(e)),
    };

AssociateError mapAssociateError(PlatformException e) => switch (e.code) {
      BleErrorCode.rejected => const AssociateRejected(),
      _ => AssociateFailed(_msg(e)),
    };

PresenceError mapPresenceError(PlatformException e) => switch (e.code) {
      BleErrorCode.notAssociated => const PresenceNotAssociated(),
      _ => PresenceFailed(_msg(e)),
    };

DisposeError mapDisposeError(PlatformException e) => DisposeFailed(_msg(e));
```

- [ ] **Step 4: 変換関数を実装**

`lib/src/converters.dart` 全文:

```dart
import 'package:deepsky_bluetooth_android/deepsky_bluetooth_android.dart';
import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:deepsky_bluetooth_util/deepsky_bluetooth_util.dart';

// DeepskyUuidは生成時に正規化済みのため、ここでの正規化は不要
ScanFilterMessage? scanFilterToMessage(DeepskyScanFilter? f) => f == null
    ? null
    : ScanFilterMessage(
        addresses: f.address,
        names: f.name,
        manufacturerData: f.manufactureData
            .map((m) => ManufacturerDataFilterMessage(
                manufacturerId: m.manufacturerId, data: m.data))
            .toList(),
        serviceData: f.serviceData
            .map((s) =>
                ServiceDataFilterMessage(serviceUuid: s.uuid.value, data: s.data))
            .toList(),
        serviceUuids: [
          ...f.serviceUuidFromByteArray.map((s) => s.uuid.value),
          ...f.serviceUuidFromString.map((s) => s.uuid.value),
        ],
      );

AndroidScanSettingsMessage androidScanSettingsToMessage(
        DeepskyAndroidScanSetting s) =>
    AndroidScanSettingsMessage(
      mode: switch (s.mode) {
        DeepskyAndroidScanMode.scanModeLowPower => ScanModeMessage.lowPower,
        DeepskyAndroidScanMode.scanModeBalanced => ScanModeMessage.balanced,
        DeepskyAndroidScanMode.scanModeLowLatency => ScanModeMessage.lowLatency,
        DeepskyAndroidScanMode.scanModeOpportunistic =>
          ScanModeMessage.opportunistic,
      },
      callbackType: switch (s.callbackType) {
        DeepskyAndroidScanCallbackType.callBackTypeAllMatches =>
          ScanCallbackTypeMessage.allMatches,
        DeepskyAndroidScanCallbackType.callBackTypeFirstMatch =>
          ScanCallbackTypeMessage.firstMatch,
        DeepskyAndroidScanCallbackType.callBackTypeMatchLost =>
          ScanCallbackTypeMessage.matchLost,
        DeepskyAndroidScanCallbackType.callBackTypeFirstMatchAndMatchLost =>
          ScanCallbackTypeMessage.firstMatchAndMatchLost,
      },
      onlyLegacy: s.onlyLegacy,
      matchMode: switch (s.matchMode) {
        DeepskyAndroidScanMatchMode.matchModeAggressive =>
          ScanMatchModeMessage.aggressive,
        DeepskyAndroidScanMatchMode.matchModeSticky =>
          ScanMatchModeMessage.sticky,
      },
      numOfMatch: switch (s.numOfMatch) {
        DeepskyAndroidScanNumOfMatch.matchNumOneAdvertisement =>
          ScanNumOfMatchMessage.one,
        DeepskyAndroidScanNumOfMatch.matchNumFewAdvertisement =>
          ScanNumOfMatchMessage.few,
        DeepskyAndroidScanNumOfMatch.matchNumMaxAdvertisement =>
          ScanNumOfMatchMessage.max,
      },
      reportDelayMillis: s.reportDelay,
      phy: switch (s.phy) {
        DeepskyAndroidScanPhy.phyLe1m => ScanPhyMessage.le1m,
        DeepskyAndroidScanPhy.phyLeCoded => ScanPhyMessage.leCoded,
        DeepskyAndroidScanPhy.phyLeAllSupported => ScanPhyMessage.allSupported,
      },
    );

BleScanResult scanResultFromMessage(ScanResultMessage m) => BleScanResult(
      deviceId: m.deviceId,
      name: m.name,
      rssi: m.rssi,
      serviceUuids: m.serviceUuids,
      manufacturerData: m.manufacturerData,
      raw: m.raw,
    );

BleConnectionState connectionStateFromMessage(ConnectionStateMessage m) =>
    switch (m) {
      ConnectionStateMessage.connecting => BleConnectionState.connecting,
      ConnectionStateMessage.connected => BleConnectionState.connected,
      ConnectionStateMessage.disconnecting => BleConnectionState.disconnecting,
      ConnectionStateMessage.disconnected => BleConnectionState.disconnected,
    };

BleService serviceFromMessage(ServiceMessage m) => BleService(
      uuid: m.uuid,
      characteristics: m.characteristics
          .map((c) => BleCharacteristic(
                uuid: c.uuid,
                properties: BleCharacteristicProperties(
                  read: c.canRead,
                  writeWithResponse: c.canWriteWithResponse,
                  writeWithoutResponse: c.canWriteWithoutResponse,
                  notify: c.canNotify,
                  indicate: c.canIndicate,
                ),
                descriptors:
                    c.descriptors.map((d) => BleDescriptor(uuid: d.uuid)).toList(),
              ))
          .toList(),
    );

CharacteristicTargetMessage characteristicTargetToMessage(
        BleCharacteristicTarget t) =>
    CharacteristicTargetMessage(
      deviceId: t.deviceId,
      serviceUuid: BleUuid.normalize(t.serviceUuid),
      characteristicUuid: BleUuid.normalize(t.characteristicUuid),
    );

BleCharacteristicTarget characteristicTargetFromMessage(
        CharacteristicTargetMessage m) =>
    BleCharacteristicTarget(
      deviceId: m.deviceId,
      serviceUuid: m.serviceUuid,
      characteristicUuid: m.characteristicUuid,
    );

DescriptorTargetMessage descriptorTargetToMessage(BleDescriptorTarget t) =>
    DescriptorTargetMessage(
      deviceId: t.deviceId,
      serviceUuid: BleUuid.normalize(t.serviceUuid),
      characteristicUuid: BleUuid.normalize(t.characteristicUuid),
      descriptorUuid: BleUuid.normalize(t.descriptorUuid),
    );

InitializeRequestMessage configToMessage(DeepskyBluetoothConfig config) =>
    switch (config) {
      ForegroundConfig() => InitializeRequestMessage(
          isBackground: false, strategy: null, notification: null),
      BackgroundConfig(:final android) => switch (android) {
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
            ),
          AndroidCompanionDeviceConfig() => InitializeRequestMessage(
              isBackground: true,
              strategy: BackgroundStrategyMessage.companionDevice,
              notification: null),
          // android == null はbridge側で事前にBackgroundConfigMissingを返すため到達しない
          null => InitializeRequestMessage(
              isBackground: true, strategy: null, notification: null),
        },
    };
```

- [ ] **Step 5: Bridge本体の失敗するテストを書く**

`test/bridge_test.dart`:

```dart
import 'dart:typed_data';

import 'package:deepsky_bluetooth_android/deepsky_bluetooth_android.dart';
import 'package:deepsky_bluetooth_android_bridge/deepsky_bluetooth_android_bridge.dart';
import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/steady.dart';

class _FakeHostApi extends BleHostApi {
  final calls = <String>[];
  PlatformException? thrown;
  InitializeRequestMessage? lastInitialize;
  List<ServiceMessage> services = [];

  void _maybeThrow() {
    final t = thrown;
    if (t != null) throw t;
  }

  @override
  Future<void> initialize(InitializeRequestMessage request) async {
    _maybeThrow();
    lastInitialize = request;
    calls.add('initialize');
  }

  @override
  Future<void> notifyDartReady() async => calls.add('notifyDartReady');

  @override
  Future<void> startScan(
      ScanFilterMessage? filter, AndroidScanSettingsMessage settings) async {
    _maybeThrow();
    calls.add('startScan');
  }

  @override
  Future<void> stopScan() async => calls.add('stopScan');

  @override
  Future<void> connect(String deviceId) async {
    _maybeThrow();
    calls.add('connect:$deviceId');
  }

  @override
  Future<void> disconnect(String deviceId) async => calls.add('disconnect:$deviceId');

  @override
  Future<List<ServiceMessage>> discoverServices(String deviceId) async {
    _maybeThrow();
    return services;
  }

  @override
  Future<Uint8List> readCharacteristic(CharacteristicTargetMessage target) async {
    _maybeThrow();
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<void> writeCharacteristic(CharacteristicTargetMessage target,
      Uint8List value, bool withResponse) async {
    _maybeThrow();
    calls.add('writeCharacteristic');
  }

  @override
  Future<void> setNotify(CharacteristicTargetMessage target, bool enabled) async {
    calls.add('setNotify:$enabled');
  }

  @override
  Future<Uint8List> readDescriptor(DescriptorTargetMessage target) async =>
      Uint8List(0);

  @override
  Future<void> writeDescriptor(
      DescriptorTargetMessage target, Uint8List value) async {}

  @override
  Future<int> requestMtu(String deviceId, int mtu) async => 247;

  @override
  Future<int> readRssi(String deviceId) async => -42;

  @override
  Future<String> associate(ScanFilterMessage? filter) async {
    _maybeThrow();
    return 'AA:BB:CC:DD:EE:FF';
  }

  @override
  Future<void> setDevicePresenceObservation(String deviceId, bool enabled) async {
    calls.add('presence:$enabled');
  }

  @override
  Future<void> dispose() async => calls.add('dispose');
}

class _RecordingObserver implements DeepskyBluetoothObserver {
  final events = <String>[];
  @override
  void onMethodStart(String methodName, Map<String, Object?> arguments) =>
      events.add('start:$methodName');
  @override
  void onMethodEnd(String methodName, Result<Object?, Exception> result) =>
      events.add('end:$methodName:${result.isOk ? 'ok' : 'err'}');
  @override
  void onCallback(String callbackName, Object? payload) =>
      events.add('cb:$callbackName');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHostApi host;
  late _RecordingObserver observer;
  late DeepskyBluetoothAndroidBridge bridge;

  setUp(() {
    host = _FakeHostApi();
    observer = _RecordingObserver();
    bridge = DeepskyBluetoothAndroidBridge(hostApi: host, observer: observer);
  });

  test('initialize(foreground) calls host and notifyDartReady', () async {
    final r = await bridge.initialize(const DeepskyBluetoothConfig.foreground());
    expect(r.isOk, isTrue);
    expect(host.lastInitialize?.isBackground, isFalse);
    expect(host.calls, contains('notifyDartReady'));
  });

  test('initialize(background, companion) sends strategy', () async {
    final r = await bridge.initialize(const DeepskyBluetoothConfig.background(
        android: AndroidCompanionDeviceConfig()));
    expect(r.isOk, isTrue);
    expect(host.lastInitialize?.strategy, BackgroundStrategyMessage.companionDevice);
  });

  test('initialize(background) without android config fails without host call',
      () async {
    final r = await bridge.initialize(const DeepskyBluetoothConfig.background());
    expect(r.err, isA<BackgroundConfigMissing>());
    expect(host.calls, isEmpty);
  });

  test('startScan maps PlatformException to sealed error', () async {
    host.thrown = PlatformException(code: 'permissionDenied');
    final r = await bridge.startScan();
    expect(r.err, isA<ScanPermissionDenied>());
  });

  test('observer records method start/end', () async {
    await bridge.startScan();
    expect(observer.events, ['start:startScan', 'end:startScan:ok']);
  });

  test('discoverServices converts messages to models', () async {
    host.services = [
      ServiceMessage(uuid: 's1', characteristics: [
        CharacteristicMessage(
          uuid: 'c1',
          canRead: true,
          canWriteWithResponse: false,
          canWriteWithoutResponse: false,
          canNotify: true,
          canIndicate: false,
          descriptors: [DescriptorMessage(uuid: 'd1')],
        ),
      ]),
    ];
    final r = await bridge.discoverServices('dev');
    final services = r.unwrap();
    expect(services.single.uuid, 's1');
    expect(services.single.characteristics.single.properties.notify, isTrue);
    expect(services.single.characteristics.single.descriptors.single.uuid, 'd1');
  });

  test('onScanResult emits converted model and observer callback', () async {
    final future = bridge.scanResults.first;
    bridge.onScanResult(ScanResultMessage(
        deviceId: 'dev', name: 'n', rssi: -50, serviceUuids: [], manufacturerData: null));
    final result = await future;
    expect(result.deviceId, 'dev');
    expect(observer.events, contains('cb:onScanResult'));
  });

  test('onConnectionStateChanged emits connection event', () async {
    final future = bridge.connectionEvents.first;
    bridge.onConnectionStateChanged('dev', ConnectionStateMessage.connected);
    final event = await future;
    expect(event.state, BleConnectionState.connected);
  });

  test('onDeviceAppeared emits companion event', () async {
    final future = bridge.companionEvents.first;
    bridge.onDeviceAppeared('dev');
    final event = await future;
    expect(event.appeared, isTrue);
  });

  test('associate returns device id', () async {
    final r = await bridge.associate();
    expect(r.unwrap(), 'AA:BB:CC:DD:EE:FF');
  });
}
```

- [ ] **Step 6: テストが失敗することを確認**

Run: `flutter test test/bridge_test.dart` → コンパイルエラーで FAIL

- [ ] **Step 7: bridge.dart を実装**

`lib/src/bridge.dart` 全文:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:deepsky_bluetooth_android/deepsky_bluetooth_android.dart';
import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:flutter/services.dart';
import 'package:steady/steady.dart';

import 'converters.dart';
import 'error_mapper.dart';

class DeepskyBluetoothAndroidBridge extends DeepskyBluetoothPlatform
    implements BleCallbacksApi {
  DeepskyBluetoothAndroidBridge({
    BleHostApi? hostApi,
    DeepskyBluetoothObserver? observer,
    BinaryMessenger? binaryMessenger,
  })  : _hostApi = hostApi ?? BleHostApi(binaryMessenger: binaryMessenger),
        _observer = observer,
        _binaryMessenger = binaryMessenger;

  final BleHostApi _hostApi;
  final DeepskyBluetoothObserver? _observer;
  final BinaryMessenger? _binaryMessenger;

  final _scanResults = StreamController<BleScanResult>.broadcast();
  final _scanErrors = StreamController<ScanError>.broadcast();
  final _connectionEvents = StreamController<BleConnectionEvent>.broadcast();
  final _characteristicValues =
      StreamController<BleCharacteristicValue>.broadcast();
  final _companionEvents = StreamController<BleCompanionEvent>.broadcast();

  /// Pigeon境界。本ライブラリでtry-catchを許可する唯一の場所。
  Future<Result<T, E>> _invoke<T, E extends DeepskyBluetoothError>(
    String method,
    Map<String, Object?> args,
    Future<T> Function() body,
    E Function(PlatformException) mapError,
  ) async {
    _observer?.onMethodStart(method, args);
    Result<T, E> result;
    try {
      result = Result.ok(await body());
    } on PlatformException catch (e) {
      result = Result.error(mapError(e));
    }
    _observer?.onMethodEnd(method, result);
    return result;
  }

  @override
  Future<Result<void, InitializeError>> initialize(
      DeepskyBluetoothConfig config) {
    if (config case BackgroundConfig(android: null)) {
      _observer?.onMethodStart('initialize', {'config': 'background'});
      const result =
          Result<void, InitializeError>.error(BackgroundConfigMissing());
      _observer?.onMethodEnd('initialize', result);
      return Future.value(result);
    }
    return _invoke('initialize', {'isBackground': config is BackgroundConfig},
        () async {
      await _hostApi.initialize(configToMessage(config));
      // initialize成功後に登録する。失敗した生成試行(AlreadyInitialized等)が
      // 稼働中インスタンスのチャネル登録を奪わないため。
      // notifyDartReadyより前に登録し、バッファ済みイベントを取りこぼさない。
      BleCallbacksApi.setUp(this, binaryMessenger: _binaryMessenger);
      await _hostApi.notifyDartReady();
    }, mapInitializeError);
  }

  @override
  Future<Result<void, ScanError>> startScan(
          {DeepskyScanFilter? filter,
          DeepskyScanOptions options = const DeepskyScanOptions()}) =>
      _invoke(
          'startScan',
          {'hasFilter': filter != null},
          () => _hostApi.startScan(scanFilterToMessage(filter),
              androidScanSettingsToMessage(options.android)),
          mapScanError);

  @override
  Future<Result<void, ScanError>> stopScan() =>
      _invoke('stopScan', const {}, _hostApi.stopScan, mapScanError);

  @override
  Future<Result<void, ConnectError>> connect(String deviceId) =>
      _invoke('connect', {'deviceId': deviceId},
          () => _hostApi.connect(deviceId), mapConnectError);

  @override
  Future<Result<void, DisconnectError>> disconnect(String deviceId) =>
      _invoke('disconnect', {'deviceId': deviceId},
          () => _hostApi.disconnect(deviceId), mapDisconnectError);

  @override
  Future<Result<List<BleService>, DiscoverServicesError>> discoverServices(
          String deviceId) =>
      _invoke(
          'discoverServices',
          {'deviceId': deviceId},
          () async => (await _hostApi.discoverServices(deviceId))
              .map(serviceFromMessage)
              .toList(),
          mapDiscoverServicesError);

  @override
  Future<Result<Uint8List, CharacteristicReadError>> readCharacteristic(
          BleCharacteristicTarget target) =>
      _invoke(
          'readCharacteristic',
          {'characteristicUuid': target.characteristicUuid},
          () => _hostApi.readCharacteristic(characteristicTargetToMessage(target)),
          mapCharacteristicReadError);

  @override
  Future<Result<void, CharacteristicWriteError>> writeCharacteristic(
          BleCharacteristicTarget target, Uint8List value,
          {required bool withResponse}) =>
      _invoke(
          'writeCharacteristic',
          {
            'characteristicUuid': target.characteristicUuid,
            'withResponse': withResponse,
          },
          () => _hostApi.writeCharacteristic(
              characteristicTargetToMessage(target), value, withResponse),
          mapCharacteristicWriteError);

  @override
  Future<Result<void, NotifyError>> setNotify(BleCharacteristicTarget target,
          {required bool enabled}) =>
      _invoke(
          'setNotify',
          {'characteristicUuid': target.characteristicUuid, 'enabled': enabled},
          () => _hostApi.setNotify(characteristicTargetToMessage(target), enabled),
          mapNotifyError);

  @override
  Future<Result<Uint8List, DescriptorReadError>> readDescriptor(
          BleDescriptorTarget target) =>
      _invoke(
          'readDescriptor',
          {'descriptorUuid': target.descriptorUuid},
          () => _hostApi.readDescriptor(descriptorTargetToMessage(target)),
          mapDescriptorReadError);

  @override
  Future<Result<void, DescriptorWriteError>> writeDescriptor(
          BleDescriptorTarget target, Uint8List value) =>
      _invoke(
          'writeDescriptor',
          {'descriptorUuid': target.descriptorUuid},
          () => _hostApi.writeDescriptor(descriptorTargetToMessage(target), value),
          mapDescriptorWriteError);

  @override
  Future<Result<int, MtuError>> requestMtu(String deviceId, int mtu) =>
      _invoke('requestMtu', {'deviceId': deviceId, 'mtu': mtu},
          () => _hostApi.requestMtu(deviceId, mtu), mapMtuError);

  @override
  Future<Result<int, RssiError>> readRssi(String deviceId) =>
      _invoke('readRssi', {'deviceId': deviceId},
          () => _hostApi.readRssi(deviceId), mapRssiError);

  @override
  Future<Result<String, AssociateError>> associate({DeepskyScanFilter? filter}) =>
      _invoke('associate', {'hasFilter': filter != null},
          () => _hostApi.associate(scanFilterToMessage(filter)),
          mapAssociateError);

  @override
  Future<Result<void, PresenceError>> setDevicePresenceObservation(
          String deviceId,
          {required bool enabled}) =>
      _invoke(
          'setDevicePresenceObservation',
          {'deviceId': deviceId, 'enabled': enabled},
          () => _hostApi.setDevicePresenceObservation(deviceId, enabled),
          mapPresenceError);

  @override
  Future<Result<void, DisposeError>> dispose() =>
      _invoke('dispose', const {}, () async {
        await _hostApi.dispose();
        // チャネル登録を解除し、dispose後の再生成(モード変更含む)を可能にする
        BleCallbacksApi.setUp(null, binaryMessenger: _binaryMessenger);
      }, mapDisposeError);

  @override
  Stream<BleScanResult> get scanResults => _scanResults.stream;

  @override
  Stream<ScanError> get scanErrors => _scanErrors.stream;

  @override
  Stream<BleConnectionEvent> get connectionEvents => _connectionEvents.stream;

  @override
  Stream<BleCharacteristicValue> get characteristicValues =>
      _characteristicValues.stream;

  @override
  Stream<BleCompanionEvent> get companionEvents => _companionEvents.stream;

  /// AndroidにState Restorationはないため何も流れない。
  @override
  Stream<List<String>> get restoredConnections => const Stream.empty();

  // --- BleCallbacksApi(ネイティブ→Dart) ---

  @override
  void onScanResult(ScanResultMessage result) {
    final model = scanResultFromMessage(result);
    _observer?.onCallback('onScanResult', model.deviceId);
    _scanResults.add(model);
  }

  @override
  void onScanFailed(String code, String message) {
    _observer?.onCallback('onScanFailed', message);
    _scanErrors.add(ScanFailed(message));
  }

  @override
  void onConnectionStateChanged(String deviceId, ConnectionStateMessage state) {
    final event = BleConnectionEvent(
        deviceId: deviceId, state: connectionStateFromMessage(state));
    _observer?.onCallback(
        'onConnectionStateChanged', '$deviceId ${event.state.name}');
    _connectionEvents.add(event);
  }

  @override
  void onCharacteristicValue(
      CharacteristicTargetMessage target, Uint8List value) {
    final model = BleCharacteristicValue(
        target: characteristicTargetFromMessage(target), value: value);
    _observer?.onCallback('onCharacteristicValue', target.characteristicUuid);
    _characteristicValues.add(model);
  }

  @override
  void onDeviceAppeared(String deviceId) {
    _observer?.onCallback('onDeviceAppeared', deviceId);
    _companionEvents.add(BleCompanionEvent(deviceId: deviceId, appeared: true));
  }

  @override
  void onDeviceDisappeared(String deviceId) {
    _observer?.onCallback('onDeviceDisappeared', deviceId);
    _companionEvents.add(BleCompanionEvent(deviceId: deviceId, appeared: false));
  }
}
```

- [ ] **Step 8: exportファイルを置換**

`lib/deepsky_bluetooth_android_bridge.dart` 全文:

```dart
library;

export 'src/bridge.dart';
export 'src/error_mapper.dart';
```

- [ ] **Step 9: テンプレートテストを削除し、テストが通ることを確認**

```powershell
git rm packages/deepsky_bluetooth_android_bridge/test/deepsky_bluetooth_android_bridge_test.dart
```

Run: `flutter test`
Expected: All tests passed

- [ ] **Step 10: コミット**

```powershell
git add packages/deepsky_bluetooth_android_bridge && git commit -m "feat(android-bridge): map pigeon api to platform interface with Result errors"
```

---

### Task 15: deepsky_bluetooth_ios_bridge(TDD)

**Files:**
- Create: `packages/deepsky_bluetooth_ios_bridge/lib/src/converters.dart`
- Create: `packages/deepsky_bluetooth_ios_bridge/lib/src/error_mapper.dart`
- Create: `packages/deepsky_bluetooth_ios_bridge/lib/src/bridge.dart`
- Modify: `packages/deepsky_bluetooth_ios_bridge/lib/deepsky_bluetooth_ios_bridge.dart`
- Create: `packages/deepsky_bluetooth_ios_bridge/test/bridge_test.dart`
- Delete: `packages/deepsky_bluetooth_ios_bridge/test/deepsky_bluetooth_ios_bridge_test.dart`(テンプレート)

Task 14と同じ構造。Androidとの差分は以下のみで、それ以外のコード(エラーマッパー全関数・converters・_invokeヘルパー・各メソッド委譲・コールバック→Stream)はTask 14と同一内容を `package:deepsky_bluetooth_ios/deepsky_bluetooth_ios.dart` import で書く。

**差分(完全列挙):**

1. クラス名は `DeepskyBluetoothIosBridge`。
2. `error_mapper.dart` から `mapAssociateError` / `mapPresenceError` を削除(iOSにはネイティブ呼び出しがないため)。
3. `converters.dart` の `configToMessage` を以下に置換(Android戦略型は存在しない):

```dart
InitializeRequestMessage configToMessage(DeepskyBluetoothConfig config) =>
    switch (config) {
      ForegroundConfig() =>
        InitializeRequestMessage(isBackground: false, restoreIdentifier: null),
      BackgroundConfig(:final ios) => InitializeRequestMessage(
          isBackground: true, restoreIdentifier: ios?.restoreIdentifier),
    };
```

4. `bridge.dart` の `initialize` の事前ガードは `ios` 設定の欠如を検査:

```dart
  @override
  Future<Result<void, InitializeError>> initialize(
      DeepskyBluetoothConfig config) {
    if (config case BackgroundConfig(ios: null)) {
      _observer?.onMethodStart('initialize', {'config': 'background'});
      const result =
          Result<void, InitializeError>.error(BackgroundConfigMissing());
      _observer?.onMethodEnd('initialize', result);
      return Future.value(result);
    }
    return _invoke('initialize', {'isBackground': config is BackgroundConfig},
        () async {
      await _hostApi.initialize(configToMessage(config));
      // Task 14と同じ: initialize成功後・notifyDartReady前に登録
      BleCallbacksApi.setUp(this, binaryMessenger: _binaryMessenger);
      await _hostApi.notifyDartReady();
    }, mapInitializeError);
  }
```

5. `requestMtu` はネイティブの `getMtu` に委譲(要求値は無視される):

```dart
  /// iOSはOSがMTUを自動ネゴシエートするため、要求値は無視して現在値を返す。
  @override
  Future<Result<int, MtuError>> requestMtu(String deviceId, int mtu) =>
      _invoke('requestMtu', {'deviceId': deviceId, 'mtu': mtu},
          () => _hostApi.getMtu(deviceId), mapMtuError);
```

6. `associate` / `setDevicePresenceObservation` はネイティブを呼ばず非対応エラー:

```dart
  @override
  Future<Result<String, AssociateError>> associate({DeepskyScanFilter? filter}) {
    _observer?.onMethodStart('associate', const {});
    const result = Result<String, AssociateError>.error(AssociateNotSupported());
    _observer?.onMethodEnd('associate', result);
    return Future.value(result);
  }

  @override
  Future<Result<void, PresenceError>> setDevicePresenceObservation(
      String deviceId,
      {required bool enabled}) {
    _observer?.onMethodStart('setDevicePresenceObservation', {'deviceId': deviceId});
    const result = Result<void, PresenceError>.error(PresenceNotSupported());
    _observer?.onMethodEnd('setDevicePresenceObservation', result);
    return Future.value(result);
  }
```

7. ストリーム: `_companionEvents` コントローラを削除し `companionEvents => const Stream.empty()`。代わりに `_restoredConnections` コントローラを追加し、`BleCallbacksApi` の `onStateRestored` を実装:

```dart
  final _restoredConnections = StreamController<List<String>>.broadcast();

  @override
  Stream<BleCompanionEvent> get companionEvents => const Stream.empty();

  @override
  Stream<List<String>> get restoredConnections => _restoredConnections.stream;

  @override
  void onStateRestored(List<String> connectedDeviceIds) {
    _observer?.onCallback('onStateRestored', connectedDeviceIds);
    _restoredConnections.add(connectedDeviceIds);
  }
```

8. `onScanFailed` / `onDeviceAppeared` / `onDeviceDisappeared` はiOSのFlutterApiに存在しないため実装しない。`scanErrors => const Stream.empty()`。
9. `startScan` はAndroid設定ではなくDarwin設定を渡す。`converters.dart` では `androidScanSettingsToMessage` の代わりに以下を定義する:

```dart
DarwinScanSettingsMessage darwinScanSettingsToMessage(
        DeepskyDarwinScanSetting s) =>
    DarwinScanSettingsMessage(
      allowDuplicates: s.allowDuplicates,
      solicitedServiceUuids:
          s.solicitedServiceUuids.map((u) => u.value).toList(),
    );
```

`bridge.dart` 側:

```dart
  @override
  Future<Result<void, ScanError>> startScan(
          {DeepskyScanFilter? filter,
          DeepskyScanOptions options = const DeepskyScanOptions()}) =>
      _invoke(
          'startScan',
          {'hasFilter': filter != null},
          () => _hostApi.startScan(scanFilterToMessage(filter),
              darwinScanSettingsToMessage(options.darwin)),
          mapScanError);
```

- [ ] **Step 1: 失敗するテストを書く**

`test/bridge_test.dart`(FakeはTask 14のものをiOSのHostApiシグネチャに合わせる: `associate`等なし、`getMtu`あり、`initialize` は `InitializeRequestMessage(isBackground:, restoreIdentifier:)`):

```dart
import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:deepsky_bluetooth_ios/deepsky_bluetooth_ios.dart';
import 'package:deepsky_bluetooth_ios_bridge/deepsky_bluetooth_ios_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

class _FakeHostApi extends BleHostApi {
  final calls = <String>[];
  PlatformException? thrown;
  InitializeRequestMessage? lastInitialize;

  void _maybeThrow() {
    final t = thrown;
    if (t != null) throw t;
  }

  @override
  Future<void> initialize(InitializeRequestMessage request) async {
    _maybeThrow();
    lastInitialize = request;
    calls.add('initialize');
  }

  @override
  Future<void> notifyDartReady() async => calls.add('notifyDartReady');

  @override
  Future<void> startScan(
      ScanFilterMessage? filter, DarwinScanSettingsMessage settings) async {
    _maybeThrow();
    calls.add('startScan');
  }

  @override
  Future<void> stopScan() async => calls.add('stopScan');

  @override
  Future<void> connect(String deviceId) async => calls.add('connect');

  @override
  Future<void> disconnect(String deviceId) async => calls.add('disconnect');

  @override
  Future<List<ServiceMessage>> discoverServices(String deviceId) async => [];

  @override
  Future<Uint8List> readCharacteristic(CharacteristicTargetMessage target) async =>
      Uint8List(0);

  @override
  Future<void> writeCharacteristic(CharacteristicTargetMessage target,
      Uint8List value, bool withResponse) async {}

  @override
  Future<void> setNotify(CharacteristicTargetMessage target, bool enabled) async {}

  @override
  Future<Uint8List> readDescriptor(DescriptorTargetMessage target) async =>
      Uint8List(0);

  @override
  Future<void> writeDescriptor(
      DescriptorTargetMessage target, Uint8List value) async {}

  @override
  Future<int> getMtu(String deviceId) async => 185;

  @override
  Future<int> readRssi(String deviceId) async => -42;

  @override
  Future<void> dispose() async => calls.add('dispose');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHostApi host;
  late DeepskyBluetoothIosBridge bridge;

  setUp(() {
    host = _FakeHostApi();
    bridge = DeepskyBluetoothIosBridge(hostApi: host);
  });

  test('background config requires ios restore identifier', () async {
    final r = await bridge.initialize(const DeepskyBluetoothConfig.background());
    expect(r.err, isA<BackgroundConfigMissing>());
    expect(host.calls, isEmpty);
  });

  test('background config passes restore identifier to native', () async {
    final r = await bridge.initialize(const DeepskyBluetoothConfig.background(
        ios: IosBackgroundConfig(restoreIdentifier: 'rid')));
    expect(r.isOk, isTrue);
    expect(host.lastInitialize?.restoreIdentifier, 'rid');
  });

  test('requestMtu delegates to getMtu and returns current value', () async {
    final r = await bridge.requestMtu('dev', 512);
    expect(r.unwrap(), 185);
  });

  test('associate is not supported on iOS', () async {
    final r = await bridge.associate();
    expect(r.err, isA<AssociateNotSupported>());
  });

  test('onStateRestored emits restored device ids', () async {
    final future = bridge.restoredConnections.first;
    bridge.onStateRestored(['dev-1']);
    expect(await future, ['dev-1']);
  });
}
```

- [ ] **Step 2: 失敗確認 → 実装 → 成功確認**

Run: `flutter test` → FAIL → 上記差分どおり実装 → `flutter test` → All tests passed

- [ ] **Step 3: テンプレートテスト削除・export置換・コミット**

`lib/deepsky_bluetooth_ios_bridge.dart` は `export 'src/bridge.dart'; export 'src/error_mapper.dart';` に置換。

```powershell
git rm packages/deepsky_bluetooth_ios_bridge/test/deepsky_bluetooth_ios_bridge_test.dart
git add packages/deepsky_bluetooth_ios_bridge && git commit -m "feat(ios-bridge): map pigeon api to platform interface with Result errors"
```

---

### Task 16: deepsky_bluetooth_macos_bridge(TDD・バックグラウンド拒否)

**Files:**
- Create: `packages/deepsky_bluetooth_macos_bridge/lib/src/converters.dart`
- Create: `packages/deepsky_bluetooth_macos_bridge/lib/src/error_mapper.dart`
- Create: `packages/deepsky_bluetooth_macos_bridge/lib/src/bridge.dart`
- Modify: `packages/deepsky_bluetooth_macos_bridge/lib/deepsky_bluetooth_macos_bridge.dart`
- Create: `packages/deepsky_bluetooth_macos_bridge/test/bridge_test.dart`
- Delete: `packages/deepsky_bluetooth_macos_bridge/test/deepsky_bluetooth_macos_bridge_test.dart`(テンプレート)

Task 15と同じ構造(import先は `package:deepsky_bluetooth_macos/deepsky_bluetooth_macos.dart`)。**iOS bridgeとの差分(完全列挙):**

1. クラス名は `DeepskyBluetoothMacosBridge`。
2. `converters.dart` に `configToMessage` は不要(initializeはbool1引数)。
3. **要件の核心:** `initialize` はBackgroundConfigを受けたらネイティブを呼ばずに `BackgroundNotSupported` を返す:

```dart
  @override
  Future<Result<void, InitializeError>> initialize(
      DeepskyBluetoothConfig config) {
    if (config is BackgroundConfig) {
      _observer?.onMethodStart('initialize', {'config': 'background'});
      const result =
          Result<void, InitializeError>.error(BackgroundNotSupported());
      _observer?.onMethodEnd('initialize', result);
      return Future.value(result);
    }
    return _invoke('initialize', const {'isBackground': false}, () async {
      await _hostApi.initialize(false);
      // Task 14と同じ: initialize成功後・notifyDartReady前に登録
      BleCallbacksApi.setUp(this, binaryMessenger: _binaryMessenger);
      await _hostApi.notifyDartReady();
    }, mapInitializeError);
  }
```

4. `restoredConnections => const Stream.empty()`(`onStateRestored` コールバックは存在しない)。`companionEvents` / `scanErrors` も `const Stream.empty()`。
5. `requestMtu` はiOS bridge同様 `getMtu` 委譲。`associate` / `setDevicePresenceObservation` はiOS bridge同様の非対応エラー(コードはTask 15の6と同一)。

- [ ] **Step 1: 失敗するテストを書く**

`test/bridge_test.dart`(FakeはTask 15のものから `initialize` を `Future<void> initialize(bool isBackground)` に変更したもの):

```dart
import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:deepsky_bluetooth_macos_bridge/deepsky_bluetooth_macos_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

// _FakeHostApi はTask 15のものと同一(initializeのみ bool isBackground 引数)のため省略せず実装すること

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('background instance is an error on macOS (requirement)', () async {
    final host = _FakeHostApi();
    final bridge = DeepskyBluetoothMacosBridge(hostApi: host);
    final r = await bridge.initialize(const DeepskyBluetoothConfig.background());
    expect(r.err, isA<BackgroundNotSupported>());
    expect(host.calls, isEmpty, reason: 'ネイティブを呼ばずにエラーを返す');
  });

  test('foreground instance initializes normally', () async {
    final host = _FakeHostApi();
    final bridge = DeepskyBluetoothMacosBridge(hostApi: host);
    final r = await bridge.initialize(const DeepskyBluetoothConfig.foreground());
    expect(r.isOk, isTrue);
    expect(host.calls, ['initialize', 'notifyDartReady']);
  });
}
```

- [ ] **Step 2: 失敗確認 → 実装 → 成功確認**

Run: `flutter test` → FAIL → 差分どおり実装 → `flutter test` → All tests passed

- [ ] **Step 3: テンプレートテスト削除・export置換・コミット**

```powershell
git rm packages/deepsky_bluetooth_macos_bridge/test/deepsky_bluetooth_macos_bridge_test.dart
git add packages/deepsky_bluetooth_macos_bridge && git commit -m "feat(macos-bridge): platform interface impl; background instantiation is an error"
```

---

### Task 17: 本体 deepsky_bluetooth — 公開API(TDD)

**Files:**
- Create: `lib/src/platform_resolver.dart`
- Create: `lib/src/deepsky_bluetooth.dart`
- Modify: `lib/deepsky_bluetooth.dart`(テンプレート全置換)
- Modify: `test/deepsky_bluetooth_test.dart`(テンプレート全置換)

- [ ] **Step 1: 失敗するテストを書く**

`test/deepsky_bluetooth_test.dart` 全文:

```dart
import 'package:deepsky_bluetooth/deepsky_bluetooth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/steady.dart';
import 'dart:typed_data';

final class _RecordingObserver implements DeepskyBluetoothObserver {
  final events = <String>[];
  @override
  void onMethodStart(String methodName, Map<String, Object?> arguments) =>
      events.add('start:$methodName');
  @override
  void onMethodEnd(String methodName, Result<Object?, Exception> result) =>
      events.add('end:$methodName:${result.isOk ? 'ok' : 'err'}');
  @override
  void onCallback(String callbackName, Object? payload) =>
      events.add('cb:$callbackName');
}

final class _FakePlatform extends DeepskyBluetoothPlatform {
  final calls = <String>[];
  InitializeError? initializeError;
  DeepskyBluetoothConfig? lastConfig;
  final scanResultsController = StreamController<BleScanResult>.broadcast();

  @override
  Future<Result<void, InitializeError>> initialize(
      DeepskyBluetoothConfig config) async {
    calls.add('initialize');
    lastConfig = config;
    final e = initializeError;
    return e == null ? const Result.ok(null) : Result.error(e);
  }

  @override
  Future<Result<void, ScanError>> startScan(
      {DeepskyScanFilter? filter,
      DeepskyScanOptions options = const DeepskyScanOptions()}) async {
    calls.add('startScan');
    return const Result.ok(null);
  }

  @override
  Future<Result<void, ScanError>> stopScan() async => const Result.ok(null);
  @override
  Future<Result<void, ConnectError>> connect(String deviceId) async {
    calls.add('connect:$deviceId');
    return const Result.ok(null);
  }

  @override
  Future<Result<void, DisconnectError>> disconnect(String deviceId) async =>
      const Result.ok(null);
  @override
  Future<Result<List<BleService>, DiscoverServicesError>> discoverServices(
          String deviceId) async =>
      const Result.ok([]);
  @override
  Future<Result<Uint8List, CharacteristicReadError>> readCharacteristic(
          BleCharacteristicTarget target) async =>
      Result.ok(Uint8List(0));
  @override
  Future<Result<void, CharacteristicWriteError>> writeCharacteristic(
          BleCharacteristicTarget target, Uint8List value,
          {required bool withResponse}) async =>
      const Result.ok(null);
  @override
  Future<Result<void, NotifyError>> setNotify(BleCharacteristicTarget target,
          {required bool enabled}) async =>
      const Result.ok(null);
  @override
  Future<Result<Uint8List, DescriptorReadError>> readDescriptor(
          BleDescriptorTarget target) async =>
      Result.ok(Uint8List(0));
  @override
  Future<Result<void, DescriptorWriteError>> writeDescriptor(
          BleDescriptorTarget target, Uint8List value) async =>
      const Result.ok(null);
  @override
  Future<Result<int, MtuError>> requestMtu(String deviceId, int mtu) async =>
      const Result.ok(23);
  @override
  Future<Result<int, RssiError>> readRssi(String deviceId) async =>
      const Result.ok(-40);
  @override
  Future<Result<String, AssociateError>> associate(
          {DeepskyScanFilter? filter}) async =>
      const Result.ok('AA:BB');
  @override
  Future<Result<void, PresenceError>> setDevicePresenceObservation(
          String deviceId,
          {required bool enabled}) async =>
      const Result.ok(null);
  @override
  Future<Result<void, DisposeError>> dispose() async => const Result.ok(null);
  @override
  Stream<BleScanResult> get scanResults => scanResultsController.stream;
  @override
  Stream<ScanError> get scanErrors => const Stream.empty();
  @override
  Stream<BleConnectionEvent> get connectionEvents => const Stream.empty();
  @override
  Stream<BleCharacteristicValue> get characteristicValues =>
      const Stream.empty();
  @override
  Stream<BleCompanionEvent> get companionEvents => const Stream.empty();
  @override
  Stream<List<String>> get restoredConnections => const Stream.empty();
}

void main() {
  test('foreground initializes the platform and returns an instance', () async {
    final platform = _FakePlatform();
    final r = await DeepskyBluetooth.foreground(platform: platform);
    expect(r.isOk, isTrue);
    expect(platform.calls, ['initialize']);
    expect(platform.lastConfig, isA<ForegroundConfig>());
  });

  test('background forwards ios/android configs to the platform', () async {
    final platform = _FakePlatform();
    final r = await DeepskyBluetooth.background(
      ios: const IosBackgroundConfig(restoreIdentifier: 'rid'),
      android: const AndroidCompanionDeviceConfig(),
      platform: platform,
    );
    expect(r.isOk, isTrue);
    final config = platform.lastConfig;
    expect(config, isA<BackgroundConfig>());
    final background = config! as BackgroundConfig;
    expect(background.ios?.restoreIdentifier, 'rid');
    expect(background.android, isA<AndroidCompanionDeviceConfig>());
  });

  test('foreground propagates initialize error', () async {
    final platform = _FakePlatform()..initializeError = const AlreadyInitialized();
    final r = await DeepskyBluetooth.foreground(platform: platform);
    expect(r.err, isA<AlreadyInitialized>());
  });

  test('foreground fails on unsupported platform', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final r = await DeepskyBluetooth.foreground();
    expect(r.err, isA<UnsupportedPlatform>());
  });

  test('methods delegate to platform with observer hooks', () async {
    final platform = _FakePlatform();
    final observer = _RecordingObserver();
    final ble = (await DeepskyBluetooth.foreground(
            observer: observer, platform: platform))
        .unwrap();
    await ble.startScan();
    expect(platform.calls, contains('startScan'));
    expect(observer.events, containsAll(['start:startScan', 'end:startScan:ok']));
  });

  test('streams notify observer on each callback', () async {
    final platform = _FakePlatform();
    final observer = _RecordingObserver();
    final ble = (await DeepskyBluetooth.foreground(
            observer: observer, platform: platform))
        .unwrap();
    final future = ble.scanResults.first;
    platform.scanResultsController.add(const BleScanResult(
        deviceId: 'dev', rssi: -1, serviceUuids: []));
    await future;
    expect(observer.events, contains('cb:scanResults'));
  });
}
```

(`dart:async` のimportを `StreamController` 用に追加すること)

- [ ] **Step 2: テストが失敗することを確認**

Run: ルートで `flutter test` → コンパイルエラーで FAIL

- [ ] **Step 3: platform_resolver.dart を実装**

`lib/src/platform_resolver.dart` 全文:

```dart
import 'package:deepsky_bluetooth_android_bridge/deepsky_bluetooth_android_bridge.dart';
import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:deepsky_bluetooth_ios_bridge/deepsky_bluetooth_ios_bridge.dart';
import 'package:deepsky_bluetooth_macos_bridge/deepsky_bluetooth_macos_bridge.dart';
import 'package:flutter/foundation.dart';

DeepskyBluetoothPlatform? resolvePlatform(DeepskyBluetoothObserver? observer) {
  if (kIsWeb) return null;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => DeepskyBluetoothAndroidBridge(observer: observer),
    TargetPlatform.iOS => DeepskyBluetoothIosBridge(observer: observer),
    TargetPlatform.macOS => DeepskyBluetoothMacosBridge(observer: observer),
    _ => null,
  };
}
```

- [ ] **Step 4: deepsky_bluetooth.dart(本体クラス)を実装**

`lib/src/deepsky_bluetooth.dart` 全文:

```dart
import 'dart:typed_data';

import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:steady/steady.dart';

import 'platform_resolver.dart';

/// Foreground/Backgroundを明示して生成するBLE Centralクライアント。
///
/// - [DeepskyBluetooth.foreground]: 通常のBLE利用。
/// - [DeepskyBluetooth.background]: iOSはState Restoration(restoreIdentifier必須)、
///   AndroidはForeground Service / CompanionDeviceのいずれかを選択。
///   macOSでのbackground生成は [BackgroundNotSupported] エラー。
class DeepskyBluetooth {
  DeepskyBluetooth._(this._platform, this._observer);

  final DeepskyBluetoothPlatform _platform;
  final DeepskyBluetoothObserver? _observer;

  /// フォアグラウンド用インスタンスを生成する。
  static Future<Result<DeepskyBluetooth, InitializeError>> foreground({
    DeepskyBluetoothObserver? observer,
    @visibleForTesting DeepskyBluetoothPlatform? platform,
  }) =>
      _create('foreground', const ForegroundConfig(), observer, platform);

  /// バックグラウンド用インスタンスを生成する。
  ///
  /// [ios] はiOSで必須(State Restoration識別子)。
  /// [android] はAndroidで必須(ForegroundService / CompanionDeviceの選択)。
  /// 対象プラットフォームで設定が不足している場合は [BackgroundConfigMissing]、
  /// macOSでは常に [BackgroundNotSupported] を返す。
  static Future<Result<DeepskyBluetooth, InitializeError>> background({
    IosBackgroundConfig? ios,
    AndroidBackgroundConfig? android,
    DeepskyBluetoothObserver? observer,
    @visibleForTesting DeepskyBluetoothPlatform? platform,
  }) =>
      _create('background', BackgroundConfig(ios: ios, android: android),
          observer, platform);

  static Future<Result<DeepskyBluetooth, InitializeError>> _create(
    String mode,
    DeepskyBluetoothConfig config,
    DeepskyBluetoothObserver? observer,
    DeepskyBluetoothPlatform? platform,
  ) async {
    observer?.onMethodStart(mode, const {});
    final p = platform ?? resolvePlatform(observer);
    if (p == null) {
      const result =
          Result<DeepskyBluetooth, InitializeError>.error(UnsupportedPlatform());
      observer?.onMethodEnd(mode, result);
      return result;
    }
    final result = (await p.initialize(config))
        .map((_) => DeepskyBluetooth._(p, observer));
    observer?.onMethodEnd(mode, result);
    return result;
  }

  Future<Result<T, E>> _observed<T, E extends Exception>(
    String method,
    Map<String, Object?> args,
    Future<Result<T, E>> Function() body,
  ) async {
    _observer?.onMethodStart(method, args);
    final result = await body();
    _observer?.onMethodEnd(method, result);
    return result;
  }

  Stream<T> _observedStream<T>(String name, Stream<T> stream) => stream.map((e) {
        _observer?.onCallback(name, e);
        return e;
      });

  Future<Result<void, ScanError>> startScan(
          {DeepskyScanFilter? filter,
          DeepskyScanOptions options = const DeepskyScanOptions()}) =>
      _observed('startScan', {'hasFilter': filter != null},
          () => _platform.startScan(filter: filter, options: options));

  Future<Result<void, ScanError>> stopScan() =>
      _observed('stopScan', const {}, _platform.stopScan);

  Future<Result<void, ConnectError>> connect(String deviceId) =>
      _observed('connect', {'deviceId': deviceId},
          () => _platform.connect(deviceId));

  Future<Result<void, DisconnectError>> disconnect(String deviceId) =>
      _observed('disconnect', {'deviceId': deviceId},
          () => _platform.disconnect(deviceId));

  Future<Result<List<BleService>, DiscoverServicesError>> discoverServices(
          String deviceId) =>
      _observed('discoverServices', {'deviceId': deviceId},
          () => _platform.discoverServices(deviceId));

  Future<Result<Uint8List, CharacteristicReadError>> readCharacteristic(
          BleCharacteristicTarget target) =>
      _observed('readCharacteristic',
          {'characteristicUuid': target.characteristicUuid},
          () => _platform.readCharacteristic(target));

  Future<Result<void, CharacteristicWriteError>> writeCharacteristic(
          BleCharacteristicTarget target, Uint8List value,
          {required bool withResponse}) =>
      _observed(
          'writeCharacteristic',
          {
            'characteristicUuid': target.characteristicUuid,
            'withResponse': withResponse,
          },
          () => _platform.writeCharacteristic(target, value,
              withResponse: withResponse));

  Future<Result<void, NotifyError>> setNotify(BleCharacteristicTarget target,
          {required bool enabled}) =>
      _observed(
          'setNotify',
          {'characteristicUuid': target.characteristicUuid, 'enabled': enabled},
          () => _platform.setNotify(target, enabled: enabled));

  Future<Result<Uint8List, DescriptorReadError>> readDescriptor(
          BleDescriptorTarget target) =>
      _observed('readDescriptor', {'descriptorUuid': target.descriptorUuid},
          () => _platform.readDescriptor(target));

  Future<Result<void, DescriptorWriteError>> writeDescriptor(
          BleDescriptorTarget target, Uint8List value) =>
      _observed('writeDescriptor', {'descriptorUuid': target.descriptorUuid},
          () => _platform.writeDescriptor(target, value));

  Future<Result<int, MtuError>> requestMtu(String deviceId, int mtu) =>
      _observed('requestMtu', {'deviceId': deviceId, 'mtu': mtu},
          () => _platform.requestMtu(deviceId, mtu));

  Future<Result<int, RssiError>> readRssi(String deviceId) =>
      _observed('readRssi', {'deviceId': deviceId},
          () => _platform.readRssi(deviceId));

  Future<Result<String, AssociateError>> associate({DeepskyScanFilter? filter}) =>
      _observed('associate', {'hasFilter': filter != null},
          () => _platform.associate(filter: filter));

  Future<Result<void, PresenceError>> setDevicePresenceObservation(
          String deviceId,
          {required bool enabled}) =>
      _observed(
          'setDevicePresenceObservation',
          {'deviceId': deviceId, 'enabled': enabled},
          () => _platform.setDevicePresenceObservation(deviceId,
              enabled: enabled));

  Future<Result<void, DisposeError>> dispose() =>
      _observed('dispose', const {}, _platform.dispose);

  Stream<BleScanResult> get scanResults =>
      _observedStream('scanResults', _platform.scanResults);
  Stream<ScanError> get scanErrors =>
      _observedStream('scanErrors', _platform.scanErrors);
  Stream<BleConnectionEvent> get connectionEvents =>
      _observedStream('connectionEvents', _platform.connectionEvents);
  Stream<BleCharacteristicValue> get characteristicValues =>
      _observedStream('characteristicValues', _platform.characteristicValues);
  Stream<BleCompanionEvent> get companionEvents =>
      _observedStream('companionEvents', _platform.companionEvents);
  Stream<List<String>> get restoredConnections =>
      _observedStream('restoredConnections', _platform.restoredConnections);
}
```

- [ ] **Step 5: exportファイルを置換**

`lib/deepsky_bluetooth.dart` 全文:

```dart
library;

export 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
export 'package:steady/steady.dart';

export 'src/deepsky_bluetooth.dart';
```

- [ ] **Step 6: テストが通ることを確認**

Run: ルートで `flutter test`
Expected: All tests passed

- [ ] **Step 7: コミット**

```powershell
git add lib test pubspec.yaml && git commit -m "feat: public DeepskyBluetooth api with platform resolution and observer"
```

---

### Task 18: ルートexampleアプリ

**Files:**

- Create: `example/`(flutter create)
- Modify: `pubspec.yaml`(workspaceにexample追加)
- Modify: `example/pubspec.yaml`
- Modify: `example/android/app/build.gradle.kts`(minSdk 31)
- Modify: `example/ios/Runner/Info.plist`
- Modify: `example/macos/Runner/DebugProfile.entitlements` / `Release.entitlements` / `Info.plist`
- Modify: `example/lib/main.dart`(全置換)

- [ ] **Step 1: exampleアプリを生成**

```powershell
flutter create example --platforms=android,ios,macos --org com.example --project-name deepsky_bluetooth_example
```

- [ ] **Step 2: workspaceへ組み込み・依存追加**

ルート `pubspec.yaml` の `workspace:` に `- example` を追加。
`example/pubspec.yaml` に `resolution: workspace` を追加し、`dependencies:` に:

```yaml
  deepsky_bluetooth:
    path: ../
  permission_handler: ^12.0.0
```

Run: ルートで `flutter pub get` → `Got dependencies!`

- [ ] **Step 3: プラットフォーム設定**

1. `example/android/app/build.gradle.kts`: `minSdk = 31`
2. `example/ios/Runner/Info.plist` の `<dict>` 内に追加:

```xml
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>BLE devices are used by this example.</string>
    <key>UIBackgroundModes</key>
    <array>
      <string>bluetooth-central</string>
    </array>
```

3. `example/macos/Runner/DebugProfile.entitlements` と `Release.entitlements` の `<dict>` 内に追加:

```xml
	<key>com.apple.security.device.bluetooth</key>
	<true/>
```

4. `example/macos/Runner/Info.plist` に `NSBluetoothAlwaysUsageDescription` を追加(iOSと同文)。

- [ ] **Step 4: main.dartを実装**

`example/lib/main.dart` 全文:

```dart
import 'dart:async';

import 'package:deepsky_bluetooth/deepsky_bluetooth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const ExampleApp());
}

/// Observerフックの内容を画面に流すロガー。
class UiLogObserver implements DeepskyBluetoothObserver {
  UiLogObserver(this.onLog);
  final void Function(String line) onLog;

  @override
  void onMethodStart(String methodName, Map<String, Object?> arguments) =>
      onLog('> $methodName $arguments');

  @override
  void onMethodEnd(String methodName, Result<Object?, Exception> result) =>
      onLog(result.isOk ? 'OK $methodName' : 'ERR $methodName: ${result.err}');

  @override
  void onCallback(String callbackName, Object? payload) =>
      onLog('* $callbackName');
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: ModeSelectionPage());
}

class ModeSelectionPage extends StatelessWidget {
  const ModeSelectionPage({super.key});

  static const _restoreId = 'com.example.deepsky.restore';
  static const _notification = AndroidNotificationConfig(
    channelId: 'ble',
    channelName: 'BLE',
    title: 'deepsky_bluetooth',
    text: 'BLE link active',
  );

  Future<void> _start(
    BuildContext context,
    Future<Result<DeepskyBluetooth, InitializeError>> Function(
            DeepskyBluetoothObserver observer)
        create,
  ) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.notification,
      ].request();
    }
    if (!context.mounted) return;
    final logs = <String>[];
    final observer = UiLogObserver(logs.add);
    final result = await create(observer);
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final data):
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => HomePage(ble: data, observer: observer, logs: logs)));
      case Err(:final error):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('init error: $error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('deepsky_bluetooth example')),
        body: ListView(children: [
          ListTile(
            title: const Text('Foreground'),
            onTap: () => _start(
                context, (observer) => DeepskyBluetooth.foreground(observer: observer)),
          ),
          ListTile(
            title: const Text('Background (iOS restore / Android FGS)'),
            onTap: () => _start(
                context,
                (observer) => DeepskyBluetooth.background(
                      ios: const IosBackgroundConfig(restoreIdentifier: _restoreId),
                      android: const AndroidForegroundServiceConfig(
                          notification: _notification),
                      observer: observer,
                    )),
          ),
          ListTile(
            title: const Text('Background (iOS restore / Android CompanionDevice)'),
            onTap: () => _start(
                context,
                (observer) => DeepskyBluetooth.background(
                      ios: const IosBackgroundConfig(restoreIdentifier: _restoreId),
                      android: const AndroidCompanionDeviceConfig(),
                      observer: observer,
                    )),
          ),
        ]),
      );
}

class HomePage extends StatefulWidget {
  const HomePage(
      {super.key, required this.ble, required this.observer, required this.logs});
  final DeepskyBluetooth ble;
  final UiLogObserver observer;
  final List<String> logs;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _devices = <String, BleScanResult>{};
  final _subscriptions = <StreamSubscription<void>>[];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _subscriptions.add(widget.ble.scanResults.listen((r) {
      setState(() => _devices[r.deviceId] = r);
    }));
    _subscriptions.add(widget.ble.connectionEvents.listen((_) => setState(() {})));
    _subscriptions.add(widget.ble.companionEvents.listen((_) => setState(() {})));
    _subscriptions
        .add(widget.ble.restoredConnections.listen((_) => setState(() {})));
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  Future<void> _toggleScan() async {
    final result = _scanning
        ? await widget.ble.stopScan()
        : await widget.ble.startScan();
    if (result.isOk) setState(() => _scanning = !_scanning);
  }

  Future<void> _connectAndDiscover(String deviceId) async {
    final connect = await widget.ble.connect(deviceId);
    if (connect.isErr) return;
    final services = await widget.ble.discoverServices(deviceId);
    if (!mounted) return;
    switch (services) {
      case Ok(:final data):
        showDialog<void>(
          context: context,
          builder: (_) => SimpleDialog(
            title: Text('Services of $deviceId'),
            children: [
              for (final s in data)
                ListTile(
                  title: Text(s.uuid),
                  subtitle: Text('${s.characteristics.length} characteristics'),
                ),
            ],
          ),
        );
      case Err(:final error):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('discover error: $error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Scan & Connect')),
        floatingActionButton: FloatingActionButton(
          onPressed: _toggleScan,
          child: Icon(_scanning ? Icons.stop : Icons.search),
        ),
        body: Column(children: [
          Expanded(
            child: ListView(children: [
              for (final d in _devices.values)
                ListTile(
                  title: Text(d.name ?? d.deviceId),
                  subtitle: Text('${d.deviceId}  RSSI:${d.rssi}'),
                  onTap: () => _connectAndDiscover(d.deviceId),
                ),
            ]),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 220,
            child: ListView(
              reverse: true,
              children: [
                for (final line in widget.logs.reversed)
                  Text(line, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ]),
      );
}
```

(注: steadyの `Ok`/`Err` パターンマッチを使用。フィールド名が `data`/`error` でない場合はsteady 1.2.0の定義に合わせて修正する)

- [ ] **Step 5: 検証**

Run: ルートで `flutter analyze`
Expected: No issues found
Run: `example` で `flutter build apk --debug`
Expected: ビルド成功

- [ ] **Step 6: コミット**

```powershell
git add example pubspec.yaml && git commit -m "feat: example app with mode selection, scan/connect ui and observer log"
```

---

### Task 19: README・最終検証

**Files:**
- Modify: `README.md`(全置換)
- Modify: `CHANGELOG.md`

- [ ] **Step 1: READMEを書く**

`README.md` に以下の構成で記載(コード例は実際のAPIと一致させること):

1. 概要: Foreground/Background明示型BLE Centralライブラリ(Android/iOS/macOS)
2. アーキテクチャ図(本計画冒頭の依存グラフを転記)
3. 使い方:

```dart
// フォアグラウンド利用
// final result = await DeepskyBluetooth.foreground(observer: MyObserver());

// バックグラウンド利用
final result = await DeepskyBluetooth.background(
  ios: const IosBackgroundConfig(restoreIdentifier: 'com.example.restore'),
  android: const AndroidForegroundServiceConfig(
    notification: AndroidNotificationConfig(
      channelId: 'ble', channelName: 'BLE',
      title: 'Connected', text: 'Maintaining BLE link',
    ),
  ),
  observer: MyObserver(),
);
switch (result) {
  case Ok(:final data):
    final scan = await data.startScan();
    switch (scan) {
      case Ok():
        data.scanResults.listen(print);
      case Err(:final error):
        switch (error) {
          case ScanPermissionDenied(): // 権限を案内
          case ScanBluetoothOff():     // BTオン依頼
          case ScanAlreadyScanning():  // 無視
          case ScanFailed():           // リトライ
        }
    }
  case Err(:final error):
    print(error);
}
```

4. プラットフォーム設定表: iOS(`NSBluetoothAlwaysUsageDescription`、`UIBackgroundModes: bluetooth-central`)、Android(minSdk 31、権限要求はアプリ責務、CompanionDeviceの注意点: associate→setDevicePresenceObservationの順で呼ぶ、エンジン復活時はmain()がヘッドレス実行されるためmain内で `DeepskyBluetooth.background` を呼び再接続すること、FGSモードでもタスクスワイプ除去後はヘッドレス再起動で復活するが接続は張り直しになること、ヘッドレス稼働中にアプリを開くとヘッドレスは破棄されUIエンジン側の初期化に一本化されること)、macOS(Bluetooth entitlement、backgroundはエラー)
5. ライフサイクルの説明: 1エンジン1インスタンス(2つ目の生成は `AlreadyInitialized`)。`background` インスタンスはフォアグラウンドでも全機能が使えるため、「普段はBG監視・随時フォアグラウンドでOTA(大量Write)」も単一インスタンスで行うこと。モード変更は `dispose()` → 再生成で行う
6. Observer・エラー設計の説明(sealed + switch網羅)

- [ ] **Step 2: CHANGELOGを更新**

`CHANGELOG.md` を `## 0.0.1` セクションのみにし、実装した機能の箇条書きへ置換。

- [ ] **Step 3: 最終検証(Windowsで可能な範囲)**

```powershell
flutter analyze            # ルート: No issues found
flutter test               # ルート
cd packages/deepsky_bluetooth_interface && flutter test
cd ../deepsky_bluetooth_android_bridge && flutter test
cd ../deepsky_bluetooth_ios_bridge && flutter test
cd ../deepsky_bluetooth_macos_bridge && flutter test
cd ../../example && flutter build apk --debug
```

Expected: すべて成功

- [ ] **Step 4: コミット**

```powershell
git add README.md CHANGELOG.md && git commit -m "docs: usage, platform setup, error and observer design"
```

- [ ] **Step 5: [macOSホスト・最終チェックポイント]**

macOSマシンで `cd example && flutter build ios --no-codesign --debug && flutter build macos --debug`。
実機確認項目: iOS実機でバックグラウンド復元(接続維持→アプリkill→デバイスイベントで再起動)、Android実機でFGS常駐とCDS復活(`adb shell am kill` 後のonDeviceAppeared)。

---

## セルフレビュー結果(計画作成時に実施済み)

- **要件カバレッジ:** FG/BG明示インスタンス化(Task 4/17)、3プラットフォーム(Task 6-13)、FG/BG問わずDartコールバック(FlutterApi+バッファ+notifyDartReady: Task 6-13)、iOS State Restoration(Task 12)、Android FGS/CDS選択(Task 4/9-11)、macOS BGエラー(Task 16 ※ネイティブ側防御はTask 13)、plugins=ネイティブ担当(Task 6-13)、Pigeon型安全通信(Task 6-8)、Bridgeがinterfaceへ適合(Task 14-16)、steady Result(全層)、sealedエラー+switch網羅(Task 2)、全パッケージ+プラグインのObserver(Task 5/9/12/13/14-17)— 全項目にタスクあり。
- **ライフサイクル(レビューで確定):** 1エンジン1インスタンス。FG+BG同時保持は非対応(backgroundインスタンスがフォアグラウンドでも全機能を持つため不要と判断。OTAユースケース含む)。`BleCallbacksApi.setUp` はinitialize成功後・notifyDartReady前に実行し、disposeで解除する(失敗した生成試行による稼働中インスタンスのチャネル乗っ取りを防止)。
- **スキャンAPI(レビューで確定):** フィルタは `DeepskyScanFilter`(エントリ単位OR、Androidは全カテゴリネイティブ・iOS/macOSはserviceUuid以外ソフトウェアフィルタ)、設定は `DeepskyScanOptions`(android/darwin)、UUIDは `DeepskyUuid`(util、fromString/fromByteArray)。`BleScanResult.raw` はAndroidのみ(`ScanRecord.getBytes()`)でiOS/macOSはnull(CoreBluetoothが生バイト列を非公開のため)。`DeepskyAndroidScanType`(active/passive)はhidden APIのため対象外。
- **Isolate/エンジン方針(レビューで確定):** 専用バックグラウンドIsolateは設けず、イベントは常に生きているエンジンのルートIsolateへ。Androidは「CDSイベント時/FGS稼働中のエンジン消失時にヘッドレスで `main()` 再実行」「UIエンジンattach時にヘッドレス破棄(接続は引き継がず再接続)」「エンジン破棄時は接続closeのみでFGSは `dispose()` まで停止しない」の3規則(Task 9-11の `HeadlessEngineLauncher` / `onEngineDetached` / `DeepskyForegroundService.isRunning`)。
- **util分離(ユーザー要望):** sealedエラー型・`BleErrorCode` 定数・`BleUuid` ユーティリティは純Dartの `deepsky_bluetooth_util`(Task 1-2)に置き、interfaceはそれを再exportするのみ。pluginsはutil/interfaceに依存せず(Pigeon生成物のみ)、エラーコード文字列はネイティブ定数(Kotlin/Swiftの `BleErrorCode`)とutilの `BleErrorCode` を一致させる規約で結合する。
- **既知のトレードオフ(実装時に注意):**
  - Task 13(macOS)はiOSファイルのコピー+完全列挙差分方式。差分適用漏れに注意。
  - Task 15/16のbridgeは「Task 14と同一+列挙差分」方式。実装時はTask 14のコードを正として書き写す。
  - Swift/KotlinはWindowsでコンパイル検証できない箇所がある(macOSチェックポイントで吸収)。
  - Pigeon生成APIの細部(`setUp` シグネチャ、Kotlinの `Long`、Swiftの `PigeonError` 名)はpigeonバージョンにより微差があり得る。生成物を見て合わせる。
  - steadyの `Ok`/`Err` パターンマッチのフィールド名(`data`/`error`)はパッケージ実物(`%PUB_CACHE%/hosted/pub.dev/steady-1.2.0/lib/src/result.dart`)で確認済み。
- **型整合:** util/interface定義(Task 2-5)とbridge/本体の参照名を相互確認済み(`BleCharacteristicTarget`、`setNotify(enabled:)`、`requestMtu`、`restoredConnections` 等)。
