import XCTest
@testable import deepsky_bluetooth_ios

final class IosNativeOwnerStateTests: XCTestCase {
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
    let owner = IosNativeOwnerState()

    let first = owner.connectRequested(deviceId: "A")
    let second = owner.connectRequested(deviceId: "A")

    XCTAssertEqual(first.epoch, 1)
    XCTAssertEqual(second.epoch, 2)
    XCTAssertTrue(owner.isCurrent(deviceId: "A", epoch: 2))
    XCTAssertFalse(owner.isCurrent(deviceId: "A", epoch: 1))
  }

  func testPoweredOffKeepsPendingConnectArmed() {
    let owner = IosNativeOwnerState()

    let attempt = owner.connectRequested(deviceId: "A")
    owner.adapterStateChanged(.poweredOff)

    XCTAssertEqual(owner.connectionState(deviceId: "A"), .pending)
    XCTAssertTrue(owner.shouldResumePendingConnects)
    XCTAssertTrue(owner.isCurrent(deviceId: "A", epoch: attempt.epoch))
  }

  func testExplicitDisconnectRetiresEpochAndCancelsPendingConnect() {
    let owner = IosNativeOwnerState()

    let attempt = owner.connectRequested(deviceId: "A")
    let result = owner.disconnectRequested(deviceId: "A", epoch: attempt.epoch)

    XCTAssertTrue(result)
    XCTAssertEqual(owner.connectionState(deviceId: "A"), .disconnected)
    XCTAssertFalse(owner.isCurrent(deviceId: "A", epoch: attempt.epoch))
    XCTAssertFalse(owner.shouldResumePendingConnects)
  }

  func testOldEpochCallbacksAreDropped() {
    let owner = IosNativeOwnerState()

    let old = owner.connectRequested(deviceId: "A")
    let current = owner.connectRequested(deviceId: "A")

    XCTAssertFalse(owner.acceptCallback(deviceId: "A", epoch: old.epoch, state: .connected))
    XCTAssertEqual(owner.connectionState(deviceId: "A"), .pending)

    XCTAssertTrue(owner.acceptCallback(deviceId: "A", epoch: current.epoch, state: .connected))
    XCTAssertEqual(owner.connectionState(deviceId: "A"), .connected)
  }

  // MARK: - HandleRegistry

  func testHandleRegistryAssignsMonotonicHandles() {
    let registry = HandleRegistry()
    let a = NSObject()
    let b = NSObject()
    XCTAssertEqual(registry.allocate(a, kind: .characteristic, deviceId: "D"), 1)
    XCTAssertEqual(registry.allocate(b, kind: .descriptor, deviceId: "D"), 2)
  }

  func testHandleRegistryReturnsSameHandleForSameObject() {
    let registry = HandleRegistry()
    let obj = NSObject()
    let h1 = registry.allocate(obj, kind: .characteristic, deviceId: "D")
    let h2 = registry.allocate(obj, kind: .characteristic, deviceId: "D")
    XCTAssertEqual(h1, h2)
  }

  func testHandleRegistryDistinguishesDuplicateUuidObjects() {
    let registry = HandleRegistry()
    let char1 = NSObject()
    let char2 = NSObject()
    let h1 = registry.allocate(char1, kind: .characteristic, deviceId: "D")
    let h2 = registry.allocate(char2, kind: .characteristic, deviceId: "D")
    XCTAssertNotEqual(h1, h2)
  }

  func testHandleRegistryCharacteristicReverseLookup() {
    let registry = HandleRegistry()
    let obj = NSObject()
    let h = registry.allocate(obj, kind: .characteristic, deviceId: "D")
    XCTAssertTrue(registry.characteristic(handle: h, deviceId: "D") === obj)
  }

  func testHandleRegistryDescriptorReverseLookup() {
    let registry = HandleRegistry()
    let obj = NSObject()
    let h = registry.allocate(obj, kind: .descriptor, deviceId: "D")
    XCTAssertTrue(registry.descriptor(handle: h, deviceId: "D") === obj)
  }

  func testHandleRegistryClearRemovesDeviceEntries() {
    let registry = HandleRegistry()
    let obj = NSObject()
    let h = registry.allocate(obj, kind: .characteristic, deviceId: "D")
    registry.clear(deviceId: "D")
    XCTAssertNil(registry.characteristic(handle: h, deviceId: "D"))
    XCTAssertNil(registry.handle(for: obj))
  }

  func testHandleRegistryClearDoesNotAffectOtherDevices() {
    let registry = HandleRegistry()
    let obj = NSObject()
    let h = registry.allocate(obj, kind: .characteristic, deviceId: "A")
    registry.clear(deviceId: "B")
    XCTAssertNotNil(registry.characteristic(handle: h, deviceId: "A"))
  }

  func testHandleRegistryServiceHandleNotInCharLookup() {
    let registry = HandleRegistry()
    let svc = NSObject()
    let h = registry.allocate(svc, kind: .service, deviceId: "D")
    XCTAssertEqual(registry.handle(for: svc), h)
    XCTAssertNil(registry.characteristic(handle: h, deviceId: "D"))
  }

  func testClearRemovesServiceHandle() {
    let registry = HandleRegistry()
    let obj = NSObject()
    _ = registry.allocate(obj, kind: .service, deviceId: "device1")
    XCTAssertNotNil(registry.handle(for: obj))
    registry.clear(deviceId: "device1")
    XCTAssertNil(registry.handle(for: obj), "Service forward entry must be removed by clear")
  }

  // MARK: - GattOperationQueue

  func testGattOperationQueueFirstEnqueueSucceeds() {
    var started: [String] = []
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    XCTAssertTrue(queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {
      started.append("D|1|1")
    })
    XCTAssertEqual(started, ["D|1|1"])
  }

  func testGattOperationQueueDuplicateEnqueueFails() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {}
    XCTAssertFalse(queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {})
  }

  func testGattOperationQueueDifferentKeysStartFifoPerDeviceEpoch() {
    var started: [String] = []
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    XCTAssertTrue(queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {
      started.append("D|1|1")
    })
    XCTAssertTrue(queue.enqueue(key: "D|1|2", deviceId: "D", epoch: 1) {
      started.append("D|1|2")
    })

    XCTAssertEqual(started, ["D|1|1"])
    XCTAssertTrue(queue.complete(key: "D|1|1"))
    XCTAssertEqual(started, ["D|1|1", "D|1|2"])
  }

  func testGattOperationQueueCompleteReturnsTrueIfInflight() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {}
    XCTAssertTrue(queue.complete(key: "D|1|1"))
  }

  func testGattOperationQueueCompleteReturnsFalseIfNotInflight() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    XCTAssertFalse(queue.complete(key: "D|1|1"))
  }

  func testGattOperationQueueCompleteAllowsReenqueue() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {}
    _ = queue.complete(key: "D|1|1")
    XCTAssertTrue(queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {})
  }

  func testGattOperationQueueCancelAllClearsInflight() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {}
    _ = queue.enqueue(key: "D|1|2", deviceId: "D", epoch: 1) {}
    queue.cancelAll(deviceId: "D", epoch: 1)
    XCTAssertTrue(queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {})
    XCTAssertTrue(queue.enqueue(key: "D|1|2", deviceId: "D", epoch: 1) {})
  }

  func testGattOperationQueueCancelAllDoesNotAffectOtherEpoch() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    _ = queue.enqueue(key: "D|2|1", deviceId: "D", epoch: 2) {}
    queue.cancelAll(deviceId: "D", epoch: 1)
    XCTAssertFalse(queue.enqueue(key: "D|2|1", deviceId: "D", epoch: 2) {})
  }

  func testGattOperationQueueTimeoutFiresCallback() {
    let expectation = expectation(description: "timeout")
    let queue = GattOperationQueue(timeout: 0.05) { deviceId, epoch in
      XCTAssertEqual(deviceId, "D")
      XCTAssertEqual(epoch, 1)
      expectation.fulfill()
    }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1) {}
    waitForExpectations(timeout: 1.0)
  }

  func testGattOperationQueueCompletePreventTimeout() {
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
