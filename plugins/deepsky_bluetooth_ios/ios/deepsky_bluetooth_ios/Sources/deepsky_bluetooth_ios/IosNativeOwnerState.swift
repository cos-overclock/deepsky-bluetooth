import Foundation

enum IosConnectionLifecycleState: Equatable {
  case pending
  case connected
  case disconnected
}

struct IosConnectionAttempt: Equatable {
  let deviceId: String
  let epoch: Int64
}

struct IosConnectionSnapshot: Equatable {
  let deviceId: String
  let epoch: Int64
  let state: IosConnectionLifecycleState
}

final class IosNativeOwnerState {
  private let epochs = EpochRegistry()
  private var states: [String: IosConnectionLifecycleState] = [:]
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

    return states.compactMap { deviceId, state in
      state == .pending ? deviceId : nil
    }
  }

  var snapshots: [IosConnectionSnapshot] {
    lock.lock()
    defer { lock.unlock() }

    return activeEpochs.compactMap { deviceId, epoch in
      guard let state = states[deviceId], state != .disconnected else {
        return nil
      }
      return IosConnectionSnapshot(deviceId: deviceId, epoch: epoch, state: state)
    }
  }

  func connectRequested(deviceId: String) -> IosConnectionAttempt {
    let epoch = epochs.allocate(deviceId: deviceId)

    lock.lock()
    defer { lock.unlock() }

    activeEpochs[deviceId] = epoch
    states[deviceId] = .pending
    return IosConnectionAttempt(deviceId: deviceId, epoch: epoch)
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

  func connectionState(deviceId: String) -> IosConnectionLifecycleState? {
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
