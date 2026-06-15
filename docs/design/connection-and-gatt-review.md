# 接続・GATT 設計レビューガイド

最終更新: 2026-06-15

## 1. この文書の目的

`deepsky_bluetooth` の接続、GATT、自動再接続、バックグラウンド復活について、
設計レビューに必要な判断だけをまとめる。

この文書で確認する対象は次の5点である。

1. 利用者に公開する API が理解しやすく、一貫しているか
2. 接続、再接続、タイムアウトの状態遷移に矛盾がないか
3. 遅延コールバックや重複 UUID を誤って処理しないか
4. Android、iOS、macOS の差分が公開契約から過度に漏れていないか
5. バックグラウンド復活時にも接続所有権が一意に保たれるか

実装コード、Pigeon メッセージの全フィールド、OS API の世代別呼び分けは詳細仕様と
実装計画へ分離する。

## 2. 文書間の優先順位

文書の責務と優先順位は次のとおり。

1. **本レビューガイド**: 設計判断と公開契約のレビュー基準
2. **詳細仕様**: 本文で省略したエッジケースと内部プロトコル
3. **実装計画**: 実装順序、テスト、非規範のコードスケッチ

詳細仕様:
[2026-06-15-connection-api-and-auto-reconnect-design.md](../superpowers/specs/2026-06-15-connection-api-and-auto-reconnect-design.md)

実装計画:
[2026-06-12-deepsky-bluetooth.md](../superpowers/plans/2026-06-12-deepsky-bluetooth.md)

本レビューガイドと詳細仕様が矛盾する場合は、設計判断として本レビューガイドを優先する。
ただし、本書に記載のない実装上の詳細は詳細仕様を参照する。

## 3. スコープ

### 対象

- BLE Central としてのスキャン、接続、切断
- GATT service discovery、read、write、notify、indicate
- descriptor、MTU、RSSI
- 接続状態と自動再接続
- Android Foreground Service / Companion Device
- iOS State Restoration
- Dart とネイティブ間の所有権、イベント引き継ぎ

### 非対象

- Peripheral role
- bonding / pairing UI
- 指数バックオフ、最大再試行回数
- UUID パスによる自動再購読
- 複数 managed instance による transport の共有
- ネイティブ BLE owner の複数プロセス・複数インスタンス化

## 4. 設計要約

### 公開 API

- 入口は `DeepskyBluetooth` とする。
- 接続後の操作は `BluetoothDevice` に集約する。
- GATT は `BleService`、`BleCharacteristic`、`BleDescriptor` の active object とする。
- ID と UUID は生の `String` ではなく `DeepskyDeviceId` と `DeepskyUuid` を使う。
- 全公開非同期操作は `Future<Result<T, XxxError>>` を返す。
- 全公開 stream は broadcast とする。

### 内部構造

- root package を `transport` と `lifecycle` の2モジュールへ分ける。
- `transport` は単発のネイティブ操作と生イベントだけを扱う。
- `lifecycle` は公開 API、接続状態、自動再接続、キャッシュ寿命を扱う。
- `lifecycle` が依存できる transport 面は内部抽象 `BleTransport` だけとする。
- ネイティブ BLE owner はプロセスグローバル singleton とする。

### 一貫性を守る識別子

- 接続実体は native owner が採番する `connectionEpoch` で識別する。
- GATT 属性は探索時に採番する epoch 内の整数 `handle` で識別する。
- 操作とイベントの相関キーは `(deviceId, connectionEpoch, handle)` とする。
- UUID は表示と検索に使えるが、操作相関の主キーにはしない。

## 5. 公開 API 契約

以下はシグネチャの要点であり、import や細かな doc comment は省略している。

```dart
class DeepskyBluetooth {
  static Future<Result<DeepskyBluetooth, InitializeError>> foreground(...);
  static Future<Result<DeepskyBluetooth, InitializeError>> background(...);

  Future<Result<void, ScanError>> startScan(...);
  Future<Result<void, ScanError>> stopScan();
  Stream<BleScanResult> get scanResults;
  Stream<ScanError> get scanErrors;

  BluetoothDevice device(DeepskyDeviceId id);
  Future<Result<BluetoothDevice, AssociateError>> associate(...);
  Stream<List<BluetoothDevice>> get restoredConnections;

  Future<Result<void, DisposeError>> dispose();
}
```

`DeepskyBluetooth` はデバイス非依存の操作だけを持つ。`dispose()` 後のインスタンスは
再利用できない。

```dart
class BluetoothDevice {
  DeepskyDeviceId get id;
  BleConnectionState get connectionState;
  Stream<BleConnectionEvent> get connectionStates;

  Future<Result<void, ConnectError>> connect({
    Duration? timeout,
    bool autoReconnect = false,
    ReconnectPolicy reconnectPolicy = const ReconnectPolicy(),
  });
  Future<Result<void, DisconnectError>> disconnect();

  Future<Result<List<BleService>, DiscoverServicesError>> discoverServices();
  List<BleService>? get services;
  Future<Result<int, MtuError>> requestMtu(int mtu);
  Future<Result<int, RssiError>> readRssi();

  Future<Result<void, PresenceError>> setDevicePresenceObservation({
    required bool enabled,
  });
  Stream<bool> get presenceEvents;
}
```

同じ device に複数の `BluetoothDevice` ハンドルがあっても、状態は owner 内で device ID
単位に共有する。

```dart
class BleCharacteristic {
  DeepskyUuid get uuid;
  BleCharacteristicProperties get properties;
  List<BleDescriptor> get descriptors;
  Stream<Uint8List> get values;

  Future<Result<Uint8List, CharacteristicReadError>> read({
    bool strictRead = false,
  });
  Future<Result<void, CharacteristicWriteError>> write(
    Uint8List value, {
    required bool withResponse,
  });
  Future<Result<void, NotifyError>> setNotify(BleNotifyType type);
}
```

- `read()` の値は戻り値で返す。
- `values` は notify / indicate 専用とする。
- write payload の MTU 分割はアプリケーションの責務とする。
- `setNotify` が CCCD を操作する。
- CCCD を descriptor API から直接書いた場合は、直接書き込みを優先する。

### レビュー確認

- デバイス指向 API と active GATT object は利用者の期待に合うか。
- `read()` と `values` の役割分離は十分明確か。
- 再接続後に GATT object を作り直す契約を許容できるか。

## 6. 接続 API の意味

### connect

既に `connected`、`connecting`、`reconnecting` の場合は成功を返す。最初の
`autoReconnect` と `reconnectPolicy` を維持し、後続 `connect()` では変更しない。
変更する場合は明示的に `disconnect()` してから接続し直す。

完了条件:

| 指定 | `connect()` Future の完了 |
|---|---|
| `autoReconnect: false` | 接続確立、タイムアウト、またはエラー |
| `autoReconnect: true` | 維持要求を受理した時点で成功。実接続は stream で観測 |

`autoReconnect: true` では無期限再試行を許すため、`timeout` は無視する。

### disconnect

- 維持要求と再接続を解除する。
- `userRequested` として切断状態を通知する。
- 接続 epoch と active GATT object を退役させる。

### 切断イベント

```dart
enum BleConnectionState {
  connecting,
  connected,
  disconnecting,
  disconnected,
  reconnecting,
}
```

`BleConnectionEvent.reason` は `disconnected` の場合だけ必須で、それ以外は null とする。

主な切断理由:

| 理由 | 再接続の扱い |
|---|---|
| `userRequested` | 停止 |
| `permissionDenied` | 終端、維持要求を解除 |
| `bluetoothUnavailable` | 終端、維持要求を解除 |
| `deviceNotFound` | 終端、維持要求を解除 |
| `notAssociated` | 終端、維持要求を解除 |
| `presenceObservationDisabled` | C 駆動が必須の headless 復活時だけ終端 |
| `bluetoothOff` | 一時停止、電源復帰待ち |
| `connectFailed` | 一時失敗 |
| `connectionLost` | 一時失敗 |
| `operationTimeout` | 一時失敗、接続実体を再生成 |
| `unknown` | 一時失敗 |

圏外、広告停止、接続タイムアウトを `deviceNotFound` にしない。有効な device identity を
構築できた後の接続失敗は `connectFailed` とする。

### レビュー確認

- `autoReconnect: true` が接続確立前に成功する意味は妥当か。
- 終端理由と一時理由の分類はアプリの復旧方法と整合するか。
- `bluetoothOff` で維持要求を残す方針は期待どおりか。

## 7. 接続状態マシン

通常接続:

```text
disconnected -> connecting -> connected
connected -> disconnecting -> disconnected(userRequested)
```

自動再接続:

```text
connecting -> connected
connected -> disconnected(reason) -> reconnecting -> connected
```

規則:

- `connecting` は利用者が開始した初回試行だけに使う。
- ライブラリが行う再試行は `reconnecting` とする。
- 一時失敗時は `disconnected(reason)` と `reconnecting` を一度だけ通知する。
- `reconnecting` 中の反復失敗は公開状態を反復せず Observer に記録する。
- 終端理由を受けたら `disconnected(reason)` を通知して停止する。
- 公開 stream は実際の状態遷移時だけ発行する。

## 8. 自動再接続の駆動源

状態マシンは共通だが、次の試行を開始する主体はプラットフォームごとに異なる。

| 駆動源 | 用途 | 次の試行 |
|---|---|---|
| A. Dart 固定間隔 | Android foreground / FGS、macOS | `ReconnectPolicy.delay` 後に Dart が開始 |
| B. iOS 保留接続 | iOS | CoreBluetooth の保留接続に委譲 |
| C. CDM presence | Android Companion Device | device appeared と adapter ON を契機に開始 |

共通規則:

- adapter OFF 中は接続試行を止め、維持要求は残す。
- adapter ON で A は即時試行し、C は appeared 状態なら即時試行する。
- B は OS の保留接続を維持する。
- 一時失敗は `disconnect()`、`dispose()`、終端理由まで無限に継続する。
- 指数バックオフと最大試行回数は初期設計に含めない。

Android Companion Device では、関連付けと presence 監視が有効なら C、それ以外は
Dart engine が生存している間だけ A を使う。headless 復活では C を必須とする。

### レビュー確認

- 3つの駆動源を1つの公開状態へ正規化する方針に不足はないか。
- 固定間隔、無限再試行をライブラリ既定とすることを許容できるか。
- Companion Device の A へのフォールバック条件は明確か。

## 9. 接続世代と GATT 属性ハンドル

### connectionEpoch

- device ごとの単調増加整数とする。
- 唯一の採番元はプロセスグローバル native owner とする。
- 新しい接続実体を生成するたびに更新する。
- 全接続操作と全ネイティブイベントに付与する。
- body は現在 epoch と一致しない要求・イベントを拒否または破棄する。

### attribute handle

- service、characteristic、descriptor の探索時に整数 handle を採番する。
- handle は1つの connection epoch 内だけ有効とする。
- 操作と通知は UUID ではなく handle で相関する。
- 同じ UUID の service や characteristic が複数存在しても区別できる。

この2つにより、切断後に到着した古い callback、操作タイムアウト後の遅延応答、
重複 UUID の取り違えを防ぐ。

## 10. GATT 操作の直列化

ネイティブ owner は device 単位の FIFO キューを持ち、同時に1操作だけ実行する。

キュー対象:

- service discovery
- characteristic read / write
- descriptor read / write
- setNotify の CCCD write
- request MTU
- read RSSI

notify / indicate は要求応答ではないためキューに載せない。

各操作は `(connectionEpoch, opSeq, operationKind)` を持つ。callback は現行 epoch と
キュー先頭の operation kind が一致した場合だけ操作を完了する。

### 操作タイムアウト

タイムアウト後に同じ接続でキューを続行しない。

1. インフライト操作を timeout 系エラーで完了する。
2. 接続実体を破棄する。
3. 現在 epoch を退役させる。
4. `disconnected(operationTimeout)` を通知する。
5. 自動再接続が有効なら新しい接続実体と epoch を作る。

目的は、遅延 callback が次の操作を誤って完了することを構造的に防ぐことである。

### iOS / macOS の read と notify

CoreBluetooth は read 応答と notify を同じ callback で返し、原因を完全には区別できない。

- 通常の `read()` は最初の該当 callback を戻り値として完了し、同じ値を `values` にも流す。
- `read(strictRead: true)` は notify 有効中なら
  `CharacteristicReadAmbiguousWhileNotifying` を返す。
- Android では read と notify の callback が別なので厳密に分離する。

### レビュー確認

- タイムアウト時に接続全体を捨てる副作用は妥当か。
- iOS / macOS の曖昧性を公開契約として扱う説明は十分か。

## 11. GATT object の寿命

- `discoverServices()` は毎回新しい active object tree を返す。
- 最新結果だけを `device.services` にキャッシュする。
- epoch 退役時に `device.services` を即時に null へ戻す。
- 古い object の操作は `NotFound` または `NotConnected` 系エラーとする。
- 古い `BleCharacteristic.values` は epoch 退役時に close する。
- 再接続後は service discovery、stream 購読、`setNotify()` をやり直す。
- UUID だけを使った object の自動付け替えは行わない。

## 12. バックグラウンドと所有権

### Android headless 復活

アプリの `main()` や `runApp()` は再実行しない。アプリが登録した
`@pragma('vm:entry-point')` の専用バックグラウンド関数を実行する。

callback handle は初期化時に native へ渡して永続化する。登録がなければ headless 復活は
行わず、UI 復帰後に再接続する。

### native owner

- BLE 接続、epoch、操作キューはプロセスグローバル singleton が所有する。
- Flutter engine ごとの plugin instance は messenger の sink だけを提供する。
- active sink は常に1つとする。
- engine detach だけでは BLE 接続を破棄しない。
- BLE 接続の解放は明示的な `dispose()` が行う。

### sink handover

順序は固定する。

```text
engine attach
-> Dart callback 登録
-> Dart ready
-> state snapshot
-> Dart state 再構築
-> snapshot ack
-> 新 sink を active 化
-> 旧 sink と engine を破棄
```

handover 中のイベントは最大256件または30秒まで保持する。上限を超えた場合は古い
notify / presence から破棄し、接続状態は最新 snapshot を正とする。

## 13. iOS State Restoration

- 復元した peripheral に新しい epoch を払い出す。
- 接続状態、探索済み GATT tree、notify 状態を可能な範囲で完全 snapshot にする。
- 復元情報がない service は null とし、再探索を要求する。
- snapshot の ready / ack 後に `restoredConnections` を通知する。
- 復元中に届いたイベントは snapshot 後に順序を保って流す。

device ID の一覧だけを復元契約にせず、native owner が保持している状態を引き継ぐ。

## 14. プラットフォーム差分

| 項目 | Android | iOS | macOS |
|---|---|---|---|
| 通常の再接続 | Dart 固定間隔 | OS 保留接続 | Dart 固定間隔 |
| process / app 復活 | FGS / Companion Device + headless engine | State Restoration | 対象外 |
| read / notify 分離 | 分離可能 | 区別不能を契約化 | 区別不能を契約化 |
| MTU 指定 | 指定値を要求 | 指定値を無視し現在値を返す | 詳細仕様に従う |
| Companion Device | API 31-32 / 33-35 / 36+ を内部統合 | 対象外 | 対象外 |
| native auto-connect | 使用しない | CoreBluetooth 保留接続 | 使用しない |

OS API の具体的な呼び分けや permission は詳細仕様を参照する。公開 API へ OS 世代差分を
直接露出させない。

## 15. モジュール境界

```text
public API / lifecycle
        |
        v
   BleTransport
        |
        v
transport implementation
        |
        v
platform interface / bridge / native owner
```

`lifecycle` の責務:

- 公開 API
- 接続状態マシン
- 自動再接続戦略
- current epoch の保持とイベント guard
- services cache と active object の寿命
- 公開 stream

`transport` の責務:

- platform 選択と初期化
- 単発の接続・GATT 操作
- 生の接続、notify、adapter、snapshot event
- state resync の受領と ack

禁止する依存:

- `lifecycle` から platform class や bridge への直接依存
- `transport` から `lifecycle` への依存
- transport に再接続 timer や公開状態遷移を持たせること

同一 Dart package 内ではコンパイラが境界を強制しないため、architecture test で検査する。

## 16. テストで保証する事項

### Dart

- 全接続状態遷移
- 終端理由と一時理由の分類
- 3つの reconnect strategy
- epoch 不一致イベントの破棄
- services cache の失効
- active stream の close
- broadcast と dispose 後の拒否
- module dependency rule

### Kotlin local JVM / Swift XCTest

- epoch の単調増加と guard
- FIFO operation queue
- timeout 時の接続退役
- handle の採番、逆引き、clear
- sink handover の ready / snapshot / ack
- バッファ上限と破棄優先順位

Bluetooth API との薄い adapter は実機または platform test で確認する。Windows では Swift を
コンパイルできないため、macOS 上の XCTest をマージ条件とする。

## 17. 集中レビューが必要なリスク

### R1. `autoReconnect: true` の成功条件

接続確立ではなく維持要求の受理で成功する。呼び出し側が通常の connect Future と同じ意味だと
誤認しない命名・説明が必要である。

### R2. GATT timeout の影響範囲

1操作の timeout で接続全体を破棄する。安全性は高いが、アプリから見ると副作用が大きい。

### R3. iOS / macOS read の曖昧性

notify 中の通常 read は通知値を返す可能性がある。`strictRead` の既定値と説明を重点確認する。

### R4. engine handover

ready / snapshot / ack の順序を誤るとイベント欠落、二重配送、古い engine への push が起きる。

### R5. 自動再接続の無限継続

一時失敗は最大回数なしで継続する。電池、ログ量、アプリ側の停止手段を確認する。

### R6. active object の失効

再接続後に discovery と notify 購読をやり直す必要がある。README と example で完全な復旧例が必要である。

## 18. レビュー完了条件

次の問いに全て回答できれば、設計レビューを完了できる。

- [ ] 公開 API の責務分担に異論がない
- [ ] `connect()` の2つの完了条件が明確である
- [ ] 切断理由の終端・一時分類が妥当である
- [ ] 状態マシンに通知漏れや無限ループ上の矛盾がない
- [ ] 3つの再接続駆動源が同じ公開契約へ正規化されている
- [ ] epoch と handle で遅延 callback、重複 UUID を防げる
- [ ] GATT timeout 時の接続破棄を許容できる
- [ ] iOS / macOS の read / notify 制約を許容できる
- [ ] active GATT object の寿命が利用者に説明可能である
- [ ] native owner と sink handover の所有権が一意である
- [ ] platform 差分が公開 API へ過度に漏れていない
- [ ] テスト境界が集中リスクをカバーしている

## 19. 変更管理

レビューで設計を変更する場合は、本書の該当節を先に更新する。その後、詳細仕様と実装計画へ
変更を反映する。

レビュー履歴や却下案を本文へ追記し続けない。必要な場合は pull request、issue、または別の
decision log に残し、本書には現在有効な判断だけを記載する。
