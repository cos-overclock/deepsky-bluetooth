# deepsky_bluetooth 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Foreground/Backgroundを明示的に分けたBLE Centralライブラリ(Android/iOS/macOS対応、Pigeon + steady Result型 + sealedエラー + Observer)を構築する。

**Architecture:** federatedプラグイン風の構成。最下層の `packages/deepsky_bluetooth_util`(純Dart・依存なし)がsealedエラー型・エラーコード定数・UUIDユーティリティを提供する。`packages/deepsky_bluetooth_interface` が抽象(モデル・Observer・Platform抽象クラス。エラー型はutilを再export)を定義し、`plugins/deepsky_bluetooth_{android,ios,macos}` がPigeon定義+ネイティブ実装(Kotlin/Swift)を持ち、`packages/deepsky_bluetooth_*_bridge` がPigeon生成型をinterface型へ変換しPlatformExceptionをsealedエラーへマップする。ルートの `deepsky_bluetooth` が公開APIで、`Platform` 判定でbridgeを選択する。pluginsはutil/interfaceのどちらにも依存しない(Pigeon生成物のみ)。

**Tech Stack:** Flutter (pub workspace), Pigeon, steady 1.2.0 (Result型), Kotlin (BluetoothGatt / ForegroundService / CompanionDeviceManager+Service), Swift (CoreBluetooth + State Restoration)。

---

> ## ⚠️ spec 優先(必読・実装前に確認)
>
> **公開API・接続・GATT・自動再接続・バックグラウンド復活・CompanionDevice** については
> [specs/2026-06-15-connection-api-and-auto-reconnect-design.md](../specs/2026-06-15-connection-api-and-auto-reconnect-design.md)
> が**唯一の規範API契約**であり本planに優先する。本plan内のコード片は実装手順を示す
> **非規範スケッチ**で、specと不一致ならコード片を採用せず同じ変更で更新する。
> `※ non-normative; spec参照` と同義として全コード片へこの規則を一括適用する。主な差分:
>
> | 論点 | 旧plan(下記タスクの旧コード) | spec の決定(優先) | 反映タスク |
> |---|---|---|---|
> | API スタイル | フラット手続き(`connect(deviceId)` / `readCharacteristic(target)`) | `BluetoothDevice` ハンドル + active `BleService/Characteristic/Descriptor` | Task 3,5,17 |
> | ストリーム | グローバル(`connectionEvents`/`characteristicValues`/`companionEvents`) | per-device / per-characteristic broadcast | Task 3,5,17 |
> | 探索DTO 名 | `BleService`(データ) | `BleServiceInfo`/`BleCharacteristicInfo`/`BleDescriptorInfo`(active 名と衝突回避) | Task 3,5 |
> | read 戻り値 | — | **`Result<Uint8List, …>` を返す**。`values` は notify/indicate 専用 | Task 5,9,12,13,17 |
> | 接続状態 | 4状態 | `reconnecting` 追加(5状態)+ `disconnected(reason)` を持つ公開イベント + body所有の状態マシン | Task 3,17 |
> | 自動再接続 | なし | 1状態マシン + 3駆動源(Dartループ/iOS保留接続/CDM presence) | Task 17 |
> | id 型 | 生 `String` | `DeepskyDeviceId`(util) | Task 2,3,5,14-17 |
> | GATT直列化 | なし | デバイス単位の操作キュー + `(epoch,opSeq)` 相関。**タイムアウト=接続再生成** | Task 9,12,13 |
> | 接続世代 epoch | なし | native owner が接続実体生成ごとに採番し、body は受領・照合。旧世代イベント破棄 | Task 3,5,6,9,12,17 |
> | 属性 handle | uuid 座標のみ | 探索時採番の `handle` で操作/通知/フィルタ相関(重複UUID対応) | Task 3,5,6,9,12,17 |
> | active GATT 寿命 | 暗黙 | epoch 退役時に旧active objectの `values` を終了。再探索・再購読が必要 | Task 3,17,18 |
> | iOS read/notify | — | Android 完全分離 / iOS 契約化(`strictRead`+`...AmbiguousWhileNotifying`) | Task 12,13 |
> | connect() 完了 | — | autoReconnect:true=armed で即 Ok(timeout 無視) | Task 17 |
> | 再接続失敗 | Observerのみ | `connectionStates` の `disconnected(reason)`。終端理由は自動再接続停止 | Task 3,5,6-8,17-19 |
> | servicesキャッシュ | 再接続後も残り得る | epoch退役時にnull、新epochの探索/resyncでのみ再設定 | Task 17 |
> | handoverバッファ | 無制限 | 256件または30秒、古いnotify/presenceから破棄しObserver警告 | Task 9,11-13 |
> | エンジン所有 | 1エンジン1インスタンス | プロセスグローバル owner + `attach→Dart ready→resync→ack` | Task 9,11,17 |
> | ヘッドレス復活 | `main()` 再実行 | **専用 `@pragma('vm:entry-point')` エントリポイント**実行 | Task 11,17,18 |
> | CompanionDevice | deprecated 直書き(2分岐) | `CompanionDeviceController` で **31–32/33–35/36+ の3分岐**統合 | Task 11 |
>
> 各タスク冒頭の **[spec反映]** 注記も参照すること。

---

## 確定済みの設計判断(ユーザー回答)

| 項目 | 決定 |
| --- | --- |
| BLE機能範囲 | スキャン+接続管理、GATT基本操作(探索/Read/Write/Notify/Indicate)、拡張操作(MTU/RSSI/ディスクリプタ)。ボンディングは対象外 |
| CompanionDevice | `associate()`(デバイス選択ダイアログ)もライブラリAPIとして提供 |
| Android minSdk | **31**(両バックグラウンド方式が常に利用可能) |
| CDSプロセス復活 | ヘッドレスFlutterEngineで**アプリ登録の専用 `@pragma('vm:entry-point')` バックグラウンドエントリポイント**を実行(`main()`/`runApp()` は実行しない。iOS State RestorationとはUI初期化を避ける点だけを対応させる。spec「バックグラウンド復活」) |
| テスト範囲 | Dartテスト + Kotlin local JVM unit test + macOS上のSwift XCTest。Bluetooth API adapterはexample実機確認 |

## 設計ルール

- **インスタンス化API:** 利用者は `DeepskyBluetooth.foreground({observer})` / `DeepskyBluetooth.background({ios, android, observer})` で生成する(モードはメソッド名で明示)。`DeepskyBluetoothConfig` は本体→bridge→ネイティブ間の内部転送型であり、利用者が直接組み立てるのは `IosBackgroundConfig` / `AndroidBackgroundConfig`(FGS/CompanionDeviceのsealed)のみ。
- **ライフサイクル:** 同一Dart isolate内で同時に生成できるインスタンスは1つ。2つ目は `AlreadyInitialized`。
  別engineからの初期化はheadless→UI handoverとして拒否せず、native ownerの候補sinkになる。
  sink切替は **engine attach(候補) → `BleCallbacksApi.setUp` → `notifyDartReady(engineToken)` →
  state resync → `ackStateResync` → 旧engine破棄** の順序を厳守する。
  `background` インスタンスはフォアグラウンドでも全APIを利用できる。`dispose()` 後は当該Dart
  インスタンスを再利用できないが、新しい `foreground()` / `background()` は生成できる。
- **Result型:** 全公開メソッドは `Future<Result<T, XxxError>>` を返す。`try-catch` はPigeon境界(PlatformException→Result変換ヘルパー)のみ許可。Kotlin側は `kotlin.Result`、Swift側は `Swift.Result`(いずれもPigeonの@asyncコールバック形式)で統一。
- **[spec反映] GATT操作の直列化:** GATTは接続ごとに同時1操作。`read`/`write`/`requestMtu`/`discoverServices`/`setNotify`(CCCD)はネイティブの**デバイス単位操作キュー + `(epoch, opSeq)` 相関**で直列化する。`read` 応答は**戻り値**で返し、notify/indicate のみを通知ストリームへ流す。
- **[spec反映] 操作timeoutの公開副作用:** timeoutした`read`/`write`/`setNotify`等はGATT接続全体を破棄し、
  `connectionStates`へ`disconnected(reason: operationTimeout)`を発行する。`autoReconnect:false`は停止する。
- **[spec反映] 再接続失敗分類:** permissionDenied/bluetoothUnavailable/deviceNotFound/notAssociatedは
  終端理由。bluetoothOffは一時理由として維持要求を残し、adapter復帰イベントまで再試行を停止する。
  deviceNotFoundは不正/解決不能device idだけに使い、圏外・接続timeout・GATT status 133・
  `didFailToConnect`はconnectFailedとして継続する。presenceObservationDisabledはC必須の
  headless復活時だけ終端で、engine生存中の監視無効化はAへ切り替える。
  一時切断時だけ`disconnected(reason)`→`reconnecting`を一度発行し、reconnecting中の各試行失敗は
  Observerへ記録して状態イベントを反復しない。
- **[spec反映] attempt/callback順序:** native `connect` はattempt arm時点で
  `ConnectionAttempt{epoch}`を即返す。bridgeはbodyのconnect Future完了前に届いた同epoch callbackを
  短期保留し、epoch設定後に順序どおり解放する。
- **sealedエラー:** メソッドごとにsealedクラス(`ScanError`, `ConnectError`, ...)を **`deepsky_bluetooth_util`** に定義し、バリアントをswitchで網羅列挙できる。全エラーは `Exception` を実装(steadyの `E extends Exception` 制約)。interfaceはutilを再exportするため、利用側はinterfaceのimportだけでエラー型に届く。
- **エラーコードプロトコル:** ネイティブは `FlutterError(code, message, null)` を投げ、bridgeが下表のcodeをsealedバリアントへマップする。Dart側のcode文字列定数は util の `BleErrorCode` に定義し、bridgeのエラーマッパーはリテラルではなく定数を参照する。

| code | 意味 |
| --- | --- |
| `permissionDenied` | 権限なし |
| `bluetoothOff` | アダプタ/電源オフ |
| `bluetoothUnavailable` | Bluetooth非搭載/OS非対応 |
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
- **コールバック→Dart:** Pigeon `@FlutterApi` でネイティブ→Dartへpush。bridgeが `Stream` として公開。ネイティブはDartの準備完了(`notifyDartReady`)までイベントをバッファする(iOS復元イベント、Android CDSイベント)。上限は256件または30秒で、古いnotify/presenceから破棄してObserverへ警告する。**[spec反映]** 値イベントは notify/indicate **専用**(read 応答はキュー経由で戻り値)。
- **[spec反映] Isolate/エンジン方針:** native BLE ownerはプロセスグローバルで接続・epoch・操作キューを保持する。
  engine detachでは候補/active sinkだけを解除し、GATT接続をcloseしない。UI engineがattachしても直ちに
  headlessを破棄せず、`notifyDartReady` とstate resyncのack完了後にのみ旧headless engineを破棄する。
  FGS停止と全接続解放は明示的な `dispose()` のみが行う。
- **[spec反映] モジュール seam:** root `deepsky_bluetooth` は `src/transport`(単発操作+生イベント)と
  `src/lifecycle`(状態マシン/3駆動源/autoReconnect)へ内部分割する。lifecycle は抽象 `BleTransport`
  のみを介して transport を利用し、`deepsky_bluetooth_interface` の platform 型へ直接依存しない。
  `BleTransport` はDI用の内部ポートであり、将来の利用者向けAPIにはしない。安定後の
  Core(`deepsky_bluetooth_core`)は生成可能な `DeepskyBluetoothCore.foreground/background` facadeを
  公開し、Managedはcore内部adapterへ依存する。
  ネイティブ(plugins/bridges)は単一 owner 維持のため分割しない(spec「段階的パッケージ分割方針」)。
  現段階ではManagedインスタンスが1 transport sessionを排他的に所有し、`dispose()`で1回だけ破棄する。
  session/coreの複数Managed間共有と利用者注入は非目標(テスト注入のみ許可)。

## 検証環境の制約(重要)

開発機はWindows。**Androidはビルド検証可、iOS/macOSはビルド不可**。iOS/macOSタスクの検証は「Pigeon生成成功 + `flutter analyze`(Dart側のみ)」までをWindowsで行い、SwiftのコンパイルはmacOSホストでのチェックポイント(タスク内に明記)とする。Swiftコードはコンパイル確認なしで書くため、macOS検証時に微修正が発生し得る。

**集中リスク:** epoch採番/ガード、操作キュー、handle相関、sink handoverは今回の中核かつネイティブ側へ
集中する。これらをBluetooth API非依存の `EpochRegistry` / `OperationQueueState` /
`HandleRegistry` / `SinkHandoverCoordinator` に分離し、Kotlin local JVM testとSwift XCTestを
必須にする。実機手動確認だけで中核状態遷移の正しさを担保しない。

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

> **[spec反映] root の内部モジュール分割。** root `deepsky_bluetooth` は内部的に
> `src/transport`(将来 `deepsky_bluetooth_core` へ抽出)と `src/lifecycle`(将来 managed に残る)へ
> 分割し、抽象 `BleTransport` を境界(seam)とする。transport=単発のGATT/接続プリミティブ+生イベント、
> lifecycle=状態マシン/3駆動源/autoReconnect/timeout/バックグラウンド復活登録。**いきなり別パッケージに
> せず、安定後に抽出**する。ネイティブ(plugins/bridges/interface/util)のトポロジは変えない
> (決定#22 の単一 owner 維持)。詳細は spec「段階的パッケージ分割方針」。
> 同一パッケージ内の依存方向は `test/architecture/module_dependency_test.dart` で強制する。

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
lib/deepsky_bluetooth.dart                  # export(lifecycle の公開API)
lib/src/transport/                          # 将来 deepsky_bluetooth_core へ抽出
  ble_transport.dart                        # lifecycle 用の内部抽象ポート
  transport_impl.dart                       # DeepskyBluetoothPlatform を選択・ラップ
  platform_resolver.dart                    # Platform 判定で bridge を選択
  transport_factory.dart                    # 初期化済みtransport sessionを生成
lib/src/lifecycle/                          # 将来 managed に残る。BleTransport 経由でのみ transport に依存
  deepsky_bluetooth.dart  bluetooth_device.dart  gatt_objects.dart
  connection_state_machine.dart  reconnect_strategy.dart
test/architecture/module_dependency_test.dart # モジュール依存方向を検査
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

### Task 2: util — sealedエラー型・エラーコード定数・UUID/DeviceIdユーティリティ

> **[spec反映]** `uuid.dart` に **`DeepskyDeviceId`** 値型を追加する(`DeepskyUuid` と同ファイル群)。
> 内部はプラットフォーム id 文字列。値等価性・`hashCode`・`toString`・`Map` キー利用可。公開API全体で
> 生 `String` の代わりに使用する。Step 5 の末尾に下記を追記し、`uuid_test.dart` に等価性テストを足すこと:
>
> ```dart
> /// デバイス識別子の値型。Android: MACアドレス / iOS,macOS: CBPeripheral.identifier(UUID文字列)。
> /// 内部表現はプラットフォーム id 文字列そのもの(正規化しない)。
> final class DeepskyDeviceId {
>   const DeepskyDeviceId(this.value);
>   final String value;
>   @override
>   bool operator ==(Object other) =>
>       other is DeepskyDeviceId && other.value == value;
>   @override
>   int get hashCode => value.hashCode;
>   @override
>   String toString() => value;
> }
> ```

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
          ConnectBluetoothUnavailable() => 'unavailable',
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

final class ScanBluetoothUnavailable extends ScanError {
  const ScanBluetoothUnavailable();
  @override
  String get message => 'Bluetooth is unavailable on this device.';
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

final class ConnectBluetoothUnavailable extends ConnectError {
  const ConnectBluetoothUnavailable();
  @override
  String get message => 'Bluetooth is unavailable on this device.';
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

/// iOS/macOS で notify 有効中に `read(strictRead: true)` した場合のみ。
/// CoreBluetooth が read 応答と通知を区別できないための安全弁(spec 決定#20)。
final class CharacteristicReadAmbiguousWhileNotifying extends CharacteristicReadError {
  const CharacteristicReadAmbiguousWhileNotifying();
  @override
  String get message =>
      'read(strictRead: true) is ambiguous while notifications are enabled on this characteristic.';
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
  static const String bluetoothUnavailable = 'bluetoothUnavailable';
  static const String alreadyScanning = 'alreadyScanning';
  static const String notFound = 'notFound';
  static const String notConnected = 'notConnected';
  static const String notSupported = 'notSupported';
  static const String bufferFull = 'bufferFull';
  static const String readAmbiguousWhileNotifying = 'readAmbiguousWhileNotifying';
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

> **[spec反映] 下記 Step 1–3 の models を以下方針で置換する**(interface 層は **DTO・値キャリア・enum のみ**。
> active な `BleService/BleCharacteristic/BleDescriptor` は body=Task 17 が構築する)。
>
> 1. **接続状態に `reconnecting` 追加(5値)**:
>    `enum BleConnectionState { connecting, connected, disconnecting, disconnected, reconnecting }`
> 2. **enum/値型を追加**:
>    - `enum BleNotifyType { disable, notify, indicate }`
>    - `enum BleDisconnectReason { userRequested, connectionLost, connectFailed, operationTimeout, permissionDenied, bluetoothOff, bluetoothUnavailable, deviceNotFound, notAssociated, presenceObservationDisabled, unknown }`
>    - 公開 `BleConnectionEvent`(`BleConnectionState state`, `BleDisconnectReason? reason`)。
>      `disconnected`だけreason必須、他stateはnull。`BluetoothDevice.connectionStates`が発行する。
>    - `class ReconnectPolicy { const ReconnectPolicy({this.delay = const Duration(seconds: 5)}); final Duration delay; }`
> 3. **探索DTO を `*Info` にリネーム + `handle` 採番**(active クラスと名前衝突回避。uuid は `DeepskyUuid`。
>    handle は探索時採番の epoch スコープ整数。spec「接続世代と属性ハンドル」):
>    `BleServiceInfo`(`int handle`, `DeepskyUuid uuid`, `List<BleCharacteristicInfo> characteristics`) /
>    `BleCharacteristicInfo`(`int handle`, `int serviceHandle`, `DeepskyUuid uuid`, `BleCharacteristicProperties properties`, `List<BleDescriptorInfo> descriptors`) /
>    `BleDescriptorInfo`(`int handle`, `DeepskyUuid uuid`)。`BleCharacteristicProperties` は据え置き。
> 4. **id/uuid を値型へ**: `BleScanResult.deviceId` を `DeepskyDeviceId`、各 uuid を `DeepskyUuid` に。
> 5. **内部キャリアのみ残す/追加(公開から廃止)**:
>    - `BlePlatformConnectionEvent`(`DeepskyDeviceId deviceId`, `int? connectionEpoch`, `BleConnectionState state`, `BleDisconnectReason? reason`) … platform→body の接続イベント。接続試行がepoch採番前に終端失敗した場合だけepochはnull。**epoch でハンドオーバ/再試行を識別**。
>    - `BleAdapterState { poweredOn, poweredOff, unavailable }` … platform→body の全device共通adapter状態。
>    - `BleNotifyEvent`(`DeepskyDeviceId deviceId`, `int connectionEpoch`, `int characteristicHandle`, `Uint8List value`) … **notify/indicate 専用**の値キャリア(旧 `BleCharacteristicValue` を置換。read 応答は載せない)。
>    - `BleOperationTimeout`(`DeepskyDeviceId deviceId`, `int connectionEpoch`) … GATT 操作タイムアウト→接続再生成の通知(spec「GATT操作の直列化」)。
>    - `ConnectionAttempt`(`int connectionEpoch`) … native owner が `connect` ごとに払い出す接続世代。
>    - `BleStateSnapshot`(`DeepskyDeviceId deviceId`, `int connectionEpoch`, `BleConnectionState state`, `BleDisconnectReason? disconnectReason`, `List<int> activeNotifyHandles`, `List<BleServiceInfo>? services`, `bool restored`)。
>    - `BleStateResync`(`String snapshotId`, `List<BleStateSnapshot> devices`) … sink handover/iOS復元で使う完全snapshot。Dart再構築後に同じ `snapshotId` をackする。
>    - `BleCompanionEvent`(`DeepskyDeviceId deviceId`, `bool appeared`) … 内部搬送用に残す。
>    - アドレッシング用 `BleCharacteristicTarget`/`BleDescriptorTarget` は **internal**・**handle ベース**(`DeepskyDeviceId deviceId`, `int connectionEpoch`, `int characteristicHandle`[, `int descriptorHandle`])。
> 6. **公開から削除**: `BleCharacteristicValue`/`BleDescriptorValue`(座標付き値クラス)。
>
> `models_test.dart` は `reconnecting` を含む `BleConnectionState.values`、切断時だけreason必須の
> `BleConnectionEvent`、`BleDisconnectReason`全値、`ConnectionAttempt`・
> `*Info` DTO(handle 含む)・`BleStateResync`・`ReconnectPolicy` 既定値・新キャリアに更新する。
> **以降の旧コード(Step 1–3 の models)は本注記で置換**。

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
      BleConnectionState.reconnecting,
    ]);
  });

  test('BleCharacteristicTarget is scoped by epoch and handle', () {
    const t = BleCharacteristicTarget(
      deviceId: DeepskyDeviceId('id'),
      connectionEpoch: 7,
      characteristicHandle: 11,
    );
    expect(t.connectionEpoch, 7);
    expect(t.characteristicHandle, 11);
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

enum BleConnectionState {
  connecting,
  connected,
  disconnecting,
  disconnected,
  reconnecting,
}

enum BleDisconnectReason {
  userRequested,
  connectionLost,
  connectFailed,
  operationTimeout,
  permissionDenied,
  bluetoothOff,
  bluetoothUnavailable,
  deviceNotFound,
  notAssociated,
  presenceObservationDisabled,
  unknown,
}

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
  const BleConnectionEvent({required this.state, this.reason})
      : assert(state == BleConnectionState.disconnected
            ? reason != null
            : reason == null);
  final BleConnectionState state;
  final BleDisconnectReason? reason;
}

class BlePlatformConnectionEvent {
  const BlePlatformConnectionEvent({
    required this.deviceId,
    required this.connectionEpoch,
    required this.state,
    this.reason,
  });
  final DeepskyDeviceId deviceId;
  final int? connectionEpoch;
  final BleConnectionState state;
  final BleDisconnectReason? reason;
}

enum BleAdapterState { poweredOn, poweredOff, unavailable }

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
    required this.connectionEpoch,
    required this.characteristicHandle,
  });
  final DeepskyDeviceId deviceId;
  final int connectionEpoch;
  final int characteristicHandle;
}

class BleDescriptorTarget {
  const BleDescriptorTarget({
    required this.deviceId,
    required this.connectionEpoch,
    required this.characteristicHandle,
    required this.descriptorHandle,
  });
  final DeepskyDeviceId deviceId;
  final int connectionEpoch;
  final int characteristicHandle;
  final int descriptorHandle;
}

class BleNotifyEvent {
  const BleNotifyEvent({
    required this.deviceId,
    required this.connectionEpoch,
    required this.characteristicHandle,
    required this.value,
  });
  final DeepskyDeviceId deviceId;
  final int connectionEpoch;
  final int characteristicHandle;
  final Uint8List value;
}

/// Android CompanionDeviceService の onDeviceAppeared / onDeviceDisappeared。
class BleCompanionEvent {
  const BleCompanionEvent({required this.deviceId, required this.appeared});
  final DeepskyDeviceId deviceId;
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
    int? backgroundCallbackHandle,
  }) = BackgroundConfig;
}

final class ForegroundConfig extends DeepskyBluetoothConfig {
  const ForegroundConfig();
}

final class BackgroundConfig extends DeepskyBluetoothConfig {
  const BackgroundConfig({
    this.ios,
    this.android,
    this.backgroundCallbackHandle,
  });

  /// iOSでバックグラウンドを使う場合は必須(State Restoration識別子)。
  final IosBackgroundConfig? ios;

  /// Androidでバックグラウンドを使う場合は必須。
  final AndroidBackgroundConfig? android;

  /// Androidヘッドレス復活用。公開factoryがPluginUtilitiesから取得して設定する内部値。
  final int? backgroundCallbackHandle;
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

> **[spec反映] platform 抽象を以下に合わせる**(接続状態マシン・再接続・タイムアウトは body 専任。platform は素の操作のみ):
> - 探索戻り値を `Result<List<BleServiceInfo>, …>` に(`BleService`→`BleServiceInfo`)。
> - `connect(deviceId)` はbodyからepochを受け取らず、native ownerが採番した
>   `Result<ConnectionAttempt, ConnectError>` を返す。他の接続操作だけがepochを受け取る。
> - `readCharacteristic`/`readDescriptor` は **`Result<Uint8List, …>`(値を返す)** のまま(spec の read 戻り値方針と一致)。
> - `connect`/`disconnect`/`readCharacteristic` 等の `deviceId`/uuid 引数を `DeepskyDeviceId`/`DeepskyUuid`(Target 経由)へ。
> - ストリームを「**内部キャリア**」型へ: `Stream<BlePlatformConnectionEvent>`(epoch/切断理由付き接続状態)、`Stream<BleNotifyEvent>`(**notify/indicate 専用**。旧 `characteristicValues` を置換)、`Stream<BleCompanionEvent>`、`restoredConnections` は `Stream<List<DeepskyDeviceId>>`。
> - **GATT 操作の直列化(キュー + `(epoch, opSeq)` 相関)は各 plugin のネイティブ実装内に閉じる**。`_FakePlatform` も上記型に追従。
> - `initialize` はnative設定だけを行う。bodyがイベントstreamを購読した後に
>   `activateCallbacks()` を呼び、`BleStateResync` を再構築して `ackStateResync(snapshotId)` を返す。

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
  Future<Result<void, InitializeError>> activateCallbacks() async =>
      const Result.ok(null);
  @override
  Future<void> ackStateResync(String snapshotId) async {}
  @override
  Future<Result<void, ScanError>> startScan(
          {DeepskyScanFilter? filter,
          DeepskyScanOptions options = const DeepskyScanOptions()}) async =>
      const Result.error(ScanBluetoothOff());
  @override
  Future<Result<void, ScanError>> stopScan() async => const Result.ok(null);
  @override
  Future<Result<ConnectionAttempt, ConnectError>> connect(
          DeepskyDeviceId deviceId) async =>
      const Result.ok(ConnectionAttempt(connectionEpoch: 1));
  @override
  Future<Result<void, DisconnectError>> disconnect(
          DeepskyDeviceId deviceId, int epoch) async =>
      const Result.ok(null);
  @override
  Future<Result<List<BleServiceInfo>, DiscoverServicesError>> discoverServices(
          DeepskyDeviceId deviceId, int epoch) async =>
      const Result.ok([]);
  @override
  Future<Result<Uint8List, CharacteristicReadError>> readCharacteristic(
          BleCharacteristicTarget target, {bool strictRead = false}) async =>
      Result.ok(Uint8List(0));
  @override
  Future<Result<void, CharacteristicWriteError>> writeCharacteristic(
          BleCharacteristicTarget target, Uint8List value,
          {required bool withResponse}) async =>
      const Result.ok(null);
  @override
  Future<Result<void, NotifyError>> setNotify(BleCharacteristicTarget target,
          BleNotifyType type) async =>
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
  Future<Result<int, MtuError>> requestMtu(
          DeepskyDeviceId deviceId, int epoch, int mtu) async =>
      const Result.ok(23);
  @override
  Future<Result<int, RssiError>> readRssi(
          DeepskyDeviceId deviceId, int epoch) async =>
      const Result.ok(-40);
  @override
  Future<Result<DeepskyDeviceId, AssociateError>> associate(
          {DeepskyScanFilter? filter}) async =>
      const Result.error(AssociateNotSupported());
  @override
  Future<Result<void, PresenceError>> setDevicePresenceObservation(
          DeepskyDeviceId deviceId,
          {required bool enabled}) async =>
      const Result.error(PresenceNotSupported());
  @override
  Future<Result<void, DisposeError>> dispose() async => const Result.ok(null);
  @override
  Stream<BleScanResult> get scanResults => const Stream.empty();
  @override
  Stream<ScanError> get scanErrors => const Stream.empty();
  @override
  Stream<BlePlatformConnectionEvent> get connectionEvents =>
      const Stream.empty();
  @override
  Stream<BleNotifyEvent> get notifyEvents =>
      const Stream.empty();
  @override
  Stream<BleOperationTimeout> get operationTimeouts => const Stream.empty();
  @override
  Stream<BleAdapterState> get adapterStates => const Stream.empty();
  @override
  Stream<BleCompanionEvent> get companionEvents => const Stream.empty();
  @override
  Stream<List<DeepskyDeviceId>> get restoredConnections =>
      const Stream.empty();
  @override
  Stream<BleStateResync> get stateResync => const Stream.empty();
}

void main() {
  test('platform abstract class can be implemented and returns Results',
      () async {
    final p = _FakePlatform();
    expect((await p.startScan()).err, isA<ScanBluetoothOff>());
    expect((await p.requestMtu(const DeepskyDeviceId('id'), 1, 247)).ok, 23);
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
///
/// [spec反映] 接続状態マシン・3駆動源の再接続・タイムアウト・状態スナップショットは
/// body(Task 17)が所有する。platform は素の操作・探索DTO返却・内部イベント発行のみ。
/// connect時のconnectionEpochはnative ownerが採番してConnectionAttemptで返す。
/// 以後の接続系操作はそのepochを引数で受け、ネイティブは全イベントへタグ付けして返す。
/// 属性のアドレッシングは UUID ではなく探索時採番の `handle` を使う(Target は handle ベース)。
abstract class DeepskyBluetoothPlatform {
  Future<Result<void, InitializeError>> initialize(
      DeepskyBluetoothConfig config);

  /// bodyが全streamを購読した後に呼ぶ。bridgeはFlutterApi handlerを登録してから
  /// nativeへDart readyを通知する。
  Future<Result<void, InitializeError>> activateCallbacks();

  /// stateResyncの再構築完了通知。ack前に旧engineを破棄してはならない。
  Future<void> ackStateResync(String snapshotId);

  Future<Result<void, ScanError>> startScan(
      {DeepskyScanFilter? filter,
      DeepskyScanOptions options = const DeepskyScanOptions()});
  Future<Result<void, ScanError>> stopScan();

  /// native ownerが新epochを採番して接続実体を生成し、そのepochを返す。
  Future<Result<ConnectionAttempt, ConnectError>> connect(
      DeepskyDeviceId deviceId);
  Future<Result<void, DisconnectError>> disconnect(
      DeepskyDeviceId deviceId, int epoch);

  /// 探索DTO(handle 採番済み)を返す。
  Future<Result<List<BleServiceInfo>, DiscoverServicesError>> discoverServices(
      DeepskyDeviceId deviceId, int epoch);

  /// read 値は戻り値で返す(notify とは分離。spec「GATT操作の直列化」)。
  /// [strictRead] は iOS/macOS で notify 有効中の曖昧 read を `CharacteristicReadAmbiguousWhileNotifying`
  /// にする安全弁(Android は常に厳密で無視)。
  Future<Result<Uint8List, CharacteristicReadError>> readCharacteristic(
      BleCharacteristicTarget target, {bool strictRead = false});
  Future<Result<void, CharacteristicWriteError>> writeCharacteristic(
      BleCharacteristicTarget target, Uint8List value,
      {required bool withResponse});
  Future<Result<void, NotifyError>> setNotify(BleCharacteristicTarget target,
      BleNotifyType type);

  Future<Result<Uint8List, DescriptorReadError>> readDescriptor(
      BleDescriptorTarget target);
  Future<Result<void, DescriptorWriteError>> writeDescriptor(
      BleDescriptorTarget target, Uint8List value);

  /// iOSではOSが自動ネゴシエートするため要求値は無視され、現在のMTUを返す。
  Future<Result<int, MtuError>> requestMtu(
      DeepskyDeviceId deviceId, int epoch, int mtu);
  Future<Result<int, RssiError>> readRssi(DeepskyDeviceId deviceId, int epoch);

  /// Android(CompanionDeviceモード)のみ。他プラットフォームは [AssociateNotSupported]。
  Future<Result<DeepskyDeviceId, AssociateError>> associate(
      {DeepskyScanFilter? filter});
  Future<Result<void, PresenceError>> setDevicePresenceObservation(
      DeepskyDeviceId deviceId,
      {required bool enabled});

  /// スキャン停止・全接続解放・(Androidの)Foreground Service停止。
  Future<Result<void, DisposeError>> dispose();

  Stream<BleScanResult> get scanResults;

  /// Androidの onScanFailed 等、開始後に非同期で発生したスキャン失敗。
  Stream<ScanError> get scanErrors;

  /// 接続状態イベント(内部キャリア。`connectionEpoch` を保持)。
  Stream<BlePlatformConnectionEvent> get connectionEvents;

  /// 通知値イベント(**notify/indicate 専用**。`connectionEpoch` と `characteristicHandle` を保持)。
  Stream<BleNotifyEvent> get notifyEvents;

  /// GATT 操作タイムアウト→接続再生成の通知(epoch 付き。body の状態マシンが想定外切断扱い)。
  Stream<BleOperationTimeout> get operationTimeouts;

  /// Bluetooth adapterの電源/利用可否。自動再接続の停止・再開トリガに使う内部stream。
  Stream<BleAdapterState> get adapterStates;

  /// Android CompanionDeviceService の出現/消失イベント。
  Stream<BleCompanionEvent> get companionEvents;

  /// iOS State Restoration で復元された接続済み deviceId のリスト。
  Stream<List<DeepskyDeviceId>> get restoredConnections;

  /// sink rebind/iOS復元時の完全snapshot。bodyは再構築後snapshotIdをackする。
  Stream<BleStateResync> get stateResync;
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
  InitializeRequestMessage(this.isBackground, this.strategy, this.notification,
      this.backgroundCallbackHandle);
  bool isBackground;
  BackgroundStrategyMessage? strategy;
  NotificationConfigMessage? notification;
  int? backgroundCallbackHandle;
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

enum ConnectionStateMessage {
  connecting,
  connected,
  disconnecting,
  disconnected,
  reconnecting,
}

enum AdapterStateMessage { poweredOn, poweredOff, unavailable }

enum DisconnectReasonMessage {
  userRequested,
  connectionLost,
  connectFailed,
  operationTimeout,
  permissionDenied,
  bluetoothOff,
  bluetoothUnavailable,
  deviceNotFound,
  notAssociated,
  presenceObservationDisabled,
  unknown,
}

enum NotifyTypeMessage { disable, notify, indicate }

class CharacteristicTargetMessage {
  CharacteristicTargetMessage(
      this.deviceId, this.connectionEpoch, this.characteristicHandle);
  String deviceId;
  int connectionEpoch;
  int characteristicHandle;
}

class DescriptorTargetMessage {
  DescriptorTargetMessage(this.deviceId, this.connectionEpoch,
      this.characteristicHandle, this.descriptorHandle);
  String deviceId;
  int connectionEpoch;
  int characteristicHandle;
  int descriptorHandle;
}

class DescriptorMessage {
  DescriptorMessage(this.handle, this.uuid);
  int handle;
  String uuid;
}

class CharacteristicMessage {
  CharacteristicMessage(this.handle, this.serviceHandle, this.uuid,
      this.canRead, this.canWriteWithResponse,
      this.canWriteWithoutResponse, this.canNotify, this.canIndicate,
      this.descriptors);
  int handle;
  int serviceHandle;
  String uuid;
  bool canRead;
  bool canWriteWithResponse;
  bool canWriteWithoutResponse;
  bool canNotify;
  bool canIndicate;
  List<DescriptorMessage> descriptors;
}

class ServiceMessage {
  ServiceMessage(this.handle, this.uuid, this.characteristics);
  int handle;
  String uuid;
  List<CharacteristicMessage> characteristics;
}

class ConnectionAttemptMessage {
  ConnectionAttemptMessage(this.connectionEpoch);
  int connectionEpoch;
}

class StateSnapshotMessage {
    StateSnapshotMessage(this.deviceId, this.connectionEpoch, this.state,
      this.disconnectReason, this.activeNotifyHandles, this.services, this.restored);
  String deviceId;
  int connectionEpoch;
  ConnectionStateMessage state;
  DisconnectReasonMessage? disconnectReason;
  List<int> activeNotifyHandles;
  List<ServiceMessage>? services;
  bool restored;
}

class StateResyncMessage {
  StateResyncMessage(this.snapshotId, this.devices);
  String snapshotId;
  List<StateSnapshotMessage> devices;
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
  /// 戻り値はengineごとのopaque token。attach時点では候補sinkのまま。
  String initialize(InitializeRequestMessage request);

  /// FlutterApi.setUp後に呼ぶ。snapshotのackまでは旧sinkをactiveのまま保つ。
  void notifyDartReady(String engineToken);
  void ackStateResync(String engineToken, String snapshotId);
  void startScan(ScanFilterMessage? filter, AndroidScanSettingsMessage settings);
  void stopScan();
  @async
  ConnectionAttemptMessage connect(String deviceId);
  @async
  void disconnect(String deviceId, int connectionEpoch);
  @async
  List<ServiceMessage> discoverServices(String deviceId, int connectionEpoch);
  @async
  Uint8List readCharacteristic(CharacteristicTargetMessage target, bool strictRead);
  @async
  void writeCharacteristic(
      CharacteristicTargetMessage target, Uint8List value, bool withResponse);
  @async
  void setNotify(CharacteristicTargetMessage target, NotifyTypeMessage type);
  @async
  Uint8List readDescriptor(DescriptorTargetMessage target);
  @async
  void writeDescriptor(DescriptorTargetMessage target, Uint8List value);
  @async
  int requestMtu(String deviceId, int connectionEpoch, int mtu);
  @async
  int readRssi(String deviceId, int connectionEpoch);
  @async
  String associate(ScanFilterMessage? filter);
  void setDevicePresenceObservation(String deviceId, bool enabled);
  void dispose();
}

@FlutterApi()
abstract class BleCallbacksApi {
  void onScanResult(ScanResultMessage result);
  void onScanFailed(String code, String message);
  void onConnectionStateChanged(
      String deviceId, int? connectionEpoch, ConnectionStateMessage state,
      DisconnectReasonMessage? disconnectReason);
  void onAdapterStateChanged(AdapterStateMessage state);
  void onCharacteristicValue(String deviceId, int connectionEpoch,
      int characteristicHandle, Uint8List value);
  void onOperationTimeout(String deviceId, int connectionEpoch);
  void onDeviceAppeared(String deviceId);
  void onDeviceDisappeared(String deviceId);
  void onStateResync(StateResyncMessage snapshot);
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

`pigeons/messages.dart` 全文(Androidとの差分: `InitializeRequestMessage` が `restoreIdentifier` を持つ /
`associate`・presence・strategy・notificationなし / `requestMtu` の代わりに `getMtu` /
FlutterApiに完全snapshotの `onStateResync` とack後の `onRestoredConnections` を追加):

```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  swiftOut:
      'ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/Messages.g.swift',
))
class InitializeRequestMessage {
  InitializeRequestMessage(
      this.isBackground, this.restoreIdentifier, this.backgroundCallbackHandle);
  bool isBackground;
  String? restoreIdentifier;
  int? backgroundCallbackHandle;
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

enum ConnectionStateMessage {
  connecting,
  connected,
  disconnecting,
  disconnected,
  reconnecting,
}

enum AdapterStateMessage { poweredOn, poweredOff, unavailable }

enum NotifyTypeMessage { disable, notify, indicate }

class CharacteristicTargetMessage {
  CharacteristicTargetMessage(
      this.deviceId, this.connectionEpoch, this.characteristicHandle);
  String deviceId;
  int connectionEpoch;
  int characteristicHandle;
}

class DescriptorTargetMessage {
  DescriptorTargetMessage(this.deviceId, this.connectionEpoch,
      this.characteristicHandle, this.descriptorHandle);
  String deviceId;
  int connectionEpoch;
  int characteristicHandle;
  int descriptorHandle;
}

class DescriptorMessage {
  DescriptorMessage(this.handle, this.uuid);
  int handle;
  String uuid;
}

class CharacteristicMessage {
  CharacteristicMessage(this.handle, this.serviceHandle, this.uuid,
      this.canRead, this.canWriteWithResponse,
      this.canWriteWithoutResponse, this.canNotify, this.canIndicate,
      this.descriptors);
  int handle;
  int serviceHandle;
  String uuid;
  bool canRead;
  bool canWriteWithResponse;
  bool canWriteWithoutResponse;
  bool canNotify;
  bool canIndicate;
  List<DescriptorMessage> descriptors;
}

class ServiceMessage {
  ServiceMessage(this.handle, this.uuid, this.characteristics);
  int handle;
  String uuid;
  List<CharacteristicMessage> characteristics;
}

class ConnectionAttemptMessage {
  ConnectionAttemptMessage(this.connectionEpoch);
  int connectionEpoch;
}

class StateSnapshotMessage {
  StateSnapshotMessage(this.deviceId, this.connectionEpoch, this.state,
      this.disconnectReason, this.activeNotifyHandles, this.services, this.restored);
  String deviceId;
  int connectionEpoch;
  ConnectionStateMessage state;
  DisconnectReasonMessage? disconnectReason;
  List<int> activeNotifyHandles;
  List<ServiceMessage>? services;
  bool restored;
}

class StateResyncMessage {
  StateResyncMessage(this.snapshotId, this.devices);
  String snapshotId;
  List<StateSnapshotMessage> devices;
}

enum DisconnectReasonMessage {
  userRequested,
  connectionLost,
  connectFailed,
  operationTimeout,
  permissionDenied,
  bluetoothOff,
  bluetoothUnavailable,
  deviceNotFound,
  notAssociated,
  presenceObservationDisabled,
  unknown,
}

// disconnected callback/state snapshotでのみ使用する。
class DarwinScanSettingsMessage {
  DarwinScanSettingsMessage(this.allowDuplicates, this.solicitedServiceUuids);
  bool allowDuplicates;
  List<String> solicitedServiceUuids;
}

@HostApi()
abstract class BleHostApi {
  String initialize(InitializeRequestMessage request);
  void notifyDartReady(String engineToken);
  void ackStateResync(String engineToken, String snapshotId);
  void startScan(ScanFilterMessage? filter, DarwinScanSettingsMessage settings);
  void stopScan();
  @async
  ConnectionAttemptMessage connect(String deviceId);
  @async
  void disconnect(String deviceId, int connectionEpoch);
  @async
  List<ServiceMessage> discoverServices(String deviceId, int connectionEpoch);
  @async
  Uint8List readCharacteristic(CharacteristicTargetMessage target, bool strictRead);
  @async
  void writeCharacteristic(
      CharacteristicTargetMessage target, Uint8List value, bool withResponse);
  @async
  void setNotify(CharacteristicTargetMessage target, NotifyTypeMessage type);
  @async
  Uint8List readDescriptor(DescriptorTargetMessage target);
  @async
  void writeDescriptor(DescriptorTargetMessage target, Uint8List value);

  /// iOSはMTU要求不可のため現在値(maximumWriteValueLength+3)を返す。
  @async
  int getMtu(String deviceId, int connectionEpoch);
  @async
  int readRssi(String deviceId, int connectionEpoch);
  void dispose();
}

@FlutterApi()
abstract class BleCallbacksApi {
  void onScanResult(ScanResultMessage result);
  void onConnectionStateChanged(
      String deviceId, int? connectionEpoch, ConnectionStateMessage state,
      DisconnectReasonMessage? disconnectReason);
  void onAdapterStateChanged(AdapterStateMessage state);
  void onCharacteristicValue(String deviceId, int connectionEpoch,
      int characteristicHandle, Uint8List value);
  void onOperationTimeout(String deviceId, int connectionEpoch);
  void onStateResync(StateResyncMessage snapshot);
  void onRestoredConnections(List<String> deviceIds);
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

`pigeons/messages.dart` 全文(iOSとの差分: `initialize(bool isBackground)` / iOS復元callbackなし):

```dart
import 'package:pigeon/pigeon.dart';

enum DisconnectReasonMessage {
  userRequested,
  connectionLost,
  connectFailed,
  operationTimeout,
  permissionDenied,
  bluetoothOff,
  bluetoothUnavailable,
  deviceNotFound,
  notAssociated,
  presenceObservationDisabled,
  unknown,
}

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

enum ConnectionStateMessage {
  connecting,
  connected,
  disconnecting,
  disconnected,
  reconnecting,
}

enum AdapterStateMessage { poweredOn, poweredOff, unavailable }

enum NotifyTypeMessage { disable, notify, indicate }

class CharacteristicTargetMessage {
  CharacteristicTargetMessage(
      this.deviceId, this.connectionEpoch, this.characteristicHandle);
  String deviceId;
  int connectionEpoch;
  int characteristicHandle;
}

class DescriptorTargetMessage {
  DescriptorTargetMessage(this.deviceId, this.connectionEpoch,
      this.characteristicHandle, this.descriptorHandle);
  String deviceId;
  int connectionEpoch;
  int characteristicHandle;
  int descriptorHandle;
}

class DescriptorMessage {
  DescriptorMessage(this.handle, this.uuid);
  int handle;
  String uuid;
}

class CharacteristicMessage {
  CharacteristicMessage(this.handle, this.serviceHandle, this.uuid,
      this.canRead, this.canWriteWithResponse,
      this.canWriteWithoutResponse, this.canNotify, this.canIndicate,
      this.descriptors);
  int handle;
  int serviceHandle;
  String uuid;
  bool canRead;
  bool canWriteWithResponse;
  bool canWriteWithoutResponse;
  bool canNotify;
  bool canIndicate;
  List<DescriptorMessage> descriptors;
}

class ServiceMessage {
  ServiceMessage(this.handle, this.uuid, this.characteristics);
  int handle;
  String uuid;
  List<CharacteristicMessage> characteristics;
}

class ConnectionAttemptMessage {
  ConnectionAttemptMessage(this.connectionEpoch);
  int connectionEpoch;
}

class StateSnapshotMessage {
  StateSnapshotMessage(this.deviceId, this.connectionEpoch, this.state,
      this.disconnectReason, this.activeNotifyHandles, this.services, this.restored);
  String deviceId;
  int connectionEpoch;
  ConnectionStateMessage state;
  DisconnectReasonMessage? disconnectReason;
  List<int> activeNotifyHandles;
  List<ServiceMessage>? services;
  bool restored;
}

class StateResyncMessage {
  StateResyncMessage(this.snapshotId, this.devices);
  String snapshotId;
  List<StateSnapshotMessage> devices;
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
  String initialize(bool isBackground);
  void notifyDartReady(String engineToken);
  void ackStateResync(String engineToken, String snapshotId);
  void startScan(ScanFilterMessage? filter, DarwinScanSettingsMessage settings);
  void stopScan();
  @async
  ConnectionAttemptMessage connect(String deviceId);
  @async
  void disconnect(String deviceId, int connectionEpoch);
  @async
  List<ServiceMessage> discoverServices(String deviceId, int connectionEpoch);
  @async
  Uint8List readCharacteristic(CharacteristicTargetMessage target, bool strictRead);
  @async
  void writeCharacteristic(
      CharacteristicTargetMessage target, Uint8List value, bool withResponse);
  @async
  void setNotify(CharacteristicTargetMessage target, NotifyTypeMessage type);
  @async
  Uint8List readDescriptor(DescriptorTargetMessage target);
  @async
  void writeDescriptor(DescriptorTargetMessage target, Uint8List value);
  @async
  int getMtu(String deviceId, int connectionEpoch);
  @async
  int readRssi(String deviceId, int connectionEpoch);
  void dispose();
}

@FlutterApi()
abstract class BleCallbacksApi {
  void onScanResult(ScanResultMessage result);
  void onConnectionStateChanged(
      String deviceId, int? connectionEpoch, ConnectionStateMessage state,
      DisconnectReasonMessage? disconnectReason);
  void onAdapterStateChanged(AdapterStateMessage state);
  void onCharacteristicValue(String deviceId, int connectionEpoch,
      int characteristicHandle, Uint8List value);
  void onOperationTimeout(String deviceId, int connectionEpoch);
  void onStateResync(StateResyncMessage snapshot);
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

> **[spec反映] GATT操作キュー(必須)を `GattConnection.kt` に実装する**:
> - デバイス(=1 `BluetoothGatt`)ごとに FIFO の `OperationQueue` を持つ。各操作は
>   native owner払い出しの `connectionEpoch` と接続内連番 `opSeq` を持つ。
> - **先頭 1 件のみ実行**。`onCharacteristicRead`/`onCharacteristicWrite`/`onDescriptorRead`/
>   `onDescriptorWrite`/`onMtuChanged`/`onReadRemoteRssi`/`onServicesDiscovered` 到着時に先頭操作の
>   completer を完了 → 次をディスパッチ(同時1操作なので FIFO で要求/応答が一意相関)。
> - 各操作にタイムアウト(例 10s)。満了で対応エラーを返し、**同じ接続ではキューを進めず**
>   epochを退役してGATT接続全体を破棄する。bodyへoperationTimeout理由を通知する。
> - **`onCharacteristicChanged`(notify/indicate)はキューに載せず**、`BleNotifyEvent` として通知ストリームへ直送。
>   read 応答(`onCharacteristicRead`)は read 操作の completer を完了させ、**値を戻り値で返す**。
> - `setNotify` は「CCCD descriptor write」操作としてキューを通す。
> - writeWithoutResponseはAPI 33+でint版`writeCharacteristic`の
>   `ERROR_GATT_WRITE_REQUEST_BUSY`、31–32でboolean版の`false`を
>   `CharacteristicWriteBufferFull`へ対応させる。
> - `connectGatt(..., autoConnect = false, ...)` を**常に**使用(再接続は body 所有。spec「自動再接続」)。
> - **切断理由マッピング**: 不正Bluetooth addressなど`getRemoteDevice`前後でidentityを構築できない場合だけ
>   `deviceNotFound`。有効addressに対する`connectGatt`後のtimeout、圏外、GATT status 133その他の
>   接続確立失敗は`connectFailed`、確立後の予期しない切断は`connectionLost`とする。
> - `ConnectionAttempt{epoch}`は`connectGatt`の接続完了を待たずarm時点で返す。
> - `BluetoothAdapter.ACTION_STATE_CHANGED`をownerで監視し、`STATE_OFF`をpoweredOff、
>   `STATE_ON`をpoweredOnとして全device共通のadapter state callbackへ流す。
>   adapter null/LE非対応はunavailableでありpoweredOffと混同しない。
> - 本タスク内でUUID座標を参照する旧コード断片はすべて削除し、探索時の
>   `handle → native object` mapと `(epoch, handle)` 検証へ置換する。UUIDは表示用DTOにだけ残す。
> - **[spec反映] `manufacturerData` 正規化**: `ScanResult` の `manufacturerData` を全プラットフォーム共通形式へ
>   そろえる(Android の `getManufacturerSpecificData()` は company id を含まないため、`BleScanResult` 生成時に
>   **先頭2バイトに company id(little-endian)を再付与**して iOS の `kCBAdvDataManufacturerData` と一致させる)。
>   フィルタ照合も同一形式。
> - `EpochRegistry` / `OperationQueueState` / `HandleRegistry` /
>   `SinkHandoverCoordinator` をAndroid framework非依存Kotlinへ分離しlocal JVM test対象にする。

**Files:**
- Modify: `plugins/deepsky_bluetooth_android/android/build.gradle.kts`(minSdk 31)
- Modify: `plugins/deepsky_bluetooth_android/android/src/main/AndroidManifest.xml`
- Create: `.../kotlin/com/example/deepsky_bluetooth_android/BleErrorCodes.kt`
- Create: `.../DeepskyBluetoothAndroidObserver.kt`
- Create: `.../ObservingBleHostApi.kt`
- Create: `.../GattConnection.kt`
- Create: `.../BleCentralManager.kt`
- Create: `.../PendingCompanionEvents.kt`
- Create: `.../core/EpochRegistry.kt`
- Create: `.../core/OperationQueueState.kt`
- Create: `.../core/HandleRegistry.kt`
- Create: `.../core/SinkHandoverCoordinator.kt`
- Create: `android/src/test/.../core/*Test.kt`
- Modify: `.../DeepskyBluetoothAndroidPlugin.kt`(テンプレート全置換)
- Delete: `plugins/deepsky_bluetooth_android/android/src/test/kotlin/.../DeepskyBluetoothAndroidPluginTest.kt`(テンプレートのみ)
- Modify: `plugins/deepsky_bluetooth_android/example/android/app/build.gradle.kts`(minSdk 31)

注: Kotlinの非同期メソッドはPigeon生成の `(kotlin.Result<T>) -> Unit` コールバックで完了させる(=ネイティブ側もResult型)。`try-catch` はPigeon同期メソッド境界(`FlutterError` throw)とObserverデコレータのみ。
API 31–32だけ旧 `BluetoothGatt` シグネチャを `@Suppress("DEPRECATION")` で使用し、
API 33+は値引数付きint戻り値版を使う。

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
    const val BLUETOOTH_UNAVAILABLE = "bluetoothUnavailable"
    const val ALREADY_SCANNING = "alreadyScanning"
    const val NOT_FOUND = "notFound"
    const val NOT_CONNECTED = "notConnected"
    const val NOT_SUPPORTED = "notSupported"
    const val BUFFER_FULL = "bufferFull"
    const val READ_AMBIGUOUS_WHILE_NOTIFYING = "readAmbiguousWhileNotifying"
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

    override fun notifyDartReady(engineToken: String) =
        observed("notifyDartReady", mapOf("engineToken" to engineToken)) {
            inner.notifyDartReady(engineToken)
        }

    override fun ackStateResync(engineToken: String, snapshotId: String) =
        observed("ackStateResync", mapOf(
            "engineToken" to engineToken,
            "snapshotId" to snapshotId,
        )) {
            inner.ackStateResync(engineToken, snapshotId)
        }

    override fun startScan(filter: ScanFilterMessage?, settings: AndroidScanSettingsMessage) =
        observed("startScan", mapOf(
            "serviceUuids" to filter?.serviceUuids,
            "names" to filter?.names,
            "mode" to settings.mode.name,
        )) {
            inner.startScan(filter, settings)
        }

    override fun stopScan() = observed("stopScan", emptyMap()) { inner.stopScan() }

    override fun connect(deviceId: String, callback: (Result<ConnectionAttemptMessage>) -> Unit) =
        observedAsync("connect", mapOf("deviceId" to deviceId), callback) { inner.connect(deviceId, it) }

    override fun disconnect(deviceId: String, connectionEpoch: Long,
                            callback: (Result<Unit>) -> Unit) =
        observedAsync("disconnect", mapOf(
            "deviceId" to deviceId, "epoch" to connectionEpoch), callback) {
            inner.disconnect(deviceId, connectionEpoch, it)
        }

    override fun discoverServices(deviceId: String, connectionEpoch: Long,
                                  callback: (Result<List<ServiceMessage>>) -> Unit) =
        observedAsync("discoverServices", mapOf(
            "deviceId" to deviceId, "epoch" to connectionEpoch), callback) {
            inner.discoverServices(deviceId, connectionEpoch, it)
        }

    override fun readCharacteristic(target: CharacteristicTargetMessage, strictRead: Boolean, callback: (Result<ByteArray>) -> Unit) =
        observedAsync("readCharacteristic", targetArgs(target), callback) { inner.readCharacteristic(target, strictRead, it) }

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
        observedAsync("readDescriptor", descriptorTargetArgs(target), callback) {
            inner.readDescriptor(target, it)
        }

    override fun writeDescriptor(target: DescriptorTargetMessage, value: ByteArray, callback: (Result<Unit>) -> Unit) =
        observedAsync("writeDescriptor", descriptorTargetArgs(target), callback) {
            inner.writeDescriptor(target, value, it)
        }

    override fun requestMtu(deviceId: String, connectionEpoch: Long, mtu: Long,
                            callback: (Result<Long>) -> Unit) =
        observedAsync("requestMtu", mapOf(
            "deviceId" to deviceId, "epoch" to connectionEpoch, "mtu" to mtu), callback) {
            inner.requestMtu(deviceId, connectionEpoch, mtu, it)
        }

    override fun readRssi(deviceId: String, connectionEpoch: Long,
                          callback: (Result<Long>) -> Unit) =
        observedAsync("readRssi", mapOf(
            "deviceId" to deviceId, "epoch" to connectionEpoch), callback) {
            inner.readRssi(deviceId, connectionEpoch, it)
        }

    override fun associate(filter: ScanFilterMessage?, callback: (Result<String>) -> Unit) =
        observedAsync("associate", mapOf("names" to filter?.names), callback) { inner.associate(filter, it) }

    override fun setDevicePresenceObservation(deviceId: String, enabled: Boolean) =
        observed("setDevicePresenceObservation", mapOf("deviceId" to deviceId, "enabled" to enabled)) {
            inner.setDevicePresenceObservation(deviceId, enabled)
        }

    override fun dispose() = observed("dispose", emptyMap()) { inner.dispose() }

    private fun targetArgs(target: CharacteristicTargetMessage) = mapOf(
        "deviceId" to target.deviceId,
        "epoch" to target.connectionEpoch,
        "characteristicHandle" to target.characteristicHandle,
    )

    private fun descriptorTargetArgs(target: DescriptorTargetMessage) = mapOf(
        "deviceId" to target.deviceId,
        "epoch" to target.connectionEpoch,
        "characteristicHandle" to target.characteristicHandle,
        "descriptorHandle" to target.descriptorHandle,
    )
}
```

- [ ] **Step 6: 保留CompanionイベントのバッファI**

`PendingCompanionEvents.kt` 全文:

```kotlin
package com.example.deepsky_bluetooth_android

import android.os.SystemClock
import android.util.Log
import java.util.ArrayDeque

/**
 * CompanionDeviceServiceのイベントを、Dart側の準備完了(notifyDartReady)まで
 * 最大256件・30秒だけバッファするシングルトン。sink接続後は即時配信。
 */
object PendingCompanionEvents {
    private const val MAX_EVENTS = 256
    private const val MAX_AGE_MILLIS = 30_000L

    private data class PendingEvent(
        val deviceId: String,
        val appeared: Boolean,
        val createdAtMillis: Long,
    )

    private val buffered = ArrayDeque<PendingEvent>()
    private var sink: ((deviceId: String, appeared: Boolean) -> Unit)? = null

    @Synchronized
    fun emit(deviceId: String, appeared: Boolean) {
        val s = sink
        if (s != null) {
            s(deviceId, appeared)
            return
        }
        val now = SystemClock.elapsedRealtime()
        prune(now)
        buffered.removeAll { it.deviceId == deviceId }
        buffered.addLast(PendingEvent(deviceId, appeared, now))
        if (buffered.size > MAX_EVENTS) {
            buffered.removeFirst()
            Log.w("DeepskyBluetooth", "Dropped oldest buffered Companion event")
        }
    }

    @Synchronized
    fun attachSink(s: (deviceId: String, appeared: Boolean) -> Unit) {
        sink = s
        prune(SystemClock.elapsedRealtime())
        buffered.forEach { event -> s(event.deviceId, event.appeared) }
        buffered.clear()
    }

    @Synchronized
    fun detachSink() {
        sink = null
    }

    private fun prune(now: Long) {
        while (buffered.isNotEmpty() &&
            now - buffered.first().createdAtMillis > MAX_AGE_MILLIS) {
            buffered.removeFirst()
            Log.w("DeepskyBluetooth", "Dropped expired buffered Companion event")
        }
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
import android.bluetooth.BluetoothStatusCodes
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import java.util.UUID

private val CCCD_UUID: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

sealed class GattOperation {
    abstract fun fail(error: Throwable)

    class ReadCharacteristic(
        val characteristicHandle: Long,
        val callback: (Result<ByteArray>) -> Unit,
    ) : GattOperation() {
        override fun fail(error: Throwable) = callback(Result.failure(error))
    }

    class WriteCharacteristic(
        val characteristicHandle: Long,
        val value: ByteArray, val withResponse: Boolean,
        val callback: (Result<Unit>) -> Unit,
    ) : GattOperation() {
        override fun fail(error: Throwable) = callback(Result.failure(error))
    }

    class SetNotify(
        val characteristicHandle: Long,
        val enabled: Boolean, val callback: (Result<Unit>) -> Unit,
    ) : GattOperation() {
        override fun fail(error: Throwable) = callback(Result.failure(error))
    }

    class ReadDescriptor(
        val characteristicHandle: Long, val descriptorHandle: Long,
        val callback: (Result<ByteArray>) -> Unit,
    ) : GattOperation() {
        override fun fail(error: Throwable) = callback(Result.failure(error))
    }

    class WriteDescriptor(
        val characteristicHandle: Long, val descriptorHandle: Long,
        val value: ByteArray,
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
    val connectionEpoch: Long,
    private val callbacks: BleCallbacksApi,
    private val observer: () -> DeepskyBluetoothAndroidObserver,
) : BluetoothGattCallback() {
    private val main = Handler(Looper.getMainLooper())
    private var gatt: BluetoothGatt? = null
    private var isConnecting = false
    private var disconnectCallback: ((Result<Unit>) -> Unit)? = null
    private var pendingDisconnectReason: DisconnectReasonMessage? = null
    private var discoverCallback: ((Result<List<ServiceMessage>>) -> Unit)? = null
    private val operations = ArrayDeque<GattOperation>()
    private var current: GattOperation? = null
    private val serviceHandles = mutableMapOf<BluetoothGattService, Long>()
    private val characteristicsByHandle = mutableMapOf<Long, BluetoothGattCharacteristic>()
    private val characteristicHandles = mutableMapOf<BluetoothGattCharacteristic, Long>()
    private val descriptorsByHandle = mutableMapOf<Long, BluetoothGattDescriptor>()
    private val descriptorHandles = mutableMapOf<BluetoothGattDescriptor, Long>()
    private var operationTimeout: Runnable? = null
    private val operationTimeoutMs = 10_000L

    var isConnected = false
        private set

    fun connect() {
        isConnecting = true
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
        pendingDisconnectReason = DisconnectReasonMessage.USER_REQUESTED
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
        removeOperationTimeout()
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
            return
        }
        // 実際に開始できた時だけ watchdog 起動(abortCurrent は current を null にするので除外)。
        if (current === op) scheduleOperationTimeout()
    }

    private fun abortCurrent(op: GattOperation, code: String, message: String): Boolean {
        current = null
        op.fail(bleError(code, message))
        main.post { driveQueue() }
        return true
    }

    // callback が先頭操作と種別整合する場合のみ先頭を完了させ次へ進める。
    // 不整合(遅延/想定外callback)なら先頭を据え置き無視する(spec「GATT操作の直列化」)。
    private fun finish(complete: (GattOperation) -> Boolean) {
        main.post {
            val op = current ?: return@post
            if (!complete(op)) return@post
            removeOperationTimeout()
            current = null
            driveQueue()
        }
    }

    private fun scheduleOperationTimeout() {
        removeOperationTimeout()
        val r = Runnable { onOperationTimedOut() }
        operationTimeout = r
        main.postDelayed(r, operationTimeoutMs)
    }

    private fun removeOperationTimeout() {
        operationTimeout?.let { main.removeCallbacks(it) }
        operationTimeout = null
    }

    // 操作が期限内に応答しない=GATTスタック不整合の可能性。接続を破棄してepochを退役する(spec #1対策)。
    // 遅延callbackは旧epochとして以後破棄され、bodyはonOperationTimeoutで再接続機構へ合流する。
    private fun onOperationTimedOut() {
        operationTimeout = null
        failAllPending(bleError(BleErrorCode.TIMEOUT, "GATT operation timed out"))
        gatt?.disconnect()
        close()
        observer().onCallback("onOperationTimeout", "${device.address}/$connectionEpoch")
        callbacks.onOperationTimeout(device.address, connectionEpoch) {}
    }

    @Suppress("DEPRECATION")
    private fun execute(op: GattOperation): Boolean {
        val g = gatt ?: return false
        return when (op) {
            is GattOperation.ReadCharacteristic -> {
                val ch = characteristicsByHandle[op.characteristicHandle]
                    ?: return abortCurrent(op, BleErrorCode.NOT_FOUND, "Characteristic not found")
                if (ch.properties and BluetoothGattCharacteristic.PROPERTY_READ == 0)
                    return abortCurrent(op, BleErrorCode.NOT_SUPPORTED, "Read not supported")
                g.readCharacteristic(ch)
            }
            is GattOperation.WriteCharacteristic -> {
                val ch = characteristicsByHandle[op.characteristicHandle]
                    ?: return abortCurrent(op, BleErrorCode.NOT_FOUND, "Characteristic not found")
                val writeType = if (op.withResponse)
                    BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                else BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                if (Build.VERSION.SDK_INT >= 33) {
                    when (g.writeCharacteristic(ch, op.value, writeType)) {
                        BluetoothStatusCodes.SUCCESS -> true
                        BluetoothStatusCodes.ERROR_GATT_WRITE_REQUEST_BUSY ->
                            abortCurrent(op, BleErrorCode.BUFFER_FULL,
                                "GATT write request busy")
                        else -> abortCurrent(op, BleErrorCode.FAILED,
                            "Failed to start characteristic write")
                    }
                } else {
                    ch.writeType = writeType
                    ch.value = op.value
                    if (g.writeCharacteristic(ch)) true
                    else if (!op.withResponse) abortCurrent(
                        op, BleErrorCode.BUFFER_FULL, "GATT write queue full")
                    else abortCurrent(
                        op, BleErrorCode.FAILED, "Failed to start characteristic write")
                }
            }
            is GattOperation.SetNotify -> {
                val ch = characteristicsByHandle[op.characteristicHandle]
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
                val d = descriptorsByHandle[op.descriptorHandle]
                    ?: return abortCurrent(op, BleErrorCode.NOT_FOUND, "Descriptor not found")
                g.readDescriptor(d)
            }
            is GattOperation.WriteDescriptor -> {
                val d = descriptorsByHandle[op.descriptorHandle]
                    ?: return abortCurrent(op, BleErrorCode.NOT_FOUND, "Descriptor not found")
                d.value = op.value
                g.writeDescriptor(d)
            }
            is GattOperation.RequestMtu -> g.requestMtu(op.mtu)
            is GattOperation.ReadRssi -> g.readRemoteRssi()
        }
    }

    // discover完了時に、列挙順でepochスコープhandleを採番して両方向mapを構築する。
    // UUIDはServiceMessage等の表示用DTOにのみ格納し、操作の解決には使わない。
    private fun rebuildHandleMaps(services: List<BluetoothGattService>) {
        serviceHandles.clear()
        characteristicsByHandle.clear()
        characteristicHandles.clear()
        descriptorsByHandle.clear()
        descriptorHandles.clear()
        var nextHandle = 1L
        services.forEach { service ->
            serviceHandles[service] = nextHandle++
            service.characteristics.forEach { characteristic ->
                val characteristicHandle = nextHandle++
                characteristicsByHandle[characteristicHandle] = characteristic
                characteristicHandles[characteristic] = characteristicHandle
                characteristic.descriptors.forEach { descriptor ->
                    val descriptorHandle = nextHandle++
                    descriptorsByHandle[descriptorHandle] = descriptor
                    descriptorHandles[descriptor] = descriptorHandle
                }
            }
        }
    }

    private fun failAllPending(error: Throwable) {
        current?.fail(error)
        current = null
        while (operations.isNotEmpty()) operations.removeFirst().fail(error)
        discoverCallback?.invoke(Result.failure(error))
        discoverCallback = null
    }

    private fun emitState(
        state: ConnectionStateMessage,
        reason: DisconnectReasonMessage? = null,
    ) {
        observer().onCallback("onConnectionStateChanged", "${device.address} ${state.name}")
        callbacks.onConnectionStateChanged(
            device.address, connectionEpoch, state, reason) {}
    }

    // --- BluetoothGattCallback ---

    override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
        main.post {
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    isConnecting = false
                    isConnected = true
                    emitState(ConnectionStateMessage.CONNECTED)
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    isConnected = false
                    val wasConnecting = isConnecting
                    isConnecting = false
                    disconnectCallback?.invoke(Result.success(Unit))
                    disconnectCallback = null
                    failAllPending(bleError(BleErrorCode.NOT_CONNECTED, "Disconnected"))
                    emitState(
                        ConnectionStateMessage.DISCONNECTED,
                        pendingDisconnectReason
                            ?: if (wasConnecting)
                                DisconnectReasonMessage.CONNECT_FAILED
                            else DisconnectReasonMessage.CONNECTION_LOST)
                    pendingDisconnectReason = null
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
                rebuildHandleMaps(g.services)
                cb(Result.success(g.services.map { service ->
                    ServiceMessage(
                        handle = serviceHandles.getValue(service),
                        uuid = service.uuid.toString(),
                        characteristics = service.characteristics.map { characteristic ->
                            val characteristicHandle = characteristicHandles.getValue(characteristic)
                            CharacteristicMessage(
                                handle = characteristicHandle,
                                serviceHandle = serviceHandles.getValue(service),
                                uuid = characteristic.uuid.toString(),
                                canRead = characteristic.properties and
                                    BluetoothGattCharacteristic.PROPERTY_READ != 0,
                                canWriteWithResponse = characteristic.properties and
                                    BluetoothGattCharacteristic.PROPERTY_WRITE != 0,
                                canWriteWithoutResponse = characteristic.properties and
                                    BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE != 0,
                                canNotify = characteristic.properties and
                                    BluetoothGattCharacteristic.PROPERTY_NOTIFY != 0,
                                canIndicate = characteristic.properties and
                                    BluetoothGattCharacteristic.PROPERTY_INDICATE != 0,
                                descriptors = characteristic.descriptors.map { descriptor ->
                                    DescriptorMessage(
                                        handle = descriptorHandles.getValue(descriptor),
                                        uuid = descriptor.uuid.toString())
                                },
                            )
                        },
                    )
                }))
            }
        }
    }

    @Deprecated("Deprecated in API 33")
    @Suppress("DEPRECATION")
    override fun onCharacteristicRead(g: BluetoothGatt, ch: BluetoothGattCharacteristic, status: Int) {
        val value = ch.value ?: ByteArray(0)
        finish { op ->
            if (op !is GattOperation.ReadCharacteristic) return@finish false
            if (status == BluetoothGatt.GATT_SUCCESS) op.callback(Result.success(value))
            else op.fail(bleError(BleErrorCode.FAILED, "Read failed (status=$status)"))
            true
        }
    }

    override fun onCharacteristicWrite(g: BluetoothGatt, ch: BluetoothGattCharacteristic, status: Int) {
        finish { op ->
            if (op !is GattOperation.WriteCharacteristic) return@finish false
            if (status == BluetoothGatt.GATT_SUCCESS) op.callback(Result.success(Unit))
            else op.fail(bleError(BleErrorCode.FAILED, "Write failed (status=$status)"))
            true
        }
    }

    @Deprecated("Deprecated in API 33")
    @Suppress("DEPRECATION")
    override fun onDescriptorRead(g: BluetoothGatt, d: BluetoothGattDescriptor, status: Int) {
        val value = d.value ?: ByteArray(0)
        finish { op ->
            if (op !is GattOperation.ReadDescriptor) return@finish false
            if (status == BluetoothGatt.GATT_SUCCESS) op.callback(Result.success(value))
            else op.fail(bleError(BleErrorCode.FAILED, "Descriptor read failed (status=$status)"))
            true
        }
    }

    override fun onDescriptorWrite(g: BluetoothGatt, d: BluetoothGattDescriptor, status: Int) {
        finish { op ->
            val ok = status == BluetoothGatt.GATT_SUCCESS
            when (op) {
                is GattOperation.SetNotify -> {
                    if (ok) op.callback(Result.success(Unit))
                    else op.fail(bleError(BleErrorCode.FAILED, "CCCD write failed (status=$status)"))
                    true
                }
                is GattOperation.WriteDescriptor -> {
                    if (ok) op.callback(Result.success(Unit))
                    else op.fail(bleError(BleErrorCode.FAILED, "Descriptor write failed (status=$status)"))
                    true
                }
                else -> false
            }
        }
    }

    override fun onMtuChanged(g: BluetoothGatt, mtu: Int, status: Int) {
        finish { op ->
            if (op !is GattOperation.RequestMtu) return@finish false
            if (status == BluetoothGatt.GATT_SUCCESS) op.callback(Result.success(mtu.toLong()))
            else op.fail(bleError(BleErrorCode.FAILED, "MTU request failed (status=$status)"))
            true
        }
    }

    override fun onReadRemoteRssi(g: BluetoothGatt, rssi: Int, status: Int) {
        finish { op ->
            if (op !is GattOperation.ReadRssi) return@finish false
            if (status == BluetoothGatt.GATT_SUCCESS) op.callback(Result.success(rssi.toLong()))
            else op.fail(bleError(BleErrorCode.FAILED, "RSSI read failed (status=$status)"))
            true
        }
    }

    @Deprecated("Deprecated in API 33")
    @Suppress("DEPRECATION")
    override fun onCharacteristicChanged(g: BluetoothGatt, ch: BluetoothGattCharacteristic) {
        val value = ch.value ?: ByteArray(0)
        val handle = characteristicHandles[ch] ?: return
        main.post {
            observer().onCallback(
                "onCharacteristicValue",
                "${device.address}/$connectionEpoch/$handle")
            callbacks.onCharacteristicValue(
                device.address, connectionEpoch, handle, value) {}
        }
    }
}
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
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
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
    private val adapterStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action != BluetoothAdapter.ACTION_STATE_CHANGED) return
            when (intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)) {
                BluetoothAdapter.STATE_ON ->
                    callbacks.onAdapterStateChanged(AdapterStateMessage.POWERED_ON) {}
                BluetoothAdapter.STATE_OFF ->
                    callbacks.onAdapterStateChanged(AdapterStateMessage.POWERED_OFF) {}
            }
        }
    }

    var activityProvider: () -> Activity? = { null }

    fun initialize(request: InitializeRequestMessage): String {
        val engineToken = candidateTokenForCurrentMessenger()
        if (isInitializedBy(engineToken)) {
            throw bleError(BleErrorCode.ALREADY_INITIALIZED, "Already initialized in this engine")
        }
        request.backgroundCallbackHandle?.let {
            HeadlessEngineLauncher.storeBackgroundHandle(context, it)
        }
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
        context.registerReceiver(
            adapterStateReceiver, IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED))
        markInitialized(engineToken)
        return engineToken
    }

    fun notifyDartReady(engineToken: String) {
        val currentAdapterState = when {
            !context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE) ||
                adapter == null -> AdapterStateMessage.UNAVAILABLE
            adapter?.isEnabled == true -> AdapterStateMessage.POWERED_ON
            else -> AdapterStateMessage.POWERED_OFF
        }
        callbacks.onAdapterStateChanged(currentAdapterState) {}
        // candidate sinkへsnapshotを送る。ackまでは旧active sinkを維持し、
        // snapshot以後のイベントはowner内で順序付きバッファへ積む。
        sendStateResyncToCandidate(engineToken)
    }

    fun ackStateResync(engineToken: String, snapshotId: String) {
        activateCandidateAndFlush(engineToken, snapshotId)
        HeadlessEngineLauncher.onUiHandoverAcknowledged()
    }

    // Androidは全フィルタカテゴリをネイティブのScanFilterで実施する
    // (1エントリ=1 ScanFilter、リスト全体でOR)。
    fun startScan(filter: ScanFilterMessage?, settings: AndroidScanSettingsMessage) {
        if (!hasPermission(Manifest.permission.BLUETOOTH_SCAN))
            throw bleError(BleErrorCode.PERMISSION_DENIED, "BLUETOOTH_SCAN denied")
        if (!context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE))
            throw bleError(BleErrorCode.BLUETOOTH_UNAVAILABLE, "Bluetooth LE unsupported")
        val a = adapter
            ?: throw bleError(BleErrorCode.BLUETOOTH_UNAVAILABLE, "No Bluetooth adapter")
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

    fun connect(deviceId: String, callback: (Result<ConnectionAttemptMessage>) -> Unit) {
        if (!hasPermission(Manifest.permission.BLUETOOTH_CONNECT)) {
            callback(Result.failure(bleError(BleErrorCode.PERMISSION_DENIED, "BLUETOOTH_CONNECT denied")))
            return
        }
        if (!context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            callback(Result.failure(bleError(
                BleErrorCode.BLUETOOTH_UNAVAILABLE, "Bluetooth LE unsupported")))
            return
        }
        val a = adapter
        if (a == null) {
            callback(Result.failure(bleError(
                BleErrorCode.BLUETOOTH_UNAVAILABLE, "No Bluetooth adapter")))
            return
        }
        if (!a.isEnabled) {
            callback(Result.failure(bleError(BleErrorCode.BLUETOOTH_OFF, "Bluetooth is off")))
            return
        }
        val device = try {
            a.getRemoteDevice(deviceId)
        } catch (e: IllegalArgumentException) {
            callback(Result.failure(bleError(BleErrorCode.NOT_FOUND, "Invalid device id: $deviceId")))
            return
        }
        val epoch = allocateConnectionEpoch(deviceId)
        val connection = GattConnection(
            context, device, epoch, callbacks, observer)
        connections[deviceId] = connection
        connection.connect()
        // attemptのarm完了で即返す。接続成否はepoch付きstate callbackで通知する。
        callback(Result.success(ConnectionAttemptMessage(connectionEpoch = epoch)))
    }

    fun disconnect(deviceId: String, connectionEpoch: Long,
                   callback: (Result<Unit>) -> Unit) {
        val c = connections[deviceId]
        if (c == null || c.connectionEpoch != connectionEpoch) {
            callback(Result.failure(bleError(BleErrorCode.NOT_CONNECTED, "Not connected")))
            return
        }
        c.disconnect(callback)
    }

    fun discoverServices(deviceId: String, connectionEpoch: Long,
                         callback: (Result<List<ServiceMessage>>) -> Unit) {
        connectionOr(deviceId, connectionEpoch, callback)
            ?.discoverServices(callback)
    }

    // Androidはread応答とnotify callbackが別なので常に厳密。strictReadは無視する(spec決定#20)。
    fun readCharacteristic(target: CharacteristicTargetMessage, strictRead: Boolean, callback: (Result<ByteArray>) -> Unit) {
        connectionOr(target.deviceId, target.connectionEpoch, callback)?.enqueue(
            GattOperation.ReadCharacteristic(
                target.characteristicHandle, callback))
    }

    fun writeCharacteristic(
        target: CharacteristicTargetMessage, value: ByteArray, withResponse: Boolean,
        callback: (Result<Unit>) -> Unit,
    ) {
        connectionOr(target.deviceId, target.connectionEpoch, callback)?.enqueue(
            GattOperation.WriteCharacteristic(
                target.characteristicHandle, value, withResponse, callback))
    }

    fun setNotify(target: CharacteristicTargetMessage, enabled: Boolean, callback: (Result<Unit>) -> Unit) {
        connectionOr(target.deviceId, target.connectionEpoch, callback)?.enqueue(
            GattOperation.SetNotify(target.characteristicHandle, enabled, callback))
    }

    fun readDescriptor(target: DescriptorTargetMessage, callback: (Result<ByteArray>) -> Unit) {
        connectionOr(target.deviceId, target.connectionEpoch, callback)?.enqueue(
            GattOperation.ReadDescriptor(
                target.characteristicHandle, target.descriptorHandle, callback))
    }

    fun writeDescriptor(target: DescriptorTargetMessage, value: ByteArray, callback: (Result<Unit>) -> Unit) {
        connectionOr(target.deviceId, target.connectionEpoch, callback)?.enqueue(
            GattOperation.WriteDescriptor(
                target.characteristicHandle, target.descriptorHandle, value, callback))
    }

    fun requestMtu(deviceId: String, connectionEpoch: Long, mtu: Long,
                   callback: (Result<Long>) -> Unit) {
        connectionOr(deviceId, connectionEpoch, callback)
            ?.enqueue(GattOperation.RequestMtu(mtu.toInt(), callback))
    }

    fun readRssi(deviceId: String, connectionEpoch: Long, callback: (Result<Long>) -> Unit) {
        connectionOr(deviceId, connectionEpoch, callback)
            ?.enqueue(GattOperation.ReadRssi(callback))
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
     * [spec反映] エンジン detach 時は **sink を unregister** するのみ(接続は
     * プロセスグローバル owner が保持し続ける。Task 9/11 でこのメソッドは owner の
     * sink 解除へ置換)。FGSは止めない(専用エントリポイントによるヘッドレス復活、
     * または UI 復帰時の sink rebind + 状態リシンクで継続。spec「エンジン所有契約」)。
     */
    fun onEngineDetached() {
        // engine固有の候補/active sinkだけを解除する。
        // 接続・scan・operation queue・epochはプロセスグローバルownerが保持する。
        unregisterSinkForCurrentEngine()
    }

    /** 利用者による明示的な破棄。FGSもここでのみ停止する。 */
    fun dispose() {
        stopScan()
        connections.values.forEach { it.close() }
        connections.clear()
        context.unregisterReceiver(adapterStateReceiver)
        unregisterAllSinks()
        DeepskyForegroundService.stop(context)
        initialized = false
    }

    private fun <T> connectionOr(
        deviceId: String,
        connectionEpoch: Long,
        callback: (Result<T>) -> Unit,
    ): GattConnection? {
        val c = connections[deviceId]
        if (c == null || !c.isConnected || c.connectionEpoch != connectionEpoch) {
            callback(Result.failure(
                bleError(BleErrorCode.NOT_CONNECTED, "Not connected or stale epoch")))
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
        val manager = BleProcessOwner.getOrCreate(binding.applicationContext) {
            DeepskyBluetoothAndroidObserverRegistry.observer
        }
        // attach時点ではcandidate。Dart側notifyDartReady(engineToken)までpushしない。
        manager.registerCandidateSink(binding.binaryMessenger, callbacks)
        central = manager
        BleHostApi.setUp(
            binding.binaryMessenger,
            ObservingBleHostApi(manager) { DeepskyBluetoothAndroidObserverRegistry.observer },
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        BleHostApi.setUp(binding.binaryMessenger, null)
        // engine固有sinkだけを解除。プロセスownerのGATT接続は維持する。
        central?.unregisterSink(binding.binaryMessenger)
        central = null
        // FGS稼働中にエンジンが消えた場合(タスクスワイプ除去等)はヘッドレスで復活させる
        HeadlessEngineLauncher.onEngineDetached(
            binding.applicationContext, isHeadless = !isUiEngine)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        isUiEngine = true
        // attach時点ではcandidate登録のみ。headless破棄はstate resync ack後。
        HeadlessEngineLauncher.onUiEngineCandidateAttached()
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

- [ ] **Step 10: 純粋状態部品のlocal JVM testを追加してコミット**

最低限のケース:
- epoch単調増加、旧epoch拒否、epoch未確定。
- FIFO同時1操作、callback種別不一致拒否、timeout時の全queue失敗とepoch退役。
- 重複UUIDでもhandle逆引きが一意、epoch退役時clear。
- sink candidate→snapshot→ack→active、256件/30秒上限、古いnotify優先破棄。

```powershell
git rm plugins/deepsky_bluetooth_android/android/src/test/kotlin/com/example/deepsky_bluetooth_android/DeepskyBluetoothAndroidPluginTest.kt
cd plugins/deepsky_bluetooth_android/android
.\gradlew.bat test
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

> **[spec反映] このタスクの Step 1(ヘッドレス launcher)と Step 2/4(CompanionDevice)を以下で置換する。**
> 詳細・根拠は spec「バックグラウンド復活」「CompanionDevice API のバージョン統合」。
>
> **(a) ヘッドレス復活 = 専用エントリポイント方式(`main()` 再実行をやめる)**
> `HeadlessEngineLauncher.ensureEngine` は `executeDartEntrypoint(createDefault())` ではなく、
> アプリが登録した専用 `@pragma('vm:entry-point')` 関数のコールバックハンドル(`SharedPreferences` に
> 永続化済み)を実行する:
>
> ```kotlin
> // ensureEngine 内、engine 生成後:
> val handle = prefs.getLong(KEY_BG_HANDLE, -1L)
> if (handle == -1L) { engine.destroy(); headlessEngine = null; return } // 未登録なら復活しない
> val cb = io.flutter.view.FlutterCallbackInformation.lookupCallbackInformation(handle)
> engine.dartExecutor.executeDartCallback(
>     io.flutter.embedding.engine.dart.DartExecutor.DartCallback(
>         context.assets, loader.findAppBundlePath(), cb))
> ```
> 専用エントリポイントは Dart 側で `WidgetsFlutterBinding.ensureInitialized()` → `DeepskyBluetooth.background()`
> を再生成し再接続する(`runApp()` は呼ばない)。**UI エンジン attach 時は owner の sink rebind +
> 状態リシンク完了後に**ヘッドレスを破棄(spec「エンジン所有契約」)。native BLE 状態はプロセスグローバル
> owner が保持。ハンドル登録は Task 17 の `DeepskyBluetooth.background(onBackgroundRelaunch:)` で行う。
>
> **(b) CompanionDevice = `CompanionDeviceController` で 31–32 / 33–35 / 36+ の3分岐統合**
> 下記 Step 4 の deprecated 直書きを、`Build.VERSION.SDK_INT` 3分岐を内包する単一抽象
> `CompanionDeviceController` 経由に置換する(`BleCentralManager` はこの抽象のみ呼ぶ。
> `@Suppress("DEPRECATION")` は古い世代パスのみ)。`DeepskyCompanionDeviceService` は
> **String 版(31–32)/ `AssociationInfo` 版(33–35)/ `onDevicePresenceEvent`(36+)の3系**を override し、
> `AssociationInfo`/`DevicePresenceEvent` からは `deviceMacAddress`(無ければ `associationId`→
> `getMyAssociations()` で解決)で `deviceId` を取り出し同一内部イベントへ正規化する。
> presence 監視は 31–35 が `startObservingDevicePresence(String)`、36+ が
> `getMyAssociations()` でdeviceIdに対応するassociationIdを解決し、
> `ObservingDevicePresenceRequest.Builder().setAssociationId(id).build()` を渡す。
> `setUuid()` はClassic Bluetooth向けの追加制約があるため使用しない。
> Manifestには31–35用 `REQUEST_OBSERVE_COMPANION_DEVICE_PRESENCE` を記載し、
> `REQUEST_OBSERVE_DEVICE_UUID_PRESENCE` は追加しない。
>
> **(c) 再接続駆動源とhandoverバッファ**
> Companion設定でも `connect()` はpresence監視を自動有効化しない。対象が関連付け済みで
> `setDevicePresenceObservation(enabled:true)` 成功済みなら駆動源C、それ以外はA。
> AはDart engine生存中だけ有効で、プロセス復活保証が必要な利用者はassociate→presence有効化を先に行う。
> ownerのhandoverバッファは `SinkHandoverCoordinator` で256件/30秒に制限し、
> 超過時は古いnotify/presenceから破棄、状態は最新snapshotへ集約してObserverへ警告する。

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
import io.flutter.view.FlutterCallbackInformation

/**
 * [spec反映] エンジン不在時に、アプリが登録した専用 @pragma('vm:entry-point') の
 * バックグラウンドエントリポイントをヘッドレスFlutterEngineで実行して Dart を復活させる。
 * **main()/runApp() は実行しない**(プラグインの Activity 依存クラッシュ・二重 runApp レースを回避。
 * spec「バックグラウンド復活」)。
 *
 * 発火点は2つ:
 * - CompanionDeviceServiceのデバイスイベント時(プロセス死後のシステム起動)
 * - Foreground Service稼働中のエンジン消失時(タスクスワイプ除去等)
 *
 * UIエンジンがActivityにattachしたら、owner の sink rebind + 状態リシンク完了後に
 * ヘッドレスを破棄して一本化する(順序は spec「エンジン所有契約」)。
 * native BLE 状態はプロセスグローバル owner(BleCentralManager)が保持し、エンジンには紐付けない。
 */
object HeadlessEngineLauncher {
    private const val PREFS = "deepsky_bluetooth"
    private const val KEY_BG_HANDLE = "background_relaunch_handle"

    @Volatile
    private var hasUiEngine = false

    private var headlessEngine: FlutterEngine? = null

    /** Task 17/Dart 側が background() 生成時に呼ぶ登録 API のネイティブ受け口で保存する。 */
    fun storeBackgroundHandle(context: Context, handle: Long) {
        context.applicationContext
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putLong(KEY_BG_HANDLE, handle).apply()
    }

    @Synchronized
    fun ensureEngine(context: Context) {
        if (hasUiEngine || headlessEngine != null) return
        val handle = context.applicationContext
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getLong(KEY_BG_HANDLE, -1L)
        if (handle == -1L) return // onBackgroundRelaunch 未登録 → 復活しない(UI 復帰で再接続)

        val loader = FlutterInjector.instance().flutterLoader()
        if (!loader.initialized()) {
            loader.startInitialization(context.applicationContext)
            loader.ensureInitializationComplete(context.applicationContext, null)
        }
        val cb = FlutterCallbackInformation.lookupCallbackInformation(handle) ?: return
        val engine = FlutterEngine(context.applicationContext)
        // main() ではなく専用エントリポイントのみを実行
        engine.dartExecutor.executeDartCallback(
            DartExecutor.DartCallback(context.assets, loader.findAppBundlePath(), cb))
        headlessEngine = engine
    }

    /** UI engineがattachした。まだheadlessを破棄しない。 */
    @Synchronized
    fun onUiEngineCandidateAttached() {
        hasUiEngine = true
    }

    /**
     * ownerがUI sinkへのstate resync ackを検証し、新sinkをactive化した後だけ呼ぶ。
     */
    @Synchronized
    fun onUiHandoverAcknowledged() {
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

実機/エミュレータ確認:
- API 31–32: String版presence callback。
- API 33–35: `AssociationInfo` callback。
- API 36+: `getMyAssociations()` からassociationIdを解決し
  `ObservingDevicePresenceRequest.setAssociationId` を使用すること。
- UI復帰: attach時点ではheadlessが生存し、state resync ack後にだけ破棄されること。

- [ ] **Step 6: コミット**

```powershell
git add plugins/deepsky_bluetooth_android && git commit -m "feat(android): companion device association, service, headless engine relaunch"
```

---

### Task 12: iOSネイティブ — CoreBluetooth + State Restoration + Observer

> **[spec反映]** (1) **GATT 操作キュー(read/notify 分離)**: `peripheral(_:didUpdateValueFor:)` は read 応答と
> notify の両方で発火するため、「read 要求が outstanding なら read 応答(completer 完了・戻り値で返す)、無ければ
> `BleNotifyEvent` として通知ストリームへ」と判定して相関させる(spec「GATT操作の直列化」)。
> read 応答として完了する場合でも `characteristic.isNotifying == true` なら**同じ値を `values` にも併流**し、
> 通知購読側の欠落を防ぐ(spec #4対策)。
> **iOSのキュー方針(Androidとの差):** CoreBluetoothのcallbackはcharacteristicスコープのため、device単位
> FIFOではなく **per-characteristic completion map** で相関する(`readCompletions`/`writeCompletions` 等)。
> これを統一 `OperationQueueState` に対するiOSの例外として認める。ただし**同一 characteristic への
> 同時 read は completer 上書きで hang するため直列化必須**(2件目はin-flight中なら拒否)。異なる
> characteristic 間はCoreBluetoothが内部直列化する。
> **`strictRead` 配線(spec決定#20)**: pigeon `readCharacteristic(target, strictRead)` で運ぶ。
> iOS/macOS は read 発行前に `strictRead && ch.isNotifying` を判定し、真なら read を発行せず
> `readAmbiguousWhileNotifying` code を投げて `CharacteristicReadAmbiguousWhileNotifying` にマップする。
> Android は read と notify の callback が別なので常に厳密、`strictRead` は無視する。
> util に `CharacteristicReadAmbiguousWhileNotifying` 型と `BleErrorCode.readAmbiguousWhileNotifying`、
> bridge(Task 14-16)に code マッピングを追加済み。
> (2) **自動再接続 B 系**: `autoReconnect:true` は `connect(_:options:)` を**タイムアウト無し**で発行し OS の保留接続に
> 依拠(`timeout` 無視)。`didConnect`/`didDisconnect` を body の状態マシンへ。
> `didFailToConnect`や接続待ちの失敗は`connectFailed`、確立後の予期しない
> `didDisconnectPeripheral`は`connectionLost`。不正UUID、または`retrievePeripherals`でも
> `CBPeripheral` identityを復元できない保存IDだけを`deviceNotFound`とする。
> `ConnectionAttempt{epoch}`は`didConnect`を待たず`central.connect`をarmした時点で返す。
> `centralManagerDidUpdateState`はpoweredOff/resetting→poweredOff、poweredOn→poweredOn、
> unsupported→unavailableをadapter state callbackへ流す。poweredOff時もiOSの保留接続を
> cancelしない。電源OFFに伴うdidDisconnectはbluetoothOffとして正規化し、connectionLostとの二重通知を避ける。
> (3) **バッファ溢れ**: `canSendWriteWithoutResponse` を見て `write(withResponse:false)` の溢れを
> `CharacteristicWriteBufferFull` にマップ。`read*` 戻り値は `Result<Uint8List>`。
> (4) **identity**: `connect` のepochはnative controllerが採番して返す。UUID検索ベースの旧
> `findCharacteristic`/`findDescriptor` は削除し、探索時に構築した `(epoch, handle) → CBAttribute`
> mapで解決する。
> (5) **State Restoration**: device id一覧ではなく、state・epoch・再採番済みservices/handles・
> `isNotifying` を含む `StateResyncMessage` をDart ready後に送る。ack後に便宜的な
> `onRestoredConnections` を送る。
> (6) **テスト境界**: `EpochRegistry` / `OperationQueueState` / `HandleRegistry` /
> `SinkHandoverCoordinator` をCoreBluetooth非依存Swiftへ分離しXCTestで検証する。
> Task 13(macOS)はこの差分を引き継ぐ(バックグラウンドは従来どおりエラー)。

**Files:**
- Create: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/DeepskyBluetoothIosObserver.swift`
- Create: `.../BleCentralController.swift`
- Create: `.../ObservingBleHostApi.swift`
- Create: `.../Core/EpochRegistry.swift`
- Create: `.../Core/OperationQueueState.swift`
- Create: `.../Core/HandleRegistry.swift`
- Create: `.../Core/SinkHandoverCoordinator.swift`
- Create: iOS plugin XCTest targetの対応テスト
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
    static let bluetoothUnavailable = "bluetoothUnavailable"
    static let alreadyScanning = "alreadyScanning"
    static let notFound = "notFound"
    static let notConnected = "notConnected"
    static let notSupported = "notSupported"
    static let bufferFull = "bufferFull"
    static let readAmbiguousWhileNotifying = "readAmbiguousWhileNotifying"
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
    private var nextConnectionEpoch: Int64 = 1
    private var epochs: [String: Int64] = [:]
    private var serviceHandles: [ObjectIdentifier: Int64] = [:]
    private var characteristicsByHandle: [String: [Int64: CBCharacteristic]] = [:]
    private var characteristicHandles: [ObjectIdentifier: Int64] = [:]
    private var descriptorsByHandle: [String: [Int64: CBDescriptor]] = [:]
    private var descriptorHandles: [ObjectIdentifier: Int64] = [:]

    private var disconnectCompletions: [String: (Result<Void, Error>) -> Void] = [:]
    private var pendingDisconnectReasons: [String: DisconnectReasonMessage] = [:]
    private var discoverCompletions: [String: (Result<[ServiceMessage], Error>) -> Void] = [:]
    private var pendingDiscovery: [String: Int] = [:]
    private var readCompletions: [String: (Result<FlutterStandardTypedData, Error>) -> Void] = [:]
    private var writeCompletions: [String: (Result<Void, Error>) -> Void] = [:]
    private var notifyCompletions: [String: (Result<Void, Error>) -> Void] = [:]
    private var descriptorReadCompletions: [String: (Result<FlutterStandardTypedData, Error>) -> Void] = [:]
    private var descriptorWriteCompletions: [String: (Result<Void, Error>) -> Void] = [:]
    private var rssiCompletions: [String: (Result<Int64, Error>) -> Void] = [:]
    private var pendingRestoredSnapshots: [StateSnapshotMessage] = []

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

    func notifyDartReady(engineToken: String) throws {
        emitCurrentAdapterState()
        let snapshotId = UUID().uuidString
        let snapshot = StateResyncMessage(
            snapshotId: snapshotId,
            devices: currentSnapshots() + pendingRestoredSnapshots)
        callbacks.onStateResync(snapshot: snapshot) { _ in }
        // pendingRestoredSnapshotsはackStateResync成功後にだけclearする。
    }

    func ackStateResync(engineToken: String, snapshotId: String) throws {
        activateCandidateSink(engineToken, snapshotId: snapshotId)
        let restoredIds = pendingRestoredSnapshots.map(\.deviceId)
        pendingRestoredSnapshots = []
        callbacks.onRestoredConnections(deviceIds: restoredIds) { _ in }
        flushBufferedEvents()
    }

    private func emitCurrentAdapterState() {
        guard let central else { return }
        let state: AdapterStateMessage
        switch central.state {
        case .poweredOn: state = .poweredOn
        case .unsupported: state = .unavailable
        case .poweredOff, .resetting: state = .poweredOff
        case .unauthorized, .unknown: return
        @unknown default: return
        }
        callbacks.onAdapterStateChanged(state: state) { _ in }
    }

    func startScan(filter: ScanFilterMessage?, settings: DarwinScanSettingsMessage) throws {
        guard let central else { throw bleError(BleErrorCode.failed, "Not initialized") }
        guard central.state == .poweredOn else {
            let code: String
            switch central.state {
            case .unauthorized: code = BleErrorCode.permissionDenied
            case .unsupported: code = BleErrorCode.bluetoothUnavailable
            default: code = BleErrorCode.bluetoothOff
            }
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

    func connect(deviceId: String,
                 completion: @escaping (Result<ConnectionAttemptMessage, Error>) -> Void) {
        guard let central else {
            return completion(.failure(bleError(BleErrorCode.failed, "Not initialized")))
        }
        switch central.state {
        case .unauthorized:
            return completion(.failure(
                bleError(BleErrorCode.permissionDenied, "Bluetooth unauthorized")))
        case .unsupported:
            return completion(.failure(
                bleError(BleErrorCode.bluetoothUnavailable, "Bluetooth unsupported")))
        case .poweredOff, .resetting, .unknown:
            return completion(.failure(
                bleError(BleErrorCode.bluetoothOff, "Bluetooth is not powered on")))
        case .poweredOn:
            break
        @unknown default:
            return completion(.failure(
                bleError(BleErrorCode.bluetoothOff, "Bluetooth state is unavailable")))
        }
        guard UUID(uuidString: deviceId) != nil else {
            return completion(.failure(
                bleError(BleErrorCode.notFound, "Invalid peripheral UUID \(deviceId)")))
        }
        guard let p = peripherals[deviceId] ?? retrievePeripheral(deviceId) else {
            // 保存IDからCBPeripheral identity自体を解決できないため終端。
            return completion(.failure(
                bleError(BleErrorCode.notFound, "Cannot resolve peripheral identity \(deviceId)")))
        }
        p.delegate = self
        let epoch = allocateConnectionEpoch(deviceId)
        emitState(deviceId, epoch, .connecting)
        central.connect(p)
        // attemptのarm完了で即返す。接続成否はepoch付きdelegate callbackで通知する。
        completion(.success(ConnectionAttemptMessage(connectionEpoch: epoch)))
    }

    func disconnect(deviceId: String, connectionEpoch: Int64,
                    completion: @escaping (Result<Void, Error>) -> Void) {
        guard currentEpoch(deviceId) == connectionEpoch else {
            return completion(.failure(
                bleError(BleErrorCode.notConnected, "Stale connection epoch")))
        }
        guard let central, let p = peripherals[deviceId], p.state == .connected else {
            return completion(.failure(bleError(BleErrorCode.notConnected, "Not connected")))
        }
        disconnectCompletions[deviceId] = completion
        pendingDisconnectReasons[deviceId] = .userRequested
        emitState(deviceId, connectionEpoch, .disconnecting)
        central.cancelPeripheralConnection(p)
    }

    func discoverServices(deviceId: String, connectionEpoch: Int64,
                          completion: @escaping (Result<[ServiceMessage], Error>) -> Void) {
        guard currentEpoch(deviceId) == connectionEpoch,
              let p = connectedPeripheral(deviceId) else {
            return completion(.failure(bleError(BleErrorCode.notConnected, "Not connected")))
        }
        discoverCompletions[deviceId] = completion
        p.discoverServices(nil)
    }

    func readCharacteristic(target: CharacteristicTargetMessage, strictRead: Bool,
                            completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void) {
        switch findCharacteristic(target) {
        case .failure(let e): completion(.failure(e))
        case .success(let (p, ch)):
            guard ch.properties.contains(.read) else {
                return completion(.failure(bleError(BleErrorCode.notSupported, "Read not supported")))
            }
            // strictRead=true で notify 有効中は、read 応答と通知を区別できないため read を発行せず
            // 曖昧エラーを返す(spec 決定#20)。strictRead=false はベストエフォート(通知値を返しうる)。
            if strictRead, ch.isNotifying {
                return completion(.failure(bleError(
                    BleErrorCode.readAmbiguousWhileNotifying,
                    "read(strictRead: true) is ambiguous while notifying")))
            }
            // per-characteristic completion map のため、同一 characteristic への read を直列化する。
            // 先行 read が in-flight のまま2件目を発行すると completer を上書きして hang するため拒否する。
            guard readCompletions[charKey(target)] == nil else {
                return completion(.failure(
                    bleError(BleErrorCode.failed, "A read for this characteristic is already in flight")))
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
                guard p.canSendWriteWithoutResponse else {
                    return completion(.failure(
                        bleError(BleErrorCode.bufferFull, "Write without response buffer is full")))
                }
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

    func getMtu(deviceId: String, connectionEpoch: Int64,
                completion: @escaping (Result<Int64, Error>) -> Void) {
        guard currentEpoch(deviceId) == connectionEpoch,
              let p = connectedPeripheral(deviceId) else {
            return completion(.failure(bleError(BleErrorCode.notConnected, "Not connected")))
        }
        completion(.success(Int64(p.maximumWriteValueLength(for: .withoutResponse)) + 3))
    }

    func readRssi(deviceId: String, connectionEpoch: Int64,
                  completion: @escaping (Result<Int64, Error>) -> Void) {
        guard currentEpoch(deviceId) == connectionEpoch,
              let p = connectedPeripheral(deviceId) else {
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

    private func allocateConnectionEpoch(_ deviceId: String) -> Int64 {
        let epoch = nextConnectionEpoch
        nextConnectionEpoch += 1
        epochs[deviceId] = epoch
        return epoch
    }

    private func currentEpoch(_ deviceId: String) -> Int64? {
        epochs[deviceId]
    }

    private func findCharacteristic(_ target: CharacteristicTargetMessage)
        -> Result<(CBPeripheral, CBCharacteristic), Error> {
        guard currentEpoch(target.deviceId) == target.connectionEpoch,
              let p = connectedPeripheral(target.deviceId) else {
            return .failure(bleError(BleErrorCode.notConnected, "Not connected"))
        }
        guard let characteristic =
                characteristicsByHandle[target.deviceId]?[target.characteristicHandle] else {
            return .failure(bleError(BleErrorCode.notFound, "Characteristic handle not found"))
        }
        return .success((p, characteristic))
    }

    private func findDescriptor(_ target: DescriptorTargetMessage)
        -> Result<(CBPeripheral, CBDescriptor), Error> {
        guard currentEpoch(target.deviceId) == target.connectionEpoch,
              let p = connectedPeripheral(target.deviceId) else {
            return .failure(bleError(BleErrorCode.notConnected, "Not connected"))
        }
        guard let descriptor =
                descriptorsByHandle[target.deviceId]?[target.descriptorHandle] else {
            return .failure(bleError(BleErrorCode.notFound, "Descriptor handle not found"))
        }
        return .success((p, descriptor))
    }

    private func charKey(_ t: CharacteristicTargetMessage) -> String {
        "\(t.deviceId)|\(t.connectionEpoch)|\(t.characteristicHandle)"
    }

    private func charKey(_ p: CBPeripheral, _ c: CBCharacteristic) -> String {
        let deviceId = p.identifier.uuidString.lowercased()
        guard let epoch = currentEpoch(deviceId),
              let handle = characteristicHandles[ObjectIdentifier(c)] else { return "" }
        return "\(deviceId)|\(epoch)|\(handle)"
    }

    private func descriptorKey(_ t: DescriptorTargetMessage) -> String {
        "\(t.deviceId)|\(t.connectionEpoch)|\(t.characteristicHandle)|\(t.descriptorHandle)"
    }

    private func descriptorKey(_ p: CBPeripheral, _ d: CBDescriptor) -> String {
        guard let c = d.characteristic else { return "" }
        let charTarget = charKey(p, c)
        guard let handle = descriptorHandles[ObjectIdentifier(d)] else { return "" }
        return "\(charTarget)|\(handle)"
    }

    private func emitState(_ deviceId: String, _ epoch: Int64,
                           _ state: ConnectionStateMessage,
                           reason: DisconnectReasonMessage? = nil) {
        observer.onCallback("onConnectionStateChanged", "\(deviceId) \(state)")
        callbacks.onConnectionStateChanged(
            deviceId: deviceId, connectionEpoch: epoch, state: state,
            disconnectReason: reason) { _ in }
    }

    private func serviceMessage(_ s: CBService) -> ServiceMessage {
        let serviceHandle = serviceHandles[ObjectIdentifier(s)]!
        return ServiceMessage(
            handle: serviceHandle,
            uuid: fullUuid(s.uuid),
            characteristics: (s.characteristics ?? []).map { c in
                let characteristicHandle = characteristicHandles[ObjectIdentifier(c)]!
                CharacteristicMessage(
                    handle: characteristicHandle,
                    serviceHandle: serviceHandle,
                    uuid: fullUuid(c.uuid),
                    canRead: c.properties.contains(.read),
                    canWriteWithResponse: c.properties.contains(.write),
                    canWriteWithoutResponse: c.properties.contains(.writeWithoutResponse),
                    canNotify: c.properties.contains(.notify),
                    canIndicate: c.properties.contains(.indicate),
                    descriptors: (c.descriptors ?? []).map {
                        DescriptorMessage(
                            handle: descriptorHandles[ObjectIdentifier($0)]!,
                            uuid: fullUuid($0.uuid))
                    }
                )
            })
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        observer.onCallback("centralManagerDidUpdateState", central.state.rawValue)
        switch central.state {
        case .poweredOn:
            callbacks.onAdapterStateChanged(state: .poweredOn) { _ in }
            // CoreBluetooth命令はpoweredOnでのみ発行する。既存pendingは重複armしない。
            for (deviceId, epoch) in epochs {
                guard let peripheral = peripherals[deviceId] else { continue }
                if peripheral.state == .disconnected {
                    observer.onCallback("rearmConnection", "\(deviceId)/\(epoch)")
                    central.connect(peripheral)
                }
            }
        case .poweredOff, .resetting:
            // 保留接続要求はcancelしない。bodyはreconnectingのまま復帰を待つ。
            callbacks.onAdapterStateChanged(state: .poweredOff) { _ in }
        case .unsupported:
            callbacks.onAdapterStateChanged(state: .unavailable) { _ in }
        case .unauthorized:
            for (deviceId, epoch) in epochs {
                emitState(deviceId, epoch, .disconnected, reason: .permissionDenied)
            }
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        guard let restored = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] else { return }
        pendingRestoredSnapshots = []
        for p in restored {
            p.delegate = self
            let deviceId = p.identifier.uuidString.lowercased()
            peripherals[deviceId] = p
            let epoch = allocateConnectionEpoch(deviceId)
            let services = rebuildHandlesFromRestoredServices(p, epoch: epoch)
            let notifyHandles = activeNotifyHandles(p, epoch: epoch)
            let state = normalizedRestoredState(p.state)
            pendingRestoredSnapshots.append(StateSnapshotMessage(
                deviceId: deviceId,
                connectionEpoch: epoch,
                state: state,
                disconnectReason: state == .disconnected ? .unknown : nil,
                activeNotifyHandles: notifyHandles,
                services: services,
                restored: true))
        }
        observer.onCallback("willRestoreState", pendingRestoredSnapshots)
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
        guard let epoch = currentEpoch(deviceId) else { return }
        emitState(deviceId, epoch, .connected)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        let deviceId = peripheral.identifier.uuidString.lowercased()
        guard let epoch = currentEpoch(deviceId) else { return }
        emitState(deviceId, epoch, .disconnected, reason: .connectFailed)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        let deviceId = peripheral.identifier.uuidString.lowercased()
        disconnectCompletions.removeValue(forKey: deviceId)?(.success(()))
        guard let epoch = currentEpoch(deviceId) else { return }
        let reason = pendingDisconnectReasons.removeValue(forKey: deviceId)
            ?? .connectionLost
        emitState(deviceId, epoch, .disconnected, reason: reason)
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
        rebuildHandleMaps(peripheral)
        completion(.success((peripheral.services ?? []).map { serviceMessage($0) }))
    }

    private func rebuildHandleMaps(_ peripheral: CBPeripheral) {
        let deviceId = peripheral.identifier.uuidString.lowercased()
        characteristicsByHandle[deviceId] = [:]
        descriptorsByHandle[deviceId] = [:]
        var nextHandle: Int64 = 1
        for service in peripheral.services ?? [] {
            serviceHandles[ObjectIdentifier(service)] = nextHandle
            nextHandle += 1
            for characteristic in service.characteristics ?? [] {
                let characteristicHandle = nextHandle
                nextHandle += 1
                characteristicHandles[ObjectIdentifier(characteristic)] = characteristicHandle
                characteristicsByHandle[deviceId]?[characteristicHandle] = characteristic
                for descriptor in characteristic.descriptors ?? [] {
                    let descriptorHandle = nextHandle
                    nextHandle += 1
                    descriptorHandles[ObjectIdentifier(descriptor)] = descriptorHandle
                    descriptorsByHandle[deviceId]?[descriptorHandle] = descriptor
                }
            }
        }
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
                // iOSはread応答とnotifyを区別できない。notify有効中なら、この更新が通知だった
                // 可能性があるため同じ値をvaluesにも併流し、通知購読側の欠落を防ぐ(spec #4対策)。
                if characteristic.isNotifying {
                    let deviceId = peripheral.identifier.uuidString.lowercased()
                    if let epoch = currentEpoch(deviceId),
                       let handle = characteristicHandles[ObjectIdentifier(characteristic)] {
                        observer.onCallback("onCharacteristicValue", key)
                        callbacks.onCharacteristicValue(
                            deviceId: deviceId, connectionEpoch: epoch,
                            characteristicHandle: handle,
                            value: FlutterStandardTypedData(bytes: data)) { _ in }
                    }
                }
            }
            return
        }
        // 保留中のreadがなければNotify/Indicateによる値更新
        guard error == nil else { return }
        let deviceId = peripheral.identifier.uuidString.lowercased()
        guard let epoch = currentEpoch(deviceId),
              let handle = characteristicHandles[ObjectIdentifier(characteristic)] else { return }
        observer.onCallback("onCharacteristicValue", key)
        callbacks.onCharacteristicValue(
            deviceId: deviceId, connectionEpoch: epoch, characteristicHandle: handle,
            value: FlutterStandardTypedData(bytes: data)) { _ in }
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

    func initialize(request: InitializeRequestMessage) throws -> String {
        try observed("initialize", ["isBackground": request.isBackground]) {
            try inner.initialize(request: request)
        }
    }

    func notifyDartReady(engineToken: String) throws {
        try observed("notifyDartReady", ["engineToken": engineToken]) {
            try inner.notifyDartReady(engineToken: engineToken)
        }
    }

    func ackStateResync(engineToken: String, snapshotId: String) throws {
        try observed("ackStateResync", [
            "engineToken": engineToken,
            "snapshotId": snapshotId,
        ]) {
            try inner.ackStateResync(
                engineToken: engineToken, snapshotId: snapshotId)
        }
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

    func connect(deviceId: String,
                 completion: @escaping (Result<ConnectionAttemptMessage, Error>) -> Void) {
        observedAsync("connect", ["deviceId": deviceId], completion) {
            inner.connect(deviceId: deviceId, completion: $0)
        }
    }

    func disconnect(deviceId: String, connectionEpoch: Int64,
                    completion: @escaping (Result<Void, Error>) -> Void) {
        observedAsync("disconnect", [
            "deviceId": deviceId, "epoch": connectionEpoch
        ], completion) {
            inner.disconnect(
                deviceId: deviceId,
                connectionEpoch: connectionEpoch,
                completion: $0)
        }
    }

    func discoverServices(deviceId: String, connectionEpoch: Int64,
                          completion: @escaping (Result<[ServiceMessage], Error>) -> Void) {
        observedAsync("discoverServices", [
            "deviceId": deviceId, "epoch": connectionEpoch
        ], completion) {
            inner.discoverServices(
                deviceId: deviceId, connectionEpoch: connectionEpoch, completion: $0)
        }
    }

    func readCharacteristic(target: CharacteristicTargetMessage, strictRead: Bool,
                            completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void) {
        observedAsync("readCharacteristic", [
            "epoch": target.connectionEpoch,
            "characteristicHandle": target.characteristicHandle
        ], completion) {
            inner.readCharacteristic(target: target, strictRead: strictRead, completion: $0)
        }
    }

    func writeCharacteristic(target: CharacteristicTargetMessage, value: FlutterStandardTypedData,
                             withResponse: Bool,
                             completion: @escaping (Result<Void, Error>) -> Void) {
        observedAsync("writeCharacteristic",
                      ["epoch": target.connectionEpoch,
                       "characteristicHandle": target.characteristicHandle,
                       "withResponse": withResponse],
                      completion) {
            inner.writeCharacteristic(target: target, value: value, withResponse: withResponse, completion: $0)
        }
    }

    func setNotify(target: CharacteristicTargetMessage, enabled: Bool,
                   completion: @escaping (Result<Void, Error>) -> Void) {
        observedAsync("setNotify",
                      ["epoch": target.connectionEpoch,
                       "characteristicHandle": target.characteristicHandle,
                       "enabled": enabled], completion) {
            inner.setNotify(target: target, enabled: enabled, completion: $0)
        }
    }

    func readDescriptor(target: DescriptorTargetMessage,
                        completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void) {
        observedAsync("readDescriptor", [
            "epoch": target.connectionEpoch,
            "descriptorHandle": target.descriptorHandle
        ], completion) {
            inner.readDescriptor(target: target, completion: $0)
        }
    }

    func writeDescriptor(target: DescriptorTargetMessage, value: FlutterStandardTypedData,
                         completion: @escaping (Result<Void, Error>) -> Void) {
        observedAsync("writeDescriptor", [
            "epoch": target.connectionEpoch,
            "descriptorHandle": target.descriptorHandle
        ], completion) {
            inner.writeDescriptor(target: target, value: value, completion: $0)
        }
    }

    func getMtu(deviceId: String, connectionEpoch: Int64,
                completion: @escaping (Result<Int64, Error>) -> Void) {
        observedAsync("getMtu", [
            "deviceId": deviceId, "epoch": connectionEpoch
        ], completion) {
            inner.getMtu(
                deviceId: deviceId, connectionEpoch: connectionEpoch, completion: $0)
        }
    }

    func readRssi(deviceId: String, connectionEpoch: Int64,
                  completion: @escaping (Result<Int64, Error>) -> Void) {
        observedAsync("readRssi", [
            "deviceId": deviceId, "epoch": connectionEpoch
        ], completion) {
            inner.readRssi(
                deviceId: deviceId, connectionEpoch: connectionEpoch, completion: $0)
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

macOSマシンでXCTestを実行後、
`cd plugins/deepsky_bluetooth_ios/example && flutter build ios --no-codesign --debug`。
Expected: 純粋状態部品の全テストとビルドが成功。Swiftコンパイルエラーが出た場合はここで修正してコミット。

---

### Task 13: macOSネイティブ — CoreBluetooth + Observer(バックグラウンドはエラー)

**Files:**
- Create: `plugins/deepsky_bluetooth_macos/macos/deepsky_bluetooth_macos/Sources/deepsky_bluetooth_macos/DeepskyBluetoothMacosObserver.swift`
- Create: `.../BleCentralController.swift`(iOS版をコピーし下記の差分を適用)
- Create: `.../ObservingBleHostApi.swift`(iOS版をコピーし下記の差分を適用)
- Create: macOS plugin XCTest target(iOSと同じ純粋状態遷移ケース)
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

5. `BleCentralController.swift`: iOS固有の `pendingRestoredSnapshots`、
   `centralManager(_:willRestoreState:)`、`onRestoredConnections` 発行だけを削除する。
   `notifyDartReady(engineToken:)` / `ackStateResync(engineToken:snapshotId:)` は
   engine handover用なのでmacOSにも残す。
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

> **[spec反映]** `DisconnectReasonMessage`を`BleDisconnectReason`へ全列挙変換し、
> Pigeon callbackは内部`BlePlatformConnectionEvent`へ変換する。`StateSnapshotMessage`も
> disconnected時のreasonを保持する。公開`BleConnectionEvent`はbody(Task 17)だけが生成する。
> `connect()`中に同epochのstate callbackが先着した場合はbridge内で保留し、
> `ConnectionAttempt`を呼び出し元へ返した直後に受信順でstreamへ流す。別epochは混ぜない。

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
    expect(mapScanError(pe('bluetoothUnavailable')),
        isA<ScanBluetoothUnavailable>());
    expect(mapScanError(pe('alreadyScanning')), isA<ScanAlreadyScanning>());
    expect(mapScanError(pe('unknown')), isA<ScanFailed>());
  });

  test('mapConnectError', () {
    expect(mapConnectError(pe('permissionDenied')), isA<ConnectPermissionDenied>());
    expect(mapConnectError(pe('bluetoothOff')), isA<ConnectBluetoothOff>());
    expect(mapConnectError(pe('bluetoothUnavailable')),
        isA<ConnectBluetoothUnavailable>());
    expect(mapConnectError(pe('notFound')), isA<ConnectDeviceNotFound>());
    expect(mapConnectError(pe('timeout')), isA<ConnectTimeout>());
    expect(mapConnectError(pe('unknown')), isA<ConnectFailed>());
  });

  test('mapCharacteristicReadError', () {
    expect(mapCharacteristicReadError(pe('notConnected')), isA<CharacteristicReadNotConnected>());
    expect(mapCharacteristicReadError(pe('notFound')), isA<CharacteristicReadNotFound>());
    expect(mapCharacteristicReadError(pe('notSupported')), isA<CharacteristicReadNotSupported>());
    expect(mapCharacteristicReadError(pe('readAmbiguousWhileNotifying')),
        isA<CharacteristicReadAmbiguousWhileNotifying>());
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
      BleErrorCode.bluetoothUnavailable => const ScanBluetoothUnavailable(),
      BleErrorCode.alreadyScanning => const ScanAlreadyScanning(),
      _ => ScanFailed(_msg(e)),
    };

ConnectError mapConnectError(PlatformException e) => switch (e.code) {
      BleErrorCode.permissionDenied => const ConnectPermissionDenied(),
      BleErrorCode.bluetoothOff => const ConnectBluetoothOff(),
      BleErrorCode.bluetoothUnavailable =>
        const ConnectBluetoothUnavailable(),
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
      BleErrorCode.readAmbiguousWhileNotifying =>
        const CharacteristicReadAmbiguousWhileNotifying(),
      _ => CharacteristicReadFailed(_msg(e)),
    };

CharacteristicWriteError mapCharacteristicWriteError(PlatformException e) =>
    switch (e.code) {
      BleErrorCode.notConnected => const CharacteristicWriteNotConnected(),
      BleErrorCode.notFound => const CharacteristicWriteNotFound(),
      BleErrorCode.notSupported => const CharacteristicWriteNotSupported(),
      BleErrorCode.bufferFull => const CharacteristicWriteBufferFull(),
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
      ConnectionStateMessage.reconnecting => BleConnectionState.reconnecting,
    };

BleAdapterState adapterStateFromMessage(AdapterStateMessage m) => switch (m) {
      AdapterStateMessage.poweredOn => BleAdapterState.poweredOn,
      AdapterStateMessage.poweredOff => BleAdapterState.poweredOff,
      AdapterStateMessage.unavailable => BleAdapterState.unavailable,
    };

BleDisconnectReason disconnectReasonFromMessage(DisconnectReasonMessage m) =>
    switch (m) {
      DisconnectReasonMessage.userRequested =>
        BleDisconnectReason.userRequested,
      DisconnectReasonMessage.connectionLost =>
        BleDisconnectReason.connectionLost,
      DisconnectReasonMessage.connectFailed =>
        BleDisconnectReason.connectFailed,
      DisconnectReasonMessage.operationTimeout =>
        BleDisconnectReason.operationTimeout,
      DisconnectReasonMessage.permissionDenied =>
        BleDisconnectReason.permissionDenied,
      DisconnectReasonMessage.bluetoothOff =>
        BleDisconnectReason.bluetoothOff,
      DisconnectReasonMessage.bluetoothUnavailable =>
        BleDisconnectReason.bluetoothUnavailable,
      DisconnectReasonMessage.deviceNotFound =>
        BleDisconnectReason.deviceNotFound,
      DisconnectReasonMessage.notAssociated =>
        BleDisconnectReason.notAssociated,
      DisconnectReasonMessage.presenceObservationDisabled =>
        BleDisconnectReason.presenceObservationDisabled,
      DisconnectReasonMessage.unknown => BleDisconnectReason.unknown,
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
      deviceId: t.deviceId.value,
      connectionEpoch: t.connectionEpoch,
      characteristicHandle: t.characteristicHandle,
    );

BleCharacteristicTarget characteristicTargetFromMessage(
        CharacteristicTargetMessage m) =>
    BleCharacteristicTarget(
      deviceId: DeepskyDeviceId(m.deviceId),
      connectionEpoch: m.connectionEpoch,
      characteristicHandle: m.characteristicHandle,
    );

DescriptorTargetMessage descriptorTargetToMessage(BleDescriptorTarget t) =>
    DescriptorTargetMessage(
      deviceId: t.deviceId.value,
      connectionEpoch: t.connectionEpoch,
      characteristicHandle: t.characteristicHandle,
      descriptorHandle: t.descriptorHandle,
    );

InitializeRequestMessage configToMessage(DeepskyBluetoothConfig config) =>
    switch (config) {
      ForegroundConfig() => InitializeRequestMessage(
          isBackground: false,
          strategy: null,
          notification: null,
          backgroundCallbackHandle: null),
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
              notification: null,
              backgroundCallbackHandle: backgroundCallbackHandle),
          // android == null はbridge側で事前にBackgroundConfigMissingを返すため到達しない
          null => InitializeRequestMessage(
              isBackground: true,
              strategy: null,
              notification: null,
              backgroundCallbackHandle: backgroundCallbackHandle),
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
  Future<String> initialize(InitializeRequestMessage request) async {
    _maybeThrow();
    lastInitialize = request;
    calls.add('initialize');
    return 'engine-test';
  }

  @override
  Future<void> notifyDartReady(String engineToken) async =>
      calls.add('notifyDartReady:$engineToken');

  @override
  Future<void> ackStateResync(
          String engineToken, String snapshotId) async =>
      calls.add('ackStateResync:$engineToken:$snapshotId');

  @override
  Future<void> startScan(
      ScanFilterMessage? filter, AndroidScanSettingsMessage settings) async {
    _maybeThrow();
    calls.add('startScan');
  }

  @override
  Future<void> stopScan() async => calls.add('stopScan');

  @override
  Future<ConnectionAttemptMessage> connect(String deviceId) async {
    _maybeThrow();
    calls.add('connect:$deviceId');
    return ConnectionAttemptMessage(connectionEpoch: 1);
  }

  @override
  Future<void> disconnect(String deviceId, int connectionEpoch) async =>
      calls.add('disconnect:$deviceId:$connectionEpoch');

  @override
  Future<List<ServiceMessage>> discoverServices(
      String deviceId, int connectionEpoch) async {
    _maybeThrow();
    return services;
  }

  @override
  Future<Uint8List> readCharacteristic(
      CharacteristicTargetMessage target, bool strictRead) async {
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
  Future<void> setNotify(
      CharacteristicTargetMessage target, NotifyTypeMessage type) async {
    calls.add('setNotify:${type.name}');
  }

  @override
  Future<Uint8List> readDescriptor(DescriptorTargetMessage target) async =>
      Uint8List(0);

  @override
  Future<void> writeDescriptor(
      DescriptorTargetMessage target, Uint8List value) async {}

  @override
  Future<int> requestMtu(
      String deviceId, int connectionEpoch, int mtu) async => 247;

  @override
  Future<int> readRssi(String deviceId, int connectionEpoch) async => -42;

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
    bridge.onConnectionStateChanged(
        'dev', 1, ConnectionStateMessage.connected, null);
    final event = await future;
    expect(event.state, BleConnectionState.connected);
  });

  test('onAdapterStateChanged emits adapter state', () async {
    final future = bridge.adapterStates.first;
    bridge.onAdapterStateChanged(AdapterStateMessage.poweredOff);
    expect(await future, BleAdapterState.poweredOff);
  });

  // Fake HostApiがconnect処理中に同epoch callbackを同期注入するケースも追加し、
  // connect Future完了後にだけconnectionEventsへ流れることを検証する。

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
  String? _engineToken;

  final _scanResults = StreamController<BleScanResult>.broadcast();
  final _scanErrors = StreamController<ScanError>.broadcast();
  final _connectionEvents =
      StreamController<BlePlatformConnectionEvent>.broadcast();
  final _notifyEvents = StreamController<BleNotifyEvent>.broadcast();
  final _operationTimeouts =
      StreamController<BleOperationTimeout>.broadcast();
  final _adapterStates = StreamController<BleAdapterState>.broadcast();
  final _stateResync = StreamController<BleStateResync>.broadcast();
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
      _engineToken = await _hostApi.initialize(configToMessage(config));
    }, mapInitializeError);
  }

  @override
  Future<Result<void, InitializeError>> activateCallbacks() =>
      _invoke('activateCallbacks', const {}, () async {
        BleCallbacksApi.setUp(this, binaryMessenger: _binaryMessenger);
        await _hostApi.notifyDartReady(_engineToken!);
      }, mapInitializeError);

  @override
  Future<void> ackStateResync(String snapshotId) =>
      _hostApi.ackStateResync(_engineToken!, snapshotId);

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
  Future<Result<ConnectionAttempt, ConnectError>> connect(
          DeepskyDeviceId deviceId) =>
      _invoke('connect', {'deviceId': deviceId.value},
          () async => connectionAttemptFromMessage(
              await _hostApi.connect(deviceId.value)), mapConnectError);

  @override
  Future<Result<void, DisconnectError>> disconnect(
          DeepskyDeviceId deviceId, int epoch) =>
      _invoke('disconnect', {'deviceId': deviceId.value, 'epoch': epoch},
          () => _hostApi.disconnect(deviceId.value, epoch), mapDisconnectError);

  @override
  Future<Result<List<BleServiceInfo>, DiscoverServicesError>> discoverServices(
          DeepskyDeviceId deviceId, int epoch) =>
      _invoke(
          'discoverServices',
          {'deviceId': deviceId.value, 'epoch': epoch},
          () async => (await _hostApi.discoverServices(deviceId.value, epoch))
              .map(serviceFromMessage)
              .toList(),
          mapDiscoverServicesError);

  @override
  Future<Result<Uint8List, CharacteristicReadError>> readCharacteristic(
          BleCharacteristicTarget target, {bool strictRead = false}) =>
      _invoke(
          'readCharacteristic',
          {
            'epoch': target.connectionEpoch,
            'characteristicHandle': target.characteristicHandle,
            'strictRead': strictRead,
          },
          () => _hostApi.readCharacteristic(
              characteristicTargetToMessage(target), strictRead),
          mapCharacteristicReadError);

  @override
  Future<Result<void, CharacteristicWriteError>> writeCharacteristic(
          BleCharacteristicTarget target, Uint8List value,
          {required bool withResponse}) =>
      _invoke(
          'writeCharacteristic',
          {
            'epoch': target.connectionEpoch,
            'characteristicHandle': target.characteristicHandle,
            'withResponse': withResponse,
          },
          () => _hostApi.writeCharacteristic(
              characteristicTargetToMessage(target), value, withResponse),
          mapCharacteristicWriteError);

  @override
  Future<Result<void, NotifyError>> setNotify(
          BleCharacteristicTarget target, BleNotifyType type) =>
      _invoke(
          'setNotify',
          {
            'epoch': target.connectionEpoch,
            'characteristicHandle': target.characteristicHandle,
            'type': type.name,
          },
          () => _hostApi.setNotify(
              characteristicTargetToMessage(target), notifyTypeToMessage(type)),
          mapNotifyError);

  @override
  Future<Result<Uint8List, DescriptorReadError>> readDescriptor(
          BleDescriptorTarget target) =>
      _invoke(
          'readDescriptor',
          {
            'epoch': target.connectionEpoch,
            'descriptorHandle': target.descriptorHandle,
          },
          () => _hostApi.readDescriptor(descriptorTargetToMessage(target)),
          mapDescriptorReadError);

  @override
  Future<Result<void, DescriptorWriteError>> writeDescriptor(
          BleDescriptorTarget target, Uint8List value) =>
      _invoke(
          'writeDescriptor',
          {
            'epoch': target.connectionEpoch,
            'descriptorHandle': target.descriptorHandle,
          },
          () => _hostApi.writeDescriptor(descriptorTargetToMessage(target), value),
          mapDescriptorWriteError);

  @override
  Future<Result<int, MtuError>> requestMtu(
          DeepskyDeviceId deviceId, int epoch, int mtu) =>
      _invoke('requestMtu',
          {'deviceId': deviceId.value, 'epoch': epoch, 'mtu': mtu},
          () => _hostApi.requestMtu(deviceId.value, epoch, mtu), mapMtuError);

  @override
  Future<Result<int, RssiError>> readRssi(
          DeepskyDeviceId deviceId, int epoch) =>
      _invoke('readRssi', {'deviceId': deviceId.value, 'epoch': epoch},
          () => _hostApi.readRssi(deviceId.value, epoch), mapRssiError);

  @override
  Future<Result<DeepskyDeviceId, AssociateError>> associate(
          {DeepskyScanFilter? filter}) =>
      _invoke('associate', {'hasFilter': filter != null},
          () async => DeepskyDeviceId(
              await _hostApi.associate(scanFilterToMessage(filter))),
          mapAssociateError);

  @override
  Future<Result<void, PresenceError>> setDevicePresenceObservation(
          DeepskyDeviceId deviceId,
          {required bool enabled}) =>
      _invoke(
          'setDevicePresenceObservation',
          {'deviceId': deviceId.value, 'enabled': enabled},
          () => _hostApi.setDevicePresenceObservation(deviceId.value, enabled),
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
  Stream<BlePlatformConnectionEvent> get connectionEvents =>
      _connectionEvents.stream;

  @override
  Stream<BleNotifyEvent> get notifyEvents => _notifyEvents.stream;

  @override
  Stream<BleOperationTimeout> get operationTimeouts =>
      _operationTimeouts.stream;

  @override
  Stream<BleAdapterState> get adapterStates => _adapterStates.stream;

  @override
  Stream<BleCompanionEvent> get companionEvents => _companionEvents.stream;

  /// AndroidにState Restorationはないため何も流れない。
  @override
  Stream<List<DeepskyDeviceId>> get restoredConnections => const Stream.empty();

  @override
  Stream<BleStateResync> get stateResync => _stateResync.stream;

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
  void onConnectionStateChanged(String deviceId, int? connectionEpoch,
      ConnectionStateMessage state, DisconnectReasonMessage? disconnectReason) {
    final event = BlePlatformConnectionEvent(
        deviceId: DeepskyDeviceId(deviceId),
        connectionEpoch: connectionEpoch,
        state: connectionStateFromMessage(state),
        reason: disconnectReason == null
            ? null
            : disconnectReasonFromMessage(disconnectReason));
    _observer?.onCallback(
        'onConnectionStateChanged', '$deviceId ${event.state.name}');
    _connectionEvents.add(event);
  }

  @override
  void onCharacteristicValue(String deviceId, int connectionEpoch,
      int characteristicHandle, Uint8List value) {
    final event = BleNotifyEvent(
        deviceId: DeepskyDeviceId(deviceId),
        connectionEpoch: connectionEpoch,
        characteristicHandle: characteristicHandle,
        value: value);
    _observer?.onCallback(
        'onCharacteristicValue', '$deviceId/$connectionEpoch/$characteristicHandle');
    _notifyEvents.add(event);
  }

  @override
  void onOperationTimeout(String deviceId, int connectionEpoch) {
    _operationTimeouts.add(BleOperationTimeout(
        deviceId: DeepskyDeviceId(deviceId),
        connectionEpoch: connectionEpoch));
  }

  @override
  void onAdapterStateChanged(AdapterStateMessage state) {
    _adapterStates.add(adapterStateFromMessage(state));
  }

  @override
  void onStateResync(StateResyncMessage message) {
    _stateResync.add(stateResyncFromMessage(message));
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

> **[spec反映]** Task 14と同じ切断理由変換を適用し、復元snapshotのdisconnected理由も失わない。

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
        InitializeRequestMessage(
          isBackground: false,
          restoreIdentifier: null,
          backgroundCallbackHandle: null,
        ),
      BackgroundConfig(:final ios, :final backgroundCallbackHandle) =>
        InitializeRequestMessage(
          isBackground: true,
          restoreIdentifier: ios?.restoreIdentifier,
          backgroundCallbackHandle: backgroundCallbackHandle,
        ),
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
      _engineToken = await _hostApi.initialize(configToMessage(config));
    }, mapInitializeError);
  }

  @override
  Future<Result<void, InitializeError>> activateCallbacks() =>
      _invoke('activateCallbacks', const {}, () async {
        BleCallbacksApi.setUp(this, binaryMessenger: _binaryMessenger);
        await _hostApi.notifyDartReady(_engineToken!);
      }, mapInitializeError);

  @override
  Future<void> ackStateResync(String snapshotId) =>
      _hostApi.ackStateResync(_engineToken!, snapshotId);
```

5. `requestMtu` はネイティブの `getMtu` に委譲(要求値は無視される):

```dart
  /// iOSはOSがMTUを自動ネゴシエートするため、要求値は無視して現在値を返す。
  @override
  Future<Result<int, MtuError>> requestMtu(
          DeepskyDeviceId deviceId, int epoch, int mtu) =>
      _invoke('requestMtu',
          {'deviceId': deviceId.value, 'epoch': epoch, 'mtu': mtu},
          () => _hostApi.getMtu(deviceId.value, epoch), mapMtuError);
```

6. `associate` / `setDevicePresenceObservation` はネイティブを呼ばず非対応エラー:

```dart
  @override
  Future<Result<DeepskyDeviceId, AssociateError>> associate(
      {DeepskyScanFilter? filter}) {
    _observer?.onMethodStart('associate', const {});
    const result =
        Result<DeepskyDeviceId, AssociateError>.error(AssociateNotSupported());
    _observer?.onMethodEnd('associate', result);
    return Future.value(result);
  }

  @override
  Future<Result<void, PresenceError>> setDevicePresenceObservation(
      DeepskyDeviceId deviceId,
      {required bool enabled}) {
    _observer?.onMethodStart(
        'setDevicePresenceObservation', {'deviceId': deviceId.value});
    const result = Result<void, PresenceError>.error(PresenceNotSupported());
    _observer?.onMethodEnd('setDevicePresenceObservation', result);
    return Future.value(result);
  }
```

7. ストリーム: `_companionEvents` を削除し、`_operationTimeouts`、`_adapterStates`、`_stateResync`、
   `_restoredConnections` を追加する。
   復元情報はdevice id一覧へ縮退させず、先に完全snapshotを流す:

```dart
  final _restoredConnections =
      StreamController<List<DeepskyDeviceId>>.broadcast();
  final _operationTimeouts =
      StreamController<BleOperationTimeout>.broadcast();
  final _adapterStates = StreamController<BleAdapterState>.broadcast();
  final _stateResync = StreamController<BleStateResync>.broadcast();

  @override
  Stream<BleCompanionEvent> get companionEvents => const Stream.empty();

  @override
  Stream<List<DeepskyDeviceId>> get restoredConnections =>
      _restoredConnections.stream;

  @override
  Stream<BleOperationTimeout> get operationTimeouts =>
      _operationTimeouts.stream;

  @override
  Stream<BleAdapterState> get adapterStates => _adapterStates.stream;

  @override
  Stream<BleStateResync> get stateResync => _stateResync.stream;

  @override
  void onOperationTimeout(String deviceId, int connectionEpoch) {
    _operationTimeouts.add(BleOperationTimeout(
        deviceId: DeepskyDeviceId(deviceId),
        connectionEpoch: connectionEpoch));
  }

  @override
  void onAdapterStateChanged(AdapterStateMessage state) {
    _adapterStates.add(adapterStateFromMessage(state));
  }

  @override
  void onStateResync(StateResyncMessage message) {
    final snapshot = stateResyncFromMessage(message);
    _observer?.onCallback('onStateResync', snapshot);
    _stateResync.add(snapshot);
  }

  @override
  void onRestoredConnections(List<String> deviceIds) {
    _observer?.onCallback('onRestoredConnections', deviceIds);
    _restoredConnections
        .add(deviceIds.map(DeepskyDeviceId.new).toList());
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
  Future<String> initialize(InitializeRequestMessage request) async {
    _maybeThrow();
    lastInitialize = request;
    calls.add('initialize');
    return 'engine-test';
  }

  @override
  Future<void> notifyDartReady(String engineToken) async =>
      calls.add('notifyDartReady:$engineToken');

  @override
  Future<void> ackStateResync(
          String engineToken, String snapshotId) async =>
      calls.add('ackStateResync:$engineToken:$snapshotId');

  @override
  Future<void> startScan(
      ScanFilterMessage? filter, DarwinScanSettingsMessage settings) async {
    _maybeThrow();
    calls.add('startScan');
  }

  @override
  Future<void> stopScan() async => calls.add('stopScan');

  @override
  Future<ConnectionAttemptMessage> connect(String deviceId) async {
    calls.add('connect');
    return ConnectionAttemptMessage(connectionEpoch: 1);
  }

  @override
  Future<void> disconnect(String deviceId, int connectionEpoch) async =>
      calls.add('disconnect');

  @override
  Future<List<ServiceMessage>> discoverServices(
          String deviceId, int connectionEpoch) async =>
      [];

  @override
  Future<Uint8List> readCharacteristic(
          CharacteristicTargetMessage target, bool strictRead) async =>
      Uint8List(0);

  @override
  Future<void> writeCharacteristic(CharacteristicTargetMessage target,
      Uint8List value, bool withResponse) async {}

  @override
  Future<void> setNotify(
      CharacteristicTargetMessage target, NotifyTypeMessage type) async {}

  @override
  Future<Uint8List> readDescriptor(DescriptorTargetMessage target) async =>
      Uint8List(0);

  @override
  Future<void> writeDescriptor(
      DescriptorTargetMessage target, Uint8List value) async {}

  @override
  Future<int> getMtu(String deviceId, int connectionEpoch) async => 185;

  @override
  Future<int> readRssi(String deviceId, int connectionEpoch) async => -42;

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

  test('restoration emits full snapshot before restored device ids', () async {
    final future = bridge.restoredConnections.first;
    bridge.onStateResync(StateResyncMessage(
      snapshotId: 'snapshot-1',
      devices: [
        StateSnapshotMessage(
          deviceId: 'dev-1',
          connectionEpoch: 7,
          state: ConnectionStateMessage.connected,
          disconnectReason: null,
          activeNotifyHandles: [11],
          services: [],
          restored: true,
        ),
      ],
    ));
    bridge.onRestoredConnections(['dev-1']);
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

> **[spec反映]** Task 14/15と同じ`DisconnectReasonMessage`変換と
> `BlePlatformConnectionEvent`搬送を実装する。

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
      _engineToken = await _hostApi.initialize(false);
    }, mapInitializeError);
  }

  @override
  Future<Result<void, InitializeError>> activateCallbacks() =>
      _invoke('activateCallbacks', const {}, () async {
        BleCallbacksApi.setUp(this, binaryMessenger: _binaryMessenger);
        await _hostApi.notifyDartReady(_engineToken!);
      }, mapInitializeError);

  @override
  Future<void> ackStateResync(String snapshotId) =>
      _hostApi.ackStateResync(_engineToken!, snapshotId);
```

4. `restoredConnections => const Stream.empty()`(iOS復元callbackは存在しない)。
   engine handover用 `stateResync` はmacOSにも残す。`companionEvents` / `scanErrors` は `const Stream.empty()`。
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

> **[spec反映] このタスクは spec のオブジェクト指向APIで全面置換する。** 下記 Step の旧フラットAPIコード
> (`connect(deviceId)`/`readCharacteristic(target)`/グローバルストリーム)は破棄し、spec
> 「エントリポイント」「BluetoothDevice」「構造化GATTオブジェクト」「自動再接続」を実装する。
> 公開シグネチャは spec を正とする。
>
> **[spec反映] モジュール分割:** 公開APIを `src/transport`(将来 `deepsky_bluetooth_core` へ抽出)と
> `src/lifecycle`(将来 managed に残る)の2モジュールで構成する。境界は抽象 `BleTransport`。
> - **transport**: `DeepskyBluetoothPlatform` を `platform_resolver` で選択し `transport_impl` でラップ。
>   scan系 / `connect→ConnectionAttempt{epoch}` / `disconnect`/`discover`/`read*`/`write*`/`setNotify`/
>   `requestMtu`/`readRssi`(epoch,handle)/ 生の接続イベント(epoch?+reason)/ notify(epoch+handle)/
>   `BleAdapterState` / state-resync 受領を内部 `BleTransport` ポートとして公開。
>   **状態マシン・autoReconnect は持たない。**
> - **lifecycle**: 下記の公開クラス・状態マシン・3駆動源・autoReconnect・timeout・services キャッシュ・
>   per-characteristic view・バックグラウンド復活登録・sink resync を実装し、**`BleTransport` 経由のみ**で
>   transport を利用する(`deepsky_bluetooth_interface` の platform 型へ直接依存しない)。
> - reason マッピング(native→reason)は bridge=transport 側、**終端/一時の分類と再試行判断は lifecycle 側**。
> - managedは `createTransport` が返す初期化済み・未active sessionを排他的に所有する。全stream購読後に
>   `activateCallbacks()`し、`dispose()`ではlifecycle資源を停止してからtransportを1回だけ破棄する。
> - 将来core抽出時は `BleTransport` を直接exportせず、生成可能な `DeepskyBluetoothCore` facadeを公開する。
>
> body(lifecycle)が実装する内部要素:
>
> - **公開クラス**: `DeepskyBluetooth`(デバイス非依存:scan/associate/restored/`device(id)`/dispose)、
>   `BluetoothDevice`(薄いハンドル。状態を持たず `DeepskyDeviceId` + body 参照のみ、`==` は id 等価)、
>   active な `BleService`/`BleCharacteristic`/`BleDescriptor`(座標 + body 参照)。コンストラクタは内部用
>   (`new` 禁止、body が構築)。
>   `BluetoothDevice`は接続対象デバイスの公開入口としてFlutter/Android利用者に馴染む名称を維持し、
>   GATT属性はBluetooth全般のdevice型と区別するため`Ble*`とする。
> - **接続状態マシン(body 唯一所有)**: per-device に `BleConnectionState`(5値)を管理し、
>   公開 `BleConnectionEvent(state, reason)` を `connectionStates` broadcast へ発行。
>   `disconnected`だけreason必須。epochの唯一の採番元はnative ownerで、bodyは
>   `ConnectionAttempt`/state resyncから受領する。`connect()` は connected/connecting/reconnecting 中なら
>   **暗黙 Ok**(最初のautoReconnect/reconnectPolicyが優先。変更はdisconnect→connectが必要)。
> - **タイムアウト**: body が platform の connect Future を `Timer` と競合(`autoReconnect:true` の iOS は無視)。
> - **自動再接続 = 1状態マシン + 3駆動源**(spec 表)。`ReconnectStrategy` を platform/モードで選択:
>   A=Dart固定間隔ループ(Android foreground/FGS/macOS), B=iOS保留接続(タイマー無し), C=CDM presence。
>   Android CompanionDevice設定では関連付け済みかつpresence監視有効ならC、その他はA。
>   `connect()`は監視を暗黙に有効化しない。engine生存中の監視無効化はAへ切り替え、
>   C必須のheadless復活時に監視不能なら`presenceObservationDisabled`で停止する。状態マシンは内部イベント
>   (`_NativeConnected`/`_NativeDisconnected{reason}`/`_RetryTick`/
>   `_PresenceAppeared`/`_PresenceDisappeared`/`_AdapterPoweredOn`/`_AdapterPoweredOff`/
>   `_AdapterUnavailable`)のみ消費。**fake timer/イベント注入でユニットテスト**する。
>   bluetoothOffは一時理由。OFF中はAのtimer/Cのconnect発行を停止し、BのOS保留接続を維持する。
>   ON復帰でA/Cを即時再評価し、BはOS再開を待つ。
>   permissionDenied/bluetoothUnavailable/deviceNotFound/notAssociatedと、C必須時の
>   presenceObservationDisabledは`disconnected(reason)`で停止。一時理由だけ
>   autoReconnect:trueで`reconnecting`へ進む。reconnecting中の各試行失敗はObserverへ記録し、
>   `disconnected`/`reconnecting`を反復発行しない。
>   `currentEpoch`は最初の`ConnectionAttempt`受領までnull。epochのnull/非null 4象限をspec表どおり
>   判定し、null同士はbodyの単調増加`connectAttemptToken`で現在試行だけを受理する。
> - **GATT 値の振り分け**: platform の `BleNotifyEvent` ストリームを
>   `(deviceId, connectionEpoch, characteristicHandle)` で
>   フィルタし `BleCharacteristic.values`(notify/indicate 専用 broadcast)を生成。**`read()` は戻り値**
>   (`BleCharacteristic.read()`/`BleDescriptor.read()` は `Result<Uint8List, …>`)。epoch退役時に旧`values`を
>   closeし、再接続後は再探索・`setNotify`・再購読を要求する。
> - **探索**: `discoverServices()` は platform の `List<BleServiceInfo>` を active 木へラップし**毎回新ハンドル**を返す。
>   直近結果を `device.services` にキャッシュし、epoch退役時は即null。古いハンドルは
>   `(epoch, handle)` で拒否し `NotFound` 系。
> - **GATT timeoutの公開契約**: active objectの`read`/`write`/`setNotify`/descriptor操作のdoc commentへ、
>   timeout時に接続全体を破棄し`disconnected(reason: operationTimeout)`となることを記載する。
> - **presence**: `setDevicePresenceObservation`/`presenceEvents` は per-device に集約(旧グローバル `companionEvents` 廃止)。
> - **バックグラウンド復活登録**: `background({..., Function? onBackgroundRelaunch})` で
>   `PluginUtilities.getCallbackHandle(onBackgroundRelaunch)` を
>   `BackgroundConfig.backgroundCallbackHandle` → Pigeon `InitializeRequestMessage` でネイティブへ渡し永続化。
> - **sink handover**: constructorで全streamを購読した後に `activateCallbacks()`。`BleStateResync` の全deviceを
>   再構築してから `ackStateResync(snapshotId)` を呼ぶ。ack前に旧engineを破棄しない。
> - **dispose**: インスタンス再利用不可。全 `ReconnectStrategy`(タイマー/購読)・per-device/per-characteristic の
>   `StreamController`・接続を破棄。
> - **Observer**: 各メソッドを `_observed` でラップ、各ストリームを `_observedStream` でフック(旧コードの仕組みを踏襲)。
>
> テストは fake platform に対し:暗黙 Ok 再connect・タイムアウト→`ConnectTimeout`・一時切断→`reconnecting`→
> `connected`・終端理由は`disconnected(reason)`で停止・`autoReconnect:false` は再試行しない・
> currentEpoch/event epochの4象限・connectAttemptTokenによる古いnull失敗の破棄・
> native払い出しepochの採用・旧epochイベント破棄・
> `read()` 戻り値・`values` がnotifyのみ・epoch退役で`values`がonDoneかつservicesがnull・A/C切替・
> 圏外/timeout/status 133が一時失敗・不正identityだけdeviceNotFound・
> bluetoothOff中は試行停止→poweredOnで再開・iOS保留接続をcancelしない・
> bluetoothUnavailableは終端・
> reconnecting中の反復失敗で公開イベントが増えないこと・
> constructor購読後に`activateCallbacks`・resync再構築後にack・callback handleのconfig転送・
> `dispose` 後の購読停止、を最低限カバーする。

**Files:**
- Create: `lib/src/transport/ble_transport.dart`(lifecycle 用の内部抽象ポート)
- Create: `lib/src/transport/transport_impl.dart`(`DeepskyBluetoothPlatform` をラップ)
- Create: `lib/src/transport/platform_resolver.dart`(Platform 判定で bridge 選択)
- Create: `lib/src/transport/transport_factory.dart`(platform解決・initialize・session生成)
- Create: `lib/src/lifecycle/deepsky_bluetooth.dart`(`DeepskyBluetooth` 本体)
- Create: `lib/src/lifecycle/bluetooth_device.dart`(`BluetoothDevice`)
- Create: `lib/src/lifecycle/gatt_objects.dart`(active `BleService`/`BleCharacteristic`/`BleDescriptor`)
- Create: `lib/src/lifecycle/connection_state_machine.dart`(状態マシン + epoch ガード)
- Create: `lib/src/lifecycle/reconnect_strategy.dart`(3駆動源 A/B/C + `ReconnectPolicy` + adapter-state 反応)
- Modify: `lib/deepsky_bluetooth.dart`(テンプレート全置換。lifecycle を export)
- Modify: `test/deepsky_bluetooth_test.dart`(テンプレート全置換)
- Create: `test/architecture/module_dependency_test.dart`(lifecycle/transport の依存方向を検査)

> テスト境界は seam に一致させる:**transport は fake platform 直結**で単発操作/生イベントを、
> **lifecycle は fake `BleTransport` 注入**で状態マシン/再接続/autoReconnect を検証する。
> 下記の Step テストは主に lifecycle 側(fake `BleTransport`)で書く。

- [ ] **Step 1: 失敗するテストを書く**

> **[spec反映] 下記の旧テストは新APIで全面置換する**(Step 4 の新OO本体・本タスク冒頭の [spec反映] 注記に対応)。
> `_FakePlatform` を新 platform シグネチャ(`connect(id) -> ConnectionAttempt`・`Result<List<BleServiceInfo>>`・
> `read*` 戻り値・`notifyEvents`/`operationTimeouts`/`stateResync` ストリーム)へ更新し、最低限:
> ① foreground/background 生成 ② `device(id).connect()` 委譲 + 暗黙Ok再connect
> ③ autoReconnect:true で armed=Ok ④ 一時切断(epoch一致)→`disconnected(reason)`→`reconnecting`→`connected`
> ⑤ reconnecting中の一時失敗では状態イベントを再発行しない ⑥ 終端理由で停止
> ⑦ epoch null/非null 4象限と古いattempt tokenの破棄 ⑧ `char.read()` 戻り値 /
> `char.values` が notify のみ(handle フィルタ) ⑨ epoch退役でservicesクリア
> ⑩ `stateResync` 受領で状態再構築 ⑪ presence無効化のA切替/C必須時の終端
> ⑫ bluetoothOffで維持要求を残してtimer停止、poweredOnで即時再開
> ⑬ bluetoothUnavailableで終端 ⑭ dispose 後の購読停止、を検証する。以下は旧フラットAPI版(参考)。

`test/deepsky_bluetooth_test.dart`(旧・要置換。**以下の `_FakePlatform` と `platform:` 注入は参考にも
使用せず削除する**。新テストは `FakeBleTransport implements BleTransport` と `transport:` 注入で書く):

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
  Future<Result<ConnectionAttempt, ConnectError>> connect(
      DeepskyDeviceId deviceId) async {
    calls.add('connect:$deviceId');
    return const Result.ok(ConnectionAttempt(connectionEpoch: 1));
  }

  @override
  Future<Result<void, DisconnectError>> disconnect(
          DeepskyDeviceId deviceId, int epoch) async =>
      const Result.ok(null);
  @override
  Future<Result<List<BleServiceInfo>, DiscoverServicesError>> discoverServices(
          DeepskyDeviceId deviceId, int epoch) async =>
      const Result.ok([]);
  @override
  Future<Result<Uint8List, CharacteristicReadError>> readCharacteristic(
          BleCharacteristicTarget target, {bool strictRead = false}) async =>
      Result.ok(Uint8List(0));
  @override
  Future<Result<void, CharacteristicWriteError>> writeCharacteristic(
          BleCharacteristicTarget target, Uint8List value,
          {required bool withResponse}) async =>
      const Result.ok(null);
  @override
  Future<Result<void, NotifyError>> setNotify(
          BleCharacteristicTarget target, BleNotifyType type) async =>
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
  Future<Result<int, MtuError>> requestMtu(
          DeepskyDeviceId deviceId, int epoch, int mtu) async =>
      const Result.ok(23);
  @override
  Future<Result<int, RssiError>> readRssi(
          DeepskyDeviceId deviceId, int epoch) async =>
      const Result.ok(-40);
  @override
  Future<Result<DeepskyDeviceId, AssociateError>> associate(
          {DeepskyScanFilter? filter}) async =>
      const Result.ok(DeepskyDeviceId('AA:BB'));
  @override
  Future<Result<void, PresenceError>> setDevicePresenceObservation(
          DeepskyDeviceId deviceId,
          {required bool enabled}) async =>
      const Result.ok(null);
  @override
  Future<Result<void, DisposeError>> dispose() async => const Result.ok(null);
  @override
  Stream<BleScanResult> get scanResults => scanResultsController.stream;
  @override
  Stream<ScanError> get scanErrors => const Stream.empty();
  @override
  Stream<BlePlatformConnectionEvent> get connectionEvents =>
      const Stream.empty();
  @override
  Stream<BleNotifyEvent> get notifyEvents => const Stream.empty();
  @override
  Stream<BleCompanionEvent> get companionEvents => const Stream.empty();
  @override
  Stream<List<DeepskyDeviceId>> get restoredConnections => const Stream.empty();
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

- [ ] **Step 3: `BleTransport` 契約を実装**

`lib/src/transport/ble_transport.dart` 全文:

```dart
import 'dart:typed_data';

import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:steady/steady.dart';

abstract interface class BleTransport {
  Future<Result<void, InitializeError>> activateCallbacks();
  Future<void> ackStateResync(String snapshotId);
  Future<Result<void, ScanError>> startScan({
    DeepskyScanFilter? filter,
    DeepskyScanOptions options = const DeepskyScanOptions(),
  });
  Future<Result<void, ScanError>> stopScan();
  Future<Result<ConnectionAttempt, ConnectError>> connect(DeepskyDeviceId id);
  Future<Result<void, DisconnectError>> disconnect(DeepskyDeviceId id, int epoch);
  Future<Result<List<BleServiceInfo>, DiscoverServicesError>> discoverServices(
      DeepskyDeviceId id, int epoch);
  Future<Result<Uint8List, CharacteristicReadError>> readCharacteristic(
      BleCharacteristicTarget target, {bool strictRead = false});
  Future<Result<void, CharacteristicWriteError>> writeCharacteristic(
      BleCharacteristicTarget target, Uint8List value,
      {required bool withResponse});
  Future<Result<void, NotifyError>> setNotify(
      BleCharacteristicTarget target, BleNotifyType type);
  Future<Result<Uint8List, DescriptorReadError>> readDescriptor(
      BleDescriptorTarget target);
  Future<Result<void, DescriptorWriteError>> writeDescriptor(
      BleDescriptorTarget target, Uint8List value);
  Future<Result<int, MtuError>> requestMtu(
      DeepskyDeviceId id, int epoch, int mtu);
  Future<Result<int, RssiError>> readRssi(DeepskyDeviceId id, int epoch);
  Future<Result<DeepskyDeviceId, AssociateError>> associate({
    DeepskyScanFilter? filter,
  });
  Future<Result<void, PresenceError>> setDevicePresenceObservation(
      DeepskyDeviceId id, {required bool enabled});
  Future<Result<void, DisposeError>> dispose();

  Stream<BleScanResult> get scanResults;
  Stream<ScanError> get scanErrors;
  Stream<BlePlatformConnectionEvent> get connectionEvents;
  Stream<BleNotifyEvent> get notifyEvents;
  Stream<BleOperationTimeout> get operationTimeouts;
  Stream<BleAdapterState> get adapterStates;
  Stream<BleCompanionEvent> get companionEvents;
  Stream<List<DeepskyDeviceId>> get restoredConnections;
  Stream<BleStateResync> get stateResync;
}
```

- [ ] **Step 4: transport adapter・resolver・factory を実装**

`lib/src/transport/platform_resolver.dart` 全文(transport_impl が `BleTransport` としてラップする):

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

`lib/src/transport/transport_impl.dart` は `BleTransport` の全メソッド・全streamを
`DeepskyBluetoothPlatform` へ1対1で委譲する。状態、再試行、Observer hookを加えない。
コンストラクタ以外でplatform型を外へ露出しない。

```dart
import 'dart:typed_data';

import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:steady/steady.dart';

import 'ble_transport.dart';

final class TransportImpl implements BleTransport {
  TransportImpl(this._platform);
  final DeepskyBluetoothPlatform _platform;

  @override
  Future<Result<void, InitializeError>> activateCallbacks() =>
      _platform.activateCallbacks();
  @override
  Future<void> ackStateResync(String snapshotId) =>
      _platform.ackStateResync(snapshotId);
  @override
  Future<Result<void, ScanError>> startScan({
    DeepskyScanFilter? filter,
    DeepskyScanOptions options = const DeepskyScanOptions(),
  }) => _platform.startScan(filter: filter, options: options);
  @override
  Future<Result<void, ScanError>> stopScan() => _platform.stopScan();
  @override
  Future<Result<ConnectionAttempt, ConnectError>> connect(DeepskyDeviceId id) =>
      _platform.connect(id);
  @override
  Future<Result<void, DisconnectError>> disconnect(
          DeepskyDeviceId id, int epoch) =>
      _platform.disconnect(id, epoch);
  @override
  Future<Result<List<BleServiceInfo>, DiscoverServicesError>> discoverServices(
          DeepskyDeviceId id, int epoch) =>
      _platform.discoverServices(id, epoch);
  @override
  Future<Result<Uint8List, CharacteristicReadError>> readCharacteristic(
          BleCharacteristicTarget target, {bool strictRead = false}) =>
      _platform.readCharacteristic(target, strictRead: strictRead);
  @override
  Future<Result<void, CharacteristicWriteError>> writeCharacteristic(
          BleCharacteristicTarget target, Uint8List value,
          {required bool withResponse}) =>
      _platform.writeCharacteristic(target, value, withResponse: withResponse);
  @override
  Future<Result<void, NotifyError>> setNotify(
          BleCharacteristicTarget target, BleNotifyType type) =>
      _platform.setNotify(target, type);
  @override
  Future<Result<Uint8List, DescriptorReadError>> readDescriptor(
          BleDescriptorTarget target) =>
      _platform.readDescriptor(target);
  @override
  Future<Result<void, DescriptorWriteError>> writeDescriptor(
          BleDescriptorTarget target, Uint8List value) =>
      _platform.writeDescriptor(target, value);
  @override
  Future<Result<int, MtuError>> requestMtu(
          DeepskyDeviceId id, int epoch, int mtu) =>
      _platform.requestMtu(id, epoch, mtu);
  @override
  Future<Result<int, RssiError>> readRssi(DeepskyDeviceId id, int epoch) =>
      _platform.readRssi(id, epoch);
  @override
  Future<Result<DeepskyDeviceId, AssociateError>> associate({
    DeepskyScanFilter? filter,
  }) => _platform.associate(filter: filter);
  @override
  Future<Result<void, PresenceError>> setDevicePresenceObservation(
          DeepskyDeviceId id, {required bool enabled}) =>
      _platform.setDevicePresenceObservation(id, enabled: enabled);
  @override
  Future<Result<void, DisposeError>> dispose() => _platform.dispose();

  @override
  Stream<BleScanResult> get scanResults => _platform.scanResults;
  @override
  Stream<ScanError> get scanErrors => _platform.scanErrors;
  @override
  Stream<BlePlatformConnectionEvent> get connectionEvents =>
      _platform.connectionEvents;
  @override
  Stream<BleNotifyEvent> get notifyEvents => _platform.notifyEvents;
  @override
  Stream<BleOperationTimeout> get operationTimeouts =>
      _platform.operationTimeouts;
  @override
  Stream<BleAdapterState> get adapterStates => _platform.adapterStates;
  @override
  Stream<BleCompanionEvent> get companionEvents => _platform.companionEvents;
  @override
  Stream<List<DeepskyDeviceId>> get restoredConnections =>
      _platform.restoredConnections;
  @override
  Stream<BleStateResync> get stateResync => _platform.stateResync;
}
```

`lib/src/transport/transport_factory.dart` 全文:

```dart
import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:steady/steady.dart';

import 'ble_transport.dart';
import 'platform_resolver.dart';
import 'transport_impl.dart';

Future<Result<BleTransport, InitializeError>> createTransport({
  required DeepskyBluetoothConfig config,
  DeepskyBluetoothObserver? observer,
}) async {
  final platform = resolvePlatform(observer);
  if (platform == null) {
    return const Result.error(UnsupportedPlatform());
  }
  final initialized = await platform.initialize(config);
  return initialized.map((_) => TransportImpl(platform));
}
```

transportのテストではfake `DeepskyBluetoothPlatform` を注入した `TransportImpl` に対して、
全メソッドの引数・戻り値と全streamが変更なしで委譲されること、およびfactoryがinitialize失敗を
そのまま返すことを検証する。

- [ ] **Step 5: deepsky_bluetooth.dart(本体クラス)を実装(lifecycle モジュール)**

`lib/src/lifecycle/deepsky_bluetooth.dart` 全文(`BleTransport` 経由でのみ transport を利用):

> **[spec反映] 以下は新オブジェクト指向APIの骨格。** 旧フラットAPI(`connect(deviceId)` 等)は廃止。
> 状態マシン、epochガード、handleフィルタは本タスク冒頭の契約と下記メソッドに従って実装し、
> 省略記号だけの未定義処理を残さない。

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PluginUtilities;
import 'package:steady/steady.dart';

import '../transport/ble_transport.dart';
import '../transport/transport_factory.dart';

/// デバイス非依存の機能のみを持つ BLE Central クライアント(エントリポイント)。
///
/// - [foreground]: 通常のBLE利用。
/// - [background]: iOSはState Restoration(restoreIdentifier必須)、AndroidはFGS/CompanionDevice。
///   macOSでのbackground生成は [BackgroundNotSupported]。
/// dispose 後は再利用不可(再生成すること)。
class DeepskyBluetooth {
  DeepskyBluetooth._(this._transport, this._observer) {
    // transport の内部イベントを deviceId で _DeviceController へ振り分ける。
    // connection/notify/timeout/companion/resync はepoch付き、adapter stateは全device共通。
    _subs
      ..add(_transport.connectionEvents.listen(_routeConnection))
      ..add(_transport.notifyEvents.listen(_routeNotify))
      ..add(_transport.operationTimeouts.listen(_routeTimeout))
      ..add(_transport.adapterStates.listen(_routeAdapterState))
      ..add(_transport.companionEvents.listen(_routeCompanion))
      ..add(_transport.stateResync.listen(_routeResync));
  }

  final BleTransport _transport;
  final DeepskyBluetoothObserver? _observer;
  final _subs = <StreamSubscription<Object?>>[];

  /// deviceId → 接続状態マシン・epoch・再接続戦略・per-characteristic 通知を所有する body 内コントローラ。
  final _devices = <DeepskyDeviceId, _DeviceController>{};

  static Future<Result<DeepskyBluetooth, InitializeError>> foreground({
    DeepskyBluetoothObserver? observer,
    @visibleForTesting BleTransport? transport,
  }) =>
      _create('foreground', const ForegroundConfig(), observer, transport, null);

  /// [onBackgroundRelaunch] は `@pragma('vm:entry-point')` を付けたトップレベル関数。
  /// ヘッドレス復活時に実行される(spec「バックグラウンド復活」)。ハンドルを native へ登録する。
  static Future<Result<DeepskyBluetooth, InitializeError>> background({
    IosBackgroundConfig? ios,
    AndroidBackgroundConfig? android,
    void Function()? onBackgroundRelaunch,
    DeepskyBluetoothObserver? observer,
    @visibleForTesting BleTransport? transport,
  }) =>
      _create('background', BackgroundConfig(ios: ios, android: android),
          observer, transport, onBackgroundRelaunch);

  static Future<Result<DeepskyBluetooth, InitializeError>> _create(
    String mode,
    DeepskyBluetoothConfig config,
    DeepskyBluetoothObserver? observer,
    BleTransport? injectedTransport,
    void Function()? onBackgroundRelaunch,
  ) async {
    observer?.onMethodStart(mode, const {});
    // ヘッドレス復活ハンドルを config に載せて native へ渡す(永続化は native 側)。
    final handle = onBackgroundRelaunch == null
        ? null
        : PluginUtilities.getCallbackHandle(onBackgroundRelaunch)?.toRawHandle();
    final effectiveConfig = switch (config) {
      BackgroundConfig(:final ios, :final android) => BackgroundConfig(
          ios: ios,
          android: android,
          backgroundCallbackHandle: handle,
        ),
      ForegroundConfig() => config,
    };
    // テスト注入されたtransportは初期化済み・未activeのsessionとして扱う。
    final created = injectedTransport == null
        ? await createTransport(config: effectiveConfig, observer: observer)
        : Result<BleTransport, InitializeError>.ok(injectedTransport);
    final result = switch (created) {
      Err(:final error) =>
        Result<DeepskyBluetooth, InitializeError>.error(error),
      Ok(:final data) => await () async {
          // constructorで全streamを購読してからFlutterApiをactive化する。
          final ble = DeepskyBluetooth._(data, observer);
          final activated = await data.activateCallbacks();
          return activated.map((_) => ble);
        }(),
    };
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

  // --- デバイス非依存 ---

  Future<Result<void, ScanError>> startScan(
          {DeepskyScanFilter? filter,
          DeepskyScanOptions options = const DeepskyScanOptions()}) =>
      _observed('startScan', {'hasFilter': filter != null},
          () => _transport.startScan(filter: filter, options: options));

  Future<Result<void, ScanError>> stopScan() =>
      _observed('stopScan', const {}, _transport.stopScan);

  Stream<BleScanResult> get scanResults =>
      _observedStream('scanResults', _transport.scanResults);
  Stream<ScanError> get scanErrors =>
      _observedStream('scanErrors', _transport.scanErrors);

  /// 既知の id からハンドルを取得(同一 id は同一 _DeviceController を共有)。
  BluetoothDevice device(DeepskyDeviceId id) =>
      BluetoothDevice._(_controllerFor(id));

  _DeviceController _controllerFor(DeepskyDeviceId id) =>
      _devices.putIfAbsent(id, () => _DeviceController(id, _transport, _observer));

  /// Android CompanionDevice のみ。関連付け済みデバイスのハンドルを返す。
  Future<Result<BluetoothDevice, AssociateError>> associate(
          {DeepskyScanFilter? filter}) =>
      _observed('associate', {'hasFilter': filter != null},
          () async => (await _transport.associate(filter: filter))
              .map((id) => device(id)));

  /// iOS State Restoration で復元された接続済みデバイス。broadcast。
  Stream<List<BluetoothDevice>> get restoredConnections => _observedStream(
        'restoredConnections',
        _transport.restoredConnections.map((ids) => ids.map(device).toList()),
      );

  Future<Result<void, DisposeError>> dispose() =>
      _observed('dispose', const {}, () async {
        for (final c in _devices.values) {
          await c.teardown(); // 再接続戦略・タイマー・StreamController を破棄
        }
        _devices.clear();
        for (final s in _subs) {
          await s.cancel();
        }
        return _transport.dispose();
      });

  // --- platform イベントの振り分け(epoch ガードは _DeviceController 側)---
  void _routeConnection(BlePlatformConnectionEvent e) =>
      _devices[e.deviceId]?.onNativeConnection(e);
  void _routeNotify(BleNotifyEvent e) => _devices[e.deviceId]?.onNotify(e);
  void _routeTimeout(BleOperationTimeout e) =>
      _devices[e.deviceId]?.onOperationTimeout(e);
  void _routeAdapterState(BleAdapterState state) {
    for (final controller in _devices.values) {
      controller.onAdapterState(state);
    }
  }
  void _routeCompanion(BleCompanionEvent e) =>
      _devices[e.deviceId]?.onCompanion(e);
  Future<void> _routeResync(BleStateResync resync) async {
    for (final snapshot in resync.devices) {
      await _controllerFor(snapshot.deviceId).onResync(snapshot);
    }
    await _transport.ackStateResync(resync.snapshotId);
  }
}

/// 薄いハンドル。状態は持たず id と owner(_DeviceController)参照のみ。`==` は id 等価。
class BluetoothDevice {
  BluetoothDevice._(this._c);
  final _DeviceController _c;

  DeepskyDeviceId get id => _c.id;

  /// 現在の接続状態スナップショット(購読前でも取得可)。未接続は disconnected。
  BleConnectionState get connectionState => _c.state;
  /// per-device の接続状態イベント。disconnectedではreason必須。broadcast。
  Stream<BleConnectionEvent> get connectionStates => _c.states;

  /// autoReconnect:false=接続確立 or timeout/エラーで完了。
  /// autoReconnect:true=維持要求の受理で即 Ok(timeout 無視)。spec「接続まわり詳細」。
  /// 既に connected/connecting/reconnecting なら暗黙 Ok。
  /// 最初のautoReconnect/reconnectPolicyが優先され、変更はdisconnect後に行う。
  Future<Result<void, ConnectError>> connect({
    Duration? timeout,
    bool autoReconnect = false,
    ReconnectPolicy reconnectPolicy = const ReconnectPolicy(),
  }) =>
      _c.connect(
          timeout: timeout,
          autoReconnect: autoReconnect,
          reconnectPolicy: reconnectPolicy);

  /// 自動再接続を解除し、ユーザー起因切断として扱う。
  Future<Result<void, DisconnectError>> disconnect() => _c.disconnect();

  /// 毎回新しいハンドル木を返す(handle 採番済み。spec「ハンドルの寿命」)。
  Future<Result<List<BleService>, DiscoverServicesError>> discoverServices() =>
      _c.discoverServices();
  List<BleService>? get services => _c.servicesCache;

  Future<Result<int, MtuError>> requestMtu(int mtu) => _c.requestMtu(mtu);
  Future<Result<int, RssiError>> readRssi() => _c.readRssi();

  Future<Result<void, PresenceError>> setDevicePresenceObservation(
          {required bool enabled}) =>
      _c.setPresence(enabled: enabled);
  Stream<bool> get presenceEvents => _c.presence;
}

enum ReconnectStrategy { dartLoop, iosPending, companionPresence }

/// body 内コントローラ(非公開)。native払い出しepoch・状態マシン・再接続戦略・
/// per-characteristic 通知ブロードキャスト・services キャッシュを所有する。
class _DeviceController {
  _DeviceController(this.id, this._transport, this._observer);
  final DeepskyDeviceId id;
  final BleTransport _transport;
  final DeepskyBluetoothObserver? _observer;

  int? _epoch; // native ownerからConnectionAttempt/state resyncで受領する。
  int _connectAttemptToken = 0;
  bool _autoReconnect = false;
  bool _adapterPoweredOn = true;
  bool _presenceObservationEnabled = false;
  bool _deviceIsPresent = false;
  ReconnectStrategy _selectedStrategy = ReconnectStrategy.dartLoop;
  var state = BleConnectionState.disconnected;
  final _states = StreamController<BleConnectionEvent>.broadcast();
  final _presence = StreamController<bool>.broadcast();
  // (epoch, characteristicHandle) → 通知broadcast。epoch退役時にcloseする。
  final _notify =
      <({int epoch, int handle}), StreamController<Uint8List>>{};
  List<BleService>? servicesCache;
  // A=Android foreground/FGS/macOS, B=iOS保留接続, C=CDM presence。
  ReconnectPolicy _reconnectPolicy = const ReconnectPolicy();
  Timer? _retryTimer;

  Stream<BleConnectionEvent> get states => _states.stream;
  Stream<bool> get presence => _presence.stream;

  Future<Result<void, ConnectError>> connect({
    Duration? timeout,
    required bool autoReconnect,
    required ReconnectPolicy reconnectPolicy,
  }) async {
    if (state == BleConnectionState.connected ||
        state == BleConnectionState.connecting ||
        state == BleConnectionState.reconnecting) {
      return const Result.ok(null); // 暗黙 Ok(最初の指定が優先)
    }
    _autoReconnect = autoReconnect;
    _emit(BleConnectionState.connecting);
    if (autoReconnect) {
      unawaited(_startConnectAttempt());
      return const Result.ok(null); // armed。_epochはattempt成功までnull
    }
    final attempt = await _transport.connect(id);
    switch (attempt) {
      case Err(:final error):
        _emit(BleConnectionState.disconnected,
            reason: disconnectReasonFromConnectError(error));
        return Result.error(error);
      case Ok(:final data):
        _epoch = data.connectionEpoch;
        return await _waitForConnectedOrError(timeout);
    }
  }

  Future<void> _startConnectAttempt() async {
    if (!_adapterPoweredOn) return;
    final token = ++_connectAttemptToken;
    final attempt = await _transport.connect(id);
    if (token != _connectAttemptToken || !_autoReconnect) return;
    switch (attempt) {
      case Ok(:final data):
        _epoch = data.connectionEpoch;
      case Err(:final error):
        final reason = disconnectReasonFromConnectError(error);
        if (isTerminalDisconnectReason(reason)) {
          _emit(BleConnectionState.disconnected, reason: reason);
          _autoReconnect = false;
          _stopReconnectStrategy();
        } else {
          _observer?.onCallback(
              'connectAttemptFailed', '${id.value} ${reason.name}');
          _enterReconnecting(reason);
          if (reason == BleDisconnectReason.bluetoothOff) {
            _adapterPoweredOn = false; // poweredOn callbackまで再試行しない
          } else {
            _scheduleReconnectForSelectedStrategy();
          }
        }
    }
  }

  Future<Result<void, DisconnectError>> disconnect() async {
    _autoReconnect = false;
    _connectAttemptToken++; // epoch未確定の進行中Futureを失効
    _stopReconnectStrategy();
    final epoch = _epoch;
    if (epoch == null) return const Result.ok(null);
    _emit(BleConnectionState.disconnecting);
    return _transport.disconnect(id, epoch);
  }

  Future<Result<List<BleService>, DiscoverServicesError>>
      discoverServices() async {
    final epoch = _epoch;
    if (epoch == null) {
      return Result.error(DiscoverServicesNotConnected());
    }
    final r = await _transport.discoverServices(id, epoch);
    return r.map((infos) {
      final tree = infos.map((i) => BleService._fromInfo(this, epoch, i)).toList();
      servicesCache = tree;
      return tree;
    });
  }

  Future<Result<int, MtuError>> requestMtu(int mtu) =>
      _transport.requestMtu(id, _epoch!, mtu);
  Future<Result<int, RssiError>> readRssi() => _transport.readRssi(id, _epoch!);
  Future<Result<void, PresenceError>> setPresence({required bool enabled}) async {
    final result =
        await _transport.setDevicePresenceObservation(id, enabled: enabled);
    if (result.isOk) {
      _presenceObservationEnabled = enabled;
      // engine生存中の無効化は維持要求を止めずAへ切り替える。
      _connectAttemptToken++;
      _selectReconnectStrategy();
    }
    return result;
  }

  /// characteristicHandle 単位の通知 view(notify/indicate 専用 broadcast)。
  Stream<Uint8List> notifyStream(int epoch, int characteristicHandle) => _notify
      .putIfAbsent((epoch: epoch, handle: characteristicHandle),
          StreamController<Uint8List>.broadcast)
      .stream;

  // --- platform イベント受信(epoch ガード)---
  void onNativeConnection(BlePlatformConnectionEvent e) {
    if (!_acceptNativeEpoch(e.connectionEpoch)) return;
    if (e.state == BleConnectionState.disconnected) {
      final epoch = e.connectionEpoch;
      if (epoch != null) _retireGattEpoch(epoch);
      final reason = e.reason ?? BleDisconnectReason.unknown;
      if (reason == BleDisconnectReason.userRequested ||
          isTerminalDisconnectReason(reason)) {
        _emit(BleConnectionState.disconnected, reason: reason);
        _autoReconnect = false;
        _connectAttemptToken++;
        _stopReconnectStrategy();
      } else if (_autoReconnect) {
        _enterReconnecting(reason);
        if (reason == BleDisconnectReason.bluetoothOff) {
          _adapterPoweredOn = false;
          _retryTimer?.cancel();
        } else {
          _scheduleReconnectForSelectedStrategy();
        }
      } else {
        _emit(BleConnectionState.disconnected, reason: reason);
      }
      return;
    }
    _emit(e.state);
  }

  void onOperationTimeout(BleOperationTimeout e) {
    if (e.connectionEpoch != _epoch) return;
    _retireGattEpoch(e.connectionEpoch);
    if (_autoReconnect) {
      _enterReconnecting(BleDisconnectReason.operationTimeout);
      _scheduleReconnectForSelectedStrategy();
    } else {
      _emit(BleConnectionState.disconnected,
          reason: BleDisconnectReason.operationTimeout);
    }
  }

  void onAdapterState(BleAdapterState adapterState) {
    switch (adapterState) {
      case BleAdapterState.poweredOff:
        if (!_adapterPoweredOn) return;
        _adapterPoweredOn = false;
        _retryTimer?.cancel(); // Aの固定間隔試行を停止
        if (state == BleConnectionState.disconnected) return;
        final epoch = _epoch;
        if (epoch != null) unawaited(_retireGattEpoch(epoch));
        // Bは同epochのOS保留接続を維持。A/Cは次回connectで新epochを受ける。
        if (_selectedStrategy != ReconnectStrategy.iosPending) _epoch = null;
        if (_autoReconnect) {
          _enterReconnecting(BleDisconnectReason.bluetoothOff);
        } else {
          _emit(BleConnectionState.disconnected,
              reason: BleDisconnectReason.bluetoothOff);
        }
      case BleAdapterState.poweredOn:
        if (_adapterPoweredOn) return;
        _adapterPoweredOn = true;
        if (!_autoReconnect || state != BleConnectionState.reconnecting) return;
        switch (_selectedStrategy) {
          case ReconnectStrategy.dartLoop:
            unawaited(_startConnectAttempt()); // delayを待たず再開
          case ReconnectStrategy.iosPending:
            if (_epoch == null) unawaited(_startConnectAttempt());
            // epoch確定済みならnative ownerがCBPeripheral.stateを見て同epochで再arm。
          case ReconnectStrategy.companionPresence:
            if (_deviceIsPresent) unawaited(_startConnectAttempt());
        }
      case BleAdapterState.unavailable:
        if (state == BleConnectionState.disconnected && !_autoReconnect) return;
        _adapterPoweredOn = false;
        _autoReconnect = false;
        _connectAttemptToken++;
        _stopReconnectStrategy();
        _emit(BleConnectionState.disconnected,
            reason: BleDisconnectReason.bluetoothUnavailable);
    }
  }

  void onNotify(BleNotifyEvent e) {
    if (e.connectionEpoch != _epoch) return;
    _notify[(epoch: e.connectionEpoch, handle: e.characteristicHandle)]
        ?.add(e.value);
  }

  void onCompanion(BleCompanionEvent e) {
    _deviceIsPresent = e.appeared;
    _presence.add(e.appeared);
    if (e.appeared &&
        _adapterPoweredOn &&
        _autoReconnect &&
        state == BleConnectionState.reconnecting &&
        _selectedStrategy == ReconnectStrategy.companionPresence) {
      unawaited(_startConnectAttempt());
    }
  }

  /// sink rebind(ヘッドレス↔UI ハンドオーバ)時の状態リシンク。
  Future<void> onResync(BleStateSnapshot s) async {
    final previousEpoch = _epoch;
    if (previousEpoch != null && previousEpoch != s.connectionEpoch) {
      await _retireGattEpoch(previousEpoch);
    }
    _epoch = s.connectionEpoch; // native が保持していた現行世代へ同期
    _emit(s.state, reason: s.disconnectReason);
    servicesCache = s.services
        ?.map((i) => BleService._fromInfo(this, s.connectionEpoch, i))
        .toList();
  }

  Future<void> _retireGattEpoch(int epoch) async {
    servicesCache = null;
    final keys = _notify.keys.where((key) => key.epoch == epoch).toList();
    for (final key in keys) {
      await _notify.remove(key)?.close(); // 旧values購読へonDone
    }
  }

  void _emit(BleConnectionState s, {BleDisconnectReason? reason}) {
    state = s;
    _states.add(BleConnectionEvent(state: s, reason: reason));
  }

  void _enterReconnecting(BleDisconnectReason reason) {
    if (state == BleConnectionState.reconnecting) {
      _observer?.onCallback(
          'reconnectAttemptFailed', '${id.value} ${reason.name}');
      return;
    }
    _emit(BleConnectionState.disconnected, reason: reason);
    _emit(BleConnectionState.reconnecting);
  }

  bool _acceptNativeEpoch(int? eventEpoch) => switch ((_epoch, eventEpoch)) {
        (null, null) => false, // null失敗はplatform Future + token経由だけで受理
        (null, int()) => false,
        (int(), null) => false,
        (final int current, final int event) => current == event,
      };

  static bool isTerminalDisconnectReason(BleDisconnectReason reason) =>
      switch (reason) {
        BleDisconnectReason.permissionDenied ||
        BleDisconnectReason.bluetoothUnavailable ||
        BleDisconnectReason.deviceNotFound ||
        BleDisconnectReason.notAssociated ||
        BleDisconnectReason.presenceObservationDisabled => true,
        _ => false,
      };

  // ConnectErrorのsealed variantを公開切断理由へ全列挙で変換する。
  static BleDisconnectReason disconnectReasonFromConnectError(
          ConnectError error) =>
      switch (error) {
        ConnectPermissionDenied() => BleDisconnectReason.permissionDenied,
        ConnectBluetoothOff() => BleDisconnectReason.bluetoothOff,
        ConnectBluetoothUnavailable() =>
          BleDisconnectReason.bluetoothUnavailable,
        ConnectDeviceNotFound() => BleDisconnectReason.deviceNotFound,
        ConnectTimeout() => BleDisconnectReason.connectFailed,
        _ => BleDisconnectReason.connectFailed,
      };

  Future<void> teardown() async {
    // 再接続戦略(タイマー/購読)停止、全 StreamController close。
    await _states.close();
    await _presence.close();
    for (final c in _notify.values) {
      await c.close();
    }
  }
}
```

active GATT クラス(`BleService`/`BleCharacteristic`/`BleDescriptor`)は handle ベースで
`_DeviceController` 経由に委譲する。read は戻り値、`values` は notify 専用(handle フィルタ):

```dart
class BleService {
  BleService._(this._c, this._epoch, this._info);
  final _DeviceController _c;
  final int _epoch;
  final BleServiceInfo _info;
  factory BleService._fromInfo(_DeviceController c, int epoch, BleServiceInfo i) =>
      BleService._(c, epoch, i);

  DeepskyUuid get uuid => _info.uuid;
  List<BleCharacteristic> get characteristics =>
      _info.characteristics.map((i) => BleCharacteristic._(_c, _epoch, _info.handle, i)).toList();
}

class BleCharacteristic {
  BleCharacteristic._(this._c, this._epoch, this._serviceHandle, this._info);
  final _DeviceController _c;
  final int _epoch;
  final int _serviceHandle;
  final BleCharacteristicInfo _info;

  DeepskyUuid get uuid => _info.uuid;
  BleCharacteristicProperties get properties => _info.properties;
  List<BleDescriptor> get descriptors =>
      _info.descriptors.map((i) => BleDescriptor._(_c, _epoch, _info.handle, i)).toList();

  /// notify/indicate のみ(epoch+handleフィルタ)。epoch退役時にonDone。
  Stream<Uint8List> get values => _c.notifyStream(_epoch, _info.handle);

  /// timeout時はGATT接続全体を破棄し、connectionStatesへ
  /// disconnected(reason: operationTimeout)を発行する。
  Future<Result<Uint8List, CharacteristicReadError>> read({bool strictRead = false}) =>
      _c._transport.readCharacteristic(_target(), strictRead: strictRead);
  /// timeout時はreadと同様にGATT接続全体を破棄する。
  Future<Result<void, CharacteristicWriteError>> write(Uint8List value,
          {required bool withResponse}) =>
      _c._transport.writeCharacteristic(_target(), value, withResponse: withResponse);
  /// CCCD書込timeout時はGATT接続全体を破棄する。
  Future<Result<void, NotifyError>> setNotify(BleNotifyType type) =>
      _c._transport.setNotify(_target(), type);

  BleCharacteristicTarget _target() => BleCharacteristicTarget(
      deviceId: _c.id, connectionEpoch: _epoch, characteristicHandle: _info.handle);
}

class BleDescriptor {
  BleDescriptor._(this._c, this._epoch, this._charHandle, this._info);
  final _DeviceController _c;
  final int _epoch;
  final int _charHandle;
  final BleDescriptorInfo _info;

  DeepskyUuid get uuid => _info.uuid;
  /// timeout時はGATT接続全体を破棄する。
  Future<Result<Uint8List, DescriptorReadError>> read() =>
      _c._transport.readDescriptor(_target());
  /// timeout時はGATT接続全体を破棄する。
  Future<Result<void, DescriptorWriteError>> write(Uint8List value) =>
      _c._transport.writeDescriptor(_target(), value);

  BleDescriptorTarget _target() => BleDescriptorTarget(
      deviceId: _c.id, connectionEpoch: _epoch,
      characteristicHandle: _charHandle, descriptorHandle: _info.handle);
}
```

- [ ] **Step 6: モジュール依存方向テストを追加**

`test/architecture/module_dependency_test.dart` 全文:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> dartFiles(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'));

void main() {
  test('lifecycle depends on the BleTransport port only', () {
    const forbidden = <String>[
      'DeepskyBluetoothPlatform',
      'transport_impl.dart',
      'platform_resolver.dart',
      'deepsky_bluetooth_android_bridge',
      'deepsky_bluetooth_ios_bridge',
      'deepsky_bluetooth_macos_bridge',
    ];
    for (final file in dartFiles('lib/src/lifecycle')) {
      final source = file.readAsStringSync();
      for (final token in forbidden) {
        expect(source, isNot(contains(token)),
            reason: '${file.path} must not depend on $token');
      }
    }
  });

  test('transport never imports lifecycle', () {
    for (final file in dartFiles('lib/src/transport')) {
      expect(file.readAsStringSync(), isNot(contains('/lifecycle/')),
          reason: '${file.path} must not import lifecycle');
    }
  });
}
```

Run: `flutter test test/architecture/module_dependency_test.dart`
Expected: PASS。以後このテストをルートの `flutter test` とCIで常時実行する。

- [ ] **Step 7: exportファイルを置換**

`lib/deepsky_bluetooth.dart` 全文:

```dart
library;

export 'package:deepsky_bluetooth_interface/deepsky_bluetooth_interface.dart';
export 'package:steady/steady.dart';

export 'src/lifecycle/deepsky_bluetooth.dart';
```

- [ ] **Step 8: テストが通ることを確認**

Run: ルートで `flutter test`
Expected: All tests passed

- [ ] **Step 9: コミット**

```powershell
git add lib test pubspec.yaml && git commit -m "feat: public DeepskyBluetooth api with platform resolution and observer"
```

---

### Task 18: ルートexampleアプリ

> **[spec反映]** 新 OO API(`ble.device(id).connect(autoReconnect: true)` → `discoverServices()` →
> `char.values.listen` / `char.read()` 戻り値 / `char.setNotify`)へ追従。さらに **`@pragma('vm:entry-point')`
> を付けたトップレベルのバックグラウンド復活関数**を定義し、`DeepskyBluetooth.background(onBackgroundRelaunch: ...)`
> に渡す例を含める(`runApp()` を呼ばず再接続のみ。spec「バックグラウンド復活」)。

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

const restoreId = 'com.example.deepsky.restore';
const notification = AndroidNotificationConfig(
  channelId: 'ble',
  channelName: 'BLE',
  title: 'deepsky_bluetooth',
  text: 'BLE link active',
);

@pragma('vm:entry-point')
Future<void> bleBackgroundEntryPoint() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DeepskyBluetooth.background(
    ios: const IosBackgroundConfig(restoreIdentifier: restoreId),
    android: const AndroidForegroundServiceConfig(notification: notification),
    onBackgroundRelaunch: bleBackgroundEntryPoint,
  );
  // runApp()は呼ばない。アプリ固有の永続化済みdevice idがある場合はここでconnectする。
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
                      ios: const IosBackgroundConfig(restoreIdentifier: restoreId),
                      android: const AndroidForegroundServiceConfig(
                          notification: notification),
                      onBackgroundRelaunch: bleBackgroundEntryPoint,
                      observer: observer,
                    )),
          ),
          ListTile(
            title: const Text('Background (iOS restore / Android CompanionDevice)'),
            onTap: () => _start(
                context,
                (observer) => DeepskyBluetooth.background(
                      ios: const IosBackgroundConfig(restoreIdentifier: restoreId),
                      android: const AndroidCompanionDeviceConfig(),
                      onBackgroundRelaunch: bleBackgroundEntryPoint,
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
  final _devices = <DeepskyDeviceId, BleScanResult>{};
  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _subscriptions.add(widget.ble.scanResults.listen((r) {
      setState(() => _devices[r.deviceId] = r);
    }));
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

  Future<void> _connectAndDiscover(DeepskyDeviceId deviceId) async {
    final device = widget.ble.device(deviceId);
    _subscriptions.add(device.connectionStates.listen((event) {
      if (event.state == BleConnectionState.disconnected) {
        widget.logs.add('disconnected: ${event.reason}');
      }
      if (event.state == BleConnectionState.connected) {
        // 新epochのhandleへ自動付け替えしないため、毎回再探索・再購読する。
        unawaited(_discoverAndSubscribe(device));
      }
      if (mounted) setState(() {});
    }));
    _subscriptions.add(device.presenceEvents.listen((_) {
      if (mounted) setState(() {});
    }));
    final connect = await device.connect(autoReconnect: true);
    if (connect.isErr) return;
  }

  Future<void> _discoverAndSubscribe(BluetoothDevice device) async {
    final services = await device.discoverServices();
    if (!mounted) return;
    switch (services) {
      case Ok(:final data):
        final notifyCharacteristics = data
            .expand((service) => service.characteristics)
            .where((characteristic) => characteristic.properties.notify)
            .toList();
        if (notifyCharacteristics.isNotEmpty) {
          final characteristic = notifyCharacteristics.first;
          _subscriptions.add(characteristic.values.listen(
            (value) => widget.logs.add('notify: $value'),
            onDone: () => widget.logs.add(
                'notification handle retired; rediscover after reconnect'),
          ));
          await characteristic.setNotify(BleNotifyType.notify);
        }
        showDialog<void>(
          context: context,
          builder: (_) => SimpleDialog(
            title: Text('Services of ${device.id}'),
            children: [
              for (final s in data)
                ListTile(
                  title: Text('${s.uuid}'),
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
                  title: Text(d.name ?? '${d.deviceId}'),
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

4. プラットフォーム設定表: iOS(`NSBluetoothAlwaysUsageDescription`、`UIBackgroundModes: bluetooth-central`、
   State Restorationは接続保留・notify状態を完全snapshotで復元)、Android(minSdk 31、権限要求はアプリ責務、
   36+のpresence監視はassociationId経路、ヘッドレス復活は登録済み専用entrypointを実行して`main()`/`runApp()`は
   呼ばない、UI復帰時はstate resync ack後にheadlessを破棄)、macOS(Bluetooth entitlement、backgroundはエラー)
5. ライフサイクルの説明: 同一isolateの2つ目は `AlreadyInitialized`。別engineは
   `attach→Dart ready→resync→ack` でhandoverする。native ownerが接続とepochを維持する。
   active GATT objectはepochスコープで、再接続時に旧`values`が終了するため再探索・再購読が必要。
6. `connectionStates` の説明: `BleConnectionEvent`を発行し、`disconnected`は必ず
   `BleDisconnectReason`を持つ。終端理由(permissionDenied/bluetoothUnavailable/deviceNotFound/
   notAssociated、およびC必須時のpresenceObservationDisabled)は再試行停止。一時理由は最初の
   `disconnected(reason)→reconnecting`だけを発行し、reconnecting中の反復失敗はObserverへ記録する。
   bluetoothOffは維持要求を残してadapter復帰を待ち、圏外/接続timeoutはconnectFailedであり
   deviceNotFoundではない。
   `autoReconnect:true`のarmed後エラーはここで観測する。
7. **再接続後の再購読コード例(必須)**: `connected`イベントごとに
   `discoverServices()`→対象characteristic選択→`values.listen(onDone: ...)`→`setNotify()`を
   再実行する完全なサンプル。epoch退役時に`device.services == null`になることも説明する。
8. Android CompanionDeviceのA/C選択: associate済み + 明示的な
   `setDevicePresenceObservation(enabled:true)`でC、それ以外はA。`connect()`は監視を自動有効化しない。
9. GATT操作timeoutの副作用: 1回のread/write/setNotify timeoutでも接続全体を破棄する。
   `autoReconnect:false`は`disconnected(reason: operationTimeout)`で停止する。
10. Observer・エラー設計の説明(sealed + switch網羅)
11. 将来拡張として、重複UUIDの選択規則を利用者が指定するopt-inのUUIDパス自動再購読ヘルパを
    検討対象に残す。ただし初期APIには含めない。

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
cd ../plugins/deepsky_bluetooth_android/android && .\gradlew.bat test
```

Expected: すべて成功

- [ ] **Step 4: コミット**

```powershell
git add README.md CHANGELOG.md && git commit -m "docs: usage, platform setup, error and observer design"
```

- [ ] **Step 5: [macOSホスト・最終チェックポイント]**

macOSマシンでiOS/macOS pluginのXCTestを実行後、
`cd example && flutter build ios --no-codesign --debug && flutter build macos --debug`。
実機確認項目:
- iOS: 接続済み・接続保留中・notify購読中の各状態でアプリをOS終了させ、再起動時の
  `BleStateResync` にstate/新epoch/services/activeNotifyHandlesが入り、ack後に
  `restoredConnections` が発行されること。
- Android: FGS常駐とCDS復活(`adb shell am kill` 後のonDeviceAppeared)、UI復帰時に
  resync ack前はheadlessが破棄されず、ack後に接続を維持したままUI sinkへ切り替わること。

---

## セルフレビュー結果(計画作成時に実施済み)

- **要件カバレッジ:** FG/BG明示インスタンス化(Task 4/17)、3プラットフォーム(Task 6-13)、FG/BG問わずDartコールバック(FlutterApi+バッファ+notifyDartReady: Task 6-13)、iOS State Restoration(Task 12)、Android FGS/CDS選択(Task 4/9-11)、macOS BGエラー(Task 16 ※ネイティブ側防御はTask 13)、plugins=ネイティブ担当(Task 6-13)、Pigeon型安全通信(Task 6-8)、Bridgeがinterfaceへ適合(Task 14-16)、steady Result(全層)、sealedエラー+switch網羅(Task 2)、全パッケージ+プラグインのObserver(Task 5/9/12/13/14-17)— 全項目にタスクあり。
- **ライフサイクル(spec反映で更新):** native BLE owner は**プロセスグローバル singleton**で接続・操作キューを保持し、
  epochの唯一の採番元になる。engine attachではcandidate sinkを登録するだけで、`BleCallbacksApi.setUp` →
  `notifyDartReady` → state resync → `ackStateResync` 後にactive化し、旧headless engineを破棄する。
  `AlreadyInitialized` は同一engine/isolate内の二重生成のみ。
- **スキャンAPI(レビューで確定):** フィルタは `DeepskyScanFilter`(エントリ単位OR、Androidは全カテゴリネイティブ・iOS/macOSはserviceUuid以外ソフトウェアフィルタ)、設定は `DeepskyScanOptions`(android/darwin)、UUIDは `DeepskyUuid`(util、fromString/fromByteArray)。`BleScanResult.raw` はAndroidのみ(`ScanRecord.getBytes()`)でiOS/macOSはnull(CoreBluetoothが生バイト列を非公開のため)。`DeepskyAndroidScanType`(active/passive)はhidden APIのため対象外。
- **Isolate/エンジン方針(spec反映で更新):** AndroidはCDSイベント/FGS稼働中のengine消失時に専用entrypointを
  `executeDartCallback` で実行する。UI attachだけではheadlessを破棄せず、resync ack後に破棄する。
  engine detachはsink解除のみで、GATT/FGSは明示的`dispose()`まで維持する。
- **active GATT寿命:** handleはepochスコープ。epoch退役時に旧`BleCharacteristic.values`をcloseし、
  `device.services`をnullへ戻す。再接続後は再探索・notify再設定・再購読を要求する。
  重複UUIDがあるため自動付け替えは行わない。README/exampleに再購読パターンを載せる。
- **util分離(ユーザー要望):** sealedエラー型・`BleErrorCode` 定数・`BleUuid` ユーティリティは純Dartの `deepsky_bluetooth_util`(Task 1-2)に置き、interfaceはそれを再exportするのみ。pluginsはutil/interfaceに依存せず(Pigeon生成物のみ)、エラーコード文字列はネイティブ定数(Kotlin/Swiftの `BleErrorCode`)とutilの `BleErrorCode` を一致させる規約で結合する。
- **既知のトレードオフ(実装時に注意):**
  - Task 13(macOS)はiOSファイルのコピー+完全列挙差分方式。差分適用漏れに注意。
  - Task 15/16のbridgeは「Task 14と同一+列挙差分」方式。実装時はTask 14のコードを正として書き写す。
  - epoch/queue/handle/handoverがネイティブへ集中するため、framework非依存部品のKotlin unit test /
    Swift XCTestをマージ条件にする。SwiftはWindowsで実行できずmacOSチェックポイントが必須。
  - Pigeon生成APIの細部(`setUp` シグネチャ、Kotlinの `Long`、Swiftの `PigeonError` 名)はpigeonバージョンにより微差があり得る。生成物を見て合わせる。
  - steadyの `Ok`/`Err` パターンマッチのフィールド名(`data`/`error`)はパッケージ実物(`%PUB_CACHE%/hosted/pub.dev/steady-1.2.0/lib/src/result.dart`)で確認済み。
- **型整合:** util/interface定義(Task 2-5)とbridge/本体の参照名を相互確認済み(`BleCharacteristicTarget`、`setNotify(enabled:)`、`requestMtu`、`restoredConnections` 等)。
- **[spec反映 2026-06-15]** specを唯一の規範API契約とする。本planのコード片は非規範スケッチで、
  specとの差異を「読み替え」で放置せず、実装変更時に同時更新する。CI/レビューでは旧シグネチャ、
  `userInitiated`、reason無しdisconnected、UUID属性座標を機械検索する。
