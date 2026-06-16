# 接続・GATT 公開API 再設計(BluetoothDevice + 構造化GATT・自動再接続)

対象: `deepsky_bluetooth` 実装計画
([2026-06-12-deepsky-bluetooth.md](../plans/2026-06-12-deepsky-bluetooth.md))の
公開API(接続・GATT操作)を、デバイス指向(オブジェクト指向)へ再設計する。

## 背景

既存計画の公開API `DeepskyBluetooth`(plan L5693-5850)は、全操作がフラットなメソッドで、
毎回 `deviceId` や `Target` を渡す手続き的設計だった。レビューの結果、以下を改善する。

1. 接続タイムアウト指定手段がない(`ConnectTimeout` 型はあるのに発火手段なし)
2. 既接続デバイスへの再 `connect` の挙動が未定義
3. 現在の接続状態スナップショット取得APIがない
4. 公開ストリームが broadcast か未記載
5. `dispose` 後の再利用可否が未記載
6. バックグラウンド自動再接続の設計がない
7. device id / UUID が生 `String`(`DeepskyUuid` 値型があるのに不統一)
8. 操作対象指定が `Target` ベースで手組みが必要、API が手続き的

## 確定した設計判断

| # | 項目 | 決定 |
|---|---|---|
| 1 | API スタイル | `BluetoothDevice` ハンドル + 構造化GATTオブジェクト(active objects) |
| 2 | 接続タイムアウト | `connect` に `Duration? timeout`。body層で実施 |
| 3 | 既接続への再connect | 暗黙的に成功(`Ok`)を返す |
| 4 | 現在接続状態 | `device.connectionState`(同期)/ `device.connectionStates`(`BleConnectionEvent` のper-device stream)。`disconnected` は必ず `reason` を持つ |
| 5 | ストリーム | per-device / per-characteristic。全て broadcast と明記 |
| 6 | dispose後再利用 | 再利用不可と明記 |
| 7 | 自動再接続 | 1つのbody状態マシン + 3駆動源(Dart固定間隔ループ / iOS保留接続 / CDM presence)。詳細は「自動再接続」 |
| 8 | device id 型 | `DeepskyDeviceId`(util に定義)を公開API全体で使用 |
| 9 | UUID 型 | `DeepskyUuid`(util)を公開API全体で使用 |
| 10 | read 戻り値 | **`Result<Uint8List, …>` を返す**(`read()` が値を返す)。`values` ストリームは notify/indicate 専用 |
| 11 | setNotify | `BleNotifyType { disable, notify, indicate }` を渡す |
| 12 | CCCD | setNotify が書く。`writeDescriptor` で直接上書きしたらそちら優先(同期ずれ注意をコメント) |
| 13 | write分割 | MTU超過分割はアプリケーションの責務 |
| 14 | バッファ溢れ | `writeWithoutResponse` の溢れを検出し `CharacteristicWriteBufferFull` を返す |
| 15 | GATT直列化 | デバイス単位の操作キュー + `(epoch, opSeq)` 相関で同時1操作を保証。**操作タイムアウトは接続を破棄して再生成**(遅延応答は旧 epoch で破棄)。詳細は「GATT操作の直列化」 |
| 16 | BG復活(Android) | `main()` 再実行をやめ、専用 `@pragma('vm:entry-point')` バックグラウンドエントリポイントをヘッドレス実行。詳細は「バックグラウンド復活」 |
| 17 | CompanionDevice API | **31–32 / 33–35 / 36+ の3分岐**を plugin 内 `CompanionDeviceController` に統合。詳細は「CompanionDevice API のバージョン統合」 |
| 18 | 接続世代(epoch) | デバイス単位の単調増加 `connectionEpoch`。native ownerが接続実体の生成・再生成ごとに +1。platform 操作と全ネイティブイベントに通し、**現行 epoch 以外は破棄**。詳細は「接続世代と属性ハンドル」 |
| 19 | 属性ハンドル(handle) | 探索時に各 service/characteristic/descriptor へ epoch スコープの整数 `handle` を採番。操作・通知・フィルタは **UUID ではなく handle** で相関(重複 UUID 対応)。epoch 退役時に active GATT オブジェクトと `values` は失効・終了する。詳細は「接続世代と属性ハンドル」 |
| 20 | iOS read/notify | Android はネイティブで完全分離。**iOS/macOS は区別不能を契約化**(read 値返却+`values` にも流す+`strictRead` で `CharacteristicReadAmbiguousWhileNotifying`)。詳細は「GATT操作の直列化」 |
| 21 | connect() 完了条件 | `autoReconnect:false`=接続確立 or timeout/エラーで完了。`autoReconnect:true`=**維持要求の受理で即 `Ok`**(timeout 無視)。詳細は「接続まわり詳細」 |
| 22 | エンジン所有 | native owner は**プロセスグローバル singleton**。各エンジンは `attach → Dart ready → resync → ack` のハンドシェイクで sink を切り替える。`AlreadyInitialized` は同一エンジン二重生成のみ。詳細は「バックグラウンド復活」 |
| 23 | epoch 所有権 | `connectionEpoch` の**唯一の採番元は native owner**。Dart body は払い出された epoch を保持・照合するが採番しない。`connect` は `ConnectionAttempt{epoch}` を返す。 |
| 24 | 再接続失敗の通知 | 初回一時失敗/リンク消失と終端失敗は `connectionStates` の `disconnected(reason: ...)` で観測可能。`bluetoothOff` は維持要求を残して電源復帰待ち、非搭載は `bluetoothUnavailable` で終端。`reconnecting` 中の反復一時失敗は common/native observer だけへ記録する |
| 25 | services キャッシュ | epoch退役時に `device.services` を即座に `null` へ戻す。旧handleを含むキャッシュを次epochへ持ち越さない |
| 26 | handoverバッファ | 最大256イベントまたは30秒。超過時は古いnotify/presenceから破棄し、状態snapshotを正として common/native observer へ警告 |
| 27 | パッケージ分割の段階方針 | body を transport/lifecycle の2モジュールへ内部分割し、内部DIポート `BleTransport` で結合。安定後に `deepsky_bluetooth_core`(生成可能な公開facade)/ `deepsky_bluetooth`(managed lifecycle)へ抽出する。ネイティブは単一 owner 維持で分割しない。詳細は「段階的パッケージ分割方針」 |

---

## レイヤリング(重要)

GATTオブジェクトを「生きたハンドル」にするため、**探索結果データ**と**操作可能ハンドル**を
層で分離する。

- **interface / platform 層(内部)** … 純粋データ。`deviceId` + `connectionEpoch` + 属性 `handle`
   座標を保持する DTO とイベントキャリア(座標は UUID ではなく **handle** を正とする。「接続世代と属性ハンドル」参照)。
  - 探索DTO: `BleServiceInfo{handle,uuid,…}` / `BleCharacteristicInfo{handle,serviceHandle,uuid,properties,…}` /
    `BleDescriptorInfo{handle,uuid}`(handle・uuid・`BleCharacteristicProperties`・入れ子)。
  - **read の値は戻り値で返す**(`readCharacteristic`/`readDescriptor` は `Result<Uint8List, …>`)。
  - 通知イベントキャリア(内部・notify/indicate 専用): `(deviceId, connectionEpoch, characteristicHandle, value)`。
    read 応答はここに流さない(下記「GATT操作の直列化」で read 応答とキューを相関させる)。
  - 接続イベントキャリア(内部): `BlePlatformConnectionEvent(deviceId, connectionEpoch?, state, reason?)`。
    epoch採番前の接続失敗だけnull、`disconnected`だけreason必須。**epoch でハンドオーバ/再試行を識別**する。
  - `DeepskyBluetoothPlatform` のストリーム(scan/connection/**通知値(notify/indicate)**/
    companion/restored)はこの層の生イベント。接続・通知・復元snapshotは `connectionEpoch` を保持する。
  - Dart 層インターフェースの型は `DeepskyDeviceId`/`DeepskyUuid`。Pigeon 境界は `String` で、
    各 bridge が相互変換する(`DeepskyUuid` 既存方針と同じ)。
- **body(`deepsky_bluetooth` 本体・公開API)** … `DeepskyBluetooth` / `BluetoothDevice` と
  active な `BleService` / `BleCharacteristic` / `BleDescriptor`。platform DTO を
  ハンドルへラップし、per-device/per-characteristic にフィルタした view と操作を提供する。
  接続状態マシン・再接続ループ・タイムアウト・状態スナップショットは **body が公開状態の唯一の真実**。
  ただし接続実体の世代番号 `connectionEpoch` は native owner が払い出し、body はその値を受領して照合する。

公開 active クラスは body が構築する(コンストラクタは内部用)。ユーザーは `new` しない。

---

## 段階的パッケージ分割方針(transport / lifecycle)

バックグラウンド自動再接続まわりで公開API層(body)の責務が肥大化している。上記レイヤリングが示す
「単発のGATT/接続プリミティブ(transport)」と「ライフサイクル統御(lifecycle)」を**まず root
パッケージ内のモジュール境界として顕在化**させ、API が安定したら別パッケージへ抽出する。
いきなり別パッケージにはしない(統合は後から困難だが、分割は seam を引いておけば後で機械的に行えるため)。

### 2モジュール構成(root `deepsky_bluetooth` 内)

```
lib/deepsky_bluetooth.dart            # export(lifecycle の公開API)
lib/src/transport/                    # 将来 deepsky_bluetooth_core へ抽出
  ble_transport.dart                  # lifecycle が依存する内部抽象ポート
  transport_impl.dart                 # DeepskyBluetoothPlatform を選択・ラップする実装
  platform_resolver.dart              # Platform 判定で bridge を選択
  transport_factory.dart              # 初期化済み BleTransport session を生成
lib/src/lifecycle/                    # 将来 deepsky_bluetooth(managed)に残る
  deepsky_bluetooth.dart  bluetooth_device.dart  gatt_objects.dart
  connection_state_machine.dart  reconnect_strategy.dart
test/architecture/
  module_dependency_test.dart         # lifecycle → transport実装/platform型の逆流を禁止
```

- **transport**: scan系 / `connect(deviceId) → ConnectionAttempt{epoch}` / `disconnect(epoch)` /
  `discover(epoch)` / `read*`・`write*`・`setNotify`・`requestMtu`・`readRssi`(epoch, handle) /
  生の接続イベント stream(`BlePlatformConnectionEvent`: epoch?+reason)/ notify stream(epoch+handle)/
  `BleAdapterState` stream / state-resync 受領。**状態マシン・autoReconnect は含めない。**
- **lifecycle**: `DeepskyBluetooth` / `BluetoothDevice` / active GATT クラス / 接続状態マシン(epoch ガード)/
  3駆動源 A·B·C(`ReconnectStrategy`)/ `ReconnectPolicy` / autoReconnect / timeout / services キャッシュ失効 /
  per-characteristic view 寿命 / `onBackgroundRelaunch` 登録 / sink resync 再構築。

### `BleTransport` 契約

`createTransport(config, observers)` はplatform解決と `initialize(config)` までを行い、
まだcallbackをactive化していない初期化済みsessionを返す。lifecycleは全streamを購読してから
`activateCallbacks()`を呼ぶ。`BleTransport` は次の単発操作と生イベントだけを持つ。

```dart
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

`TransportImpl` はこの契約を `DeepskyBluetoothPlatform` へ1対1で委譲するadapterであり、
状態遷移、再試行、タイマー、servicesキャッシュ、公開Observerイベントを追加しない。
observer は共通 Dart contract 用と platform native 用を分離する。lifecycle は
`DeepskyBluetoothCommonObserver` の型付き `onXxxStart` / `onXxxEnd` / callback hook を呼び、
bridge/platform は `DeepskyBluetoothAndroidObserver` / `DeepskyBluetoothIosObserver` /
`DeepskyBluetoothMacosObserver` の native 診断 hook を呼ぶ。どちらも複数登録でき、登録順に
呼び出す。observer 例外は BLE 操作本体と後続 observer を止めない。

### seam 規律(将来抽出を機械的にする)

- **`BleTransport`(抽象)が lifecycle から見た transport の唯一の面**。これはDI・テスト用の内部ポートであり、
  将来のcore利用者向け公開APIそのものにはしない。lifecycle は `transport/ble_transport.dart`
  だけを import し、`deepsky_bluetooth_interface` の platform 型(`DeepskyBluetoothPlatform` 等)へ
  直接触れない。
- util / interface の**モデル・値型・エラー型**(`DeepskyDeviceId`/`DeepskyUuid`/`Ble*Info`/
  `BleConnectionEvent`/`BleDisconnectReason` 等)は両モジュール共有のまま(既に別パッケージ)。
- reason マッピング表(native→reason)は bridge=transport 側、**終端/一時の分類と再試行判断は
  lifecycle 側**。
- テスト境界もこの seam に一致させる:transport は fake platform 直結で単発操作/生イベントを、
  lifecycle は fake `BleTransport` 注入で状態マシン/再接続を検証する。
- 同一パッケージ内ではDartコンパイラがモジュール依存方向を強制しないため、
  `test/architecture/module_dependency_test.dart` で `src/lifecycle/**` から
  `transport_impl.dart` / `platform_resolver.dart` / bridgeパッケージ /
  `DeepskyBluetoothPlatform` への依存を禁止し、`src/transport/**` から `src/lifecycle/**` への
  依存も禁止する。このテストをCIの `flutter test` に含める。
- 将来抽出時:`lib/src/transport/` を `packages/deepsky_bluetooth_core/lib/src/` へ移し、
  利用者向けには生成可能な **`DeepskyBluetoothCore` facade** を公開する。`BleTransport` はcore内部の
  DIポートとして非公開のままにし、managed側はcoreが提供する内部adapterを介して依存する。
  `DeepskyBluetoothCore` は `foreground()` / `background()` factoryと、scan・単発connect/disconnect・
  GATT操作・生イベント・`dispose()`を公開する。抽象型だけをexportして生成手段のないAPIにはしない。

### transport session の所有権

- 現段階では `DeepskyBluetooth.foreground()` / `background()` が
  `createTransport(config, observers)` で初期化済みの `BleTransport` を1つ生成し、
  そのmanagedインスタンスが**排他的に所有**する。利用者によるtransport注入はテスト時だけ許可する。
- lifecycleの `dispose()` は再接続戦略とstream購読を先に停止してから、所有するtransportの
  `dispose()`を1回だけ呼ぶ。transportを複数managedインスタンスで共有しない。
- 将来coreを公開した後も、managedは既存coreとの共有を初期リリースでは許可せず、内部で専用coreを生成する。
  core共有や外部注入は、owner・dispose・sink handoverの多重化を解決する別設計まで非目標とする。

### 守るべき制約 — ネイティブは分割しない

決定#22「プロセスグローバル単一 owner」を保つため、**ネイティブを機能で分割しない**。
FGS/CompanionDeviceService/headless launcher/sink handover/epoch採番は Core 側プラグイン
(現 `plugins/*` + `*_bridge`)に一本化し、lifecycle は Dart のオーケストレーション層として上に載せる。
バックグラウンド復活のネイティブも transport(将来 core)側が持つ。プラグイン/ブリッジのトポロジは
この方針変更では一切変えない。

---

## エントリポイント `DeepskyBluetooth`

デバイス非依存の機能のみを持つ。

```dart
class DeepskyBluetooth {
  static Future<Result<DeepskyBluetooth, InitializeError>> foreground({
    DeepskyBluetoothObservers observers = const DeepskyBluetoothObservers(),
    /*…*/
  });
  static Future<Result<DeepskyBluetooth, InitializeError>> background({
    IosBackgroundConfig? ios,
    AndroidBackgroundConfig? android,
    DeepskyBluetoothObservers observers = const DeepskyBluetoothObservers(),
    /*…*/
  });

  Future<Result<void, ScanError>> startScan({DeepskyScanFilter? filter, DeepskyScanOptions options = const DeepskyScanOptions()});
  Future<Result<void, ScanError>> stopScan();

  /// ブロードキャストストリーム(複数購読可)。
  Stream<BleScanResult> get scanResults;
  Stream<ScanError> get scanErrors;

  /// Android CompanionDevice のみ。関連付け済みデバイスのハンドルを返す。
  Future<Result<BluetoothDevice, AssociateError>> associate({DeepskyScanFilter? filter});

  /// iOS State Restoration で復元された接続済み/接続保留中デバイス。broadcast。
  Stream<List<BluetoothDevice>> get restoredConnections;

  /// 既知の id からハンドルを取得(scan結果・復元・associate 以外の経路用)。
  BluetoothDevice device(DeepskyDeviceId id);

  /// dispose 後このインスタンスは再利用不可。再利用時は foreground()/background() で再生成。
  /// 全デバイスの再接続ループ・タイマー・StreamController を破棄する。
  Future<Result<void, DisposeError>> dispose();
}
```

備考:
- `BleScanResult.deviceId` は `DeepskyDeviceId`。接続は `ble.device(result.deviceId).connect()`。
- `DeepskyBluetoothObservers` は `common` / `android` / `ios` / `macos` の各 list を持つ。
  root package 利用時も native 側の低レベルログを見られるよう、platform native observer も
  root の `foreground()` / `background()` に渡せる。実行中 platform 以外の native observer は無視する。
- 旧 `connectionEvents` グローバルストリーム、旧 `connectionStates` グローバルマップ、
  旧 `characteristicValues` グローバルストリームは**廃止**(per-device/per-characteristic へ移行)。
- 旧deviceId付き公開 `BleConnectionEvent` は廃止。新しい公開 `BleConnectionEvent` は
  per-device stream用の `state + reason`、platform内部搬送は `BlePlatformConnectionEvent` とする。

---

## `BluetoothDevice`(接続・デバイス単位の操作)

薄いハンドル。状態は持たず `id` と owner(body)参照のみ。`==` は `id` 等価。同一 id の
複数ハンドルは矛盾しない。
名称はFlutter/Android利用者に馴染みのある「接続対象デバイス」を表す公開入口として
`BluetoothDevice` を維持する。`BleService`/`BleCharacteristic`/`BleDescriptor` は
Bluetooth全般のデバイス型と区別してGATT/BLE属性であることを示すため `Ble*` とする。

```dart
class BluetoothDevice {
  DeepskyDeviceId get id;

  /// 現在の接続状態スナップショット(購読前でも取得可)。未接続は disconnected。
  BleConnectionState get connectionState;
  /// per-device の接続状態イベント。broadcast。
  /// disconnected イベントは必ず reason を持つ。
  Stream<BleConnectionEvent> get connectionStates;

  /// 既に connected/connecting/reconnecting の場合は暗黙的に成功(Ok)を返す。
  /// 最初の connect の autoReconnect/reconnectPolicy が優先され、後続呼び出しでは変更されない。
  /// 変更するには disconnect() 後に connect() し直す。
  /// 完了条件:
  ///   - autoReconnect:false → 接続確立 or [timeout] 超過(ConnectTimeout)/エラーで完了。
  ///   - autoReconnect:true  → **維持要求の受理で即 Ok**([timeout] 無視)。実接続は connectionStates で観測。
  /// [autoReconnect] true で、一時的な想定外切断・タイムアウト時に再接続を継続
  /// (disconnect/dispose または終端切断理由で解除)。
  /// false の場合、想定外切断後は disconnected で停止し再試行しない。
  /// [reconnectPolicy] は autoReconnect が true かつ駆動源 A(Dart固定間隔ループ)のときのみ有効。
  Future<Result<void, ConnectError>> connect({
    Duration? timeout,
    bool autoReconnect = false,
    ReconnectPolicy reconnectPolicy = const ReconnectPolicy(),
  });

  /// 自動再接続を解除し、ユーザー起因切断として扱う(以降の再接続を行わない)。
  Future<Result<void, DisconnectError>> disconnect();

  /// 毎回新しいハンドル木を返す(後述「ハンドルの寿命」)。
  Future<Result<List<BleService>, DiscoverServicesError>> discoverServices();
  /// 直近の discoverServices() 成功結果のキャッシュ。初回探索前は null。
  List<BleService>? get services;

  /// iOS は要求値を無視し現在 MTU を返す。
  Future<Result<int, MtuError>> requestMtu(int mtu);
  Future<Result<int, RssiError>> readRssi();

  /// Android CompanionDevice の presence 監視 ON/OFF。
  Future<Result<void, PresenceError>> setDevicePresenceObservation({required bool enabled});
  /// presence イベント(true=appeared / false=disappeared)。broadcast。
  Stream<bool> get presenceEvents;
}
```

公開イベントと切断理由:
```dart
class BleConnectionEvent {
  const BleConnectionEvent({required this.state, this.reason})
      : assert(state == BleConnectionState.disconnected
            ? reason != null
            : reason == null);
  final BleConnectionState state;
  final BleDisconnectReason? reason;
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
```

`reason` は `state == disconnected` のときだけ非nullかつ必須。同期getter `connectionState` は
従来どおりenumのみを返し、理由を必要とする利用者は `connectionStates` を購読する。
`permissionDenied` / `bluetoothUnavailable` / `deviceNotFound` / `notAssociated` は
**現在の維持要求に対する終端理由**であり、bodyは自動再接続を解除する。
`presenceObservationDisabled` は後述の「Cが必須なのにpresence監視を利用できない」場合だけ終端理由とする。
`bluetoothOff` は一時理由であり、維持要求を残してadapterの電源復帰を待つ。
権限付与・Bluetooth対応端末への変更・正しいdevice idの取得・関連付け・presence有効化後に、アプリが再度
`connect()` する。
その他は一時理由で、`autoReconnect:true` の場合は
`disconnected(reason)` → `reconnecting` の順に通知して再試行する。

### native失敗から切断理由へのマッピング

この表を全platform bridge/native ownerの規範とする。圏外、無応答、接続確立タイムアウトを
`deviceNotFound` にしてはならない。

| native事象 | Android | iOS/macOS | `BleDisconnectReason` | 分類 |
|---|---|---|---|---|
| 権限拒否/unauthorized | `BLUETOOTH_CONNECT` 不許可 | `CBManagerState.unauthorized` | `permissionDenied` | 終端 |
| Bluetooth電源OFF/一時利用不能 | adapterは存在するがdisabled/`STATE_OFF` | `poweredOff`/`resetting` | `bluetoothOff` | 一時 |
| Bluetooth非搭載/OS非対応 | adapter null、Bluetooth LE非対応 | `unsupported` | `bluetoothUnavailable` | 終端 |
| device idを解釈・解決できない | 不正Bluetooth address、`getRemoteDevice` がidentityを構築不能 | 不正UUID、保存IDをidentityとして復元不能と明示判定 | `deviceNotFound` | 終端 |
| 対象が圏外、広告停止、無応答 | `connectGatt` 後の接続失敗/タイムアウト、GATT status 133等 | `didFailToConnect`、OS接続待ち | `connectFailed` | 一時 |
| 確立済み接続のリンク消失 | 接続後の予期しない `STATE_DISCONNECTED` | 予期しない `didDisconnectPeripheral` | `connectionLost` | 一時 |
| GATT操作タイムアウト | ownerの操作watchdog満了 | ownerの操作watchdog満了 | `operationTimeout` | 一時 |
| CDM未関連付け | `DeviceNotAssociatedException` | 該当なし | `notAssociated` | 終端 |
| C必須だがpresence監視不能 | 監視無効/登録消失をheadless復活時に検出 | 該当なし | `presenceObservationDisabled` | 終端 |
| 分類不能な接続失敗 | その他 | その他 | `unknown` | 一時 |

`deviceNotFound` は「スキャン結果に現在存在しない」「接続タイムアウトした」という意味ではない。
Androidの有効なBluetooth addressやDarwinの有効なperipheral UUIDからidentityを構築できた後の失敗は、
デバイスが現在見えなくても `connectFailed` とする。`ConnectTimeout` もreason変換時は
`connectFailed` とし、駆動源Aの固定間隔再試行を継続する。

> presence は `setDevicePresenceObservation` がデバイス単位のため
> `device.presenceEvents` に集約し、旧グローバル `companionEvents` / `BleCompanionEvent` は
> 廃止した。

---

## 接続まわり詳細

### タイムアウトと connect() の完了条件
body が platform の connect Future をタイマーと競合させる。期限超過で保留接続をキャンセルし
`ConnectTimeout` を返す。iOS(CoreBluetooth)はネイティブタイムアウトを持たないため、この方式で
全プラットフォーム統一。

**`connect()` Future の完了条件(明文化):**
- `autoReconnect: false` … **接続確立 or `timeout`/エラー**で完了。`timeout` を指定しなければ確立まで待つ。
- `autoReconnect: true` … **「維持要求を受理した時点で即 `Ok`」**(`timeout` は無視)。受理と同時に状態は
  `connecting`(初回)/`reconnecting` へ遷移し、実接続は `connectionStates` で観測する。
  - 根拠: 無期限・無限リトライ前提で「初回接続まで待つ」と圏外時に `connect()` が永久ハングする。
    iOS 保留接続・Android Dart ループ・CDM presence いずれの駆動源でも *armed=受理* で統一する。
  - したがって `autoReconnect: true` では `timeout` は無視(iOS の保留接続だけでなく全駆動源で)。
  - 受理後の接続試行が終端理由で失敗した場合もFutureを後から失敗へ変更しない。
    `connectionStates` に `disconnected(reason)` を発行して維持要求を解除する。

### 接続状態マシン
```dart
enum BleConnectionState { connecting, connected, disconnecting, disconnected, reconnecting }
```
- `connecting`: ユーザーが `connect()` した **初回接続試行時のみ**。
- `reconnecting`: ライブラリ起因の **全再接続試行**(想定外切断・タイムアウトいずれの契機でも)。

自動再接続デバイスのライフサイクル:
```
connecting → connected → disconnected → reconnecting ──(公開イベントなしの再試行)──→ connected
```
初回成功後 `connecting` は二度と出ない。ユーザー起因の `connect()` は `connecting → connected`
のみ。

### 自動再接続 — 1つの状態マシン + 3つの駆動源

再接続の**状態マシンは body が唯一所有**する(`connecting`/`connected`/`disconnecting`/
`disconnected`/`reconnecting` の遷移と `connectionStates` への発行)。一方で「次の再接続試行を
いつ起こすか」を決める**駆動源(trigger)はプラットフォームで 3 種**ある。状態マシンは駆動源を
抽象化した内部イベントだけを消費し、どの駆動源でも同一に振る舞う。

内部イベント(状態マシンの入力)。platform 由来イベントは **`connectionEpoch` を保持**し、
状態マシンは入口で `epoch != device.currentEpoch` のイベントを**破棄**する(再試行・disconnect・
タイムアウト後に届く旧世代の connected/disconnected を確実に無視。「接続世代と属性ハンドル」参照):
```dart
sealed class _ReconnectTrigger {}
class _NativeConnected     extends _ReconnectTrigger { int epoch; } // platform: 接続確立
class _NativeDisconnected  extends _ReconnectTrigger {
  int? epoch;
  BleDisconnectReason reason;
} // platform: 切断/接続試行失敗。epoch採番前の失敗はnull
class _OpTimeout           extends _ReconnectTrigger { int epoch; } // GATT操作タイムアウト→接続再生成
class _RetryTick           extends _ReconnectTrigger {} // 駆動源A: Dartタイマー満了
class _PresenceAppeared    extends _ReconnectTrigger {} // 駆動源C: CDM 出現
class _PresenceDisappeared extends _ReconnectTrigger {} // 駆動源C: CDM 消失
class _AdapterPoweredOff   extends _ReconnectTrigger {} // 全駆動源: 一時停止
class _AdapterPoweredOn    extends _ReconnectTrigger {} // A/C: 即時再試行、B: OS保留接続を継続
class _AdapterUnavailable  extends _ReconnectTrigger {} // 全駆動源: 終端
```

3 つの駆動源(`ReconnectStrategy` として body 内で選択):

| 駆動源 | 対象 | 再接続試行のトリガ | `reconnecting` 発行契機 | `timeout` |
|---|---|---|---|---|
| A. Dart固定間隔ループ | Android foreground / Android FGS / macOS | body の `Timer(delay)` 満了で platform connect 再発行。電源OFF中はtimer停止、`poweredOn`で即時再試行 | 想定外切断/電源OFF → `reconnecting` → 再connect | 各試行に適用 |
| B. iOS 保留接続(OS再接続) | iOS | OS が無期限の保留接続で自動再試行(body はタイマーを回さない)。`poweredOff`でもcancelせず`poweredOn`復帰を待つ | `didDisconnect`/`poweredOff`で `reconnecting`、`didConnect` で `connected` | **無視**(保留接続のため) |
| C. CDM presence | Android CompanionDevice | `onDeviceAppeared` かつadapter ONで platform connect。電源OFF中はpresence状態を保持し、`STATE_ON`で即時再評価 | `onDeviceDisappeared`/電源OFFで `reconnecting`、条件成立後の接続成功で `connected` | 適用しない(presence/電源待ち) |

platformは内部 `BleAdapterState { poweredOn, poweredOff, unavailable }` streamを提供する。
Androidは `BluetoothAdapter.ACTION_STATE_CHANGED` の `STATE_ON`/`STATE_OFF`、Darwinは
`centralManagerDidUpdateState` の `poweredOn`/`poweredOff`/`resetting`/`unsupported` を変換する。
`unauthorized` はadapter状態ではなく既存の `permissionDenied` として扱う。
engine attach/handover時は、native ownerが現在のadapter状態をstate resyncより先にcandidate sinkへ
必ず1回再送する。adapter streamを購読した後にcallbacksをactivateする既存順序と組み合わせ、
電源OFF中のengine切替でも状態を取りこぼさない。

`poweredOff` 到着時、autoReconnect対象は一度だけ
`disconnected(reason: bluetoothOff)` → `reconnecting` へ遷移するが維持要求を解除しない。
Aはretry timerを停止し、Cはpresence監視を維持したままconnect発行だけを止める。Bは
`cancelPeripheralConnection` を呼ばず、CoreBluetoothの保留接続要求を維持する。
`poweredOn` 到着時、Aはdelayを待たず即時試行、Cはdevice appearedなら即時試行する。Bはnative ownerが
維持対象の`CBPeripheral.state`を確認し、`.connecting`なら既存requestを維持、`.disconnected`なら
同epochで1回だけ再armする。初回電源OFFなどでepoch未確定ならbodyが通常のplatform connectを1回発行する。
電源OFF/ONが複数回通知されても同一状態イベントやconnect requestを反復しない。

AndroidでのA/C選択:
- Android FGS/foreground設定は常にA。
- Android CompanionDevice設定では、対象デバイスが関連付け済みで
  `setDevicePresenceObservation(enabled: true)` が成功済みならC、それ以外はA。
- `connect(autoReconnect:true)` はpresence監視を暗黙に有効化しない。未関連付けデバイスへの有効化は
  `notAssociated`。Companion設定で監視を有効化すると次の再接続契機からCへ切り替える。
- Dart engineが生存している間にpresence監視を無効化した場合は、維持要求を解除せずAへ切り替える。
  この操作だけでは `presenceObservationDisabled` を発行しない。
- Android CompanionDeviceのheadless/プロセス復活時はCが必須である。その時点で関連付け済みの維持対象に
  presence監視が無効、またはOS側登録が失われている場合だけ
  `disconnected(reason: presenceObservationDisabled)` を発行して維持要求を解除する。
- Aへフォールバック中はDart engineが生存している間だけ固定間隔再試行できる。プロセス復活を必要とする
  常時接続では、アプリが先にassociateとpresence監視有効化を完了させる。

`ReconnectPolicy` は駆動源 A のみで使用する固定間隔(指数バックオフは非採用)。
```dart
class ReconnectPolicy {
  const ReconnectPolicy({this.delay = const Duration(seconds: 5)});
  final Duration delay; // 駆動源A の固定リトライ間隔。B/C では未使用
}
```

`_OpTimeout`(GATT 操作タイムアウト)到着時: native owner が当該接続を破棄し、bodyへ通知する
(「接続世代と属性ハンドル」「GATT操作の直列化」)。これは想定外切断と同じ経路に合流する。
`autoReconnect == true` ならbodyが次の `platform.connect(deviceId)` を発行して新epochを受領し、
`false` なら `disconnected` で停止する。

ネイティブ `disconnected`(`_NativeDisconnected`)到着時の状態マシン分岐(駆動源共通):
- `reason == userRequested`(直前がユーザー起因 `disconnect()`/`dispose()`)→ `disconnected(reason)` 発行・
  登録解除して終了。駆動源 A はタイマー停止、C は presence 監視停止。
- 終端理由 → `disconnected(reason)` 発行後、`autoReconnect` を解除して終了。
- `autoReconnect == false` の一時的な想定外切断 → `disconnected(reason)` 発行後に終了。再試行しない。
- `autoReconnect == true` の一時的な想定外切断 → `disconnected(reason)` 発行後 `reconnecting` へ。以降は選択中の駆動源が次の試行を起こす:
  - A: `delay` 待機 → platform connect → 一時失敗なら公開状態は `reconnecting` のまま維持し再度
    `delay`。各試行失敗は common/native observer へ記録するが、`disconnected`/`reconnecting` を反復発行しない。
  - B: 保留接続のまま `didConnect` を待つ(再発行不要)。
  - C: `onDeviceAppeared` を待ち、出現時の一時的な接続失敗でも公開状態は `reconnecting` を維持する。
  いずれも `disconnect`/`dispose` まで無限継続。

公開状態イベントは**状態遷移時だけ**発行する。初回接続試行が一時失敗した場合、または確立済み接続が
失われた場合に一度だけ `disconnected(reason)` → `reconnecting` を発行する。その後
`reconnecting` 中の一時失敗は common/native observer だけへ記録する。終端理由を受けた場合は現在状態にかかわらず
`disconnected(reason)` を発行して停止する。

> **「全プラットフォーム共通の Dart ループ」ではない。** Dart タイマーが試行を所有するのは A のみで、
> B/C は OS/CDM がスケジューリングする。状態マシンと `connectionStates` の発行だけが共通。
> ユニットテストは駆動源を差し替え可能にし、A は fake timer、B/C は内部イベント注入で検証する。

Android の native `autoConnect` は A/C いずれでも常に `false`(OS の自動再接続には依存しない)。
B(iOS)のみ OS の保留接続に依拠する。

### epoch未確定期間

`currentEpoch` の型は `int?`。維持要求をarmした直後、presence待ち、または
`platform.connect(deviceId)` が `ConnectionAttempt` を返す前は `null` とする。この期間はepoch付き
nativeイベントを採用せず、接続試行自体の失敗だけをepochなし
`_NativeDisconnected(reason: ...)` として処理する。`ConnectionAttempt{epoch}` 受領時に初めて
`currentEpoch` を設定し、以後は一致するepochのイベントだけを受理する。

| `currentEpoch` | event epoch | 判定 |
|---|---|---|
| `null` | `null` | 現在実行中のconnect試行から同期変換された失敗だけ受理 |
| `null` | `m` | 破棄。退役済み試行の遅延イベント |
| `n` | `null` | 破棄。epoch確定後の無相関イベント |
| `n` | `m` | `n == m` の場合だけ受理 |

`null × null` の相関にはbody内の単調増加 `connectAttemptToken` を使う。platform `connect` を呼ぶ直前に
tokenを更新し、Future完了時に現在tokenと一致する場合だけepochなし失敗へ変換する。disconnect、
strategy切替、終端停止、または新しい試行開始でtokenを失効させる。

`null × m` を正しく破棄できるよう、platform bridgeは `connect()` の
`ConnectionAttempt{epoch}` をbodyへ返す前に届いた同epochのstate callbackを短期保留し、Future完了後に
順序を保って解放する。native ownerもattemptをarmした時点で`ConnectionAttempt`を即完了し、接続確立まで
Futureを保留しない。この順序保証により、現在試行の`connected`が`currentEpoch == null`の窓へ落ちることを
防ぐ。

---

## 接続世代と属性ハンドル(identity / generation)

「どの接続試行か」「どの属性か」を一意に識別するため、2 つの ID をネイティブ〜body〜公開 API に通す。
これにより遅延コールバックの誤完了(#1)・重複 UUID 属性(#2)・旧世代イベントの混入(#3)を構造的に防ぐ。

### connectionEpoch(接続世代)
- **デバイス単位の単調増加カウンタ。唯一の採番元はプロセスグローバルな native owner。**
  body は採番せず、`platform.connect(deviceId)` が返す `ConnectionAttempt{epoch}` または状態リシンクで
  現行値を受領する。これにより headless/UI のどちらから接続を開始しても重複採番しない。
- native owner は新しい接続実体を生成・再生成する直前に epoch を +1 する(Android: `connectGatt` ごと、
  iOS/macOS: 新しい `connect` 要求を armed にするごと)。iOS の1つの保留接続要求は接続完了まで同じ
  epochを使い、切断後に保留接続を再armするときに次のepochを払い出す。
- platform の `connect` を除く全接続操作(`disconnect`/`discoverServices`/`read*`/`write*`/
  `requestMtu`/`readRssi`/`setNotify`)に **body が保持する現行 epoch を引数で渡す**。ネイティブは
  一致しない epoch の要求を `NotConnected` または `NotFound` で拒否する。
- ネイティブは当該接続の全 callback(接続状態・GATT 応答・notify)に epoch をタグ付けして返す。
- body は受信イベントの `epoch != currentEpoch` を**破棄**。`close()`/`disconnect()` で epoch を退役。
- 効果: タイムアウトで接続を破棄して epoch を上げた後に旧 `BluetoothGatt` の遅延 callback が来ても、
  旧 epoch のため落ちる(#1)。`disconnect()` 後の遅延 disconnected・再試行中の旧 connected も同様(#3)。

### attribute handle(属性ハンドル)
- **探索時に各 service/characteristic/descriptor へ採番する epoch スコープの整数 handle。**
  ネイティブが `discoverServices` で発見順に採番し、`handle → native オブジェクト` のマップを保持。
- 探索 DTO(`Ble*Info`)・アドレッシング `Target`・通知イベントは **uuid ではなく handle** を座標に使う。
  Pigeon 境界も handle(int)を運ぶ。
- 操作・通知・古いハンドルの相関はすべて `(deviceId, connectionEpoch, handle)` で行う。**同一 UUID の
  service/characteristic が複数あっても一意に識別**できる(#2)。公開ハンドル(`BleCharacteristic` 等)は
  引き続き `uuid` をユーザー向けに公開するが、内部操作は handle を使う。
- Android の `getInstanceId()` は service 跨ぎの一意保証が無く、iOS の CoreBluetooth オブジェクトには
  安定 ID が無いため、**ライブラリ採番 handle を正**とする(クロスプラットフォーム統一)。
- handle は epoch スコープ。再探索/再接続で無効化される(`discoverServices()` が毎回新しいハンドル木を
  返す既存方針と整合)。古い handle での操作は対象不在なら `NotFound` 系。

### Pigeon / platform 反映
- `connect(deviceId)` はnative採番済みの `ConnectionAttempt{epoch}` を返す。他の接続操作には
  `int epoch` を追加し、`Target` をhandleベースにする。イベントキャリアには
  `epoch`(+ notify は `characteristicHandle`)を追加する(Task 5/6 に反映)。

---

## 構造化GATTオブジェクト

`discoverServices()` が返すツリーを生きたハンドルにする。各オブジェクトは内部に owner(body)
参照と座標 `(deviceId, connectionEpoch, handle)` を保持する(「接続世代と属性ハンドル」参照。
`uuid` はユーザー向け公開のみで、操作の相関には handle を使う)。

```dart
class BleService {
  DeepskyUuid get uuid;
  List<BleCharacteristic> get characteristics;
}

class BleCharacteristic {
  DeepskyUuid get uuid;
  BleCharacteristicProperties get properties; // read/writeWithResponse/writeWithoutResponse/notify/indicate
  List<BleDescriptor> get descriptors;

  /// notify/indicate 通知**のみ**(この characteristic のみ)。broadcast。
  /// この接続epoch内だけ有効。epoch退役時にonDoneとなる。read 応答はここに流れない。
  Stream<Uint8List> get values;

  /// read 応答は**戻り値で返す**(values には流れない)。
  /// GATT 操作キューにより read 要求と応答が相関する(後述「GATT操作の直列化」)。
  /// [strictRead]: iOS/macOS で notify 有効中に read する場合の安全弁。
  ///   false(既定)= ベストエフォート(通知値を返しうる)。
  ///   true = notify 有効中は `CharacteristicReadAmbiguousWhileNotifying` を返す(Android では無視=常に厳密)。
  /// 操作タイムアウト時はGATT接続全体を破棄する。autoReconnect:falseでは
  /// disconnected(reason: operationTimeout)で停止し、アプリがconnectし直すまで回復しない。
  Future<Result<Uint8List, CharacteristicReadError>> read({bool strictRead = false});
  /// 操作タイムアウト時はreadと同様にGATT接続全体を破棄する。
  Future<Result<void, CharacteristicWriteError>> write(Uint8List value, {required bool withResponse});

  /// CCCD を書く。BleNotifyType.disable/notify/indicate。
  /// 注意: writeDescriptor で CCCD を直接上書きした場合はそちらが優先され、
  /// ライブラリが保持する notify 状態と実機状態が同期ずれを起こしうる。
  /// CCCD書込タイムアウト時はGATT接続全体を破棄する。
  Future<Result<void, NotifyError>> setNotify(BleNotifyType type);
}

class BleDescriptor {
  DeepskyUuid get uuid;
  /// read 応答を**戻り値で返す**。descriptor には notify が無いため values ストリームは持たない。
  /// 操作タイムアウト時はGATT接続全体を破棄する。
  Future<Result<Uint8List, DescriptorReadError>> read();
  /// 操作タイムアウト時はGATT接続全体を破棄する。
  Future<Result<void, DescriptorWriteError>> write(Uint8List value);
}

enum BleNotifyType { disable, notify, indicate }
```

使用例:
```dart
final services = (await device.discoverServices()).unwrap();
final char = services.firstWhere((s) => s.uuid == svc)
                     .characteristics.firstWhere((c) => c.uuid == chr);
final sub = char.values.listen(print);   // notify/indicate のみが届く
await char.setNotify(BleNotifyType.notify);
final value = (await char.read()).unwrap();   // read 応答は戻り値で受け取る
await char.write(payload, withResponse: true);
```

備考:
- **read 応答と notify を分離**: read は戻り値、`values` は notify/indicate 専用。同一 characteristic で
  read 中に通知が届いてもストリーム上で混ざらない(レース解消)。
- 旧 `BleCharacteristicValue` / `BleDescriptorValue`(座標付き値クラス)は**公開APIから廃止**。
  notify 値は `Stream<Uint8List>`、read 値は戻り値。座標はハンドルで自明。
  (内部の **notify 専用**イベントキャリアは interface 層に残す)
- `BleCharacteristic.values` は body の per-device 通知ブロードキャストを
  `(connectionEpoch, characteristicHandle)` でフィルタした view。
- 再接続・再探索で epoch/handle が変わるため、旧 `BleCharacteristic` の `values` は `onDone` となる。
  利用者は接続後に `discoverServices()` を再実行し、新しい active object で `setNotify` と購読をやり直す。
  重複UUIDを許すため、UUIDだけを使った暗黙のハンドル付け替えは行わない。
- **write 分割なし**: MTU 超過ペイロードの分割はアプリケーションの責務。`requestMtu` は提供する。
- **バッファ溢れ**: `write(withResponse: false)` 連投で溢れ(iOS `canSendWriteWithoutResponse`
  等)を検出した場合、`CharacteristicWriteBufferFull` を返す。Android API 33+ は
  `BluetoothGatt.writeCharacteristic(characteristic, value, WRITE_TYPE_NO_RESPONSE)` の戻り値
  `BluetoothStatusCodes.ERROR_GATT_WRITE_REQUEST_BUSY` をこのエラーへ対応させる。API 31–32 は
  deprecated boolean版の戻り値 `false` をbusy候補として同エラーへ対応させる。直列キューにより
  ライブラリ自身の並行発行はないため、falseは送信受付不可として扱う。

---

## GATT操作の直列化(重要)

BLE の GATT は **接続ごとに同時 1 操作**しか走らせられない。とくに Android `BluetoothGatt` は
2 つ目の操作を呼ぶと `false` を返して**静かに失敗**し、`onCharacteristicRead`/`onMtuChanged` 等の
コールバックは**どの要求への応答かを示さない**(グローバル通知)。並行 `read`/`write`/`requestMtu`/
`discoverServices`/`setNotify`(CCCD 書込)を安全に捌くため、**デバイス単位の直列キュー**を設ける。

設計(ネイティブ各 plugin が所有):
- デバイス(=1 接続=1 `connectionEpoch`)ごとに FIFO の `OperationQueue` を持つ。各操作は
  `(epoch, opSeq)`(opSeq=接続内連番)を持ち、`@async` の Pigeon コールバック(completer)を保持する。
- キューは**先頭 1 件のみ実行**。GATT コールバック到着時、**callback の epoch がキューの epoch と一致**し、
  かつ先頭操作と種別整合する場合のみ先頭の completer を完了させ次をディスパッチする
  (同時 1 操作なので FIFO で相関。epoch 不一致の遅延 callback は破棄)。
- **notify/indicate(`onCharacteristicChanged`)はキューに載せない**。非要求イベントとして
  通知ストリームへ直接ルーティングする(`characteristicHandle` 付き)。read 応答
  (`onCharacteristicRead`)はキュー先頭の read 操作の completer を完了(= read 値が戻り値で返る理由)。
- `setNotify` は CCCD 書込(descriptor write)としてキューを通す。

**操作タイムアウト = 接続再生成(#1 対策)。** 各操作にタイムアウト(既定 例: 10s)を付け、満了したら
**キューを進めて続行しない**。当該デバイスの `connectionEpoch` を無効化し、`BluetoothGatt.disconnect()`
+`close()`(iOS は `cancelPeripheralConnection`)で接続を破棄してから `_OpTimeout(epoch)`→
想定外切断として body の状態マシンへ通知する(再接続機構が引き継ぐ)。インフライト操作は `timeout` 系
エラーで完了。
- 根拠: タイムアウト時点で GATT スタックは不整合になりうるため、同一接続での続行は危険(遅延応答が
  次操作を誤完了する/スタックが詰まる)。**接続を捨てて epoch を上げる**ことで、遅れて届く旧接続の
  callback はすべて旧 epoch として破棄され、誤完了が原理的に起きない。「常時接続+自動再接続」前提と整合。
- 不採用: タイムアウト操作を tombstone 化し接続維持のまま遅延応答を 1 件消費する案。重複 UUID
  (handle 多重)下で消費先の一意性が崩れるため非推奨。
- この副作用はactive GATT APIの各 `read`/`write`/`setNotify` doc commentにも明記する。
  `autoReconnect:false` では自動回復せず、`disconnected(reason: operationTimeout)` で停止する。

**iOS/macOS の read/notify 分離(#4 対策)。** CoreBluetooth は `peripheral(_:didUpdateValueFor:)` を
read 応答と notify の**両方**で同一 delegate に流し、原因を区別できない。区別不能を**契約として認める**:
- per-characteristic に read を直列化し、read が outstanding な characteristic への最初の
  `didUpdateValueFor(handle)` を **read 応答として完了**しつつ、**同じ値を `values` stream にも流す**
  (通知購読側のデータ欠落を防止)。
- ドキュメントに *「iOS/macOS では通知有効中の `read()` は、直後に届いた通知値を返すことがある。
  通知主体の用途では `values` を真実とせよ」* と明記。
- 安全弁: `read(strictRead: true)` 時、当該 characteristic の notify が有効なら read を発行せず
  `CharacteristicReadAmbiguousWhileNotifying` を返す(Android は両 callback が別なので strictRead を無視し常に厳密)。
- 不採用: 通知の一時停止(in-flight 通知を確実に flush できずレース解消にならない)。

> platform 抽象のメソッドシグネチャ(`readCharacteristic → Result<Uint8List>` 等)は変えない
> (引数に `epoch`/handle を追加する以外)。直列化・タイムアウト・再生成は各 plugin のネイティブ実装内に
> 閉じる(body は `_OpTimeout`/接続イベントを epoch 付きで受けるのみ)。

---

## バックグラウンド復活(Android ヘッドレス)

**旧案の破綻要因**: `executeDartEntrypoint(createDefault())` でアプリの `main()`(=`runApp()`)を
View 無しで再実行する案は、(1) 多くのプラグインが Activity 前提で headless 実行時にクラッシュしうる、
(2) 不要な UI 初期化コスト、(3) UI エンジン復帰との二重 `runApp()` レース、を抱える。

**新方式(専用バックグラウンドエントリポイント)** — workmanager / flutter_background_service と同系:
- アプリは BLE 復活処理を行うトップレベル関数を 1 つ定義し `@pragma('vm:entry-point')` を付ける。
  **`runApp()` は呼ばない。**
- 登録: `DeepskyBluetooth.background(..., onBackgroundRelaunch: myBgEntry)` 生成時に
  `PluginUtilities.getCallbackHandle(myBgEntry)` で得たコールバックハンドル(int)を
  `DeepskyBluetoothConfig.backgroundCallbackHandle` に格納し、Pigeon `InitializeRequestMessage` の
  `backgroundCallbackHandle` としてネイティブへ渡し、
  `SharedPreferences` に永続化する(プロセス死を跨ぐため)。
- 復活: CDS イベント / FGS 稼働中のエンジン消失時、`HeadlessEngineLauncher` は保存済みハンドルから
  `FlutterCallbackInformation.lookupCallbackInformation(handle)` を引き、`DartCallback` で
  ヘッドレスエンジンを起動する。実行されるのは `main()` ではなく**この専用エントリポイントのみ**。
- 専用エントリポイント内で `WidgetsFlutterBinding.ensureInitialized()` → `DeepskyBluetooth.background()`
  を(ヘッドレス用フラグ付きで)再生成し、関連付け済み/既知デバイスへ再接続する。`runApp()` は呼ばない。
- iOS との対応関係: iOS State Restoration はOSがアプリをバックグラウンド再起動し、
  同じrestore identifierで `CBCentralManager` を再生成して状態を受け取る。Androidの専用
  エントリポイントもUI初期化を避ける点だけを揃え、iOSを「復元ハンドラだけが走る」仕組みとは扱わない。
- 後方互換: `onBackgroundRelaunch` 未登録時はヘッドレス復活を行わず(FGS は接続喪失のまま、UI 復帰で
  再接続)、`backgroundConfigMissing` 相当のドキュメント警告を出す。

### エンジン所有契約 — プロセスグローバル owner + sink ハンドオーバ(#7 対策)

別 `FlutterEngine` は別 BinaryMessenger・別 Dart isolate を持つため、「既存インスタンスを別エンジンへ委譲」は
できない(Pigeon messenger を跨げない)。所有モデルを次のように定義する:

- **native BLE owner をプロセスグローバル singleton** にする(`BluetoothGatt` 接続・操作キュー・
  `connectionEpoch`・`CompanionDeviceController` を保持)。**エンジンには紐付けない。**
- 各 `FlutterEngine` の plugin インスタンスは薄い。`onAttachedToEngine` では messenger と
  `engineToken` を**候補sink**として登録するだけで、まだアクティブにしない。Dart側が
  `BleCallbacksApi.setUp` を完了して `notifyDartReady(engineToken)` を呼んだ時点で初めてpush可能になる。
  **アクティブ sink は常に 1 つ**で、候補sinkへのイベントpushは禁止する。
- Dart の `foreground()/background()` 初期化:
  - owner 未初期化 → 通常どおり設定し `initialized = true`。
  - owner 既初期化(= 別エンジンで稼働中。headless→UI のハンドオーバ等)→ **当該エンジンへ sink を
    rebind し、現在状態を返す(拒否しない)**。`AlreadyInitialized` は **同一エンジン/isolate 内の
    二重生成のみ**に限定する。
- **状態リシンク(必須):** Dart ready 後、owner は新 sink へ一意な `snapshotId` と
  **現在の接続状態スナップショット**を pushする
  ── 各 `deviceId` の `connectionEpoch`/`BleConnectionState`、active notify の `characteristicHandle` 集合、
  探索済み構造(あれば)。Dart 側はこれを受領して状態マシン・per-characteristic view を再構築する
  (接続は native 側で保持済みのため切らない)。再構築完了後、Dart は
  `ackStateResync(engineToken, snapshotId)` を呼ぶ。
- **ハンドオーバ手順(順序固定):** UI engine attach(候補登録) → Dart `BleCallbacksApi.setUp`
  → `notifyDartReady(engineToken)` → ownerがsnapshotをpush → Dartが再構築
  → `ackStateResync(engineToken, snapshotId)` → ownerが新sinkをactive化
  → 旧headless sinkをunregister → headless `FlutterEngine.destroy()`。
  ack 前に旧sink/engineを破棄してはならない。これによりPigeon handler未登録へのpushとイベント欠落を防ぐ。
  専用エントリポイントは
  UI を持たないため**二重 `runApp()` のレースが原理的に発生しない**。
- バッファリング: active sink が無い期間およびhandover中のイベントは owner が短期バッファし、
  ack 後に新active sinkへflushする。snapshot作成後に発生したイベントも順序を保ってsnapshotの後に流す。
  上限は**256イベントまたは最古イベントから30秒**。上限超過時は古いnotify/presenceイベントから破棄し、
  接続状態は最新snapshotへ集約して保持する。破棄件数と理由は common/native observer へ警告し、Dart readyが来ないため
  ownerのGATT接続を破棄することはしない。

---

## CompanionDevice API のバージョン統合(plugin 内マージ)

`CompanionDeviceManager` の API は **31–32 / 33–35 / 36+ の 3 世代**で形が異なる(minSdk 31 のため
3 分岐すべてが実機で到達可能)。**3 世代の API を参照し、plugin 内の単一抽象 `CompanionDeviceController`
(Kotlin)へマージ**する。`BleCentralManager` はこの抽象のみを呼び、`Build.VERSION.SDK_INT` 分岐は
Controller 内に閉じ込める(`@Suppress("DEPRECATION")` は古い世代パスのみ)。

確認済み API レベル(公式 reference。実装時に最新を再確認):
- `associate(req, Callback, Handler)` + `onDeviceFound(IntentSender)` … 旧来。`associate(req, Executor, Callback)` + `onAssociationCreated(AssociationInfo)` … **API 33**。
- `CompanionDeviceService.onDeviceAppeared(String)` … 追加 31 / deprecated 33。`onDeviceAppeared(AssociationInfo)` … 追加 33 / deprecated 36。
- `startObservingDevicePresence(String)` … 追加 33 / deprecated 36。`startObservingDevicePresence(ObservingDevicePresenceRequest)` + `DevicePresenceEvent` + `onDevicePresenceEvent` … **API 36**(Android 16)。
- presence パーミッション: String 版は `REQUEST_OBSERVE_COMPANION_DEVICE_PRESENCE`(31–35 で必要)。
  36+ は関連付け済みBLE機器の `associationId` を
  `ObservingDevicePresenceRequest.Builder.setAssociationId()` に設定する。UUID版 `setUuid()` は
  Classic Bluetooth向けかつ追加制約があるため、本ライブラリでは使用しない。

| 操作 | 31–32 | 33–35 | 36+ | マージ後の抽象 |
|---|---|---|---|---|
| associate | `associate(Callback, Handler)` + `onDeviceFound(IntentSender)` → `startIntentSenderForResult` | `associate(Executor, Callback)` + `onAssociationPending`/`onAssociationCreated(AssociationInfo)` | 33–35 と同じ | `associate(filter) → Result<DeepskyDeviceId>` |
| presence 監視 | `startObservingDevicePresence(String)` | `startObservingDevicePresence(String)` | `getMyAssociations()` で deviceId に対応する associationId を解決し、`startObservingDevicePresence(ObservingDevicePresenceRequest.Builder().setAssociationId(id).build())` | `setPresenceObservation(deviceId, enabled)` |
| presence callback | `onDeviceAppeared(String)` / `onDeviceDisappeared(String)` | `onDeviceAppeared(AssociationInfo)` / `onDeviceDisappeared(AssociationInfo)` | `onDevicePresenceEvent(DevicePresenceEvent)` | 内部 `PendingCompanionEvents.emit(deviceId, appeared)` |

実装方針:
- `DeepskyCompanionDeviceService` は **String 版(31–32)・`AssociationInfo` 版(33–35)・
  `onDevicePresenceEvent`(36+)の 3 系**を override し、同一の内部イベントへ正規化する。
  `AssociationInfo`/`DevicePresenceEvent` 版は `deviceMacAddress`(無い場合は `associationId` から
  `getMyAssociations()` で解決)で `deviceId` を取り出す。
- Manifest は31–35のString版用 `REQUEST_OBSERVE_COMPANION_DEVICE_PRESENCE` を記載する。
  36+はassociationId経路を使うため `REQUEST_OBSERVE_DEVICE_UUID_PRESENCE` は要求しない。
- 旧 plan の deprecated 直書き(Task 11)はこの Controller 経由に置換する。
- deprecated レベルは 36 近辺で変動があり得るため、実装時に各メソッドの公式ページで再確認すること。

公式参照:
- Android `BluetoothGatt.writeCharacteristic`:
  https://developer.android.com/reference/android/bluetooth/BluetoothGatt#writeCharacteristic(android.bluetooth.BluetoothGattCharacteristic,byte[],int)
- Android `BluetoothStatusCodes.ERROR_GATT_WRITE_REQUEST_BUSY`:
  https://developer.android.com/reference/android/bluetooth/BluetoothStatusCodes#ERROR_GATT_WRITE_REQUEST_BUSY
- Android `BluetoothAdapter.ACTION_STATE_CHANGED`:
  https://developer.android.com/reference/android/bluetooth/BluetoothAdapter#ACTION_STATE_CHANGED
- Android `CompanionDeviceManager`:
  https://developer.android.com/reference/android/companion/CompanionDeviceManager
- Android `ObservingDevicePresenceRequest.Builder`:
  https://developer.android.com/reference/android/companion/ObservingDevicePresenceRequest.Builder
- Apple Core Bluetooth State Preservation and Restoration:
  https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothBackgroundProcessingForIOSApps/PerformingTasksWhileYourAppIsInTheBackground.html
- Apple `centralManagerDidUpdateState`:
  https://developer.apple.com/documentation/corebluetooth/cbcentralmanagerdelegate/centralmanagerdidupdatestate(_:)
- Apple Core Bluetooth connection lifecycle:
  https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/PerformingCommonCentralRoleTasks.html

---

## ハンドルの寿命・陳腐化

ハンドルはネイティブ GATT オブジェクトへの生ポインタではなく「座標 + body 参照」。

1. `discoverServices()` は**毎回新しいハンドル木**を返す(その時点のスナップショット。
   `properties`/`descriptors` は探索時点の値)。直近結果は `device.services` にキャッシュ。
   epoch退役(切断、操作タイムアウト、再接続開始、明示disconnect)時にキャッシュを即座に `null` へ戻す。
   新epochでstate resyncから再構築されたservicesがある場合だけ、その新しい木を設定する。
2. 古いハンドルに可変の `isValid` フラグは持たせない。操作は常に
   `(deviceId, connectionEpoch, handle)` 座標で実行:
   - 対象が存在(epoch/handle が現行)→ 正常動作
   - 既に存在しない(再探索/再接続で handle 失効、または epoch 退役)→ `NotFound` 系エラー
     (専用 stale エラーは設けない)
3. `values` ストリームは `(connectionEpoch, characteristicHandle)` に固定される。epoch退役時に
   bodyがcontrollerをcloseし、購読へ `onDone` を通知する。再接続後は `discoverServices()`、
   `setNotify()`、`values.listen()` をやり直す。重複UUIDのどの属性へ追従すべきか一意に決められないため、
   bodyによる自動付け替えは行わない。

---

## iOS State Restoration の復元契約

Core Bluetoothは接続済みだけでなく、接続保留中のperipheralとnotify購読状態も復元し得る。
復元イベントをdevice id一覧だけへ縮退させない。

- `centralManager(_:willRestoreState:)` で復元した各 `CBPeripheral` にdelegateを再設定する。
- native ownerは各peripheralへ**新しいepoch**を払い出し、現在の `CBPeripheral.state` を
  `connected` / `reconnecting` / `disconnected` へ正規化する。
- 復元済み `services` / `characteristics` / `descriptors` が存在する場合は新しいepoch内でhandleを再採番する。
  情報が無い場合はservicesをnullとし、接続後の再探索を要求する。
- `characteristic.isNotifying == true` の属性を `activeNotifyHandles` に含める。
- Dartへは通常の `BleStateSnapshot` と同じ完全snapshotを送り、`restoredConnections` は
  snapshotのready/ack完了後に復元対象deviceのハンドル一覧を通知する便宜ストリームとする。
- `BleStateSnapshot.disconnectReason` はstateが`disconnected`なら必須、それ以外はnull。
  OSから詳細理由を復元できない場合は`unknown`を使用する。
- 復元処理が未完了の間に届いたdelegate eventはownerでバッファし、snapshot後にepoch順でflushする。

---

## 値型(util)

device id / UUID を表す値型は **util ライブラリ(`deepsky_bluetooth_util`)** に定義する
(既存 `DeepskyUuid` と同じ場所)。値等価性・`hashCode`・`toString`・`Map` キー利用可。
interface の models / DTO は util を import 済み。Pigeon/ネイティブ境界は `String`、各 bridge が
相互変換。

```dart
// deepsky_bluetooth_util(DeepskyUuid と同ファイル群)
class DeepskyDeviceId { /* 値型。内部はプラットフォーム id 文字列 */ }
```

公開API全体で `DeepskyDeviceId` / `DeepskyUuid` を使用:
- `BluetoothDevice.id`、`BleScanResult.deviceId`、`device(...)`、`restoredConnections`、`associate`
- `BleService.uuid` / `BleCharacteristic.uuid` / `BleDescriptor.uuid`

---

## ストリーム種別 / dispose

- 全公開ストリーム(`scanResults`/`scanErrors`/`restoredConnections`/`connectionStates`/
  `presenceEvents`/`BleCharacteristic.values`(notify/indicate 専用))は **broadcast**(複数購読可)と明記。
  `BleDescriptor` は values ストリームを持たない(read は戻り値)。
- `BleCharacteristic.values` はactive objectのepoch退役時に終了する。再接続後の再購読が必要。
- READMEには `connectionStates` の `connected` を契機に
  `discoverServices()` →対象characteristic選択→`values.listen()`→`setNotify()` を再実行する
  **再接続後の再購読パターン**を完全な例として載せる。
- `dispose` 後、`DeepskyBluetooth` インスタンスは再利用不可(再生成すること)。全再接続ループ・
  タイマー・StreamController を破棄。

---

## エラー型変更

- `CharacteristicWriteError` に `CharacteristicWriteBufferFull` を追加(`writeWithoutResponse`
  バッファ溢れ)。
- `CharacteristicReadError` に `CharacteristicReadAmbiguousWhileNotifying` を追加
  (iOS/macOS で `read(strictRead: true)` かつ notify 有効時)。
- 操作タイムアウト/接続再生成は **専用エラーを設けず** `*Timeout`(connect)や `*NotConnected`/`*Failed`
  に集約(タイムアウトした GATT 操作は対応する `*Failed`/`*NotConnected` を返す)。接続イベントには
  `disconnected(reason: operationTimeout)` を必ず発行する。`autoReconnect:false` では回復しない。
- 他はレビュー時点のバリアント(`NotConnected`/`NotFound`/`NotSupported`/`Failed` 等)を踏襲。

---

## ネイティブ中核ロジックのテスト境界と集中リスク

epoch採番、epochガード、FIFO操作キュー、handle registry、sink handoverは新規ロジックが集中し、
iOS/macOS実装はWindowsホストでコンパイルできない。実機手動確認だけに依存しないよう、
Bluetooth APIオブジェクトを直接持たない純粋な状態部品へ分離する:

- `EpochRegistry`: deviceIdごとの単調増加採番と現行epoch照合。
- `OperationQueueState`: `(epoch, opSeq, operationKind)` のenqueue/先頭完了/timeout退役。
- `HandleRegistry`: 1回の探索結果へのhandle採番、逆引き、epoch退役時clear。
- `SinkHandoverCoordinator`: candidate/active、snapshotId、ack、256件/30秒バッファ規則。

Kotlinはlocal JVM unit test、SwiftはmacOS上のXCTestで同じ状態遷移ケースを検証する。
BluetoothGatt/CoreBluetoothとの薄いadapterだけをinstrumented/実機テスト対象にする。
WindowsではSwiftテストを実行できないため、macOSチェックポイントをマージ条件として扱う。

---

## 影響範囲(plan 上のタスク)

このspecが plan に対して**優先**する。plan の該当タスクは本specの決定で更新済み(冒頭バナー参照)。

- **Task 2 (util)**: `DeepskyDeviceId` 追加。
- **Task 3 (interface models)**: `BleConnectionState` に `reconnecting` 追加;
  公開 `BleConnectionEvent`/`BleDisconnectReason` と内部 `BlePlatformConnectionEvent` /
  `BleAdapterState` を追加;
  `ReconnectPolicy`・`BleNotifyType` 追加;探索DTO を `BleServiceInfo`/`BleCharacteristicInfo`/`BleDescriptorInfo`
  に整理し **`handle`(+ characteristic は `serviceHandle`)を追加**;uuid/deviceId を
  `DeepskyUuid`/`DeepskyDeviceId` 化;内部キャリアに **`connectionEpoch`/`characteristicHandle`** 追加;
  `BleCompanionEvent`/公開 `BleCharacteristicValue`・`BleDescriptorValue`
  廃止(内部の **notify 専用**キャリアは残す)。
- **Task 5 (platform抽象)**: 接続状態マシン・3駆動源の再接続・タイムアウト・状態スナップショットは
  body 専任。`connect` はnative採番済み `ConnectionAttempt{epoch}` を返し、他の各操作に
  **`int epoch` 引数**を追加、`Target` を **handle ベース**へ、
  全イベントキャリアに **`epoch`(notify は `characteristicHandle`)** を付与。`read*` は
  `Result<Uint8List>`。adapter状態streamと、owner からの**状態リシンク push**(sink rebind 時)も
  platform 契約に含める。
- **Task 6/7/8 (pigeon)**: initializeに `backgroundCallbackHandle`、接続結果にnative採番epoch、
  メッセージに `epoch`/`handle`/`serviceHandle` を追加、`Target` を handle 化、
  通知コールバックに `epoch`(+handle)追加、接続コールバックに nullable `epoch` と
  `DisconnectReasonMessage?` と `AdapterStateMessage` callbackを追加、状態snapshotにも切断理由を追加、
  `notifyDartReady(engineToken)` /
  `ackStateResync(engineToken,snapshotId)` と状態リシンク用FlutterApiを追加。
- **Task 9 (native android)**: **プロセスグローバル owner singleton 化**(接続/キュー/epoch 採番・保持);
  `connectGatt` autoConnect=false・native採番epoch返却/タグ付け;**GATT 操作キュー(`(epoch, opSeq)` 相関、
  タイムアウト=接続破棄+再生成)**;notify は通知ストリーム / read は応答キューに分離;
  探索時 **handle 採番 + `handle→native` マップ**;write-without-response はAPI 33+の
  `ERROR_GATT_WRITE_REQUEST_BUSY` / 31–32のboolean `false` でバッファ溢れ検出;
  `manufacturerData` 正規化;engine attach/detach での **sink register/unregister + 状態リシンク**。
- **Task 11 (native android)**: ヘッドレス復活を**専用 `@pragma('vm:entry-point')` エントリポイント**
  方式へ再設計(`main()` 再実行をやめる、`executeDartCallback`);initialize DTOのcallback handleを永続化;
  **ready/resync/ack sink ハンドオーバ**;CompanionDevice は
  **`CompanionDeviceController` で 31–32/33–35/36+ の3分岐統合**し36+はassociationIdを使用。
- **Task 12/13 (native ios/macos)**: native ownerによるepoch採番・iOS 保留接続;GATT 操作キュー
  (epoch 相関、タイムアウト=接続再生成);**iOS read/notify 契約**(read outstanding 判定 + `values` 併流 +
  `strictRead`);handle 採番;write-without-response バッファ溢れ検出;iOS復元時の完全snapshot生成。
- **Task 14/15/16 (bridges)**: `String` ⇔ `DeepskyDeviceId`/`DeepskyUuid` 変換、`epoch`/`handle` の
  受け渡し、`autoConnect=false` 固定、バッファ溢れ/read-ambiguous 検出のマッピング。
  connect Future完了前に届いた同epochのstate callbackを保留し、bodyがepochを受領した後に解放する。
- **Task 17 (本体)**: `DeepskyBluetooth`/`BluetoothDevice`/active GATT クラスの実装、body所有の
  **native払い出しepochの保持・状態マシン(epoch ガード)**・broadcast・3駆動源の再接続(`ReconnectStrategy`)・
  connect() 完了条件(autoReconnect で armed=Ok)・暗黙成功・**handle ベースの per-characteristic
  フィルタ view**(epoch退役で終了)・epoch退役時の`services`クリア・
  `disconnected(reason)`による終端/一時失敗通知と再試行分類・A/C選択・dispose 破棄・
  `onBackgroundRelaunch` ハンドル登録・**sink rebind 時の状態リシンク受領/ack**・ドキュメント。
  公開APIは **transport/lifecycle の2モジュール**で構成し、lifecycle は `BleTransport` 抽象のみを介して
  transport に依存する(transport=単発操作+生イベント、lifecycle=状態マシン/3駆動源/autoReconnect)。
  「段階的パッケージ分割方針」を正とする。
- **Task 18 (example)**: 新 API + `@pragma('vm:entry-point')` バックグラウンドエントリポイントへ追従。
  切断理由表示と再接続後の再探索・再購読を実演。

## 非目標 (YAGNI)

- 指数バックオフ・最大試行回数・一時失敗に対する「諦め」通知
  (一時理由は固定間隔・無限リトライ。終端理由は即停止して`disconnected(reason)`を通知)。
- `autoReconnect` の後付けトグル(`connect` のフラグのみ。再 `connect` は暗黙 Ok で最初の指定が優先)。
- 再接続専用の別ストリーム(`connectionStates` の `disconnected(reason)` / `reconnecting` で足りる)。
- UUIDパス指定による自動再購読ヘルパ。重複UUIDの扱いを明示するopt-in APIとして将来検討するが、
  初期実装ではアプリが再探索・再購読する。
- グローバル横断ストリーム(per-device/per-characteristic に集約)。
