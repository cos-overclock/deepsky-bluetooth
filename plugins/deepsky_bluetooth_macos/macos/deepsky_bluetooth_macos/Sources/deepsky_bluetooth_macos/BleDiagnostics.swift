#if os(macOS)
import Foundation
import os

/// CoreBluetooth native owner の診断を os_log へ出力する薄い wrapper。
/// Dart の DeepskyBluetoothMacosObserver と同じ診断ポイント（CB state、epoch、
/// queue、handle、sink handover）を Console.app から観測できるようにする。
/// macOS は CoreBluetooth state restoration を持たないため restore 系の診断は持たない。
final class BleDiagnostics {
  static let subsystem = "com.deepsky.bluetooth"

  private let owner = OSLog(subsystem: BleDiagnostics.subsystem, category: "owner")
  private let queue = OSLog(subsystem: BleDiagnostics.subsystem, category: "queue")
  private let handleLog = OSLog(subsystem: BleDiagnostics.subsystem, category: "handle")
  private let sink = OSLog(subsystem: BleDiagnostics.subsystem, category: "sink")

  func adapterState(_ state: String) {
    os_log("adapter state -> %{public}@", log: owner, type: .info, state)
  }

  func connection(deviceId: String, epoch: Int64?, state: String, reason: String?) {
    os_log("connection %{public}@ epoch=%{public}@ -> %{public}@ reason=%{public}@",
           log: owner, type: .info,
           deviceId, epoch.map(String.init) ?? "nil", state, reason ?? "nil")
  }

  func operation(_ kind: String, deviceId: String, epoch: Int64, phase: String) {
    // Int64 は %lld（%d は 32bit でずれる）。
    os_log("op %{public}@ %{public}@ epoch=%{public}lld %{public}@",
           log: queue, type: .debug, kind, deviceId, epoch, phase)
  }

  func handle(deviceId: String, epoch: Int64, handle: Int64, attribute: String) {
    // Int64 は %lld（%d は 32bit でずれる）。
    os_log("handle %{public}@ epoch=%{public}lld %{public}@=%{public}lld",
           log: handleLog, type: .debug, deviceId, epoch, attribute, handle)
  }

  func sinkHandover(engineToken: String, phase: String) {
    os_log("sink handover %{public}@ %{public}@",
           log: sink, type: .info, engineToken, phase)
  }
}
#endif
