import XCTest
@testable import deepsky_bluetooth_macos

final class MacosNativeOwnerStateTests: XCTestCase {
  func testEpochRegistryAllocatesMonotonicEpochsPerDevice() {
    let registry = EpochRegistry()

    XCTAssertEqual(registry.allocate(deviceId: "A"), 1)
    XCTAssertEqual(registry.allocate(deviceId: "A"), 2)
    XCTAssertEqual(registry.allocate(deviceId: "B"), 1)

    registry.retire(deviceId: "A")

    XCTAssertEqual(registry.allocate(deviceId: "A"), 3)
  }

  func testEpochRegistryAcceptsOnlyCurrentEpoch() {
    let registry = EpochRegistry()

    let first = registry.allocate(deviceId: "A")
    let second = registry.allocate(deviceId: "A")

    XCTAssertFalse(registry.isCurrent(deviceId: "A", epoch: first))
    XCTAssertTrue(registry.isCurrent(deviceId: "A", epoch: second))

    registry.retire(deviceId: "A")

    XCTAssertFalse(registry.isCurrent(deviceId: "A", epoch: second))
  }

  func testConnectAllocatesANewEpochForEachRequest() {
    let owner = MacosNativeOwnerState()

    let first = owner.connectRequested(deviceId: "A")
    let second = owner.connectRequested(deviceId: "A")

    XCTAssertEqual(first.epoch, 1)
    XCTAssertEqual(second.epoch, 2)
    XCTAssertTrue(owner.isCurrent(deviceId: "A", epoch: 2))
    XCTAssertFalse(owner.isCurrent(deviceId: "A", epoch: 1))
  }

  func testPoweredOffKeepsPendingConnectArmed() {
    let owner = MacosNativeOwnerState()

    let attempt = owner.connectRequested(deviceId: "A")
    owner.adapterStateChanged(.poweredOff)

    XCTAssertEqual(owner.connectionState(deviceId: "A"), .pending)
    XCTAssertTrue(owner.shouldResumePendingConnects)
    XCTAssertTrue(owner.isCurrent(deviceId: "A", epoch: attempt.epoch))
  }

  func testExplicitDisconnectRetiresEpochAndCancelsPendingConnect() {
    let owner = MacosNativeOwnerState()

    let attempt = owner.connectRequested(deviceId: "A")
    let result = owner.disconnectRequested(deviceId: "A", epoch: attempt.epoch)

    XCTAssertTrue(result)
    XCTAssertEqual(owner.connectionState(deviceId: "A"), .disconnected)
    XCTAssertFalse(owner.isCurrent(deviceId: "A", epoch: attempt.epoch))
    XCTAssertFalse(owner.shouldResumePendingConnects)
  }

  func testStaleDisconnectIsRejected() {
    let owner = MacosNativeOwnerState()

    let old = owner.connectRequested(deviceId: "A")
    _ = owner.connectRequested(deviceId: "A")

    XCTAssertFalse(owner.disconnectRequested(deviceId: "A", epoch: old.epoch))
    XCTAssertEqual(owner.connectionState(deviceId: "A"), .pending)
  }

  func testOldEpochCallbacksAreDropped() {
    let owner = MacosNativeOwnerState()

    let old = owner.connectRequested(deviceId: "A")
    let current = owner.connectRequested(deviceId: "A")

    XCTAssertFalse(owner.acceptCallback(deviceId: "A", epoch: old.epoch, state: .connected))
    XCTAssertEqual(owner.connectionState(deviceId: "A"), .pending)

    XCTAssertTrue(owner.acceptCallback(deviceId: "A", epoch: current.epoch, state: .connected))
    XCTAssertEqual(owner.connectionState(deviceId: "A"), .connected)
  }

  func testDisconnectedCallbackRetiresEpochAndClearsSnapshot() {
    let owner = MacosNativeOwnerState()

    let attempt = owner.connectRequested(deviceId: "A")
    XCTAssertTrue(owner.acceptCallback(deviceId: "A", epoch: attempt.epoch, state: .connected))
    XCTAssertEqual(owner.snapshots.count, 1)

    XCTAssertTrue(owner.acceptCallback(deviceId: "A", epoch: attempt.epoch, state: .disconnected))
    XCTAssertEqual(owner.connectionState(deviceId: "A"), .disconnected)
    XCTAssertFalse(owner.isCurrent(deviceId: "A", epoch: attempt.epoch))
    XCTAssertTrue(owner.snapshots.isEmpty)
  }

  func testSnapshotsExposeActiveConnectionsForForegroundReconnect() {
    let owner = MacosNativeOwnerState()

    let a = owner.connectRequested(deviceId: "A")
    let b = owner.connectRequested(deviceId: "B")
    _ = owner.acceptCallback(deviceId: "A", epoch: a.epoch, state: .connected)

    let snapshots = owner.snapshots.sorted { $0.deviceId < $1.deviceId }
    XCTAssertEqual(snapshots.map(\.deviceId), ["A", "B"])
    XCTAssertEqual(snapshots[0], MacosConnectionSnapshot(deviceId: "A", epoch: a.epoch, state: .connected))
    XCTAssertEqual(snapshots[1], MacosConnectionSnapshot(deviceId: "B", epoch: b.epoch, state: .pending))
  }
}
