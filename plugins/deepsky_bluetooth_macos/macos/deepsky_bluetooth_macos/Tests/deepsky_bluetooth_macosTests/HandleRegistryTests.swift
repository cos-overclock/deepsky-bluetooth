import XCTest
@testable import deepsky_bluetooth_macos

final class HandleRegistryTests: XCTestCase {
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
}
