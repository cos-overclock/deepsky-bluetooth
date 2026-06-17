# iOS GATT read/write/notify and strictRead Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the remaining gap for Issue #32 by (1) making a normal characteristic `read()` deliver its value to BOTH the return value and the `values` stream unconditionally, and (2) extracting the GATT operation decision logic into a CoreBluetooth-independent unit covered by Swift XCTest.

**Architecture:** PR #77 (Issue #31) already implemented the GATT operation code in `IosBleProcessOwner`. This plan extracts the pure decision logic (read/write/notify gating, strictRead ambiguity, write-without-response backpressure, read/notify callback routing) into a new pure value-type module `GattOperationDecisions.swift`, adds unit tests for it, then rewires `IosBleProcessOwner` to delegate to those decisions — landing the read→values contract fix in the process.

**Tech Stack:** Swift, CoreBluetooth, XCTest, Flutter Pigeon (`Messages.g.swift`).

## Global Constraints

- **Cannot compile/run Swift on the development host (Windows).** Per review guide §16, macOS XCTest is the merge gate. All "run the test" steps below are verified on CI/macOS, NOT locally. The implementer on Windows writes code to match the documented expectations and relies on CI for green.
- `GattOperationDecisions.swift` MUST NOT `import CoreBluetooth` — it stays pure so it compiles and tests on any platform (mirrors `GattOperationQueue.swift`).
- The contract source of truth is `docs/design/connection-and-gatt-review.md` §10. Review guide overrides spec on conflict (§2).
- Error codes/constructors live in `BleErrorMapping` — do NOT introduce new error strings; reuse `notSupported`, `readAmbiguousWhileNotifying`, `bufferFull`, `failed`.
- Match existing file style: 2-space indentation, Japanese inline comments where they explain contract intent, no `#if os(iOS)` guard on pure files.

---

### Task 1: Pure GATT operation decision logic + unit tests

**Files:**
- Create: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/GattOperationDecisions.swift`
- Test: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Tests/deepsky_bluetooth_iosTests/GattOperationDecisionsTests.swift`

**Interfaces:**
- Consumes: nothing (pure Foundation).
- Produces (consumed by Task 2):
  - `struct CharacteristicCapability { let canRead, canWriteWithResponse, canWriteWithoutResponse, canNotify, canIndicate, isNotifying: Bool }`
  - `enum ReadDecision: Equatable { case proceed, notSupported, ambiguousWhileNotifying }`
  - `enum WriteDecision: Equatable { case proceedWithResponse, proceedWithoutResponse, notSupported, bufferFull }`
  - `enum NotifyDecision: Equatable { case proceed, notSupported }`
  - `enum ReadCallbackRouting: Equatable { case completeReadSuccessThenEmit, completeReadFailure, emitNotify, ignore }`
  - `enum GattOperationDecisions` with statics:
    - `readDecision(strictRead: Bool, capability: CharacteristicCapability) -> ReadDecision`
    - `writeDecision(withResponse: Bool, capability: CharacteristicCapability, canSendWithoutResponse: Bool) -> WriteDecision`
    - `notifyDecision(capability: CharacteristicCapability) -> NotifyDecision`
    - `readCallbackRouting(hasPendingRead: Bool, hasError: Bool) -> ReadCallbackRouting`

- [ ] **Step 1: Write the failing tests**

Create `GattOperationDecisionsTests.swift`:

```swift
import XCTest
@testable import deepsky_bluetooth_ios

final class GattOperationDecisionsTests: XCTestCase {
  private func cap(
    canRead: Bool = false,
    canWriteWithResponse: Bool = false,
    canWriteWithoutResponse: Bool = false,
    canNotify: Bool = false,
    canIndicate: Bool = false,
    isNotifying: Bool = false
  ) -> CharacteristicCapability {
    CharacteristicCapability(
      canRead: canRead,
      canWriteWithResponse: canWriteWithResponse,
      canWriteWithoutResponse: canWriteWithoutResponse,
      canNotify: canNotify,
      canIndicate: canIndicate,
      isNotifying: isNotifying
    )
  }

  // MARK: - readDecision

  func testReadNotSupportedWhenCannotRead() {
    XCTAssertEqual(
      GattOperationDecisions.readDecision(strictRead: false, capability: cap(canRead: false)),
      .notSupported)
  }

  func testReadProceedsWhenReadableAndNotNotifying() {
    XCTAssertEqual(
      GattOperationDecisions.readDecision(strictRead: false, capability: cap(canRead: true)),
      .proceed)
  }

  func testStrictReadAmbiguousWhileNotifying() {
    XCTAssertEqual(
      GattOperationDecisions.readDecision(
        strictRead: true, capability: cap(canRead: true, isNotifying: true)),
      .ambiguousWhileNotifying)
  }

  func testStrictReadProceedsWhenNotNotifying() {
    XCTAssertEqual(
      GattOperationDecisions.readDecision(
        strictRead: true, capability: cap(canRead: true, isNotifying: false)),
      .proceed)
  }

  func testNonStrictReadProceedsWhileNotifying() {
    XCTAssertEqual(
      GattOperationDecisions.readDecision(
        strictRead: false, capability: cap(canRead: true, isNotifying: true)),
      .proceed)
  }

  // MARK: - writeDecision

  func testWriteWithResponseNotSupported() {
    XCTAssertEqual(
      GattOperationDecisions.writeDecision(
        withResponse: true, capability: cap(canWriteWithResponse: false),
        canSendWithoutResponse: true),
      .notSupported)
  }

  func testWriteWithResponseProceeds() {
    XCTAssertEqual(
      GattOperationDecisions.writeDecision(
        withResponse: true, capability: cap(canWriteWithResponse: true),
        canSendWithoutResponse: false),
      .proceedWithResponse)
  }

  func testWriteWithoutResponseNotSupported() {
    XCTAssertEqual(
      GattOperationDecisions.writeDecision(
        withResponse: false, capability: cap(canWriteWithoutResponse: false),
        canSendWithoutResponse: true),
      .notSupported)
  }

  func testWriteWithoutResponseBufferFullWhenCannotSend() {
    XCTAssertEqual(
      GattOperationDecisions.writeDecision(
        withResponse: false, capability: cap(canWriteWithoutResponse: true),
        canSendWithoutResponse: false),
      .bufferFull)
  }

  func testWriteWithoutResponseProceedsWhenCanSend() {
    XCTAssertEqual(
      GattOperationDecisions.writeDecision(
        withResponse: false, capability: cap(canWriteWithoutResponse: true),
        canSendWithoutResponse: true),
      .proceedWithoutResponse)
  }

  // MARK: - notifyDecision

  func testNotifyProceedsWhenNotifySupported() {
    XCTAssertEqual(
      GattOperationDecisions.notifyDecision(capability: cap(canNotify: true)), .proceed)
  }

  func testNotifyProceedsWhenIndicateSupported() {
    XCTAssertEqual(
      GattOperationDecisions.notifyDecision(capability: cap(canIndicate: true)), .proceed)
  }

  func testNotifyNotSupportedWhenNeither() {
    XCTAssertEqual(
      GattOperationDecisions.notifyDecision(capability: cap()), .notSupported)
  }

  // MARK: - readCallbackRouting

  func testRoutingPendingReadSuccessCompletesAndEmits() {
    XCTAssertEqual(
      GattOperationDecisions.readCallbackRouting(hasPendingRead: true, hasError: false),
      .completeReadSuccessThenEmit)
  }

  func testRoutingPendingReadErrorCompletesFailure() {
    XCTAssertEqual(
      GattOperationDecisions.readCallbackRouting(hasPendingRead: true, hasError: true),
      .completeReadFailure)
  }

  func testRoutingNoPendingReadSuccessEmitsNotify() {
    XCTAssertEqual(
      GattOperationDecisions.readCallbackRouting(hasPendingRead: false, hasError: false),
      .emitNotify)
  }

  func testRoutingNoPendingReadErrorIgnored() {
    XCTAssertEqual(
      GattOperationDecisions.readCallbackRouting(hasPendingRead: false, hasError: true),
      .ignore)
  }
}
```

- [ ] **Step 2: Run tests to verify they fail (CI/macOS)**

Run (on macOS): `swift test --filter GattOperationDecisionsTests` from the package dir
`plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios`.
Expected: FAIL — "cannot find 'GattOperationDecisions' / 'CharacteristicCapability' in scope".
(On Windows this cannot run; proceed by code inspection.)

- [ ] **Step 3: Write minimal implementation**

Create `GattOperationDecisions.swift`:

```swift
import Foundation

/// CoreBluetooth 非依存の characteristic 能力スナップショット。
/// CBCharacteristic に依存せずに GATT 操作の判断をテスト可能にする。
struct CharacteristicCapability {
  let canRead: Bool
  let canWriteWithResponse: Bool
  let canWriteWithoutResponse: Bool
  let canNotify: Bool
  let canIndicate: Bool
  let isNotifying: Bool
}

enum ReadDecision: Equatable {
  case proceed
  case notSupported
  case ambiguousWhileNotifying
}

enum WriteDecision: Equatable {
  case proceedWithResponse
  case proceedWithoutResponse
  case notSupported
  case bufferFull
}

enum NotifyDecision: Equatable {
  case proceed
  case notSupported
}

/// didUpdateValueFor characteristic の配送先。
/// CoreBluetooth は read 応答と notify を同じ callback で返すため、
/// pending read の有無と error の有無から配送先を決める。
enum ReadCallbackRouting: Equatable {
  /// pending read 成功: 戻り値を完了し、同じ値を values にも流す（Review guide §10）。
  case completeReadSuccessThenEmit
  /// pending read 失敗: 戻り値を失敗で完了する。
  case completeReadFailure
  /// pending read なしの成功: notify として values に流す。
  case emitNotify
  /// pending read なしの error: 破棄する。
  case ignore
}

enum GattOperationDecisions {
  static func readDecision(
    strictRead: Bool,
    capability: CharacteristicCapability
  ) -> ReadDecision {
    guard capability.canRead else { return .notSupported }
    if strictRead && capability.isNotifying { return .ambiguousWhileNotifying }
    return .proceed
  }

  static func writeDecision(
    withResponse: Bool,
    capability: CharacteristicCapability,
    canSendWithoutResponse: Bool
  ) -> WriteDecision {
    if withResponse {
      return capability.canWriteWithResponse ? .proceedWithResponse : .notSupported
    }
    guard capability.canWriteWithoutResponse else { return .notSupported }
    return canSendWithoutResponse ? .proceedWithoutResponse : .bufferFull
  }

  static func notifyDecision(capability: CharacteristicCapability) -> NotifyDecision {
    (capability.canNotify || capability.canIndicate) ? .proceed : .notSupported
  }

  static func readCallbackRouting(
    hasPendingRead: Bool,
    hasError: Bool
  ) -> ReadCallbackRouting {
    switch (hasPendingRead, hasError) {
    case (true, false): return .completeReadSuccessThenEmit
    case (true, true): return .completeReadFailure
    case (false, false): return .emitNotify
    case (false, true): return .ignore
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass (CI/macOS)**

Run (on macOS): `swift test --filter GattOperationDecisionsTests`
Expected: PASS (17 tests).

- [ ] **Step 5: Commit**

```bash
git add plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/GattOperationDecisions.swift \
        plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Tests/deepsky_bluetooth_iosTests/GattOperationDecisionsTests.swift
git commit -m "feat(ios): add pure GATT operation decision logic for Issue #32"
```

---

### Task 2: Wire decisions into IosBleProcessOwner + read→values contract fix

**Files:**
- Modify: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/IosBleProcessOwner.swift`
  - `readCharacteristic` (currently lines 167-192)
  - `writeCharacteristic` (currently lines 194-229)
  - `setNotify` (currently lines 231-253)
  - `didUpdateValueFor characteristic` delegate (currently lines 539-562)
  - Add private helper `capability(of:)`

**Interfaces:**
- Consumes from Task 1: `CharacteristicCapability`, `GattOperationDecisions.readDecision/writeDecision/notifyDecision/readCallbackRouting`, and the result enums.
- Produces: no new public surface; behavior change only.

- [ ] **Step 1: Add the capability helper**

Add to the "GATT ヘルパー" section of `IosBleProcessOwner.swift` (near `findCharacteristic`):

```swift
  private func capability(of ch: CBCharacteristic) -> CharacteristicCapability {
    CharacteristicCapability(
      canRead: ch.properties.contains(.read),
      canWriteWithResponse: ch.properties.contains(.write),
      canWriteWithoutResponse: ch.properties.contains(.writeWithoutResponse),
      canNotify: ch.properties.contains(.notify),
      canIndicate: ch.properties.contains(.indicate),
      isNotifying: ch.isNotifying
    )
  }
```

- [ ] **Step 2: Rewrite `readCharacteristic` to use `readDecision`**

Replace the body of the `.success(let (peripheral, ch))` case in `readCharacteristic`:

```swift
    case .success(let (peripheral, ch)):
      switch GattOperationDecisions.readDecision(
        strictRead: strictRead, capability: capability(of: ch)) {
      case .notSupported:
        completion(.failure(BleErrorMapping.notSupported("Read not supported")))
        return
      case .ambiguousWhileNotifying:
        completion(.failure(BleErrorMapping.readAmbiguousWhileNotifying()))
        return
      case .proceed:
        break
      }
      let key = charKey(target)
      guard opQueue.enqueue(key: key, deviceId: target.deviceId, epoch: target.connectionEpoch) else {
        completion(.failure(BleErrorMapping.failed("A read for this characteristic is already in flight")))
        return
      }
      readCompletions[key] = completion
      peripheral.readValue(for: ch)
```

- [ ] **Step 3: Rewrite `writeCharacteristic` to use `writeDecision`**

Replace the body of the `.success(let (peripheral, ch))` case in `writeCharacteristic`:

```swift
    case .success(let (peripheral, ch)):
      switch GattOperationDecisions.writeDecision(
        withResponse: withResponse,
        capability: capability(of: ch),
        canSendWithoutResponse: peripheral.canSendWriteWithoutResponse) {
      case .notSupported:
        let message = withResponse
          ? "Write with response not supported"
          : "Write without response not supported"
        completion(.failure(BleErrorMapping.notSupported(message)))
      case .bufferFull:
        completion(.failure(BleErrorMapping.bufferFull()))
      case .proceedWithResponse:
        let key = charKey(target)
        guard opQueue.enqueue(key: key, deviceId: target.deviceId, epoch: target.connectionEpoch) else {
          completion(.failure(BleErrorMapping.failed("A write for this characteristic is already in flight")))
          return
        }
        writeCompletions[key] = completion
        peripheral.writeValue(value.data, for: ch, type: .withResponse)
      case .proceedWithoutResponse:
        peripheral.writeValue(value.data, for: ch, type: .withoutResponse)
        completion(.success(()))
      }
```

- [ ] **Step 4: Rewrite `setNotify` to use `notifyDecision`**

Replace the support-check guard in the `.success` case of `setNotify`:

```swift
    case .success(let (peripheral, ch)):
      let enabled = type != .disable
      switch GattOperationDecisions.notifyDecision(capability: capability(of: ch)) {
      case .notSupported:
        completion(.failure(BleErrorMapping.notSupported("Notify/Indicate not supported")))
        return
      case .proceed:
        break
      }
      let key = charKey(target)
      guard opQueue.enqueue(key: key, deviceId: target.deviceId, epoch: target.connectionEpoch) else {
        completion(.failure(BleErrorMapping.failed("A notify state change for this characteristic is already in flight")))
        return
      }
      notifyCompletions[key] = completion
      peripheral.setNotifyValue(enabled, for: ch)
```

- [ ] **Step 5: Rewrite `didUpdateValueFor characteristic` to use routing (read→values contract fix)**

Replace the whole `func peripheral(_:didUpdateValueFor characteristic:error:)` body:

```swift
  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateValueFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    guard let key = charKey(peripheral, characteristic) else { return }
    let data = characteristic.value ?? Data()
    let hasPendingRead = readCompletions[key] != nil
    switch GattOperationDecisions.readCallbackRouting(
      hasPendingRead: hasPendingRead, hasError: error != nil) {
    case .completeReadSuccessThenEmit:
      _ = opQueue.complete(key: key)
      readCompletions.removeValue(forKey: key)?(.success(FlutterStandardTypedData(bytes: data)))
      // Review guide §10: 通常 read は戻り値完了に加えて同じ値を values にも流す。
      emitCharacteristicValue(peripheral, characteristic, data: data)
    case .completeReadFailure:
      _ = opQueue.complete(key: key)
      readCompletions.removeValue(forKey: key)?(
        .failure(BleErrorMapping.failed(error?.localizedDescription ?? "Read failed")))
    case .emitNotify:
      emitCharacteristicValue(peripheral, characteristic, data: data)
    case .ignore:
      break
    }
  }
```

- [ ] **Step 6: Build + run full Swift test suite (CI/macOS)**

Run (on macOS): `swift build` then `swift test` from
`plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios`.
Expected: builds clean; all tests pass (existing `IosNativeOwnerStateTests` + new `GattOperationDecisionsTests`).
(On Windows: verify by inspection that every replaced symbol — `CharacteristicCapability`, the decision enums/functions, `capability(of:)` — is defined and spelled consistently across Task 1 and Task 2.)

- [ ] **Step 7: Commit**

```bash
git add plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/IosBleProcessOwner.swift
git commit -m "feat(ios): route GATT operations through decision logic and stream read values for Issue #32"
```

---

## Notes for the implementer

- The behavior change visible to consumers is ONLY in Step 5 of Task 2: a successful normal `read()` now ALWAYS emits its value to `values` (previously only when `isNotifying`). This realizes review guide §10 and Issue #32 acceptance criterion "通常read値を戻り値とvaluesの双方へ配送する".
- All other refactors are behavior-preserving — they move inline conditionals into tested pure functions. Confirm the `notSupported` message strings match the originals so no other test/consumer regresses.
- No Pigeon regeneration is needed; no message schema changes.
