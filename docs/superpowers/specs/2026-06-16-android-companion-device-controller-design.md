# Android CompanionDeviceController 設計（Issue #26）

## 目的

Android の Companion Device Manager（CDM）を使った関連付け（associate）と
presence 監視について、API 世代（31-32 / 33-35 / 36+）の差分を単一の
`CompanionDeviceController` へ閉じ込める。`BleProcessOwner`（owner）は SDK 分岐を
一切持たず、正規化済みの値だけを扱う。

親 Issue #5、設計参照: Review guide §§8, 14 / Implementation plan Task 11。

## スコープ

### 本 PR（#26）に含む

- `associate` の API 31-32 / 33+ 分岐（チューザ起動・ActivityResult 受領まで含む）
- presence 監視の開始/停止 API の 31-35 / 36+ 分岐
- 36+ 用の associationId 解決
- deprecated CDM API 使用を controller 内へ隔離
- associate 結果を正準 DeepskyDeviceId（大文字 MAC）へ正規化
- 必要 permission を plugin manifest へ追加
- `ActivityAware` 配線（チューザ起動と結果受領のため）

### 本 PR に含まない（後続 Issue）

- `CompanionDeviceService` の presence event callback override と
  appeared/disappeared 配送、pending event 保存、owner への配送（#27）
- `COMPANION_DEVICE` background strategy の `initialize` 受理と headless 復活（#27/#29）。
  `initialize` の `COMPANION_DEVICE` は引き続き未実装エラーのまま据え置く。

## 識別子の規約

DeepskyDeviceId は既存実装（`BleProcessOwner.connect` が `adapter.getRemoteDevice(deviceId)`、
scan が `device.address` を返す）に合わせ、正準形を大文字の MAC アドレス
`XX:XX:XX:XX:XX:XX` とする。CDM から得る `BluetoothDevice.address` /
`AssociationInfo.deviceMacAddress`（`MacAddress`）はこの正準形へ正規化する。

## モジュール構成と責務

### 純粋コンポーネント（`core/`、Bluetooth/CDM API 非依存、JVM テスト対象）

**`CompanionApiGeneration`** — `sdkInt: Int` から使用すべき API 世代を返す純粋関数。

- `associateApi`:
  - `LEGACY_31_32`: `CompanionDeviceManager.Callback.onDeviceFound(IntentSender)` 経路
  - `MODERN_33_PLUS`: `onAssociationPending(IntentSender)` + `onAssociationCreated(AssociationInfo)` 経路
- `presenceApi`:
  - `LEGACY_31_35`: `startObservingDevicePresence(String)` / `stopObservingDevicePresence(String)`（deprecated）
  - `MODERN_36_PLUS`: `ObservingDevicePresenceRequest`（associationId 指定）経路
- SDK 31 未満は非対応（`isSupported = false`）として扱い、owner が機能不可エラーへ変換できる情報を返す。

**`DeviceAddressNormalizer`** — MAC アドレス文字列を正準 DeepskyDeviceId へ正規化・検証する。

- 小文字→大文字、形式検証（6 オクテット、`:` 区切り）
- 無効入力は `null`（呼び出し側でエラー化）

**`CompanionAssociationResolver`** — 36+ presence 用に、関連付け一覧から associationId を解決する。

- 入力: `List<AssociationEntry(associationId: Int, deviceAddress: String?)>` と対象 deviceId
- アドレスは正規化して大小無視で照合
- 一致が無ければ `null`（owner が `notAssociated` へ変換）

### 薄いフレームワーク adapter（実機/platform 検証）

**`CompanionDeviceController`** — `CompanionDeviceManager` を保持し、上記純粋
コンポーネントの判定に従って実 CDM API を呼ぶだけ。`@Deprecated` /
`@SuppressLint("NewApi")` をここに隔離する。owner からは世代差分が見えない。

公開メソッド（概略）:

- `associate(filter, activity, callback)`: `AssociationRequest` を組み、世代に応じた
  Callback を登録。チューザ `IntentSender` を `activity.startIntentSenderForResult` で起動し、
  結果（`BluetoothDevice` / `AssociationInfo`）を正規化して `callback` へ DeepskyDeviceId を返す。
- `setDevicePresenceObservation(deviceId, enabled)`: 世代に応じて
  device address 版 / `ObservingDevicePresenceRequest`（associationId）版を呼ぶ。
  36+ は `getMyAssociations()` から resolver で associationId を解決し、未関連付けなら
  `notAssociated` を返す。

## データフロー

### associate

```
Flutter associate(filter)
  → BleCentralManager.associate (observeAsync)
  → BleProcessOwner.associate(filter, callback)        // owner は世代分岐なし
  → CompanionDeviceController.associate(filter, activity, callback)
      - AssociationRequest を filter から構築
      - generation.associateApi で分岐:
        · LEGACY_31_32: onDeviceFound(IntentSender) → startIntentSenderForResult
            → ActivityResult EXTRA_DEVICE(BluetoothDevice) → normalizer → deviceId
        · MODERN_33_PLUS: onAssociationCreated(AssociationInfo) → deviceMacAddress → normalizer → deviceId
            (onAssociationPending(IntentSender) は確認ダイアログ起動経路)
  → callback(Result.success(deviceId))                 // 正規化済み DeepskyDeviceId
```

Activity 不在で `associate` が呼ばれた場合は `bleError(FAILED, "Activity required for association")`
を返す。

### presence

```
Flutter setDevicePresenceObservation(deviceId, enabled)
  → BleProcessOwner.setDevicePresenceObservation(deviceId, enabled)
  → CompanionDeviceController:
      · LEGACY_31_35: start/stopObservingDevicePresence(deviceId)   // deprecated, controller 内に隔離
      · MODERN_36_PLUS: resolver で associationId 解決
          → ObservingDevicePresenceRequest.Builder().setAssociationId(id) で start/stop
          → 未関連付けなら notAssociated エラー
```

## ActivityAware 配線

- `DeepskyBluetoothAndroidPlugin` に `ActivityAware` を実装。`onAttachedToActivity` /
  `onReattachedToActivityForConfigChanges` で `ActivityPluginBinding` を保持し、
  `Activity` を controller（owner 経由）へ供給する。
- `binding.addActivityResultListener` でチューザ結果（REQUEST_CODE 照合）を受け取り、
  pending な associate callback を解決する。
- `onDetachedFromActivity` / `onDetachedFromActivityForConfigChanges` で Activity 参照と
  listener をクリアする。接続・scan・epoch は process-global owner が保持し続ける。

## エラー正規化

- `BleErrorCode.NOT_ASSOCIATED`（既存）: 36+ presence で関連付けが無い。
- `BleErrorCode.PRESENCE_OBSERVATION_DISABLED`（既存）: 必要時に使用。
- CDM 例外・失敗 callback は `BleErrorMapping` 経由で正規化し、SDK 由来の生例外を
  owner/Flutter へ漏らさない。

## テスト

### JVM ユニットテスト（純粋ロジック、Bluetooth/CDM 非依存）

- `CompanionApiGenerationTest` — 世代境界網羅:
  - SDK 31, 32 → `LEGACY_31_32` / `LEGACY_31_35`
  - SDK 33, 34, 35 → `MODERN_33_PLUS` / `LEGACY_31_35`
  - SDK 36+ → `MODERN_33_PLUS` / `MODERN_36_PLUS`
  - SDK 30 以下 → `isSupported = false`
- `DeviceAddressNormalizerTest` — 大小/区切り正規化、無効フォーマット拒否、`MacAddress` 文字列形式。
- `CompanionAssociationResolverTest` — 一致 deviceId → associationId、大小無視一致、
  未一致 → null、複数関連付け、`deviceAddress = null` エントリのスキップ。

「API 世代別 unit test が通る」を世代セレクタの境界網羅で満たす。実 CDM 呼び出し・
チューザ・ActivityResult は薄い adapter として実機/platform 検証扱い（§16 準拠、
Windows では Swift 同様にここはマージ条件の自動テスト外）。

### manifest

plugin `AndroidManifest.xml` へ追加:

```xml
<uses-feature android:name="android.software.companion_device_setup" />
<uses-permission android:name="android.permission.REQUEST_COMPANION_RUN_IN_BACKGROUND" />
<uses-permission android:name="android.permission.REQUEST_COMPANION_USE_DATA_IN_BACKGROUND" />
<uses-permission android:name="android.permission.REQUEST_OBSERVE_COMPANION_PRESENCE" />
```

BLUETOOTH_SCAN / BLUETOOTH_CONNECT / FOREGROUND_SERVICE 系は既存のまま。

## 受け入れ条件との対応

- [ ] Ble owner が SDK 分岐を直接持たない → owner は controller へ委譲、分岐は controller/純粋層のみ
- [ ] associate 結果を DeepskyDeviceId へ正規化 → `DeviceAddressNormalizer`
- [ ] API 世代別 unit test が通る → `CompanionApiGenerationTest` ほか
- [ ] 必要 permission が manifest にある → CDM 関連 permission を追加

## 実装順序（TDD）

1. `CompanionApiGeneration` + test
2. `DeviceAddressNormalizer` + test
3. `CompanionAssociationResolver` + test
4. `CompanionDeviceController`（薄い adapter）
5. `BleProcessOwner.associate` / `setDevicePresenceObservation` 配線
6. `BleCentralManager` の暫定エラーを実配線へ置換
7. `DeepskyBluetoothAndroidPlugin` の `ActivityAware` 配線
8. manifest permission 追加
