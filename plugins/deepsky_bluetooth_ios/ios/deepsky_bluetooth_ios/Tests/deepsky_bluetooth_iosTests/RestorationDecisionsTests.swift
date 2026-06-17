import XCTest
@testable import deepsky_bluetooth_ios

final class RestorationDecisionsTests: XCTestCase {
  // MARK: - disconnectReason

  func testDisconnectedSnapshotCarriesReason() {
    XCTAssertEqual(
      RestorationDecisions.disconnectReason(for: .disconnected),
      .unknown)
  }

  func testConnectedSnapshotHasNoReason() {
    XCTAssertNil(RestorationDecisions.disconnectReason(for: .connected))
  }

  func testReconnectingSnapshotHasNoReason() {
    XCTAssertNil(RestorationDecisions.disconnectReason(for: .reconnecting))
  }

  func testConnectingSnapshotHasNoReason() {
    XCTAssertNil(RestorationDecisions.disconnectReason(for: .connecting))
  }

  // MARK: - activeNotifyHandles

  func testActiveNotifyHandlesSelectsNotifyingOnly() {
    let entries: [(handle: Int64, isNotifying: Bool)] = [
      (handle: 1, isNotifying: true),
      (handle: 2, isNotifying: false),
      (handle: 3, isNotifying: true),
    ]
    XCTAssertEqual(RestorationDecisions.activeNotifyHandles(from: entries), [1, 3])
  }

  func testActiveNotifyHandlesPreservesOrder() {
    let entries: [(handle: Int64, isNotifying: Bool)] = [
      (handle: 5, isNotifying: true),
      (handle: 2, isNotifying: true),
      (handle: 9, isNotifying: true),
    ]
    XCTAssertEqual(RestorationDecisions.activeNotifyHandles(from: entries), [5, 2, 9])
  }

  func testActiveNotifyHandlesEmptyWhenNoneNotifying() {
    let entries: [(handle: Int64, isNotifying: Bool)] = [
      (handle: 1, isNotifying: false),
      (handle: 2, isNotifying: false),
    ]
    XCTAssertTrue(RestorationDecisions.activeNotifyHandles(from: entries).isEmpty)
  }

  // MARK: - RestorationEventBuffer

  func testBufferIsNotBufferingByDefault() {
    let buffer = RestorationEventBuffer<Int>()
    XCTAssertFalse(buffer.isBuffering)
  }

  func testEnqueueWhenNotBufferingReturnsFalse() {
    let buffer = RestorationEventBuffer<Int>()
    XCTAssertFalse(buffer.enqueueIfBuffering(1))
  }

  func testBeginActivatesBuffering() {
    let buffer = RestorationEventBuffer<Int>()
    buffer.begin()
    XCTAssertTrue(buffer.isBuffering)
  }

  func testEnqueueWhileBufferingReturnsTrueAndStores() {
    let buffer = RestorationEventBuffer<Int>()
    buffer.begin()
    XCTAssertTrue(buffer.enqueueIfBuffering(7))
  }

  func testFlushReturnsBufferedEventsInArrivalOrder() {
    let buffer = RestorationEventBuffer<Int>()
    buffer.begin()
    _ = buffer.enqueueIfBuffering(1)
    _ = buffer.enqueueIfBuffering(2)
    _ = buffer.enqueueIfBuffering(3)
    XCTAssertEqual(buffer.flush(), [1, 2, 3])
  }

  func testFlushDeactivatesBuffering() {
    let buffer = RestorationEventBuffer<Int>()
    buffer.begin()
    _ = buffer.flush()
    XCTAssertFalse(buffer.isBuffering)
    XCTAssertFalse(buffer.enqueueIfBuffering(1))
  }

  func testFlushAfterEnqueueIsEmptyOnSecondFlush() {
    let buffer = RestorationEventBuffer<Int>()
    buffer.begin()
    _ = buffer.enqueueIfBuffering(1)
    XCTAssertEqual(buffer.flush(), [1])
    XCTAssertEqual(buffer.flush(), [])
  }

  func testBeginClearsPreviousPendingEvents() {
    let buffer = RestorationEventBuffer<Int>()
    buffer.begin()
    _ = buffer.enqueueIfBuffering(99)
    buffer.begin()
    XCTAssertEqual(buffer.flush(), [])
  }

  // MARK: - Restoration fixture (non-degradation)

  /// 復元 fixture: 探索済み GATT tree と notify 状態を持つ device が、
  /// device ID 一覧へ縮退せず full snapshot を構築できることを確認する。
  func testRestorationFixtureKeepsFullGattTreeAndNotifyHandles() {
    // service(handle 1) > characteristic(handle 2, notifying) + characteristic(handle 4)
    let entries: [(handle: Int64, isNotifying: Bool)] = [
      (handle: 2, isNotifying: true),
      (handle: 4, isNotifying: false),
    ]
    let services = [
      ServiceMessage(
        handle: 1,
        uuid: "0000180d-0000-1000-8000-00805f9b34fb",
        characteristics: [
          CharacteristicMessage(
            handle: 2,
            serviceHandle: 1,
            uuid: "00002a37-0000-1000-8000-00805f9b34fb",
            canRead: true,
            canWriteWithResponse: false,
            canWriteWithoutResponse: false,
            canNotify: true,
            canIndicate: false,
            descriptors: []),
          CharacteristicMessage(
            handle: 4,
            serviceHandle: 1,
            uuid: "00002a38-0000-1000-8000-00805f9b34fb",
            canRead: true,
            canWriteWithResponse: false,
            canWriteWithoutResponse: false,
            canNotify: false,
            canIndicate: false,
            descriptors: []),
        ]),
    ]

    let snapshot = StateSnapshotMessage(
      deviceId: "device-a",
      connectionEpoch: 1,
      state: .connected,
      disconnectReason: RestorationDecisions.disconnectReason(for: .connected),
      activeNotifyHandles: RestorationDecisions.activeNotifyHandles(from: entries),
      services: services,
      restored: true)

    XCTAssertEqual(snapshot.activeNotifyHandles, [2])
    XCTAssertNil(snapshot.disconnectReason)
    XCTAssertEqual(snapshot.services?.count, 1)
    XCTAssertEqual(snapshot.services?.first?.characteristics.count, 2)
    XCTAssertTrue(snapshot.restored)
  }
}
