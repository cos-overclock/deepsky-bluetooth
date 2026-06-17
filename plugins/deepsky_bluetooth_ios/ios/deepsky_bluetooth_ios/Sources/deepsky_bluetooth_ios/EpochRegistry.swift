import Foundation

final class EpochRegistry {
  private var lastIssued: [String: Int64] = [:]
  private var current: [String: Int64] = [:]
  private let lock = NSLock()

  func allocate(deviceId: String) -> Int64 {
    lock.lock()
    defer { lock.unlock() }

    let next = (lastIssued[deviceId] ?? 0) + 1
    lastIssued[deviceId] = next
    current[deviceId] = next
    return next
  }

  func current(deviceId: String) -> Int64? {
    lock.lock()
    defer { lock.unlock() }

    return current[deviceId]
  }

  func isCurrent(deviceId: String, epoch: Int64) -> Bool {
    lock.lock()
    defer { lock.unlock() }

    return current[deviceId] == epoch
  }

  func retire(deviceId: String) {
    lock.lock()
    defer { lock.unlock() }

    current.removeValue(forKey: deviceId)
  }
}
