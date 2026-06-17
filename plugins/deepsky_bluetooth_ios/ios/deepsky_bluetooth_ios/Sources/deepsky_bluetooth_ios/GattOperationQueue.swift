import Foundation

final class GattOperationQueue {
  private var inflight: Set<String> = []
  private var timeoutTasks: [String: DispatchWorkItem] = [:]
  private let timeoutInterval: TimeInterval
  private let onTimeout: (String, Int64) -> Void

  init(timeout: TimeInterval = 30, onTimeout: @escaping (String, Int64) -> Void) {
    self.timeoutInterval = timeout
    self.onTimeout = onTimeout
  }

  func enqueue(key: String, deviceId: String, epoch: Int64) -> Bool {
    guard !inflight.contains(key) else { return false }
    inflight.insert(key)
    let work = DispatchWorkItem { [weak self] in
      guard let self else { return }
      self.inflight.remove(key)
      self.timeoutTasks.removeValue(forKey: key)
      self.onTimeout(deviceId, epoch)
    }
    timeoutTasks[key] = work
    DispatchQueue.main.asyncAfter(deadline: .now() + timeoutInterval, execute: work)
    return true
  }

  func complete(key: String) -> Bool {
    timeoutTasks.removeValue(forKey: key)?.cancel()
    return inflight.remove(key) != nil
  }

  func cancelAll(deviceId: String, epoch: Int64) {
    let prefix = "\(deviceId)|\(epoch)|"
    for key in Array(inflight) where key.hasPrefix(prefix) {
      timeoutTasks.removeValue(forKey: key)?.cancel()
      inflight.remove(key)
    }
  }
}
