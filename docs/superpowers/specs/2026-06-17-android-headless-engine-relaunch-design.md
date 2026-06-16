# Android headless engine 復活設計（Issue #28）

## 目的

process 死後にシステムから起動された `CompanionDeviceService`、または Foreground Service
稼働中の UI engine 消失をトリガに、アプリが登録した専用 `@pragma('vm:entry-point')`
バックグラウンドエントリポイントを **headless `FlutterEngine`** で実行して Dart を復活させる。
`main()` / `runApp()` は実行しない（Activity 依存 plugin のクラッシュ・二重 `runApp` レースを
回避。Review guide §12）。native BLE 状態はプロセスグローバル owner（`BleProcessOwner`）が
保持し、engine には紐付けない。

親 Issue #5、依存: `DeepskyCompanionDeviceService`（#27）/ Foreground Service（#25）。
設計参照: Review guide §12 / Implementation plan Task 11 Step 1。

## スコープ

### 本 PR（#28）に含む

- background callback handle の `SharedPreferences` 永続化と読み出し
- `FlutterCallbackInformation.lookupCallbackInformation` + `executeDartCallback` による
  専用エントリポイント実行（`executeDartEntrypoint` / `main()` を使わない）
- headless engine lifecycle の純粋状態機械（UI engine 在席 / headless 生存の遷移）
- callback 未登録時の headless 非起動 + observer 警告（fallback/warning）
- `initialize()` での handle 永続化と `COMPANION_DEVICE` strategy の受理（#27 までの
  未実装エラーを解消）
- `DeepskyCompanionDeviceService` の各 callback から headless 復活を起動する配線
- plugin の engine attach/detach・Activity attach を lifecycle 状態機械へ配線する

### 本 PR に含まない（後続 Issue）

- active/candidate sink の切替・state snapshot 送信・ack 後の旧 engine 破棄本体（#29）。
  本 PR は破棄の **機構**（`onUiHandoverAcknowledged`）のみ提供し、その **発火**（ack 経路）は
  #29 で配線する。`BleCentralManager.ackStateResync` は引き続きスタブ。
- 再接続状態マシン本体（Task 17）。background handle を Dart 側から登録する
  `DeepskyBluetooth.background(onBackgroundRelaunch:)` も Task 17。本 PR は handle の
  **受け口**（`initialize` 経由の永続化）のみ。

## モジュール構成と責務

### 純粋コンポーネント（`core/`、Flutter/Android API 非依存、JVM テスト対象）

**`HeadlessLifecycleState`** — process グローバルな headless engine lifecycle の状態機械。
`ForegroundServiceState` と同型の `internal object`。2 フラグ `hasUiEngine` / `headlessAlive`
を持ち、起動・破棄の **判定** をすべてここが行う（launcher は副作用の実行のみ）。
受け入れ条件「launcher lifecycle test が通る」の対象。

- `shouldStartHeadless(handleRegistered: Boolean): Boolean`
  → `handleRegistered && !hasUiEngine && !headlessAlive`。
  handle 未登録・UI engine 在席・headless 既存のいずれでも `false`
  （受け入れ条件「callback 未登録時に headless 起動しない」）。
- `onHeadlessStarted()`: engine が実際に生成できた後にだけ呼び `headlessAlive = true`。
- `onUiEngineCandidateAttached()`: `hasUiEngine = true`。UI engine 在席中は headless を
  破棄しない（破棄は ack 後のみ）。
- `onUiHandoverAcknowledged(): Boolean`: headless 生存なら `false` 化して `true` を返す
  （#29 が発火する破棄機構）。
- `onEngineDetached(isHeadless, fgsRunning, handleRegistered): Boolean`:
  headless 自身の detach は `headlessAlive=false` にして `false`。UI engine detach は
  `hasUiEngine=false` にし、`fgsRunning && handleRegistered && !headlessAlive` のとき
  `true`（= 復活を要する）を返す。
- `resetForTest()`。

framework 非依存なので、全遷移を local JVM test で検証できる（Review guide §16）。

### 薄いフレームワーク shell（実機/platform 検証、§16）

**`HeadlessEngineLauncher`** — `FlutterEngine` と `SharedPreferences` を触る唯一の層。
判定は `HeadlessLifecycleState` に委譲し、ここは永続化と engine 生成/破棄の glue に薄く保つ。

- 定数: `PREFS = "deepsky_bluetooth"`、`KEY = "background_relaunch_handle"`、`NO_HANDLE = -1L`。
- `storeBackgroundHandle(context, handle: Long)`: `SharedPreferences` へ永続化する
  （process 跨ぎで復活できるよう commit は `apply()`）。
- `ensureEngine(context)`（`@Synchronized`）:
  1. handle を読み出す。`shouldStartHeadless(handle != NO_HANDLE)` が `false` なら return。
     handle 未登録時は `BleNativeObservers.emitCallback("headless.relaunchSkipped", …)` で
     警告してから return（fallback/warning）。
  2. `FlutterLoader` を初期化（未初期化なら `startInitialization` →
     `ensureInitializationComplete`）。
  3. `FlutterCallbackInformation.lookupCallbackInformation(handle)` が `null`（handle が
     無効化）なら警告して return（状態は変えない）。
  4. `FlutterEngine(appContext)` を生成し、
     `dartExecutor.executeDartCallback(DartCallback(assets, findAppBundlePath(), cb))` を実行。
     **`executeDartEntrypoint` / `main()` は呼ばない。**
  5. 生成した engine を保持し `HeadlessLifecycleState.onHeadlessStarted()`。
- `onUiEngineCandidateAttached()`: 状態機械へ委譲。
- `onUiHandoverAcknowledged()`: 状態機械が `true` を返したら headless engine を `destroy()`
  して参照を手放す（#29 が発火）。
- `onEngineDetached(context, isHeadless: Boolean)`: 状態機械へ委譲し、`true`（復活要）なら
  `ensureEngine(context)` を呼ぶ。

`FlutterEngine` 生成・`SharedPreferences`・`FlutterLoader` は framework 依存のため実機/
platform 検証。lifecycle の判定ロジックは `HeadlessLifecycleState` の JVM test が担保する。

## 配線

### `BleCentralManager.initialize`

- `request.backgroundCallbackHandle != null` のとき
  `HeadlessEngineLauncher.storeBackgroundHandle(context, handle)` で永続化する。
- `COMPANION_DEVICE` strategy: 従来の未実装 `throw` をやめ、`BleProcessOwner.attach(context)`
  まで（presence 監視は `associate` 起点で別途有効化される。init では監視を自動開始しない。
  Review guide §8）。`FOREGROUND_SERVICE` 経路は #25 のまま。
- `null` strategy（background 指定だが strategy 無し）は従来どおり
  `BACKGROUND_CONFIG_MISSING`。

### `DeepskyCompanionDeviceService`

6 つの callback（31-32 / 33-35 / 36+ の appeared/disappeared）それぞれで、既存の
`BleProcessOwner.ensureAttached(applicationContext)` の直後に
`HeadlessEngineLauncher.ensureEngine(applicationContext)` を呼ぶ。これが process 死後の
復活トリガ（受け入れ条件「process 死後も保存 handle から復活できる」）。

### `DeepskyBluetoothAndroidPlugin`

- `onAttachedToActivity`（`bindActivity`）→ `HeadlessEngineLauncher.onUiEngineCandidateAttached()`。
  headless engine の plugin instance は Activity に attach しないため、これで UI engine を識別する。
- 各 plugin instance に `wasUiEngine: Boolean` を持ち、Activity attach 時に `true` にする。
- `onDetachedFromEngine` → `HeadlessEngineLauncher.onEngineDetached(context, isHeadless = !wasUiEngine)`。

## データフロー

```
[復活トリガ 1] CDS callback（process 死後にシステム起動）
  → BleProcessOwner.ensureAttached(ctx)
  → HeadlessEngineLauncher.ensureEngine(ctx)
[復活トリガ 2] UI engine detach かつ FGS 稼働中
  → plugin.onDetachedFromEngine
  → HeadlessEngineLauncher.onEngineDetached(ctx, isHeadless=false)
  → 状態機械が true → ensureEngine(ctx)

ensureEngine:
  handle 読み出し → shouldStartHeadless?
    no（未登録/UI 在席/既存）→ 未登録なら警告して return
    yes → FlutterLoader 初期化 → lookupCallbackInformation
           → null なら警告 return
           → FlutterEngine 生成 → executeDartCallback（main 不使用）
           → onHeadlessStarted()
```

## エラー・境界の扱い

- handle 未登録（`-1`）/ `lookupCallbackInformation` が `null`: headless を起動せず observer
  へ警告のみ。UI 復帰時に通常経路で再接続するため致命ではない。
- `ensureEngine` は CDS スレッド・plugin detach・FGS 経路から並行に呼ばれ得るため
  `@Synchronized`。状態機械も `@Synchronized` で二重起動・破棄競合を防ぐ。
- UI engine 在席中・ack 前は headless を破棄しない（active sink を常に 1 つに保つ前段。
  本体は #29）。

## テスト

### JVM ユニットテスト（純粋ロジック）

`HeadlessLifecycleStateTest`（`@AfterTest` で `resetForTest`）:

- `shouldStartHeadless`: 未登録 → false（「callback 未登録時に headless 起動しない」）、
  登録済み + engine 無し → true、UI engine 在席 → false、headless 既存 → false。
- `onHeadlessStarted` 後は再度の `shouldStartHeadless` が false（二重起動しない）。
- `onUiEngineCandidateAttached` 後は `shouldStartHeadless` が false。
- `onUiHandoverAcknowledged`: 生存時 true（破棄要）/ 非生存時 false。
- `onEngineDetached`:
  - `isHeadless=true` → `headlessAlive=false`、戻り値 false。
  - UI detach × `fgsRunning` × `handleRegistered` × `headlessAlive` の真理値表
    （復活要は `fgsRunning && handleRegistered && !headlessAlive` のときだけ true）。

実 `FlutterEngine` 生成・`executeDartCallback`・`SharedPreferences` 永続化は framework
依存のため実機/platform 検証（§16、Windows ではマージ条件の自動テスト外）。「launcher
lifecycle test が通る」は `HeadlessLifecycleState` の遷移 unit test で満たす。

### manifest

CDS の `<service>` 宣言・CDM permission は #26/#27 で追加済み。本 PR で manifest 変更は無い。

## 受け入れ条件との対応

- [x] `main()` / `runApp()` を実行しない → `executeDartCallback`（`executeDartEntrypoint` 不使用）
- [x] process 死後も保存 handle から復活できる → `SharedPreferences` 永続化 + CDS からの
  `ensureEngine`
- [x] callback 未登録時に headless 起動しない → `shouldStartHeadless(handleRegistered=false)`
  → false + 警告
- [x] launcher lifecycle test が通る → `HeadlessLifecycleStateTest` の遷移網羅

## 実装順序（TDD）

1. `core/HeadlessLifecycleState` + `HeadlessLifecycleStateTest`
2. `HeadlessEngineLauncher`（薄い shell、状態機械へ委譲）
3. `DeepskyCompanionDeviceService` に `ensureEngine` 配線
4. `DeepskyBluetoothAndroidPlugin` に UI engine 識別・detach 配線
5. `BleCentralManager.initialize` で handle 永続化と `COMPANION_DEVICE` 受理
