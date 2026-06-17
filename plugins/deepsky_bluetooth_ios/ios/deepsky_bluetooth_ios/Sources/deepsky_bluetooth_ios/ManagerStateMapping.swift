import Foundation

/// CoreBluetooth 非依存の central manager 状態。
/// CBManagerState に依存せず adapter state と接続ガードの判断をテスト可能にする。
enum BleManagerState {
  case unknown
  case resetting
  case unsupported
  case unauthorized
  case poweredOff
  case poweredOn
}

/// CoreBluetooth 非依存の接続失敗種別。
/// owner が CBError.Code から変換し、純粋ロジックで reason を決める。
enum BleConnectionFailure {
  case none
  case timeout
  case peripheralDisconnected
  case connectionFailed
  case limitReached
  case other
}

enum ManagerStateMapping {
  /// 公開 adapter state は poweredOn / poweredOff / unavailable の3値へ縮約する。
  static func adapterState(for state: BleManagerState) -> AdapterStateMessage {
    switch state {
    case .poweredOn:
      return .poweredOn
    case .poweredOff:
      return .poweredOff
    case .unknown, .resetting, .unsupported, .unauthorized:
      return .unavailable
    }
  }

  /// connect / scan 実行前のガード。unauthorized / poweredOff / unsupported を区別する。
  /// poweredOn のときだけ nil（続行可）を返す。
  static func connectGuardError(for state: BleManagerState) -> (code: String, message: String)? {
    switch state {
    case .poweredOn:
      return nil
    case .poweredOff:
      return (BleErrorCode.bluetoothOff, "Bluetooth is off")
    case .unauthorized:
      return (BleErrorCode.permissionDenied, "Bluetooth permission denied")
    case .unsupported:
      return (BleErrorCode.bluetoothUnavailable, "Bluetooth LE unavailable")
    case .unknown, .resetting:
      return (BleErrorCode.bluetoothUnavailable, "Bluetooth is not ready")
    }
  }

  /// 切断 reason を CB error 種別から決める。圏外・切断は終端理由へ縮退させない（§6）。
  static func disconnectReason(for failure: BleConnectionFailure) -> DisconnectReasonMessage {
    switch failure {
    case .none:
      return .userRequested
    case .timeout, .peripheralDisconnected, .limitReached:
      return .connectionLost
    case .connectionFailed:
      return .connectFailed
    case .other:
      return .unknown
    }
  }
}
