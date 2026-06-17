import XCTest
@testable import deepsky_bluetooth_macos

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
