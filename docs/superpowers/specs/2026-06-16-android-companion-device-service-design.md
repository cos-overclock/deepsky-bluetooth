# Android CompanionDeviceService と presence event 設計（Issue #27）

## 目的

Android の `CompanionDeviceService` が返す device presence callback を、API 世代
（31-32 / 33-35 / 36+）の差分を閉じ込めて単一の内部 event へ正規化し、Flutter engine
（sink）不在でも保持して、復帰した sink へ配送する。あわせて、presence 監視の有効/無効から
再接続駆動源 A（Dart 固定間隔）/ C（CDM presence）の切替判定を提供する。

親 Issue #5、依存: `CompanionDeviceController`（#26）。設計参照: Review guide §§8, 12, 14 /
Implementation plan Task 11。

## スコープ

### 本 PR（#27）に含む

- `DeepskyCompanionDeviceService` で 31-32（`String`）/ 33-35（`AssociationInfo`）/
  36+（`DevicePresenceEvent`）の presence callback を override する
- 3 世代を単一の内部 event `CompanionPresenceEvent(deviceId, appeared)` へ正規化する
- sink 不在時の pending event 保存と、sink 復帰時の owner からの配送を実装する
- presence 監視の有効/無効から再接続駆動源 A/C の切替情報を提供する
- plugin manifest へ `CompanionDeviceService` の `<service>` 宣言を追加する

### 本 PR に含まない（後続 Issue）

- headless `FlutterEngine` の実生成と `initialize(COMPANION_DEVICE)` の受理（#29）。
  `initialize` の `COMPANION_DEVICE` は引き続き未実装エラーのまま据え置く。background
  callback handle の登録は Task 17 に属するため、本 PR では engine を生成しない。
- 再接続状態マシン本体（Task 17）。本 PR は A/C 判定の純粋ロジックのみ提供する。

## 識別子の規約

#26 と同じく正準 DeepskyDeviceId は大文字 MAC `XX:XX:XX:XX:XX:XX`。CDM 由来の
`String address` / `AssociationInfo.deviceMacAddress`（`MacAddress`、`toString()` は小文字）
は `DeviceAddressNormalizer` でこの正準形へ揃える。

## モジュール構成と責務

### 純粋コンポーネント（`core/`、Bluetooth/CDM API 非依存、JVM テスト対象）

**`CompanionPresenceEvent`** — 正規化済み内部 event。`data class(deviceId: String, appeared: Boolean)`。
3 世代すべてがこの型へ収束する（受け入れ条件「同じ内部 event」）。

**`CompanionPresenceNormalizer`** — 世代別の生入力を `CompanionPresenceEvent?` へ正規化する純粋関数群。

- `fromAddress(rawAddress: String?, appeared: Boolean)`: 31-32 の `String` 経路。MAC 正規化。
- `fromAssociation(deviceAddress: String?, associationId: Int?, associations, appeared: Boolean)`:
  33-35 の `AssociationInfo` 経路。`deviceMacAddress` を優先し、無ければ `associationId` を
  `associations` から逆引きして address を得る。
- `fromPresenceEvent(associationId: Int, eventType: Int, associations)`: 36+ の `DevicePresenceEvent`
  経路。`EVENT_BLE_APPEARED`(2)/`EVENT_BLE_DISAPPEARED`(3) を appeared へ写像し、それ以外の
  event type は対象外として `null`。`associationId` を逆引きして address を得る。
- いずれも正規化・解決不能なら `null`（呼び出し側で破棄）。framework 定数値（2/3）は
  公開かつ安定なので、文書化した上で純粋層に持たせ unit test 可能にする。

**`CompanionAssociationResolver`（拡張）** — 既存の `resolveAssociationId` に対する逆引き
`resolveDeviceId(associations, associationId): String?` を追加する。一致 entry の
`deviceAddress` を正規化して返し、無ければ `null`。

**`PendingPresenceBuffer`** — sink 不在時に presence event を保持する有界 FIFO。

- `record(event)`: 末尾へ追加。上限（既定 256、Review guide §12 の handover 上限に合わせる）
  超過時は先頭（最古）を破棄する。
- `drain(): List<CompanionPresenceEvent>`: 保持分を返して空にする（sink 復帰時の flush 用）。
- 受け入れ条件「engine 不在でも event を保持できる」を満たす。

**`ReconnectDriverSelector`** — presence 有効/無効と UI engine 有無から再接続駆動源を選ぶ純粋関数。

- `select(presenceEnabled: Boolean, hasUiEngine: Boolean): ReconnectDriver`
  - `presenceEnabled` → `CDM_PRESENCE`（C）
  - else `hasUiEngine` → `DART_INTERVAL`（A）
  - else（headless かつ presence 無効） → `NONE`（= presence 必須だが不在）
- Review guide §8「関連付け+presence 有効なら C、それ以外は Dart engine 生存中だけ A、
  headless 復活では C 必須」をそのまま純粋判定にする。受け入れ条件「headless 復活時の
  presence 必須判定」を満たす。

### 薄いフレームワーク adapter（実機/platform 検証、§16）

**`DeepskyCompanionDeviceService`** — `CompanionDeviceService` を継承し、3 世代の callback を
override して生プリミティブを抽出し `BleProcessOwner` の受け口へ転送するだけ。正規化・
解決・配送は owner と純粋層が行うので、ここは世代ごとの override と抽出のみに薄く保つ。

override 対象:

- `onDeviceAppeared(address: String)` / `onDeviceDisappeared(address: String)`（31-32、deprecated）
- `onDeviceAppeared(associationInfo: AssociationInfo)` /
  `onDeviceDisappeared(associationInfo: AssociationInfo)`（33-35）
- `onDevicePresenceEvent(event: DevicePresenceEvent)`（36+）

`@Deprecated` / `@SuppressLint("NewApi")` はここに隔離する。

## owner 配線（`BleProcessOwner`）

- 受け口（service から呼ぶ）:
  - `onCompanionDeviceAppeared(rawAddress)` / `onCompanionDeviceDisappeared(rawAddress)`（31-32）
  - `onCompanionAssociationEvent(deviceAddress, associationId, appeared)`（33-35）
  - `onCompanionPresenceEvent(associationId, eventType)`（36+）
- 各受け口は controller の `associationEntries()` 取得 → `CompanionPresenceNormalizer` で
  正規化 → `deliverPresence(event)`。
- `deliverPresence(event)`: sink があれば `sink.onDeviceAppeared/Disappeared(deviceId)` を
  emit（+ `BleNativeObservers.emitCallback`）。無ければ `PendingPresenceBuffer.record`。
- `registerSink` 時に `PendingPresenceBuffer.drain()` を新 sink へ flush する。
- `setDevicePresenceObservation(deviceId, enabled)`: controller 委譲が成功したら presence
  有効 device 集合を更新する（`enabled` で add/remove）。
- `reconnectDriver(deviceId): ReconnectDriver`: presence 有効集合と sink 有無から
  `ReconnectDriverSelector.select` を返す（後続 Task 17 が利用、本 PR では判定提供のみ）。
- `dispose` で pending buffer と presence 有効集合をクリアする。

**`CompanionDeviceController`（拡張）** — `associationEntries(): List<AssociationEntry>` を追加し、
33+ で `cdm.myAssociations` を `AssociationEntry(id, deviceMacAddress?.toString())` へ写す。
31-32 は `AssociationInfo` 非対応のため空リスト（String 経路は逆引き不要）。`@SuppressLint` は
controller 内に隔離する。

## データフロー

```
CompanionDeviceService callback（世代別）
  → BleProcessOwner.onCompanion*（生プリミティブ）
      - controller.associationEntries()
      - CompanionPresenceNormalizer.* → CompanionPresenceEvent?（null は破棄）
      - deliverPresence(event):
          · sink あり → sink.onDeviceAppeared/Disappeared(deviceId)
          · sink なし → PendingPresenceBuffer.record(event)
  （sink 復帰: registerSink → PendingPresenceBuffer.drain() を flush）
```

## エラー・境界の扱い

- 正規化不能（不正 MAC、未解決 associationId、対象外 eventType）は `null` で静かに破棄する。
  presence event は best-effort で、生例外を Flutter へ伝播させない。
- service callback は system プロセス由来で engine 生存を保証しないため、owner は常に
  sink 有無を確認してから配送/保持を選ぶ。

## テスト

### JVM ユニットテスト（純粋ロジック）

- `CompanionPresenceNormalizerTest`:
  - 31-32 `fromAddress`: appeared/disappeared、大小正規化、不正 MAC → null。
  - 33-35 `fromAssociation`: `deviceMacAddress` 優先、null 時 `associationId` 逆引き、
    両方無し → null。
  - 36+ `fromPresenceEvent`: `EVENT_BLE_APPEARED`/`EVENT_BLE_DISAPPEARED` 写像、
    対象外 eventType → null、未関連付け associationId → null。
  - **世代横断同値**: 同一 device に対する 3 経路が等しい `CompanionPresenceEvent` になる
    （受け入れ条件「31-32/33-35/36+ で同じ内部 event」）。
- `PendingPresenceBufferTest`: record/drain の FIFO 順、空 drain、上限超過で最古破棄、
  drain 後の空化（受け入れ条件「engine 不在でも保持」）。
- `ReconnectDriverSelectorTest`: presence 有効 → C、無効+UI engine → A、
  無効+headless → NONE（受け入れ条件「headless 復活時の presence 必須判定」）。
- `CompanionAssociationResolverTest`（拡張）: `resolveDeviceId` の一致/大小無視/未一致/
  null address スキップ。

実 `CompanionDeviceService` 継承・実 CDM 呼び出しは framework 依存のため実機/platform 検証
（§16、Windows ではマージ条件の自動テスト外）。「service callback test が通る」は service が
委譲する純粋正規化・配送ロジックの unit test で満たす。

### manifest

`<application>` 内へ追加:

```xml
<service
    android:name="com.example.deepsky_bluetooth_android.DeepskyCompanionDeviceService"
    android:exported="true"
    android:permission="android.permission.BIND_COMPANION_DEVICE_SERVICE">
    <intent-filter>
        <action android:name="android.companion.CompanionDeviceService" />
    </intent-filter>
</service>
```

CDM 関連 permission / feature は #26 で追加済み。

## 受け入れ条件との対応

- [x] 31-32/33-35/36+ で同じ内部 event になる → `CompanionPresenceNormalizer` + 横断同値テスト
- [x] engine 不在でも event を保持できる → `PendingPresenceBuffer`
- [x] headless 復活時の presence 必須判定が可能 → `ReconnectDriverSelector`
- [x] service callback test が通る → 純粋正規化・配送ロジックの unit test 群

## 実装順序（TDD）

1. `CompanionAssociationResolver.resolveDeviceId` + test
2. `CompanionPresenceEvent` / `CompanionPresenceNormalizer` + test
3. `PendingPresenceBuffer` + test
4. `ReconnectDriverSelector` + test
5. `CompanionDeviceController.associationEntries`（薄い adapter）
6. `BleProcessOwner` の受け口・配送・presence 有効集合・driver 判定
7. `DeepskyCompanionDeviceService`（薄い adapter）
8. manifest `<service>` 追加
