import Foundation

enum MacosConnectionLifecycleState: Equatable {
  case pending
  case connected
  case disconnected
}

struct MacosConnectionAttempt: Equatable {
  let deviceId: String
  let epoch: Int64
}

struct MacosConnectionSnapshot: Equatable {
  let deviceId: String
  let epoch: Int64
  let state: MacosConnectionLifecycleState
}

/// CoreBluetooth 非依存の central owner 状態。
/// epoch 採番・callback guard・接続 lifecycle をテスト可能な純粋ロジックへ分離する。
final class MacosNativeOwnerState {
  private let epochs = EpochRegistry()
  private var states: [String: MacosConnectionLifecycleState] = [:]
  private var activeEpochs: [String: Int64] = [:]
  private var adapterState: AdapterStateMessage = .unavailable
  private let lock = NSLock()

  var shouldResumePendingConnects: Bool {
    lock.lock()
    defer { lock.unlock() }

    return states.values.contains(.pending)
  }

  var pendingDeviceIds: [String] {
    lock.lock()
    defer { lock.unlock() }

    return states.compactMap { entry in
      entry.value == .pending ? entry.key : nil
    }
  }

  var snapshots: [MacosConnectionSnapshot] {
    lock.lock()
    defer { lock.unlock() }

    return activeEpochs.compactMap { entry in
      guard let state = states[entry.key], state != .disconnected else {
        return nil
      }
      return MacosConnectionSnapshot(deviceId: entry.key, epoch: entry.value, state: state)
    }
  }

  func connectRequested(deviceId: String) -> MacosConnectionAttempt {
    let epoch = epochs.allocate(deviceId: deviceId)

    lock.lock()
    defer { lock.unlock() }

    activeEpochs[deviceId] = epoch
    states[deviceId] = .pending
    return MacosConnectionAttempt(deviceId: deviceId, epoch: epoch)
  }

  func disconnectRequested(deviceId: String, epoch: Int64) -> Bool {
    guard epochs.isCurrent(deviceId: deviceId, epoch: epoch) else {
      return false
    }

    epochs.retire(deviceId: deviceId)

    lock.lock()
    defer { lock.unlock() }

    activeEpochs.removeValue(forKey: deviceId)
    states[deviceId] = .disconnected
    return true
  }

  func adapterStateChanged(_ state: AdapterStateMessage) {
    lock.lock()
    defer { lock.unlock() }

    adapterState = state
  }

  func connectionState(deviceId: String) -> MacosConnectionLifecycleState? {
    lock.lock()
    defer { lock.unlock() }

    return states[deviceId]
  }

  func currentEpoch(deviceId: String) -> Int64? {
    epochs.current(deviceId: deviceId)
  }

  func isCurrent(deviceId: String, epoch: Int64) -> Bool {
    epochs.isCurrent(deviceId: deviceId, epoch: epoch)
  }

  func acceptCallback(
    deviceId: String,
    epoch: Int64,
    state callbackState: ConnectionStateMessage
  ) -> Bool {
    guard epochs.isCurrent(deviceId: deviceId, epoch: epoch) else {
      return false
    }

    if callbackState == .disconnected {
      epochs.retire(deviceId: deviceId)
    }

    lock.lock()
    defer { lock.unlock() }

    switch callbackState {
    case .connected:
      states[deviceId] = .connected
    case .disconnected:
      states[deviceId] = .disconnected
      activeEpochs.removeValue(forKey: deviceId)
    case .connecting, .reconnecting:
      states[deviceId] = .pending
    case .disconnecting:
      break
    }
    return true
  }
}
