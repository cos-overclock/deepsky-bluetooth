import Foundation

enum HandleKind {
  case service
  case characteristic
  case descriptor
}

/// CoreBluetooth 非依存の handle registry。
/// service/characteristic/descriptor へ device ごとに単調増加 handle を採番し、
/// 重複 UUID を ObjectIdentifier で区別する。epoch 退役・切断時は clear で逆引きごと破棄する。
final class HandleRegistry {
  private var forward: [ObjectIdentifier: Int64] = [:]
  private var servicesByDeviceId: [String: [Int64: AnyObject]] = [:]
  private var charByHandle: [String: [Int64: AnyObject]] = [:]
  private var descByHandle: [String: [Int64: AnyObject]] = [:]
  private var nextHandle: Int64 = 1

  func allocate(_ object: AnyObject, kind: HandleKind, deviceId: String) -> Int64 {
    let id = ObjectIdentifier(object)
    if let existing = forward[id] { return existing }
    let handle = nextHandle
    nextHandle += 1
    forward[id] = handle
    switch kind {
    case .service:
      if servicesByDeviceId[deviceId] == nil { servicesByDeviceId[deviceId] = [:] }
      servicesByDeviceId[deviceId]![handle] = object
    case .characteristic:
      if charByHandle[deviceId] == nil { charByHandle[deviceId] = [:] }
      charByHandle[deviceId]![handle] = object
    case .descriptor:
      if descByHandle[deviceId] == nil { descByHandle[deviceId] = [:] }
      descByHandle[deviceId]![handle] = object
    }
    return handle
  }

  func handle(for object: AnyObject) -> Int64? {
    forward[ObjectIdentifier(object)]
  }

  func characteristic(handle: Int64, deviceId: String) -> AnyObject? {
    charByHandle[deviceId]?[handle]
  }

  func descriptor(handle: Int64, deviceId: String) -> AnyObject? {
    descByHandle[deviceId]?[handle]
  }

  func clear(deviceId: String) {
    let services = servicesByDeviceId.removeValue(forKey: deviceId) ?? [:]
    let chars = charByHandle.removeValue(forKey: deviceId) ?? [:]
    let descs = descByHandle.removeValue(forKey: deviceId) ?? [:]
    for obj in services.values { forward.removeValue(forKey: ObjectIdentifier(obj)) }
    for obj in chars.values { forward.removeValue(forKey: ObjectIdentifier(obj)) }
    for obj in descs.values { forward.removeValue(forKey: ObjectIdentifier(obj)) }
  }
}
