# IPC Pigeon 契約の確定（Issue #16）

作成日: 2026-06-16

親Issue: #3 [IPC] Android・iOS・macOSのPigeon契約を定義・生成する
対象Issue: #16 [IPC] 共通Pigeon messageとHost/Flutter API仕様を確定する

## 1. この文書の目的

3 platform（Android / iOS / macOS）で意味上同型となる Pigeon の message / Host API /
Flutter callback API を、実際の Pigeon 入力ファイル（`pigeons/messages.dart`）として確定する。

設計判断の正本はレビューガイド `docs/design/connection-and-gatt-review.md` §§9-14 と
実装計画 `docs/superpowers/plans/2026-06-12-deepsky-bluetooth.md` Tasks 6-8 にある。
本書はそれらを #16 のスコープへ落とし込み、3 platform 間の共通部分と差分、nullable 規則を
明示する。

## 2. スコープ

### 対象（#16 で実装する）

- `plugins/deepsky_bluetooth_android/pigeons/messages.dart`
- `plugins/deepsky_bluetooth_ios/pigeons/messages.dart`
- `plugins/deepsky_bluetooth_macos/pigeons/messages.dart`

内容は実装計画 Tasks 6-8 の正本スキーマをそのまま転記する。

### 非対象（#17 / #18 / #19 で実装する）

- `dart run pigeon` によるコード生成（`lib/src/messages.g.dart`、`Messages.g.kt`、
  `Messages.g.swift`）
- 各プラグインの `lib/*.dart` を生成物の export へ置換する作業
- ネイティブ実装・bridge の配線

注: `pigeon: ^26.0.2` は 3 プラグインの `dev_dependency` に既に存在するため、依存追加は不要。
（解決バージョンは 26.3.4。）

## 3. 3 platform の共通コア

次の型・API は 3 platform で意味・形が同型である。

### 共通 message

- フィルタ: `ManufacturerDataFilterMessage` / `ServiceDataFilterMessage` / `ScanFilterMessage`
- スキャン結果: `ScanResultMessage`
- 列挙: `ConnectionStateMessage` / `AdapterStateMessage` / `DisconnectReasonMessage` /
  `NotifyTypeMessage`
- GATT 相関: `CharacteristicTargetMessage` / `DescriptorTargetMessage`
- GATT 構造: `DescriptorMessage` / `CharacteristicMessage` / `ServiceMessage`
- 接続世代: `ConnectionAttemptMessage`（`connectionEpoch`）
- 状態同期: `StateSnapshotMessage` / `StateResyncMessage`

### 共通 Host API（`BleHostApi`）

`initialize`（戻り値は engine 単位の opaque token）/ `notifyDartReady` / `ackStateResync` /
`startScan` / `stopScan` / `connect`（`@async`、native 採番済み `ConnectionAttemptMessage` を返す）/
`disconnect` / `discoverServices` / `readCharacteristic`（`strictRead` 付き）/
`writeCharacteristic` / `setNotify` / `readDescriptor` / `writeDescriptor` / RSSI / MTU / `dispose`。

### 共通 Flutter callback API（`BleCallbacksApi`）

`onScanResult` / `onConnectionStateChanged` / `onAdapterStateChanged` /
`onCharacteristicValue` / `onOperationTimeout` / `onStateResync`。

## 4. platform 差分（公開契約として許容する）

| 項目 | Android | iOS | macOS |
|---|---|---|---|
| initialize 引数 | `InitializeRequestMessage`（strategy/notification/backgroundCallbackHandle） | `InitializeRequestMessage`（restoreIdentifier/backgroundCallbackHandle） | `initialize(bool isBackground)`（background は backgroundNotSupported） |
| scan settings | `AndroidScanSettingsMessage` | `DarwinScanSettingsMessage` | `DarwinScanSettingsMessage` |
| MTU | `requestMtu`（指定値を要求） | `getMtu`（現在値を返す） | `getMtu` |
| companion / presence | `associate` / `setDevicePresenceObservation` / `onDeviceAppeared` / `onDeviceDisappeared` | なし | なし |
| scan 失敗 callback | `onScanFailed` | なし（CoreBluetooth は adapter state で表現） | なし |
| 復元 callback | なし | `onRestoredConnections` | なし |

これらの差分はレビューガイド §14 の platform 差分表に対応する。公開 Dart API へ OS 世代差分を
露出させない方針は bridge / lifecycle 層で守る。

## 5. 受け入れ条件のマッピング

- **3 platform で意味上同型の schema となる** — §3 の共通コアが 3 ファイルで同一形。差分は §4 に
  限定し、いずれも設計上意図された platform 固有事項。
- **read response と notify event が別経路である** — `readCharacteristic(...)` は Host API の戻り値
  （`Uint8List`）で値を返す。notify / indicate は `onCharacteristicValue` callback のみを経路とする。
  共通の「read 結果 callback」は持たない。
- **nullable epoch が採番前失敗だけに限定される** — `connectionEpoch` は全 message / API で非 null。
  唯一の例外は `onConnectionStateChanged(deviceId, int? connectionEpoch, ...)` で、null は
  native owner が epoch を採番する前に接続が失敗した場合だけを表す。

## 6. 検証方針

#16 ではコード生成を行わないため、次で確認する。

- 各プラグインで `dart pub get` が成功する（`pigeon` dev_dependency が解決する）。
- 3 つの `pigeons/messages.dart` が実装計画 Task 6/7/8 の正本スキーマと一致する。
- `pigeons/*.dart` に対する `flutter analyze` は #16 のゲートにしない。これらは生成後にのみ完全に
  解決する Pigeon 入力ファイルであり、生成は #17 / #18 / #19 の責務。

本書はテスト駆動の対象ではない。Pigeon 入力ファイルはコードジェネレータが消費する宣言的定義で
あり、振る舞いの検証は生成を行う #17-19 で実施する。
