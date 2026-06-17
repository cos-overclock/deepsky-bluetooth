# iOS Native Observer / Manager-State & CBError Mapping Completion Design

**Issue:** #34 (`[iOS Native] Observer・error mapping・Swift build/XCTestを完成する`), final sub-issue of #6.

**Date:** 2026-06-17

## Goal

Close Issue #34 by completing the iOS native owner: distinguish
`unauthorized` / `poweredOff` / `unsupported` in the Bluetooth-state guard,
map CoreBluetooth error codes to the common disconnect-reason contract, add
native `os_log` diagnostics, and cover the new mapping with a pure-logic
XCTest suite. Plugin / Pigeon handler wiring is already complete from
#30–#33 and is not changed.

## Background

PRs for #30–#33 already implemented connect/disconnect, GATT discovery and
operations, the FIFO operation queue, epoch retirement, handle registry, and
State Restoration inside `IosBleProcessOwner`. The remaining gaps versus the
Issue #34 acceptance criteria:

- `poweredOnCentral()` and `adapterState(from:)` collapse
  `.unsupported` and `.unauthorized` into a single
  `bluetoothUnavailable` / `unavailable` result — they are **not**
  distinguished.
- `didFailToConnect` already maps to `connectFailed`
  (`IosBleProcessOwner.swift:472`); `didDisconnect` chooses
  `userRequested` / `connectionLost` from `error == nil`. Neither inspects
  the CoreBluetooth error code.
- There is no `os_log` / native diagnostic logging anywhere in the Swift
  sources, although the Dart `DeepskyBluetoothIosObserver` contract exists.

## Constraints

- **Swift cannot be compiled/run on the Windows development host and there
  is no in-repo CI.** Per review guide §16, macOS XCTest is the merge gate.
  Test code is written here and verified on macOS review. The Windows gate is
  `dart analyze`.
- Pure decision modules MUST NOT `import CoreBluetooth`, so they compile and
  test on any platform (mirrors `GattOperationDecisions.swift` /
  `RestorationDecisions.swift`).
- **No Pigeon schema change.** The public `AdapterStateMessage` stays the
  3-value surface (`poweredOn` / `poweredOff` / `unavailable`). The
  unauthorized/unsupported distinction is expressed through the existing
  canonical error codes, not a new adapter state. Generated files
  (`Messages.g.swift`, `messages.g.dart`) are gitignored.
- Reuse the canonical error-code strings from
  `packages/deepsky_bluetooth_util/lib/src/error_codes.dart`
  (`permissionDenied`, `bluetoothOff`, `bluetoothUnavailable` already exist).
- Match existing file style: 2-space indentation, Japanese inline comments
  for contract intent.

## Acceptance Criteria (from Issue #34)

- [ ] `unauthorized` / `poweredOff` / `unsupported` are distinguished.
- [ ] `didFailToConnect` maps to `connectFailed`.
- [ ] macOS host: Swift build + XCTest pass.
- [ ] Windows: `dart analyze` passes.

## Architecture

### 1. Pure mapping module — `ManagerStateMapping.swift`

CoreBluetooth-free. Owns the manager-state and CB-error contract decisions.

- `enum BleManagerState` mirroring `CBManagerState`:
  `unknown / resetting / unsupported / unauthorized / poweredOff / poweredOn`.
- `static func adapterState(for: BleManagerState) -> AdapterStateMessage`
  — `poweredOn → .poweredOn`, `poweredOff → .poweredOff`, everything else
  `→ .unavailable` (public surface unchanged).
- `static func connectGuardError(for: BleManagerState) -> (code: String, message: String)?`
  — the distinction:
  - `poweredOn → nil` (proceed)
  - `poweredOff → (bluetoothOff, …)`
  - `unauthorized → (permissionDenied, …)`
  - `unsupported → (bluetoothUnavailable, "Bluetooth LE unavailable")`
  - `unknown` / `resetting → (bluetoothUnavailable, "Bluetooth is not ready")`
- `enum BleConnectionFailure` (CoreBluetooth-free semantic kind):
  `none / timeout / peripheralDisconnected / connectionFailed /
  limitReached / other`.
- `static func disconnectReason(for failure: BleConnectionFailure) -> DisconnectReasonMessage`:
  - `none → .userRequested`
  - `timeout / peripheralDisconnected / limitReached → .connectionLost`
  - `connectionFailed → .connectFailed`
  - `other → .unknown`

  The owner does the `CBError.Code → BleConnectionFailure` translation so the
  CoreBluetooth raw-value numbering stays out of the pure (and cross-platform
  testable) module.

### 2. Error constants — `BleErrorMapping.swift`

Add the `permissionDenied` code + a `BleErrorMapping.permissionDenied()`
factory so `connectGuardError` results convert to `PigeonError`.

### 3. Native diagnostics — `BleDiagnostics.swift`

Thin wrapper over `os.Logger` (subsystem `com.deepsky.bluetooth`),
categories `owner / queue / epoch / handle / restoration / sink`. Typed
log methods invoked from the owner at the diagnostic sites matching the Dart
observer's method set (CB state change, epoch change, op queued/start/end,
handle discovered, sink handover, willRestoreState). Side-effecting and
thin; not unit-tested beyond its subsystem/category constants.

### 4. Owner wiring — `IosBleProcessOwner.swift`

- `poweredOnCentral()`: replace the grouped `.unsupported/.unauthorized`
  branch with `ManagerStateMapping.connectGuardError(for:)` (via a
  `CBManagerState → BleManagerState` adapter), throwing the mapped
  `PigeonError`.
- `adapterState(from:)`: delegate to `ManagerStateMapping.adapterState(for:)`.
- `didFailToConnect`: continues to yield `.connectFailed`
  unconditionally — a connect attempt that never established is always
  `connectFailed` (acceptance criterion). It does not consult the CBError
  mapper.
- `didDisconnectPeripheral`: translate `(error as? CBError)?.code` into a
  `BleConnectionFailure` (nil error → `.none`) and derive the reason through
  `ManagerStateMapping.disconnectReason(for:)`, replacing the current
  `error == nil ? .userRequested : .connectionLost` heuristic.
- Insert `BleDiagnostics` log calls at the diagnostic sites.
- No change to plugin registration / Pigeon handler setup.

## Data Flow

```
CBCentralManager state
  -> CBManagerState -> BleManagerState (owner adapter)
     -> ManagerStateMapping.adapterState  -> AdapterStateMessage -> onAdapterStateChanged
     -> ManagerStateMapping.connectGuardError -> PigeonError (connect/scan guard)

CBPeripheral disconnect / connect-fail
  -> CBError.Code -> BleConnectionFailure (owner adapter)
     -> ManagerStateMapping.disconnectReason -> DisconnectReasonMessage -> onConnectionStateChanged
```

## Error Handling

All guard failures surface as `PigeonError` with canonical codes the Dart
mappers already understand; no new code strings beyond adding `permissionDenied`
to the Swift constants (already canonical in Dart). Unknown CB error codes
degrade to `.unknown` (a transient reason), never to a terminal reason, per
review guide §6.

## Testing

- `ManagerStateMappingTests.swift` (XCTest, pure): adapter-state mapping for
  all six states; `connectGuardError` distinguishing
  unauthorized/poweredOff/unsupported and returning `nil` for poweredOn;
  CB-error-code → reason table including the `connectFailed` case and the
  nil → `userRequested` / unknown-code → `unknown` fallbacks.
- Existing `GattOperationDecisionsTests`, `IosNativeOwnerStateTests`,
  `RestorationDecisionsTests` unchanged.
- Verified on macOS (`swift build` / `swift test`); `dart analyze` on Windows.

## Out of Scope

- Pigeon schema / `AdapterStateMessage` expansion.
- Changes to Android/macOS plugins or the contracts package.
- The pre-existing Swift `operationTimeout` vs canonical `timeout` code naming
  (untouched; not part of #34).
