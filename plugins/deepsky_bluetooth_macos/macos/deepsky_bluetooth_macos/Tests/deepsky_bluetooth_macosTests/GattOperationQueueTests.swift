import XCTest
@testable import deepsky_bluetooth_macos

final class GattOperationQueueTests: XCTestCase {
  func testFirstEnqueueStartsImmediately() {
    var started: [String] = []
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    XCTAssertTrue(queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {
      started.append("D|1|1")
    })
    XCTAssertEqual(started, ["D|1|1"])
  }

  func testDuplicateKeyEnqueueFails() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {}
    XCTAssertFalse(queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {})
  }

  func testOneOperationPerDeviceEpochRunsFifo() {
    var started: [String] = []
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    XCTAssertTrue(queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {
      started.append("D|1|1")
    })
    // 同一 device|epoch の 2 件目は実行中の完了まで開始しない（同時 1 operation）。
    XCTAssertTrue(queue.enqueue(key: "D|1|2", deviceId: "D", epoch: 1) {
      started.append("D|1|2")
    })
    XCTAssertEqual(started, ["D|1|1"])

    XCTAssertTrue(queue.complete(key: "D|1|1"))
    XCTAssertEqual(started, ["D|1|1", "D|1|2"])
  }

  func testContainsTracksActiveAndPendingKeys() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {}
    _ = queue.enqueue(key: "D|1|2", deviceId: "D", epoch: 1) {}

    XCTAssertTrue(queue.contains(key: "D|1|1"))
    XCTAssertTrue(queue.contains(key: "D|1|2"))

    _ = queue.complete(key: "D|1|1")
    XCTAssertFalse(queue.contains(key: "D|1|1"))
    XCTAssertTrue(queue.contains(key: "D|1|2"))

    _ = queue.complete(key: "D|1|2")
    XCTAssertFalse(queue.contains(key: "D|1|2"))
  }

  func testCompleteReturnsTrueOnlyWhenInflight() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {}
    XCTAssertTrue(queue.complete(key: "D|1|1"))
    XCTAssertFalse(queue.complete(key: "D|1|1"))
  }

  func testCompleteAllowsReenqueue() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {}
    _ = queue.complete(key: "D|1|1")
    XCTAssertTrue(queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {})
  }

  func testCancelAllClearsActiveAndPending() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {}
    _ = queue.enqueue(key: "D|1|2", deviceId: "D", epoch: 1) {}
    queue.cancelAll(deviceId: "D", epoch: 1)
    XCTAssertTrue(queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {})
    XCTAssertTrue(queue.enqueue(key: "D|1|2", deviceId: "D", epoch: 1) {})
  }

  func testCancelAllDoesNotAffectOtherEpoch() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    _ = queue.enqueue(key: "D|2|1", deviceId: "D", epoch: 2) {}
    queue.cancelAll(deviceId: "D", epoch: 1)
    XCTAssertFalse(queue.enqueue(key: "D|2|1", deviceId: "D", epoch: 2) {})
  }

  func testDifferentDeviceEpochsRunConcurrently() {
    var started: [String] = []
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    _ = queue.enqueue(key: "A|1|1", deviceId: "A", epoch: 1) { started.append("A") }
    _ = queue.enqueue(key: "B|1|1", deviceId: "B", epoch: 1) { started.append("B") }
    XCTAssertEqual(Set(started), ["A", "B"])
  }

  func testTimeoutFiresCallbackWithDeviceEpoch() {
    let expectation = expectation(description: "timeout")
    let queue = GattOperationQueue(timeout: 0.05) { deviceId, epoch in
      XCTAssertEqual(deviceId, "D")
      XCTAssertEqual(epoch, 1)
      expectation.fulfill()
    }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {}
    waitForExpectations(timeout: 1.0)
  }

  func testCompletePreventsTimeout() {
    let neverExpectation = expectation(description: "no timeout")
    neverExpectation.isInverted = true
    let queue = GattOperationQueue(timeout: 0.05) { _, _ in
      neverExpectation.fulfill()
    }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {}
    _ = queue.complete(key: "D|1|1")
    waitForExpectations(timeout: 0.2)
  }
}
