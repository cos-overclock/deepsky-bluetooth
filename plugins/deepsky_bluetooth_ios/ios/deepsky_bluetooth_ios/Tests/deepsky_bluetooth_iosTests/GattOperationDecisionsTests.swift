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
