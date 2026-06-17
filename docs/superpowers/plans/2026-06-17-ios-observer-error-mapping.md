# iOS Native Observer / Manager-State & CBError Mapping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close Issue #34 by distinguishing `unauthorized`/`poweredOff`/`unsupported` in the iOS Bluetooth-state guard, mapping CoreBluetooth error codes to the common disconnect-reason contract, adding native `os_log` diagnostics, and covering the new mapping with a pure-logic XCTest suite.

**Architecture:** Extract a CoreBluetooth-free `ManagerStateMapping` enum (mirroring the `GattOperationDecisions`/`RestorationDecisions` pattern) that owns the manager-state and CB-error contract decisions and is XCTest-covered cross-platform. Add a thin `BleDiagnostics` `os_log` wrapper. Rewire `IosBleProcessOwner` to delegate to the pure mapping and emit diagnostics. Plugin/Pigeon wiring is already complete and unchanged.

**Tech Stack:** Swift, CoreBluetooth, os.log (`OSLog`), XCTest, Flutter Pigeon (`Messages.g.swift`).

## Global Constraints

- **Swift cannot be compiled/run on the Windows dev host; no in-repo CI.** Per review guide §16, macOS XCTest is the merge gate; the Windows gate is `dart analyze`. "Run the test" steps are verified on macOS, by inspection on Windows.
- Pure decision modules MUST NOT `import CoreBluetooth` (so they compile/test on any platform). `ManagerStateMapping.swift` is plain Foundation, no `#if os(iOS)` guard — mirrors `GattOperationDecisions.swift`/`RestorationDecisions.swift`.
- **No Pigeon schema change.** Public `AdapterStateMessage` stays `poweredOn`/`poweredOff`/`unavailable`. Generated files (`Messages.g.swift`, `messages.g.dart`) are gitignored — do not edit them.
- Canonical error-code strings live in `packages/deepsky_bluetooth_util/lib/src/error_codes.dart` (`permissionDenied`, `bluetoothOff`, `bluetoothUnavailable` already exist). Swift `BleErrorCode` constants must keep these exact values.
- File style: 2-space indentation, Japanese inline comments for contract intent.
- `os.log` `OSLog` API (not the iOS 14+ `Logger` struct) so the iOS 13 deployment floor needs no `@available` guards. `BleDiagnostics.swift` is `#if os(iOS)`-guarded (owner-only, never tested).

## Acceptance Criteria (Issue #34)

- [ ] `unauthorized`/`poweredOff`/`unsupported` are distinguished.
- [ ] `didFailToConnect` maps to `connectFailed`.
- [ ] macOS: Swift build + XCTest pass.
- [ ] Windows: `dart analyze` passes.

## File Structure

- Create: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/ManagerStateMapping.swift` — pure manager-state/CB-error → contract mapping.
- Create: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Tests/deepsky_bluetooth_iosTests/ManagerStateMappingTests.swift` — XCTest for the above.
- Create: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/BleDiagnostics.swift` — `os_log` wrapper.
- Modify: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/BleErrorMapping.swift` — add `permissionDenied` code + factory.
- Modify: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/IosBleProcessOwner.swift` — delegate to `ManagerStateMapping`, route disconnect reasons, emit diagnostics.

---

### Task 1: Pure manager-state / CB-error mapping + error constant + tests

**Files:**
- Modify: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/BleErrorMapping.swift`
- Create: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/ManagerStateMapping.swift`
- Test: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Tests/deepsky_bluetooth_iosTests/ManagerStateMappingTests.swift`

**Interfaces:**
- Consumes: `AdapterStateMessage`, `DisconnectReasonMessage` (Messages.g.swift); `BleErrorCode` (BleErrorMapping.swift).
- Produces (consumed by Task 3):
  - `enum BleManagerState { unknown, resetting, unsupported, unauthorized, poweredOff, poweredOn }`
  - `enum BleConnectionFailure { none, timeout, peripheralDisconnected, connectionFailed, limitReached, other }`
  - `ManagerStateMapping.adapterState(for: BleManagerState) -> AdapterStateMessage`
  - `ManagerStateMapping.connectGuardError(for: BleManagerState) -> (code: String, message: String)?`
  - `ManagerStateMapping.disconnectReason(for: BleConnectionFailure) -> DisconnectReasonMessage`
  - `BleErrorCode.permissionDenied` (String); `BleErrorMapping.permissionDenied() -> PigeonError`

- [ ] **Step 1: Add the `permissionDenied` error constant + factory.**

In `BleErrorMapping.swift`, add to `enum BleErrorCode` (after `bluetoothUnavailable` on line 5):

```swift
  static let permissionDenied = "permissionDenied"
```

and add to `enum BleErrorMapping` (after the `bluetoothUnavailable` factory):

```swift
  static func permissionDenied(_ message: String = "Bluetooth permission denied") -> PigeonError {
    bleError(BleErrorCode.permissionDenied, message)
  }
```

- [ ] **Step 2: Write the failing tests** (`ManagerStateMappingTests.swift`):

```swift
import XCTest
@testable import deepsky_bluetooth_ios

final class ManagerStateMappingTests: XCTestCase {
  // MARK: - adapterState

  func testAdapterStatePoweredOn() {
    XCTAssertEqual(ManagerStateMapping.adapterState(for: .poweredOn), .poweredOn)
  }

  func testAdapterStatePoweredOff() {
    XCTAssertEqual(ManagerStateMapping.adapterState(for: .poweredOff), .poweredOff)
  }

  func testAdapterStateUnsupportedUnauthorizedUnknownAreUnavailable() {
    for state: BleManagerState in [.unsupported, .unauthorized, .unknown, .resetting] {
      XCTAssertEqual(ManagerStateMapping.adapterState(for: state), .unavailable)
    }
  }

  // MARK: - connectGuardError distinguishes the three states

  func testGuardPoweredOnAllowsProceed() {
    XCTAssertNil(ManagerStateMapping.connectGuardError(for: .poweredOn))
  }

  func testGuardPoweredOffIsBluetoothOff() {
    XCTAssertEqual(ManagerStateMapping.connectGuardError(for: .poweredOff)?.code,
                   BleErrorCode.bluetoothOff)
  }

  func testGuardUnauthorizedIsPermissionDenied() {
    XCTAssertEqual(ManagerStateMapping.connectGuardError(for: .unauthorized)?.code,
                   BleErrorCode.permissionDenied)
  }

  func testGuardUnsupportedIsBluetoothUnavailable() {
    XCTAssertEqual(ManagerStateMapping.connectGuardError(for: .unsupported)?.code,
                   BleErrorCode.bluetoothUnavailable)
  }

  func testGuardUnknownAndResettingAreBluetoothUnavailable() {
    XCTAssertEqual(ManagerStateMapping.connectGuardError(for: .unknown)?.code,
                   BleErrorCode.bluetoothUnavailable)
    XCTAssertEqual(ManagerStateMapping.connectGuardError(for: .resetting)?.code,
                   BleErrorCode.bluetoothUnavailable)
  }

  func testGuardThreeStatesAreDistinct() {
    let off = ManagerStateMapping.connectGuardError(for: .poweredOff)?.code
    let unauth = ManagerStateMapping.connectGuardError(for: .unauthorized)?.code
    let unsup = ManagerStateMapping.connectGuardError(for: .unsupported)?.code
    XCTAssertEqual(Set([off, unauth, unsup]).count, 3)
  }

  // MARK: - disconnectReason from CB error kind

  func testDisconnectReasonNoneIsUserRequested() {
    XCTAssertEqual(ManagerStateMapping.disconnectReason(for: .none), .userRequested)
  }

  func testDisconnectReasonTransientKindsAreConnectionLost() {
    for kind: BleConnectionFailure in [.timeout, .peripheralDisconnected, .limitReached] {
      XCTAssertEqual(ManagerStateMapping.disconnectReason(for: kind), .connectionLost)
    }
  }

  func testDisconnectReasonConnectionFailedIsConnectFailed() {
    XCTAssertEqual(ManagerStateMapping.disconnectReason(for: .connectionFailed), .connectFailed)
  }

  func testDisconnectReasonOtherIsUnknown() {
    XCTAssertEqual(ManagerStateMapping.disconnectReason(for: .other), .unknown)
  }
}
```

- [ ] **Step 3: Run tests to verify they fail (macOS):**

Run: `swift test --filter ManagerStateMappingTests`
Expected: FAIL — `ManagerStateMapping` / `BleManagerState` not in scope. (Windows: by inspection.)

- [ ] **Step 4: Write `ManagerStateMapping.swift`:**

```swift
import Foundation

/// CoreBluetooth 非依存の central manager 状態。
/// CBManagerState に依存せず adapter state と接続ガードの判断をテスト可能にする。
enum BleManagerState {
  case unknown
  case resetting
  case unsupported
  case unauthorized
  case poweredOff
  case poweredOn
}

/// CoreBluetooth 非依存の接続失敗種別。
/// owner が CBError.Code から変換し、純粋ロジックで reason を決める。
enum BleConnectionFailure {
  case none
  case timeout
  case peripheralDisconnected
  case connectionFailed
  case limitReached
  case other
}

enum ManagerStateMapping {
  /// 公開 adapter state は poweredOn / poweredOff / unavailable の3値へ縮約する。
  static func adapterState(for state: BleManagerState) -> AdapterStateMessage {
    switch state {
    case .poweredOn:
      return .poweredOn
    case .poweredOff:
      return .poweredOff
    case .unknown, .resetting, .unsupported, .unauthorized:
      return .unavailable
    }
  }

  /// connect / scan 実行前のガード。unauthorized / poweredOff / unsupported を区別する。
  /// poweredOn のときだけ nil（続行可）を返す。
  static func connectGuardError(for state: BleManagerState) -> (code: String, message: String)? {
    switch state {
    case .poweredOn:
      return nil
    case .poweredOff:
      return (BleErrorCode.bluetoothOff, "Bluetooth is off")
    case .unauthorized:
      return (BleErrorCode.permissionDenied, "Bluetooth permission denied")
    case .unsupported:
      return (BleErrorCode.bluetoothUnavailable, "Bluetooth LE unavailable")
    case .unknown, .resetting:
      return (BleErrorCode.bluetoothUnavailable, "Bluetooth is not ready")
    }
  }

  /// 切断 reason を CB error 種別から決める。圏外・切断は終端理由へ縮退させない（§6）。
  static func disconnectReason(for failure: BleConnectionFailure) -> DisconnectReasonMessage {
    switch failure {
    case .none:
      return .userRequested
    case .timeout, .peripheralDisconnected, .limitReached:
      return .connectionLost
    case .connectionFailed:
      return .connectFailed
    case .other:
      return .unknown
    }
  }
}
```

- [ ] **Step 5: Run tests to verify they pass (macOS):**

Run: `swift test --filter ManagerStateMappingTests`
Expected: PASS (all 13 tests). (Windows: by inspection.)

- [ ] **Step 6: Commit:**

```bash
git add plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/BleErrorMapping.swift \
        plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/ManagerStateMapping.swift \
        plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Tests/deepsky_bluetooth_iosTests/ManagerStateMappingTests.swift
git commit -m "feat(ios): add pure manager-state and CB-error mapping for Issue #34"
```

---

### Task 2: Native os_log diagnostics wrapper

**Files:**
- Create: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/BleDiagnostics.swift`

**Interfaces:**
- Produces (consumed by Task 3): `final class BleDiagnostics` with `static let subsystem = "com.deepsky.bluetooth"` and instance methods:
  - `adapterState(_ state: String)`
  - `connection(deviceId: String, epoch: Int64?, state: String, reason: String?)`
  - `operation(_ kind: String, deviceId: String, epoch: Int64, phase: String)`
  - `handle(deviceId: String, epoch: Int64, handle: Int64, attribute: String)`
  - `restore(deviceIds: [String])`
  - `sinkHandover(engineToken: String, phase: String)`

This is a thin side-effecting wrapper; it is `#if os(iOS)`-guarded and not unit-tested (logging has no observable return). Its only contract is the stable `subsystem`/category strings.

- [ ] **Step 1: Write `BleDiagnostics.swift`:**

```swift
#if os(iOS)
import Foundation
import os

/// CoreBluetooth native owner の診断を os_log へ出力する薄い wrapper。
/// Dart の DeepskyBluetoothIosObserver と同じ診断ポイント（CB state、epoch、
/// queue、handle、restore、sink handover）を Console.app から観測できるようにする。
final class BleDiagnostics {
  static let subsystem = "com.deepsky.bluetooth"

  private let owner = OSLog(subsystem: BleDiagnostics.subsystem, category: "owner")
  private let queue = OSLog(subsystem: BleDiagnostics.subsystem, category: "queue")
  private let handleLog = OSLog(subsystem: BleDiagnostics.subsystem, category: "handle")
  private let restoreLog = OSLog(subsystem: BleDiagnostics.subsystem, category: "restoration")
  private let sink = OSLog(subsystem: BleDiagnostics.subsystem, category: "sink")

  func adapterState(_ state: String) {
    os_log("adapter state -> %{public}@", log: owner, type: .info, state)
  }

  func connection(deviceId: String, epoch: Int64?, state: String, reason: String?) {
    os_log("connection %{public}@ epoch=%{public}@ -> %{public}@ reason=%{public}@",
           log: owner, type: .info,
           deviceId, epoch.map(String.init) ?? "nil", state, reason ?? "nil")
  }

  func operation(_ kind: String, deviceId: String, epoch: Int64, phase: String) {
    os_log("op %{public}@ %{public}@ epoch=%{public}d %{public}@",
           log: queue, type: .debug, kind, deviceId, epoch, phase)
  }

  func handle(deviceId: String, epoch: Int64, handle: Int64, attribute: String) {
    os_log("handle %{public}@ epoch=%{public}d %{public}@=%{public}d",
           log: handleLog, type: .debug, deviceId, epoch, attribute, handle)
  }

  func restore(deviceIds: [String]) {
    os_log("willRestoreState devices=%{public}@",
           log: restoreLog, type: .info, deviceIds.joined(separator: ","))
  }

  func sinkHandover(engineToken: String, phase: String) {
    os_log("sink handover %{public}@ %{public}@",
           log: sink, type: .info, engineToken, phase)
  }
}
#endif
```

- [ ] **Step 2: Verify it builds (macOS):**

Run: `swift build`
Expected: builds (the file compiles out entirely off-iOS via `#if os(iOS)`; on iOS it compiles against `os`). (Windows: by inspection — balanced `#if`/`#endif`, `os_log` format specifiers match argument arity.)

- [ ] **Step 3: Commit:**

```bash
git add plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/BleDiagnostics.swift
git commit -m "feat(ios): add os_log diagnostics wrapper for Issue #34"
```

---

### Task 3: Wire mapping + diagnostics into IosBleProcessOwner

**Files:**
- Modify: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/IosBleProcessOwner.swift`

**Interfaces:**
- Consumes: everything Produced by Tasks 1 and 2.

- [ ] **Step 1: Add the diagnostics instance + CoreBluetooth adapters.**

After the `restorationBuffer` property (line 20), add:

```swift
  private let diagnostics = BleDiagnostics()
```

At the end of the file but still inside the `#if os(iOS)` block (just before the final `}` of the class, alongside the other private helpers), add the two CoreBluetooth → pure-enum adapters:

```swift
  private func bleManagerState(_ state: CBManagerState) -> BleManagerState {
    switch state {
    case .poweredOn: return .poweredOn
    case .poweredOff: return .poweredOff
    case .unsupported: return .unsupported
    case .unauthorized: return .unauthorized
    case .resetting: return .resetting
    case .unknown: return .unknown
    @unknown default: return .unknown
    }
  }

  private func connectionFailure(from error: Error?) -> BleConnectionFailure {
    guard let error else { return .none }
    guard let cbError = error as? CBError else { return .other }
    switch cbError.code {
    case .connectionTimeout: return .timeout
    case .peripheralDisconnected: return .peripheralDisconnected
    case .connectionFailed: return .connectionFailed
    case .connectionLimitReached: return .limitReached
    default: return .other
    }
  }
```

- [ ] **Step 2: Replace `adapterState(from:)` to delegate to the pure mapping.**

Replace the whole body of `adapterState(from:)` (currently lines 1008-1021):

```swift
  private func adapterState(from state: CBManagerState) -> AdapterStateMessage {
    ManagerStateMapping.adapterState(for: bleManagerState(state))
  }
```

- [ ] **Step 3: Replace the grouped state branches in `poweredOnCentral()`.**

Replace the `switch central.state { … }` block (currently lines 909-920) with:

```swift
    if central.state == .poweredOn {
      return central
    }
    if let guardError = ManagerStateMapping.connectGuardError(for: bleManagerState(central.state)) {
      throw bleError(guardError.code, guardError.message)
    }
    return central
```

- [ ] **Step 4: Route `didFailToConnect` and `didDisconnect` reasons + diagnostics.**

In `centralManager(_:didFailToConnect:error:)`, keep `reason: .connectFailed` (a never-established attempt is always `connectFailed`), and add a diagnostics call immediately before the `emitConnectionState(...)` call:

```swift
    diagnostics.connection(deviceId: deviceId, epoch: epoch, state: "disconnected",
                           reason: "connectFailed")
```

In `centralManager(_:didDisconnectPeripheral:error:)`, replace the existing emit (currently lines 492-497):

```swift
    let reason = ManagerStateMapping.disconnectReason(for: connectionFailure(from: error))
    diagnostics.connection(deviceId: deviceId, epoch: epoch, state: "disconnected",
                           reason: "\(reason)")
    emitConnectionState(
      deviceId: deviceId,
      epoch: epoch,
      state: .disconnected,
      reason: reason
    )
```

- [ ] **Step 5: Add the remaining diagnostic call sites.**

In `centralManagerDidUpdateState(_:)`, after `emitAdapterState(adapterState)` (line 381), add:

```swift
    diagnostics.adapterState("\(adapterState)")
```

In `centralManager(_:willRestoreState:)`, after `restoredDeviceIds = restored.map(\.identifier.uuidString)` (line 399), add:

```swift
    diagnostics.restore(deviceIds: restoredDeviceIds)
```

In `registerSink(engineToken:callbacks:)` (line 47) add as the first line of the body:

```swift
    diagnostics.sinkHandover(engineToken: engineToken, phase: "register")
```

In `unregisterSink(engineToken:)` (line 51) add as the first line of the body:

```swift
    diagnostics.sinkHandover(engineToken: engineToken, phase: "unregister")
```

- [ ] **Step 6: Build + full suite (macOS):**

Run: `swift build` then `swift test`
Expected: build succeeds; all suites pass (`ManagerStateMappingTests`, `GattOperationDecisionsTests`, `IosNativeOwnerStateTests`, `RestorationDecisionsTests`). (Windows: inspect symbol consistency — `bleManagerState`/`connectionFailure` cover every `CBManagerState`/`CBError.Code` case used; `bleError` already exists in BleErrorMapping.swift; `diagnostics` is in scope.)

- [ ] **Step 7: Commit:**

```bash
git add plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/IosBleProcessOwner.swift
git commit -m "feat(ios): route manager-state/CB-error mapping and diagnostics through owner for Issue #34"
```

---

### Task 4: Windows gate — Dart analyze

**Files:** none (verification task).

- [ ] **Step 1: Run the Dart analyzer at the repo root.**

Run: `dart analyze`
Expected: `No issues found!` (the iOS plugin's Dart surface — `observer.dart`, generated `messages.g.dart` — is unchanged; this confirms nothing regressed). If the workspace requires `flutter pub get` first, run it, then re-run analyze.

- [ ] **Step 2 (no commit):** This task produces no code; it gates the PR.

---

## Self-Review notes

- **Spec coverage:** unauthorized/poweredOff/unsupported distinction → Task 1 `connectGuardError` + Task 3 Step 3. `didFailToConnect → connectFailed` → Task 3 Step 4 (unchanged reason). os_log/native observer → Task 2 + Task 3 Step 5. CBError→reason → Task 1 `disconnectReason` + Task 3 Step 1/Step 4. XCTest → Task 1. macOS build → Task 3 Step 6. dart analyze → Task 4.
- **Type consistency:** `BleManagerState`/`BleConnectionFailure`/`ManagerStateMapping` symbols and the `connectGuardError`/`disconnectReason`/`adapterState` signatures are identical across Tasks 1 and 3. `BleErrorCode.permissionDenied` defined in Task 1, used in Task 1's `connectGuardError`. `diagnostics` property name consistent across Task 3 steps.
- **No Pigeon change:** all enum cases used (`AdapterStateMessage.poweredOn/.poweredOff/.unavailable`, `DisconnectReasonMessage.userRequested/.connectionLost/.connectFailed/.unknown`) exist in the current `Messages.g.swift`.
