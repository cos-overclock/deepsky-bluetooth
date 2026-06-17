# iOS State Restoration Full Snapshot + Event Ordering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close Issue #33 by making iOS State Restoration deliver a complete snapshot (GATT tree + active notify handles + disconnect reason) instead of degrading to a device-ID list, and by preserving event order across the snapshot/ack boundary (restored-device delegate events flush *after* the snapshot is acked).

**Architecture:** PR #77/#78 (Issues #31/#32) already implemented connection + GATT operations in `IosBleProcessOwner`, with `centralManager(_:willRestoreState:)` restoring the peripheral delegate, assigning a fresh epoch, and recording the device's lifecycle state. Today the resync that follows (`emitStateResync`) sends `services: nil` / `activeNotifyHandles: []` / `disconnectReason: nil`, and `onRestoredConnections` fires inside `notifyDartReady` *before* the ack — so the restoration contract degrades to device IDs and offers no ordering guarantee. This plan extracts the pure restoration logic (disconnect-reason mapping, notify-handle selection, in-flight event buffering) into a new CoreBluetooth-independent module `RestorationDecisions.swift` covered by XCTest, then rewires `IosBleProcessOwner` to (1) rebuild and store the restored GATT tree + active notify handles, (2) emit full restoration snapshots, and (3) buffer delegate events during the restoration window and flush them in order after the ack.

**Tech Stack:** Swift, CoreBluetooth, XCTest, Flutter Pigeon (`Messages.g.swift`).

## Global Constraints

- **Cannot compile/run Swift on the development host (Windows), and there is no in-repo CI workflow.** Per review guide §16, macOS XCTest is the merge gate. All "run the test" steps below are verified on macOS, NOT locally. On Windows the implementer writes code to match documented expectations and relies on macOS review for green.
- `RestorationDecisions.swift` MUST NOT `import CoreBluetooth` — it stays pure Foundation so it compiles and tests on any platform (mirrors `GattOperationQueue.swift` / `GattOperationDecisions.swift`).
- The contract source of truth is `docs/design/connection-and-gatt-review.md` §13 (and §10/§12 for sink ordering). Review guide overrides spec on conflict (§2).
- Reuse existing Pigeon message types (`StateSnapshotMessage`, `StateResyncMessage`, `ServiceMessage`) and `DisconnectReasonMessage`. **No Pigeon regeneration / schema change.**
- Match existing file style: 2-space indentation, Japanese inline comments where they explain contract intent, no `#if os(iOS)` guard on pure files.

## Acceptance Criteria (from Issue #33)

- [ ] 復元契約をdevice ID一覧へ縮退させない — resync carries the rebuilt GATT tree + active notify handles for restored devices.
- [ ] disconnected snapshotがreasonを持つ — every snapshot whose state is `.disconnected` carries a non-nil `disconnectReason`.
- [ ] snapshot/ack前後のevent順序を維持する — delegate events arriving during restoration are buffered and flushed (in arrival order) only after `onStateResync` → ack → `onRestoredConnections`.
- [ ] restoration fixture testが通る — `RestorationDecisionsTests` exercises the pure logic.

---

### Task 1: Pure restoration decision logic + unit tests

**Files:**
- Create: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/RestorationDecisions.swift`
- Test: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Tests/deepsky_bluetooth_iosTests/RestorationDecisionsTests.swift`

**Interfaces produced (consumed by Task 2):**
- `enum RestorationDecisions` statics:
  - `disconnectReason(for state: ConnectionStateMessage) -> DisconnectReasonMessage?` → `.unknown` when `.disconnected`, else `nil`.
  - `activeNotifyHandles(from entries: [(handle: Int64, isNotifying: Bool)]) -> [Int64]` → handles where `isNotifying`, order preserved.
- `final class RestorationEventBuffer<Event>` — `begin()`, `enqueueIfBuffering(_:) -> Bool` (returns false / does not store when inactive), `flush() -> [Event]` (returns buffered events FIFO and deactivates), `isBuffering`.

- [ ] **Step 1: Write the failing tests** (`RestorationDecisionsTests.swift`) — see Notes for full content.
- [ ] **Step 2: Run tests to verify they fail (macOS):** `swift test --filter RestorationDecisionsTests` → FAIL (symbols not in scope). (Windows: by inspection.)
- [ ] **Step 3: Write `RestorationDecisions.swift`.**
- [ ] **Step 4: Run tests to verify they pass (macOS).**
- [ ] **Step 5: Commit** `feat(ios): add pure restoration decision logic for Issue #33`.

---

### Task 2: Wire restoration snapshot + event ordering into IosBleProcessOwner

**Files:**
- Modify: `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/IosBleProcessOwner.swift`

**Changes:**
1. State: add `restoredServices: [String: [ServiceMessage]]`, `restoredNotifyHandles: [String: [Int64]]`, a `RestorationEventBuffer<RestorationDeferredEvent>`, and a private `enum RestorationDeferredEvent`.
2. `centralManager(_:willRestoreState:)`: for each restored peripheral, after restoring the delegate / epoch / state, rebuild the handle tree from `peripheral.services` (when present) via `rebuildHandles`, store `restoredServices`/`restoredNotifyHandles` (notify handles via `RestorationDecisions.activeNotifyHandles`), and `restorationBuffer.begin()`.
3. `emitStateResync`: emit full snapshots — `services: restoredServices[id]`, `activeNotifyHandles: restoredNotifyHandles[id] ?? []`, `disconnectReason: RestorationDecisions.disconnectReason(for: state)`, `restored: restoredServices[id] != nil`.
4. `emitConnectionState` / `emitCharacteristicValue`: route through `restorationBuffer.enqueueIfBuffering` before calling `activeCallbacks`.
5. `notifyDartReady`: emit adapter state + resync only (remove the early `onRestoredConnections`).
6. `ackStateResync`: send `onRestoredConnections`, then `flushRestorationBuffer()` (deliver deferred events in order), then clear `restoredDeviceIds`.
7. Clear `restoredServices`/`restoredNotifyHandles` for a device on rediscovery (`rebuildHandles`), disconnect, timeout, and dispose.

- [ ] **Step 1–7** per above.
- [ ] **Step 8: Build + full suite (macOS):** `swift build` then `swift test`. (Windows: inspect symbol consistency.)
- [ ] **Step 9: Commit** `feat(ios): deliver full restoration snapshot and ordered event flush for Issue #33`.

---

## Notes for the implementer

- Buffering window is `willRestoreState` → `ackStateResync`. Only `emitConnectionState` / `emitCharacteristicValue` consult the buffer; `onStateResync` / `onAdapterStateChanged` are delivered directly (they are the snapshot itself).
- Restored peripherals with no restored `services` send `services: nil` (Dart re-discovers per §13); their `activeNotifyHandles` is `[]`.
- `onRestoredConnections` moves from `notifyDartReady` to `ackStateResync` to honor §13 "ready/ack 後に restoredConnections を通知する".
- No new error strings; no Pigeon schema change.
