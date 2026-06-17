import Foundation

final class GattOperationQueue {
  private struct Operation {
    let key: String
    let deviceId: String
    let epoch: Int64
    let start: () -> Void
  }

  private var inflight: [String: Operation] = [:]
  private var pending: [String: [Operation]] = [:]
  private var knownKeys: Set<String> = []
  private var timeoutTasks: [String: DispatchWorkItem] = [:]
  private let timeoutInterval: TimeInterval
  private let onTimeout: (String, Int64) -> Void

  init(timeout: TimeInterval = 30, onTimeout: @escaping (String, Int64) -> Void) {
    self.timeoutInterval = timeout
    self.onTimeout = onTimeout
  }

  func enqueue(
    key: String,
    deviceId: String,
    epoch: Int64,
    start: @escaping () -> Void
  ) -> Bool {
    guard !knownKeys.contains(key) else { return false }

    let scope = scopeKey(deviceId: deviceId, epoch: epoch)
    let operation = Operation(key: key, deviceId: deviceId, epoch: epoch, start: start)
    knownKeys.insert(key)

    guard inflight[scope] == nil else {
      pending[scope, default: []].append(operation)
      return true
    }

    inflight[scope] = operation
    startOperation(operation, scope: scope)
    return true
  }

  func complete(key: String) -> Bool {
    guard let scope = inflight.first(where: { $0.value.key == key })?.key else {
      return false
    }

    timeoutTasks.removeValue(forKey: key)?.cancel()
    inflight.removeValue(forKey: scope)
    knownKeys.remove(key)
    startNext(scope: scope)
    return true
  }

  func contains(key: String) -> Bool {
    knownKeys.contains(key)
  }

  func cancelAll(deviceId: String, epoch: Int64) {
    let scope = scopeKey(deviceId: deviceId, epoch: epoch)
    if let active = inflight.removeValue(forKey: scope) {
      timeoutTasks.removeValue(forKey: active.key)?.cancel()
      knownKeys.remove(active.key)
    }
    for operation in pending.removeValue(forKey: scope) ?? [] {
      knownKeys.remove(operation.key)
    }
  }

  private func startOperation(_ operation: Operation, scope: String) {
    let work = DispatchWorkItem { [weak self] in
      guard let self else { return }
      guard self.inflight[scope]?.key == operation.key else { return }
      self.inflight.removeValue(forKey: scope)
      self.timeoutTasks.removeValue(forKey: operation.key)
      self.knownKeys.remove(operation.key)
      self.onTimeout(operation.deviceId, operation.epoch)
    }
    timeoutTasks[operation.key] = work
    DispatchQueue.main.asyncAfter(deadline: .now() + timeoutInterval, execute: work)
    operation.start()
  }

  private func startNext(scope: String) {
    guard var queue = pending[scope], !queue.isEmpty else { return }
    let next = queue.removeFirst()
    if queue.isEmpty {
      pending.removeValue(forKey: scope)
    } else {
      pending[scope] = queue
    }
    inflight[scope] = next
    startOperation(next, scope: scope)
  }

  private func scopeKey(deviceId: String, epoch: Int64) -> String {
    "\(deviceId)|\(epoch)"
  }
}
