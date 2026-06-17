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

/// 初期化要求の受理可否。macOS は background BLE を持たないため拒否する（Review guide §14）。
enum InitializeDecision: Equatable {
  case proceed
  case backgroundNotSupported
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

  /// macOS は CoreBluetooth の background 実行に対応しないため、
  /// background 指定の初期化は backgroundNotSupported として拒否する（§14）。
  static func initializeDecision(isBackground: Bool) -> InitializeDecision {
    isBackground ? .backgroundNotSupported : .proceed
  }
}
