import Foundation

/// iOS State Restoration の純粋ロジック。CoreBluetooth に依存せず XCTest で検証する。
/// Review guide §13 を参照。
enum RestorationDecisions {
  /// 復元 snapshot の切断理由を決める。
  /// disconnected な snapshot は必ず reason を持たせる（device ID 一覧へ縮退させない）。
  static func disconnectReason(
    for state: ConnectionStateMessage
  ) -> DisconnectReasonMessage? {
    state == .disconnected ? .unknown : nil
  }

  /// 復元した GATT tree のうち notify/indicate 有効な characteristic handle だけを
  /// 到着順で抽出する。
  static func activeNotifyHandles(
    from entries: [(handle: Int64, isNotifying: Bool)]
  ) -> [Int64] {
    entries.compactMap { $0.isNotifying ? $0.handle : nil }
  }
}

/// 復元中（willRestoreState 〜 ackStateResync）に到着した delegate event を
/// 保持し、flush 時に到着順で取り出す純粋バッファ。CoreBluetooth 非依存。
/// snapshot/ack の前後で event 順序を保つために使う（Review guide §13）。
final class RestorationEventBuffer<Event> {
  private(set) var isBuffering = false
  private var pending: [Event] = []

  /// 復元開始。以前の保留 event は破棄して buffering を有効化する。
  func begin() {
    isBuffering = true
    pending.removeAll()
  }

  /// buffering 中なら event を積んで true を返す（呼び出し側は即時配送しない）。
  /// buffering していなければ何も保持せず false を返す。
  func enqueueIfBuffering(_ event: Event) -> Bool {
    guard isBuffering else { return false }
    pending.append(event)
    return true
  }

  /// buffering を終了し、保持していた event を到着順で返す。
  func flush() -> [Event] {
    isBuffering = false
    let events = pending
    pending.removeAll()
    return events
  }
}
