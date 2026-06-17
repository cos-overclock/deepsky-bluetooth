# iOS Discovery・HandleRegistry・GattOperationQueue 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `IosBleProcessOwner` に GATT discovery、handle 採番、per-characteristic 操作直列化、操作タイムアウトを実装する。

**Architecture:** `HandleRegistry`（CoreBluetooth 非依存の handle 双方向マップ）と `GattOperationQueue`（per-characteristic 完了追跡 + タイムアウト）を独立クラスとして作成し、`IosBleProcessOwner` に組み込む。

**Tech Stack:** Swift 5.9+, XCTest, CoreBluetooth, Pigeon（生成済み Messages.g.swift）

## Global Constraints

- Swift ファイルはすべて `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/` 以下に置く
- テストファイルは `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Tests/deepsky_bluetooth_iosTests/` 以下
- `#if os(iOS)` ガードは `IosBleProcessOwner.swift` のみ。`HandleRegistry` / `GattOperationQueue` は OS 非依存のためガード不要
- Windows での検証コマンド: `flutter analyze plugins/deepsky_bluetooth_ios`（Swift コンパイルは macOS チェックポイントで行う）
- XCTest は macOS でのみ実行可能。テストコードを先に書き、macOS チェックポイントで実行する
- `IosBleProcessOwner` はシングルトン（`static let shared`）かつ全操作がメインキューで行われる前提

---

## ファイル構成

| 操作 | パス |
|------|------|
| 更新 | `Sources/deepsky_bluetooth_ios/BleErrorMapping.swift` |
| 新規 | `Sources/deepsky_bluetooth_ios/HandleRegistry.swift` |
| 新規 | `Sources/deepsky_bluetooth_ios/GattOperationQueue.swift` |
| 更新 | `Sources/deepsky_bluetooth_ios/IosBleProcessOwner.swift` |
| 更新 | `Tests/deepsky_bluetooth_iosTests/IosNativeOwnerStateTests.swift` |

---

### Task 1: BleErrorMapping 拡張 + HandleRegistry

**Files:**
- Modify: `Sources/deepsky_bluetooth_ios/BleErrorMapping.swift`
- Create: `Sources/deepsky_bluetooth_ios/HandleRegistry.swift`
- Modify: `Tests/deepsky_bluetooth_iosTests/IosNativeOwnerStateTests.swift`

**Interfaces:**
- Produces:
  - `BleErrorMapping.readAmbiguousWhileNotifying() -> PigeonError`
  - `BleErrorMapping.bufferFull() -> PigeonError`
  - `BleErrorMapping.operationTimeout() -> PigeonError`
  - `HandleRegistry.allocate(_:kind:deviceId:) -> Int64`
  - `HandleRegistry.handle(for:) -> Int64?`
  - `HandleRegistry.characteristic(handle:deviceId:) -> AnyObject?`
  - `HandleRegistry.descriptor(handle:deviceId:) -> AnyObject?`
  - `HandleRegistry.clear(deviceId:)`
  - `enum HandleKind { case service, characteristic, descriptor }`

- [ ] **Step 1: BleErrorMapping.swift にエラーコードを追加**

`BleErrorCode` の末尾に追加、`BleErrorMapping` に3メソッド追加:

```swift
enum BleErrorCode {
  static let bluetoothOff = "bluetoothOff"
  static let bluetoothUnavailable = "bluetoothUnavailable"
  static let alreadyScanning = "alreadyScanning"
  static let notFound = "notFound"
  static let notConnected = "notConnected"
  static let notSupported = "notSupported"
  static let failed = "failed"
  static let readAmbiguousWhileNotifying = "readAmbiguousWhileNotifying"
  static let bufferFull = "bufferFull"
  static let operationTimeout = "operationTimeout"
}

func bleError(_ code: String, _ message: String) -> PigeonError {
  PigeonError(code: code, message: message, details: nil)
}

enum BleErrorMapping {
  static func bluetoothOff() -> PigeonError {
    bleError(BleErrorCode.bluetoothOff, "Bluetooth is off")
  }
  static func bluetoothUnavailable(_ message: String) -> PigeonError {
    bleError(BleErrorCode.bluetoothUnavailable, message)
  }
  static func alreadyScanning() -> PigeonError {
    bleError(BleErrorCode.alreadyScanning, "Scan already running")
  }
  static func notFound(_ message: String) -> PigeonError {
    bleError(BleErrorCode.notFound, message)
  }
  static func notConnected() -> PigeonError {
    bleError(BleErrorCode.notConnected, "Not connected")
  }
  static func notSupported(_ message: String) -> PigeonError {
    bleError(BleErrorCode.notSupported, message)
  }
  static func failed(_ message: String) -> PigeonError {
    bleError(BleErrorCode.failed, message)
  }
  static func readAmbiguousWhileNotifying() -> PigeonError {
    bleError(BleErrorCode.readAmbiguousWhileNotifying,
             "read(strictRead: true) is ambiguous while notifying")
  }
  static func bufferFull() -> PigeonError {
    bleError(BleErrorCode.bufferFull, "Write without response buffer is full")
  }
  static func operationTimeout() -> PigeonError {
    bleError(BleErrorCode.operationTimeout, "GATT operation timed out")
  }
}
```

- [ ] **Step 2: HandleRegistry.swift を新規作成**

```swift
import Foundation

enum HandleKind {
  case service
  case characteristic
  case descriptor
}

final class HandleRegistry {
  private var forward: [ObjectIdentifier: Int64] = [:]
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
      break
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
    let chars = charByHandle.removeValue(forKey: deviceId) ?? [:]
    let descs = descByHandle.removeValue(forKey: deviceId) ?? [:]
    for obj in chars.values { forward.removeValue(forKey: ObjectIdentifier(obj)) }
    for obj in descs.values { forward.removeValue(forKey: ObjectIdentifier(obj)) }
  }
}
```

- [ ] **Step 3: XCTest を IosNativeOwnerStateTests.swift に追記**

既存の `IosNativeOwnerStateTests` クラスの末尾（最後の `}` の前）に追記:

```swift
  // MARK: - HandleRegistry

  func testHandleRegistryAssignsMonotonicHandles() {
    let registry = HandleRegistry()
    let a = NSObject()
    let b = NSObject()
    XCTAssertEqual(registry.allocate(a, kind: .characteristic, deviceId: "D"), 1)
    XCTAssertEqual(registry.allocate(b, kind: .descriptor, deviceId: "D"), 2)
  }

  func testHandleRegistryReturnsSameHandleForSameObject() {
    let registry = HandleRegistry()
    let obj = NSObject()
    let h1 = registry.allocate(obj, kind: .characteristic, deviceId: "D")
    let h2 = registry.allocate(obj, kind: .characteristic, deviceId: "D")
    XCTAssertEqual(h1, h2)
  }

  func testHandleRegistryDistinguishesDuplicateUuidObjects() {
    let registry = HandleRegistry()
    let char1 = NSObject()
    let char2 = NSObject()
    let h1 = registry.allocate(char1, kind: .characteristic, deviceId: "D")
    let h2 = registry.allocate(char2, kind: .characteristic, deviceId: "D")
    XCTAssertNotEqual(h1, h2)
  }

  func testHandleRegistryCharacteristicReverseLookup() {
    let registry = HandleRegistry()
    let obj = NSObject()
    let h = registry.allocate(obj, kind: .characteristic, deviceId: "D")
    XCTAssertTrue(registry.characteristic(handle: h, deviceId: "D") === obj)
  }

  func testHandleRegistryDescriptorReverseLookup() {
    let registry = HandleRegistry()
    let obj = NSObject()
    let h = registry.allocate(obj, kind: .descriptor, deviceId: "D")
    XCTAssertTrue(registry.descriptor(handle: h, deviceId: "D") === obj)
  }

  func testHandleRegistryClearRemovesDeviceEntries() {
    let registry = HandleRegistry()
    let obj = NSObject()
    let h = registry.allocate(obj, kind: .characteristic, deviceId: "D")
    registry.clear(deviceId: "D")
    XCTAssertNil(registry.characteristic(handle: h, deviceId: "D"))
    XCTAssertNil(registry.handle(for: obj))
  }

  func testHandleRegistryClearDoesNotAffectOtherDevices() {
    let registry = HandleRegistry()
    let obj = NSObject()
    let h = registry.allocate(obj, kind: .characteristic, deviceId: "A")
    registry.clear(deviceId: "B")
    XCTAssertNotNil(registry.characteristic(handle: h, deviceId: "A"))
  }

  func testHandleRegistryServiceHandleNotInCharLookup() {
    let registry = HandleRegistry()
    let svc = NSObject()
    let h = registry.allocate(svc, kind: .service, deviceId: "D")
    XCTAssertEqual(registry.handle(for: svc), h)
    XCTAssertNil(registry.characteristic(handle: h, deviceId: "D"))
  }
```

- [ ] **Step 4: flutter analyze で Swift ファイルが解析エラーなしを確認**

```powershell
flutter analyze plugins/deepsky_bluetooth_ios
```

Expected: `No issues found!`（Swift コンパイルはしないため XCTest 結果は macOS チェックポイントで確認）

- [ ] **Step 5: コミット**

```powershell
git add plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/BleErrorMapping.swift `
         plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/HandleRegistry.swift `
         plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Tests/deepsky_bluetooth_iosTests/IosNativeOwnerStateTests.swift
git commit -m "feat(ios): add HandleRegistry and extend BleErrorMapping for Issue #31"
```

---

### Task 2: GattOperationQueue

**Files:**
- Create: `Sources/deepsky_bluetooth_ios/GattOperationQueue.swift`
- Modify: `Tests/deepsky_bluetooth_iosTests/IosNativeOwnerStateTests.swift`

**Interfaces:**
- Consumes: なし（独立クラス）
- Produces:
  - `GattOperationQueue.init(timeout: TimeInterval, onTimeout: (String, Int64) -> Void)`
  - `GattOperationQueue.enqueue(key: String, deviceId: String, epoch: Int64) -> Bool`
  - `GattOperationQueue.complete(key: String) -> Bool`
  - `GattOperationQueue.cancelAll(deviceId: String, epoch: Int64)`

- [ ] **Step 1: XCTest を IosNativeOwnerStateTests.swift に追記**

既存テストクラスの末尾（最後の `}` の前）に追記:

```swift
  // MARK: - GattOperationQueue

  func testGattOperationQueueFirstEnqueueSucceeds() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    XCTAssertTrue(queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1))
  }

  func testGattOperationQueueDuplicateEnqueueFails() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1)
    XCTAssertFalse(queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1))
  }

  func testGattOperationQueueDifferentKeysCoexist() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    XCTAssertTrue(queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1))
    XCTAssertTrue(queue.enqueue(key: "D|1|2", deviceId: "D", epoch: 1))
  }

  func testGattOperationQueueCompleteReturnsTrueIfInflight() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1)
    XCTAssertTrue(queue.complete(key: "D|1|1"))
  }

  func testGattOperationQueueCompleteReturnsFalseIfNotInflight() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    XCTAssertFalse(queue.complete(key: "D|1|1"))
  }

  func testGattOperationQueueCompleteAllowsReenqueue() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1)
    _ = queue.complete(key: "D|1|1")
    XCTAssertTrue(queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1))
  }

  func testGattOperationQueueCancelAllClearsInflight() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1)
    _ = queue.enqueue(key: "D|1|2", deviceId: "D", epoch: 1)
    queue.cancelAll(deviceId: "D", epoch: 1)
    XCTAssertTrue(queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1))
    XCTAssertTrue(queue.enqueue(key: "D|1|2", deviceId: "D", epoch: 1))
  }

  func testGattOperationQueueCancelAllDoesNotAffectOtherEpoch() {
    let queue = GattOperationQueue(timeout: 60) { _, _ in }
    _ = queue.enqueue(key: "D|2|1", deviceId: "D", epoch: 2)
    queue.cancelAll(deviceId: "D", epoch: 1)
    XCTAssertFalse(queue.enqueue(key: "D|2|1", deviceId: "D", epoch: 2))
  }

  func testGattOperationQueueTimeoutFiresCallback() {
    let expectation = expectation(description: "timeout")
    let queue = GattOperationQueue(timeout: 0.05) { deviceId, epoch in
      XCTAssertEqual(deviceId, "D")
      XCTAssertEqual(epoch, 1)
      expectation.fulfill()
    }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1)
    waitForExpectations(timeout: 1.0)
  }

  func testGattOperationQueueCompletePreventTimeout() {
    let neverExpectation = expectation(description: "no timeout")
    neverExpectation.isInverted = true
    let queue = GattOperationQueue(timeout: 0.05) { _, _ in
      neverExpectation.fulfill()
    }
    _ = queue.enqueue(key: "D|1|1", deviceId: "D", epoch: 1)
    _ = queue.complete(key: "D|1|1")
    waitForExpectations(timeout: 0.2)
  }
```

- [ ] **Step 2: GattOperationQueue.swift を新規作成**

```swift
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
```

- [ ] **Step 3: flutter analyze で解析エラーなしを確認**

```powershell
flutter analyze plugins/deepsky_bluetooth_ios
```

Expected: `No issues found!`

- [ ] **Step 4: コミット**

```powershell
git add plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/GattOperationQueue.swift `
         plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Tests/deepsky_bluetooth_iosTests/IosNativeOwnerStateTests.swift
git commit -m "feat(ios): add GattOperationQueue for Issue #31"
```

---

### Task 3: Discovery 実装（IosBleProcessOwner 更新）

**Files:**
- Modify: `Sources/deepsky_bluetooth_ios/IosBleProcessOwner.swift`

**Interfaces:**
- Consumes:
  - `HandleRegistry.allocate(_:kind:deviceId:) -> Int64`
  - `HandleRegistry.handle(for:) -> Int64?`
  - `HandleRegistry.clear(deviceId:)`
  - `GattOperationQueue.enqueue(key:deviceId:epoch:) -> Bool`
  - `GattOperationQueue.complete(key:) -> Bool`
  - `BleErrorMapping.failed(_:) -> PigeonError`
- Produces: `discoverServices` が `[ServiceMessage]` を返す。`HandleRegistry` に全属性の handle が登録済み。

- [ ] **Step 1: IosBleProcessOwner に新規プロパティと init 更新を追加**

クラス先頭の既存プロパティ群（`private var restoredDeviceIds` の後）に追記:

```swift
  private let handleRegistry = HandleRegistry()
  private var opQueue: GattOperationQueue!
  private var discoverCompletions: [String: (Result<[ServiceMessage], Error>) -> Void] = [:]
  private var pendingDiscovery: [String: Int] = [:]
  private var readCompletions: [String: (Result<FlutterStandardTypedData, Error>) -> Void] = [:]
  private var writeCompletions: [String: (Result<Void, Error>) -> Void] = [:]
  private var notifyCompletions: [String: (Result<Void, Error>) -> Void] = [:]
  private var descriptorReadCompletions: [String: (Result<FlutterStandardTypedData, Error>) -> Void] = [:]
  private var descriptorWriteCompletions: [String: (Result<Void, Error>) -> Void] = [:]
  private var rssiCompletions: [String: (Result<Int64, Error>) -> Void] = [:]
```

`private override init()` を次のように更新（`super.init()` の後に `opQueue` 初期化を追加）:

```swift
  private override init() {
    super.init()
    opQueue = GattOperationQueue(onTimeout: { [weak self] deviceId, epoch in
      self?.handleOperationTimeout(deviceId: deviceId, epoch: epoch)
    })
  }
```

- [ ] **Step 2: IosBleProcessOwner にヘルパーメソッドを追加**

クラス末尾の `#endif` 直前の `private` メソッド群に追加:

```swift
  // MARK: - GATT ヘルパー

  private func fullUuid(_ uuid: CBUUID) -> String {
    let s = uuid.uuidString.lowercased()
    switch s.count {
    case 4: return "0000\(s)-0000-1000-8000-00805f9b34fb"
    case 8: return "\(s)-0000-1000-8000-00805f9b34fb"
    default: return s
    }
  }

  private func charKey(_ target: CharacteristicTargetMessage) -> String {
    "\(target.deviceId)|\(target.connectionEpoch)|\(target.characteristicHandle)"
  }

  private func charKey(_ peripheral: CBPeripheral, _ ch: CBCharacteristic) -> String? {
    let deviceId = peripheral.identifier.uuidString
    guard let epoch = state.currentEpoch(deviceId: deviceId),
          let handle = handleRegistry.handle(for: ch) else { return nil }
    return "\(deviceId)|\(epoch)|\(handle)"
  }

  private func descKey(_ target: DescriptorTargetMessage) -> String {
    "\(target.deviceId)|\(target.connectionEpoch)|\(target.characteristicHandle)|\(target.descriptorHandle)"
  }

  private func descKey(_ peripheral: CBPeripheral, _ d: CBDescriptor) -> String? {
    guard let ch = d.characteristic else { return nil }
    let deviceId = peripheral.identifier.uuidString
    guard let epoch = state.currentEpoch(deviceId: deviceId),
          let charHandle = handleRegistry.handle(for: ch),
          let descHandle = handleRegistry.handle(for: d) else { return nil }
    return "\(deviceId)|\(epoch)|\(charHandle)|\(descHandle)"
  }

  private func rssiKey(_ deviceId: String, _ epoch: Int64) -> String {
    "\(deviceId)|\(epoch)|rssi"
  }

  private func discoveryKey(_ deviceId: String, _ epoch: Int64) -> String {
    "\(deviceId)|\(epoch)|discovery"
  }

  private func findCharacteristic(
    _ target: CharacteristicTargetMessage
  ) -> Result<(CBPeripheral, CBCharacteristic), Error> {
    guard state.isCurrent(deviceId: target.deviceId, epoch: target.connectionEpoch),
          let peripheral = peripheralsByDeviceId[target.deviceId],
          peripheral.state == .connected
    else {
      return .failure(BleErrorMapping.notConnected())
    }
    guard let ch = handleRegistry.characteristic(
      handle: target.characteristicHandle, deviceId: target.deviceId) as? CBCharacteristic
    else {
      return .failure(BleErrorMapping.notFound(
        "Characteristic handle \(target.characteristicHandle) not found"))
    }
    return .success((peripheral, ch))
  }

  private func findDescriptor(
    _ target: DescriptorTargetMessage
  ) -> Result<(CBPeripheral, CBDescriptor), Error> {
    guard state.isCurrent(deviceId: target.deviceId, epoch: target.connectionEpoch),
          let peripheral = peripheralsByDeviceId[target.deviceId],
          peripheral.state == .connected
    else {
      return .failure(BleErrorMapping.notConnected())
    }
    guard let d = handleRegistry.descriptor(
      handle: target.descriptorHandle, deviceId: target.deviceId) as? CBDescriptor
    else {
      return .failure(BleErrorMapping.notFound(
        "Descriptor handle \(target.descriptorHandle) not found"))
    }
    return .success((peripheral, d))
  }

  private func rebuildHandles(peripheral: CBPeripheral) -> [ServiceMessage] {
    let deviceId = peripheral.identifier.uuidString
    handleRegistry.clear(deviceId: deviceId)
    return (peripheral.services ?? []).map { service in
      let svcHandle = handleRegistry.allocate(service, kind: .service, deviceId: deviceId)
      let characteristics = (service.characteristics ?? []).map { ch -> CharacteristicMessage in
        let charHandle = handleRegistry.allocate(ch, kind: .characteristic, deviceId: deviceId)
        let descriptors = (ch.descriptors ?? []).map { d -> DescriptorMessage in
          let descHandle = handleRegistry.allocate(d, kind: .descriptor, deviceId: deviceId)
          return DescriptorMessage(handle: descHandle, uuid: fullUuid(d.uuid))
        }
        return CharacteristicMessage(
          handle: charHandle,
          serviceHandle: svcHandle,
          uuid: fullUuid(ch.uuid),
          canRead: ch.properties.contains(.read),
          canWriteWithResponse: ch.properties.contains(.write),
          canWriteWithoutResponse: ch.properties.contains(.writeWithoutResponse),
          canNotify: ch.properties.contains(.notify),
          canIndicate: ch.properties.contains(.indicate),
          descriptors: descriptors
        )
      }
      return ServiceMessage(handle: svcHandle, uuid: fullUuid(service.uuid),
                            characteristics: characteristics)
    }
  }
```

- [ ] **Step 3: discoverServices スタブを実装に置換**

既存の `discoverServices` メソッド全体を置換:

```swift
  func discoverServices(
    deviceId: String,
    connectionEpoch: Int64,
    completion: @escaping (Result<[ServiceMessage], Error>) -> Void
  ) {
    guard state.isCurrent(deviceId: deviceId, epoch: connectionEpoch),
          let peripheral = peripheralsByDeviceId[deviceId],
          peripheral.state == .connected
    else {
      completion(.failure(BleErrorMapping.notConnected()))
      return
    }
    let key = discoveryKey(deviceId, connectionEpoch)
    guard opQueue.enqueue(key: key, deviceId: deviceId, epoch: connectionEpoch) else {
      completion(.failure(BleErrorMapping.failed("Service discovery already in progress")))
      return
    }
    discoverCompletions[deviceId] = completion
    peripheral.discoverServices(nil)
  }
```

- [ ] **Step 4: CBPeripheralDelegate discovery メソッドを追加**

`IosBleProcessOwner` クラス内（`// MARK: - GATT ヘルパー` の上あたりに追加）:

```swift
  // MARK: - CBPeripheralDelegate (discovery)

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    let deviceId = peripheral.identifier.uuidString
    guard discoverCompletions[deviceId] != nil else { return }
    if let error {
      guard let epoch = state.currentEpoch(deviceId: deviceId) else { return }
      _ = opQueue.complete(discoveryKey(deviceId, epoch))
      pendingDiscovery.removeValue(forKey: deviceId)
      discoverCompletions.removeValue(forKey: deviceId)?(
        .failure(BleErrorMapping.failed(error.localizedDescription)))
      return
    }
    let services = peripheral.services ?? []
    if services.isEmpty {
      guard let epoch = state.currentEpoch(deviceId: deviceId) else { return }
      _ = opQueue.complete(discoveryKey(deviceId, epoch))
      discoverCompletions.removeValue(forKey: deviceId)?(.success([]))
      return
    }
    pendingDiscovery[deviceId] = services.count
    services.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverCharacteristicsFor service: CBService,
    error: Error?
  ) {
    let deviceId = peripheral.identifier.uuidString
    guard discoverCompletions[deviceId] != nil else { return }
    let chars = service.characteristics ?? []
    pendingDiscovery[deviceId, default: 0] += chars.count - 1
    chars.forEach { peripheral.discoverDescriptors(for: $0) }
    finishDiscoveryIfDone(peripheral, deviceId: deviceId)
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverDescriptorsFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    let deviceId = peripheral.identifier.uuidString
    pendingDiscovery[deviceId, default: 0] -= 1
    finishDiscoveryIfDone(peripheral, deviceId: deviceId)
  }

  private func finishDiscoveryIfDone(_ peripheral: CBPeripheral, deviceId: String) {
    guard pendingDiscovery[deviceId] == 0,
          let epoch = state.currentEpoch(deviceId: deviceId),
          let completion = discoverCompletions.removeValue(forKey: deviceId)
    else { return }
    pendingDiscovery.removeValue(forKey: deviceId)
    let services = rebuildHandles(peripheral: peripheral)
    _ = opQueue.complete(discoveryKey(deviceId, epoch))
    completion(.success(services))
  }
```

- [ ] **Step 5: disconnect に handleRegistry.clear を追加**

既存 `disconnect` メソッド内、`if let peripheral = peripheralsByDeviceId.removeValue(forKey: deviceId)` の前に追加:

```swift
    handleRegistry.clear(deviceId: deviceId)
```

全体で、この箇所の `disconnect` メソッドは次のようになる:

```swift
  func disconnect(
    deviceId: String,
    connectionEpoch: Int64,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard state.disconnectRequested(deviceId: deviceId, epoch: connectionEpoch) else {
      completion(.failure(BleErrorMapping.notConnected()))
      return
    }
    handleRegistry.clear(deviceId: deviceId)
    if let peripheral = peripheralsByDeviceId.removeValue(forKey: deviceId) {
      central?.cancelPeripheralConnection(peripheral)
    }
    emitConnectionState(
      deviceId: deviceId,
      epoch: connectionEpoch,
      state: .disconnected,
      reason: .userRequested
    )
    completion(.success(()))
  }
```

- [ ] **Step 6: centralManager didDisconnectPeripheral に handleRegistry.clear を追加**

既存の `centralManager(_:didDisconnectPeripheral:error:)` の末尾の `emitConnectionState` 呼び出し直前に追加:

```swift
    handleRegistry.clear(deviceId: deviceId)
    emitConnectionState(
      deviceId: deviceId,
      epoch: epoch,
      state: .disconnected,
      reason: error == nil ? .userRequested : .connectionLost
    )
```

- [ ] **Step 7: flutter analyze で解析エラーなしを確認**

```powershell
flutter analyze plugins/deepsky_bluetooth_ios
```

Expected: `No issues found!`

- [ ] **Step 8: コミット**

```powershell
git add plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/IosBleProcessOwner.swift
git commit -m "feat(ios): implement service discovery with HandleRegistry for Issue #31"
```

---

### Task 4: GATT 操作実装（read / write / setNotify / descriptor / RSSI）

**Files:**
- Modify: `Sources/deepsky_bluetooth_ios/IosBleProcessOwner.swift`

**Interfaces:**
- Consumes:
  - `GattOperationQueue.enqueue(key:deviceId:epoch:) -> Bool`
  - `GattOperationQueue.complete(key:) -> Bool`
  - `HandleRegistry.characteristic(handle:deviceId:) -> AnyObject?`
  - `HandleRegistry.descriptor(handle:deviceId:) -> AnyObject?`
  - `BleErrorMapping.readAmbiguousWhileNotifying() -> PigeonError`
  - `BleErrorMapping.bufferFull() -> PigeonError`
  - `charKey(_:)`, `descKey(_:)`, `rssiKey(_:_:)` ヘルパー（Task 3 で追加済み）
  - `findCharacteristic(_:)`, `findDescriptor(_:)` ヘルパー（Task 3 で追加済み）

- [ ] **Step 1: readCharacteristic スタブを置換**

```swift
  func readCharacteristic(
    target: CharacteristicTargetMessage,
    strictRead: Bool,
    completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void
  ) {
    switch findCharacteristic(target) {
    case .failure(let e):
      completion(.failure(e))
    case .success(let (peripheral, ch)):
      guard ch.properties.contains(.read) else {
        completion(.failure(BleErrorMapping.notSupported("Read not supported")))
        return
      }
      if strictRead, ch.isNotifying {
        completion(.failure(BleErrorMapping.readAmbiguousWhileNotifying()))
        return
      }
      let key = charKey(target)
      guard opQueue.enqueue(key: key, deviceId: target.deviceId, epoch: target.connectionEpoch) else {
        completion(.failure(BleErrorMapping.failed("A read for this characteristic is already in flight")))
        return
      }
      readCompletions[key] = completion
      peripheral.readValue(for: ch)
    }
  }
```

- [ ] **Step 2: writeCharacteristic スタブを置換**

```swift
  func writeCharacteristic(
    target: CharacteristicTargetMessage,
    value: FlutterStandardTypedData,
    withResponse: Bool,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    switch findCharacteristic(target) {
    case .failure(let e):
      completion(.failure(e))
    case .success(let (peripheral, ch)):
      if withResponse {
        guard ch.properties.contains(.write) else {
          completion(.failure(BleErrorMapping.notSupported("Write with response not supported")))
          return
        }
        let key = charKey(target)
        guard opQueue.enqueue(key: key, deviceId: target.deviceId, epoch: target.connectionEpoch) else {
          completion(.failure(BleErrorMapping.failed("A write for this characteristic is already in flight")))
          return
        }
        writeCompletions[key] = completion
        peripheral.writeValue(value.data, for: ch, type: .withResponse)
      } else {
        guard ch.properties.contains(.writeWithoutResponse) else {
          completion(.failure(BleErrorMapping.notSupported("Write without response not supported")))
          return
        }
        guard peripheral.canSendWriteWithoutResponse else {
          completion(.failure(BleErrorMapping.bufferFull()))
          return
        }
        peripheral.writeValue(value.data, for: ch, type: .withoutResponse)
        completion(.success(()))
      }
    }
  }
```

- [ ] **Step 3: setNotify スタブを置換**

```swift
  func setNotify(
    target: CharacteristicTargetMessage,
    type: NotifyTypeMessage,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    switch findCharacteristic(target) {
    case .failure(let e):
      completion(.failure(e))
    case .success(let (peripheral, ch)):
      let enabled = type != .disable
      guard ch.properties.contains(.notify) || ch.properties.contains(.indicate) else {
        completion(.failure(BleErrorMapping.notSupported("Notify/Indicate not supported")))
        return
      }
      let key = charKey(target)
      guard opQueue.enqueue(key: key, deviceId: target.deviceId, epoch: target.connectionEpoch) else {
        completion(.failure(BleErrorMapping.failed("A notify state change for this characteristic is already in flight")))
        return
      }
      notifyCompletions[key] = completion
      peripheral.setNotifyValue(enabled, for: ch)
    }
  }
```

- [ ] **Step 4: readDescriptor スタブを置換**

```swift
  func readDescriptor(
    target: DescriptorTargetMessage,
    completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void
  ) {
    switch findDescriptor(target) {
    case .failure(let e):
      completion(.failure(e))
    case .success(let (peripheral, d)):
      let key = descKey(target)
      guard opQueue.enqueue(key: key, deviceId: target.deviceId, epoch: target.connectionEpoch) else {
        completion(.failure(BleErrorMapping.failed("A descriptor read is already in flight")))
        return
      }
      descriptorReadCompletions[key] = completion
      peripheral.readValue(for: d)
    }
  }
```

- [ ] **Step 5: writeDescriptor スタブを置換**

```swift
  func writeDescriptor(
    target: DescriptorTargetMessage,
    value: FlutterStandardTypedData,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    switch findDescriptor(target) {
    case .failure(let e):
      completion(.failure(e))
    case .success(let (peripheral, d)):
      let key = descKey(target)
      guard opQueue.enqueue(key: key, deviceId: target.deviceId, epoch: target.connectionEpoch) else {
        completion(.failure(BleErrorMapping.failed("A descriptor write is already in flight")))
        return
      }
      descriptorWriteCompletions[key] = completion
      peripheral.writeValue(value.data, for: d)
    }
  }
```

- [ ] **Step 6: readRssi スタブを置換**

```swift
  func readRssi(
    deviceId: String,
    connectionEpoch: Int64,
    completion: @escaping (Result<Int64, Error>) -> Void
  ) {
    guard state.isCurrent(deviceId: deviceId, epoch: connectionEpoch),
          let peripheral = peripheralsByDeviceId[deviceId],
          peripheral.state == .connected
    else {
      completion(.failure(BleErrorMapping.notConnected()))
      return
    }
    let key = rssiKey(deviceId, connectionEpoch)
    guard opQueue.enqueue(key: key, deviceId: deviceId, epoch: connectionEpoch) else {
      completion(.failure(BleErrorMapping.failed("RSSI read already in flight")))
      return
    }
    rssiCompletions[deviceId] = completion
    peripheral.readRSSI()
  }
```

- [ ] **Step 7: CBPeripheralDelegate GATT コールバックを追加**

クラス内の discovery delegate の後に追加:

```swift
  // MARK: - CBPeripheralDelegate (GATT operations)

  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateValueFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    guard let key = charKey(peripheral, characteristic) else { return }
    let data = characteristic.value ?? Data()
    if let completion = readCompletions.removeValue(forKey: key) {
      _ = opQueue.complete(key)
      if let error {
        completion(.failure(BleErrorMapping.failed(error.localizedDescription)))
      } else {
        completion(.success(FlutterStandardTypedData(bytes: data)))
        // read 応答と notify を区別できないため、notify 有効中なら同値を values にも流す
        if characteristic.isNotifying {
          emitCharacteristicValue(peripheral, characteristic, data: data)
        }
      }
      return
    }
    // pending read がなければ notify イベント
    guard error == nil else { return }
    emitCharacteristicValue(peripheral, characteristic, data: data)
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didWriteValueFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    guard let key = charKey(peripheral, characteristic),
          let completion = writeCompletions.removeValue(forKey: key) else { return }
    _ = opQueue.complete(key)
    if let error {
      completion(.failure(BleErrorMapping.failed(error.localizedDescription)))
    } else {
      completion(.success(()))
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateNotificationStateFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    guard let key = charKey(peripheral, characteristic),
          let completion = notifyCompletions.removeValue(forKey: key) else { return }
    _ = opQueue.complete(key)
    if let error {
      completion(.failure(BleErrorMapping.failed(error.localizedDescription)))
    } else {
      completion(.success(()))
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateValueFor descriptor: CBDescriptor,
    error: Error?
  ) {
    guard let key = descKey(peripheral, descriptor),
          let completion = descriptorReadCompletions.removeValue(forKey: key) else { return }
    _ = opQueue.complete(key)
    if let error {
      completion(.failure(BleErrorMapping.failed(error.localizedDescription)))
    } else {
      let data = descriptor.value as? Data ?? Data()
      completion(.success(FlutterStandardTypedData(bytes: data)))
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didWriteValueFor descriptor: CBDescriptor,
    error: Error?
  ) {
    guard let key = descKey(peripheral, descriptor),
          let completion = descriptorWriteCompletions.removeValue(forKey: key) else { return }
    _ = opQueue.complete(key)
    if let error {
      completion(.failure(BleErrorMapping.failed(error.localizedDescription)))
    } else {
      completion(.success(()))
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
    let deviceId = peripheral.identifier.uuidString
    guard let epoch = state.currentEpoch(deviceId: deviceId) else { return }
    let key = rssiKey(deviceId, epoch)
    guard let completion = rssiCompletions.removeValue(forKey: deviceId) else { return }
    _ = opQueue.complete(key)
    if let error {
      completion(.failure(BleErrorMapping.failed(error.localizedDescription)))
    } else {
      completion(.success(RSSI.int64Value))
    }
  }

  private func emitCharacteristicValue(
    _ peripheral: CBPeripheral,
    _ ch: CBCharacteristic,
    data: Data
  ) {
    let deviceId = peripheral.identifier.uuidString
    guard let epoch = state.currentEpoch(deviceId: deviceId),
          let handle = handleRegistry.handle(for: ch) else { return }
    activeCallbacks?.onCharacteristicValue(
      deviceId: deviceId,
      connectionEpoch: epoch,
      characteristicHandle: handle,
      value: FlutterStandardTypedData(bytes: data)
    ) { _ in }
  }
```

- [ ] **Step 8: flutter analyze で解析エラーなしを確認**

```powershell
flutter analyze plugins/deepsky_bluetooth_ios
```

Expected: `No issues found!`

- [ ] **Step 9: コミット**

```powershell
git add plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/IosBleProcessOwner.swift
git commit -m "feat(ios): implement GATT read/write/notify/descriptor/RSSI for Issue #31"
```

---

### Task 5: タイムアウト実装 + dispose 更新

**Files:**
- Modify: `Sources/deepsky_bluetooth_ios/IosBleProcessOwner.swift`

**Interfaces:**
- Consumes: `GattOperationQueue.cancelAll(deviceId:epoch:)`, `BleErrorMapping.operationTimeout()`, `activeCallbacks?.onOperationTimeout`
- Produces: `handleOperationTimeout(deviceId:epoch:)` が epoch 退役 + 切断通知 + 全 in-flight 失敗を行う

- [ ] **Step 1: failPendingOperations と handleOperationTimeout を追加**

`// MARK: - GATT ヘルパー` の直前に追加:

```swift
  // MARK: - タイムアウト

  private func failPendingOperations(deviceId: String) {
    let err = BleErrorMapping.operationTimeout()
    discoverCompletions.removeValue(forKey: deviceId)?(.failure(err))
    pendingDiscovery.removeValue(forKey: deviceId)
    for key in Array(readCompletions.keys) where key.hasPrefix("\(deviceId)|") {
      readCompletions.removeValue(forKey: key)?(.failure(err))
    }
    for key in Array(writeCompletions.keys) where key.hasPrefix("\(deviceId)|") {
      writeCompletions.removeValue(forKey: key)?(.failure(err))
    }
    for key in Array(notifyCompletions.keys) where key.hasPrefix("\(deviceId)|") {
      notifyCompletions.removeValue(forKey: key)?(.failure(err))
    }
    for key in Array(descriptorReadCompletions.keys) where key.hasPrefix("\(deviceId)|") {
      descriptorReadCompletions.removeValue(forKey: key)?(.failure(err))
    }
    for key in Array(descriptorWriteCompletions.keys) where key.hasPrefix("\(deviceId)|") {
      descriptorWriteCompletions.removeValue(forKey: key)?(.failure(err))
    }
    rssiCompletions.removeValue(forKey: deviceId)?(.failure(err))
  }

  private func handleOperationTimeout(deviceId: String, epoch: Int64) {
    activeCallbacks?.onOperationTimeout(deviceId: deviceId, connectionEpoch: epoch) { _ in }
    failPendingOperations(deviceId: deviceId)
    opQueue.cancelAll(deviceId: deviceId, epoch: epoch)
    _ = state.disconnectRequested(deviceId: deviceId, epoch: epoch)
    if let peripheral = peripheralsByDeviceId[deviceId] {
      central?.cancelPeripheralConnection(peripheral)
    }
    handleRegistry.clear(deviceId: deviceId)
    emitConnectionState(
      deviceId: deviceId, epoch: epoch,
      state: .disconnected, reason: .operationTimeout
    )
  }
```

- [ ] **Step 2: dispose を更新してすべての in-flight を失敗させる**

既存 `dispose` メソッドを置換:

```swift
  func dispose() {
    stopScan()
    for (deviceId, peripheral) in peripheralsByDeviceId {
      if let epoch = state.currentEpoch(deviceId: deviceId) {
        _ = state.disconnectRequested(deviceId: deviceId, epoch: epoch)
        opQueue.cancelAll(deviceId: deviceId, epoch: epoch)
      }
      failPendingOperations(deviceId: deviceId)
      handleRegistry.clear(deviceId: deviceId)
      central?.cancelPeripheralConnection(peripheral)
    }
    peripheralsByDeviceId.removeAll()
    callbacksByEngine.removeAll()
    activeEngineToken = nil
    restoredDeviceIds.removeAll()
  }
```

- [ ] **Step 3: flutter analyze で解析エラーなしを確認**

```powershell
flutter analyze plugins/deepsky_bluetooth_ios
```

Expected: `No issues found!`

- [ ] **Step 4: コミット**

```powershell
git add plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/IosBleProcessOwner.swift
git commit -m "feat(ios): implement operation timeout and epoch retirement for Issue #31"
```

---

### Task 6: [macOS] XCTest・Swift build チェックポイント

macOS マシンで実行。Windows では実行不可。

**Files:** なし（検証のみ）

- [ ] **Step 1: XCTest を実行**

```bash
cd plugins/deepsky_bluetooth_ios/example
xcodebuild test \
  -scheme Runner \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:RunnerTests \
  | xcpretty
```

または Swift Package Test（iOS Simulator 不要な場合）:

```bash
cd plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios
swift test
```

Expected: 全テスト PASS（`HandleRegistry` 8 ケース + `GattOperationQueue` 10 ケース + 既存 `IosNativeOwnerState` 4 ケース = 合計 22 ケース）

- [ ] **Step 2: iOS ビルド確認**

```bash
cd plugins/deepsky_bluetooth_ios/example
flutter build ios --no-codesign --debug
```

Expected: ビルド成功

- [ ] **Step 3: Swift コンパイルエラーがあった場合は修正してコミット**

```bash
git add plugins/deepsky_bluetooth_ios/
git commit -m "fix(ios): fix Swift compile errors found at macOS checkpoint"
```

エラーがない場合はコミット不要。

---

## チェックリスト（受け入れ条件対照）

| 受け入れ条件 | 実装箇所 |
|---|---|
| 重複 UUID 属性を handle で区別できる | Task 1: HandleRegistry, Task 3: rebuildHandles |
| 同時 1 operation を保証する（per-characteristic） | Task 2: GattOperationQueue.enqueue 拒否, Task 4: 全 GATT ops |
| timeout 後の遅延 delegate を破棄する | Task 5: epoch 退役 + failPendingOperations |
| registry/queue の Swift XCTest が通る | Task 1/2: XCTest, Task 6: macOS チェックポイント |
