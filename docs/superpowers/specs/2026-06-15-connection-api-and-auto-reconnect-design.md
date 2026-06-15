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
| 4 | 現在接続状態 | `device.connectionState`(同期)/ `device.connectionStates`(per-device stream) |
| 5 | ストリーム | per-device / per-characteristic。全て broadcast と明記 |
| 6 | dispose後再利用 | 再利用不可と明記 |
| 7 | 自動再接続 | body層Dartループ・固定間隔・プラットフォーム適応 |
| 8 | device id 型 | `DeepskyDeviceId`(util に定義)を公開API全体で使用 |
| 9 | UUID 型 | `DeepskyUuid`(util)を公開API全体で使用 |
| 10 | read 戻り値 | `Result<void, …>`。値は対象の `values` ストリームに流す |
| 11 | setNotify | `BleNotifyType { disable, notify, indicate }` を渡す |
| 12 | CCCD | setNotify が書く。`writeDescriptor` で直接上書きしたらそちら優先(同期ずれ注意をコメント) |
| 13 | write分割 | MTU超過分割はアプリケーションの責務 |
| 14 | バッファ溢れ | `writeWithoutResponse` の溢れを検出し `CharacteristicWriteBufferFull` を返す |

---

## レイヤリング(重要)

GATTオブジェクトを「生きたハンドル」にするため、**探索結果データ**と**操作可能ハンドル**を
層で分離する。

- **interface / platform 層(内部)** … 純粋データ。`deviceId`/uuid 座標を保持する
   DTO とイベントキャリア。
  - 探索DTO: `BleServiceInfo` / `BleCharacteristicInfo` / `BleDescriptorInfo`
    (uuid・`BleCharacteristicProperties`・入れ子)
  - 値イベントキャリア(内部): `(deviceId, serviceUuid, characteristicUuid[, descriptorUuid], value)`
  - `DeepskyBluetoothPlatform` のストリーム(scan/connection/characteristic値/descriptor値/
    companion/restored)はこの層の生イベント。
  - Dart 層インターフェースの型は `DeepskyDeviceId`/`DeepskyUuid`。Pigeon 境界は `String` で、
    各 bridge が相互変換する(`DeepskyUuid` 既存方針と同じ)。
- **body(`deepsky_bluetooth` 本体・公開API)** … `DeepskyBluetooth` / `BluetoothDevice` と
  active な `BleService` / `BleCharacteristic` / `BleDescriptor`。platform DTO を
  ハンドルへラップし、per-device/per-characteristic にフィルタした view と操作を提供する。
  接続状態マシン・再接続ループ・タイムアウト・状態スナップショットは **body が唯一の真実**。

公開 active クラスは body が構築する(コンストラクタは内部用)。ユーザーは `new` しない。

---

## エントリポイント `DeepskyBluetooth`

デバイス非依存の機能のみを持つ。

```dart
class DeepskyBluetooth {
  static Future<Result<DeepskyBluetooth, InitializeError>> foreground({DeepskyBluetoothObserver? observer, /*…*/});
  static Future<Result<DeepskyBluetooth, InitializeError>> background({IosBackgroundConfig? ios, AndroidBackgroundConfig? android, /*…*/});

  Future<Result<void, ScanError>> startScan({DeepskyScanFilter? filter, DeepskyScanOptions options = const DeepskyScanOptions()});
  Future<Result<void, ScanError>> stopScan();

  /// ブロードキャストストリーム(複数購読可)。
  Stream<BleScanResult> get scanResults;
  Stream<ScanError> get scanErrors;

  /// Android CompanionDevice のみ。関連付け済みデバイスのハンドルを返す。
  Future<Result<BluetoothDevice, AssociateError>> associate({DeepskyScanFilter? filter});

  /// iOS State Restoration で復元された接続済みデバイス。broadcast。
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
- 旧 `connectionEvents` グローバルストリーム、旧 `connectionStates` グローバルマップ、
  旧 `characteristicValues` グローバルストリームは**廃止**(per-device/per-characteristic へ移行)。
- `BleConnectionEvent` クラスは廃止(deviceId はハンドルで自明、状態は `BleConnectionState`)。

---

## `BluetoothDevice`(接続・デバイス単位の操作)

薄いハンドル。状態は持たず `id` と owner(body)参照のみ。`==` は `id` 等価。同一 id の
複数ハンドルは矛盾しない。

```dart
class BluetoothDevice {
  DeepskyDeviceId get id;

  /// 現在の接続状態スナップショット(購読前でも取得可)。未接続は disconnected。
  BleConnectionState get connectionState;
  /// per-device の接続状態ストリーム。broadcast。
  Stream<BleConnectionState> get connectionStates;

  /// 既に connected/connecting の場合は暗黙的に成功(Ok)を返す。
  /// [timeout] 経過で未確立なら ConnectTimeout。
  /// [autoReconnect] true で、想定外切断・タイムアウト時に再接続を継続(disconnect/dispose で解除)。
  /// [reconnectPolicy] は autoReconnect が true のときのみ有効。
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

> 派生判断(要確認): presence は `setDevicePresenceObservation` がデバイス単位のため
> `device.presenceEvents` に集約し、旧グローバル `companionEvents` / `BleCompanionEvent` は
> 廃止した。

---

## 接続まわり詳細

### タイムアウト
body が platform の connect Future をタイマーと競合させる。期限超過で保留接続をキャンセルし
`ConnectTimeout` を返す。iOS(CoreBluetooth)はネイティブタイムアウトを持たないため、この方式で
全プラットフォーム統一。`autoReconnect: true` の iOS では保留接続(OS再接続)を使うため
`timeout` は無視。

### 接続状態マシン
```dart
enum BleConnectionState { connecting, connected, disconnecting, disconnected, reconnecting }
```
- `connecting`: ユーザーが `connect()` した **初回接続試行時のみ**。
- `reconnecting`: ライブラリ起因の **全再接続試行**(想定外切断・タイムアウトいずれの契機でも)。

自動再接続デバイスのライフサイクル:
```
connecting → connected → disconnected → reconnecting → reconnecting → … → connected
```
初回成功後 `connecting` は二度と出ない。ユーザー起因の `connect()` は `connecting → connected`
のみ。

### 自動再接続(body層 Dartループ)
ForegroundService はプロセス生存を保証するため Dart タイマーで十分。Dart 実装でユニットテスト
可能・全プラットフォーム共通に保つ。

`ReconnectPolicy` は固定間隔リトライ(指数バックオフは非採用)。
```dart
class ReconnectPolicy {
  const ReconnectPolicy({this.delay = const Duration(seconds: 5)});
  final Duration delay; // 固定リトライ間隔
}
```

ネイティブ `disconnected` 到着時の分岐:
- 直前がユーザー起因 `disconnect()` → `disconnected` 発行・登録解除して終了。
- 想定外切断 → `disconnected` 発行後ループ:
  `reconnecting` 発行 → `delay` 待機 → platform connect 再発行 → 失敗なら再び `reconnecting`、
  成功で `connected`。`disconnect`/`dispose` まで無限継続。

### プラットフォーム適応(`autoReconnect: true` = 「接続を維持する」)

| プラットフォーム | 実現方法 | 備考 |
|---|---|---|
| Android ForegroundService | Dart固定間隔ループ | `connectGatt(..., autoConnect = false, ...)` を**常に**使用 |
| iOS | 無期限の保留接続(OS再接続) | `timeout` 無視。保留中 `reconnecting`、復帰で `connected` |
| Android CompanionDevice | CDM presence に依拠 | 観測可能な範囲で `reconnecting`/`connected` 発行 |
| macOS | Dart固定間隔ループ | フォアグラウンドのみ |

Android の native `autoConnect` は常に `false`。OS の自動再接続には依存せず、再接続は Dart
ループが所有する。

---

## 構造化GATTオブジェクト

`discoverServices()` が返すツリーを生きたハンドルにする。各オブジェクトは内部に owner(body)
参照と座標 `(deviceId, serviceUuid, characteristicUuid[, descriptorUuid])` を保持する。

```dart
class BleService {
  DeepskyUuid get uuid;
  List<BleCharacteristic> get characteristics;
}

class BleCharacteristic {
  DeepskyUuid get uuid;
  BleCharacteristicProperties get properties; // read/writeWithResponse/writeWithoutResponse/notify/indicate
  List<BleDescriptor> get descriptors;

  /// notify/indicate 通知 + read 応答(この characteristic のみ)。broadcast。
  /// 再接続をまたいで購読が生存する(座標フィルタのため)。
  Stream<Uint8List> get values;

  /// 値は戻り値ではなく values に流れる。
  Future<Result<void, CharacteristicReadError>> read();
  Future<Result<void, CharacteristicWriteError>> write(Uint8List value, {required bool withResponse});

  /// CCCD を書く。BleNotifyType.disable/notify/indicate。
  /// 注意: writeDescriptor で CCCD を直接上書きした場合はそちらが優先され、
  /// ライブラリが保持する notify 状態と実機状態が同期ずれを起こしうる。
  Future<Result<void, NotifyError>> setNotify(BleNotifyType type);
}

class BleDescriptor {
  DeepskyUuid get uuid;
  /// read 応答(この descriptor のみ)。broadcast。
  Stream<Uint8List> get values;
  Future<Result<void, DescriptorReadError>> read(); // 値は values に流れる
  Future<Result<void, DescriptorWriteError>> write(Uint8List value);
}

enum BleNotifyType { disable, notify, indicate }
```

使用例:
```dart
final services = (await device.discoverServices()).unwrap();
final char = services.firstWhere((s) => s.uuid == svc)
                     .characteristics.firstWhere((c) => c.uuid == chr);
final sub = char.values.listen(print);
await char.setNotify(BleNotifyType.notify);
await char.read();                       // 値は char.values に届く
await char.write(payload, withResponse: true);
```

備考:
- 旧 `BleCharacteristicValue` / `BleDescriptorValue`(座標付き値クラス)は**公開APIから廃止**。
  値は `Stream<Uint8List>`。座標はハンドルで自明。(内部のイベントキャリアは interface 層に残す)
- `BleCharacteristic.values` は body の per-device ブロードキャストを座標でフィルタした view。
- **write 分割なし**: MTU 超過ペイロードの分割はアプリケーションの責務。`requestMtu` は提供する。
- **バッファ溢れ**: `write(withResponse: false)` 連投で溢れ(iOS `canSendWriteWithoutResponse`
  等)を検出した場合、`CharacteristicWriteBufferFull` を返す。

---

## ハンドルの寿命・陳腐化

ハンドルはネイティブ GATT オブジェクトへの生ポインタではなく「座標 + body 参照」。

1. `discoverServices()` は**毎回新しいハンドル木**を返す(その時点のスナップショット。
   `properties`/`descriptors` は探索時点の値)。直近結果は `device.services` にキャッシュ。
2. 古いハンドルは**明示的に無効化しない**。操作は常に uuid 座標で実行:
   - 対象が存在 → 正常動作
   - 既に存在しない → `NotFound` 系エラー(専用 stale エラーは設けない)
3. `values` ストリームは座標フィルタのため、ハンドルの世代に依存せず**再接続をまたいで生存**。
   常時接続用途で再購読不要。

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
  `presenceEvents`/`BleCharacteristic.values`/`BleDescriptor.values`)は **broadcast**(複数購読可)と明記。
- `dispose` 後、`DeepskyBluetooth` インスタンスは再利用不可(再生成すること)。全再接続ループ・
  タイマー・StreamController を破棄。

---

## エラー型変更

- `CharacteristicWriteError` に `CharacteristicWriteBufferFull` を追加(`writeWithoutResponse`
  バッファ溢れ)。
- 他はレビュー時点のバリアント(`NotConnected`/`NotFound`/`NotSupported`/`Failed` 等)を踏襲。

---

## 影響範囲(plan 上のタスク)

- **Task 2 (util)**: `DeepskyDeviceId` 追加。
- **Task 3 (interface models)**: `BleConnectionState` に `reconnecting` 追加;`ReconnectPolicy`・
  `BleNotifyType` 追加;探索DTO を `BleServiceInfo`/`BleCharacteristicInfo`/`BleDescriptorInfo`
  に整理(active クラスは body へ);uuid/deviceId を `DeepskyUuid`/`DeepskyDeviceId` 化;
  `BleConnectionEvent`/`BleCompanionEvent`/公開 `BleCharacteristicValue`・`BleDescriptorValue`
  の扱い見直し(内部キャリアは残す)。
- **Task 5 (platform抽象)**: 接続状態マシン・再接続ループ・タイムアウト・状態スナップショットは
  body 専任。platform は単純 connect + 保留接続発行、探索DTO 返却、内部値イベント発行を担う。
- **Task 14/15/16 (bridges)**: `String` ⇔ `DeepskyDeviceId`/`DeepskyUuid` 変換、Android は
  `autoConnect=false` 固定、バッファ溢れ検出のマッピング。
- **Task 17 (本体)**: `DeepskyBluetooth`/`BluetoothDevice`/active GATT クラスの実装、body所有の
  接続状態マシン・broadcast・再接続ループ・タイムアウト・暗黙成功・per-device/per-characteristic
  フィルタ view・`services` キャッシュ・dispose 破棄・ドキュメント。
- **Task 9/12/13 (native)**: Android `connectGatt` autoConnect=false、iOS 保留接続、
  write-without-response バッファ溢れ検出。
- **Task 18 (example)**: 新 API へ追従。

## 非目標 (YAGNI)

- 指数バックオフ・最大試行回数・「諦め」通知(固定間隔・無限リトライ)。
- `autoReconnect` の後付けトグル(`connect` のフラグのみ)。
- 再接続専用の詳細イベントストリーム(`reconnecting` 状態 + Observer ログで足りる)。
- グローバル横断ストリーム(per-device/per-characteristic に集約)。
