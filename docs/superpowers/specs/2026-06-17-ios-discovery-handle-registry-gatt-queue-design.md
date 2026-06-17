# iOS Discovery・HandleRegistry・GATT Queue 設計

Issue #31 実装設計。2026-06-17。

## スコープ

Issue #30 で実装した `IosBleProcessOwner` / `IosNativeOwnerState` / `EpochRegistry` を前提とし、
以下を追加する。

- service / characteristic / descriptor の discovery と handle 採番
- CoreBluetooth object の handle 逆引き（HandleRegistry）
- per-characteristic FIFO 完了マップと重複要求拒否（GattOperationQueue）
- 操作タイムアウト時の epoch 退役と切断通知

GATT 操作（read / write / setNotify / descriptor / RSSI）の実装も同 PR に含める。

## 前提

- `setNotify` の pigeon シグネチャは `type: NotifyTypeMessage`（`.disable` / `.notify` / `.indicate`）。
- タイムアウトは `onOperationTimeout(deviceId, epoch)` で Dart に通知してから epoch を退役する。
- iOS は CoreBluetooth callback が characteristic スコープのため device 単位 FIFO ではなく
  per-characteristic 直列化とする（同一 characteristic への同時 read/write を拒否）。

## コンポーネント設計

### HandleRegistry（新規、CoreBluetooth 非依存）

```
final class HandleRegistry {
  // ObjectIdentifier(CBObject) → Int64 handle
  // (deviceId, Int64) → AnyObject（CBCharacteristic または CBDescriptor）
  // handle カウンタはデバイスをまたいで単調増加

  func allocate(object: AnyObject, deviceId: String) -> Int64
  func handle(for object: AnyObject) -> Int64?
  func object(handle: Int64, deviceId: String) -> AnyObject?
  func clear(deviceId: String)
}
```

- `allocate` は同一 `ObjectIdentifier` で再呼び出しされた場合、既存 handle を返す。
- `clear` は `characteristicsByHandle[deviceId]` と `descriptorsByHandle[deviceId]` を削除する。
  `forward`（ObjectIdentifier → handle）も対象 deviceId のエントリを削除する。
- XCTest で `NSObject` サブクラスのモックを使って採番・逆引き・clear を検証する。

### GattOperationQueue（新規、CoreBluetooth 非依存）

```
final class GattOperationQueue {
  init(timeout: TimeInterval = 30,
       onTimeout: @escaping (String, Int64) -> Void)

  // key = "deviceId|epoch|charHandle" または "deviceId|epoch|charHandle|descHandle"
  func enqueue(key: String) -> Bool          // false なら already in-flight → caller はエラーを返す
  func complete(key: String) -> Bool         // in-flight を解除。未登録なら false
  func cancelAll(deviceId: String, epoch: Int64)  // epoch 退役時に全 in-flight を破棄
}
```

- `enqueue` が `true` を返した場合のみ `DispatchWorkItem` をスケジュールする。
- タイムアウト発火時：`complete(key)` → `onTimeout(deviceId, epoch)` を呼ぶ。
- `cancelAll` はタイムアウト `DispatchWorkItem` をキャンセルして辞書を清掃する。
- タイムアウト処理はメインキューで行う（CoreBluetooth delegate と同キュー）。
- `timeout` は init injection 可能なので XCTest では 0.1s を使う。

### IosBleProcessOwner 更新

`HandleRegistry` と `GattOperationQueue` のインスタンスを保持する。

```swift
private let handleRegistry = HandleRegistry()
private lazy var opQueue = GattOperationQueue(
    timeout: 30,
    onTimeout: { [weak self] deviceId, epoch in
        self?.handleOperationTimeout(deviceId: deviceId, epoch: epoch)
    }
)
```

#### discovery フロー

```
discoverServices(deviceId, connectionEpoch)
  guard isCurrent + peripheral.state == connected
  discoverCompletions[deviceId] = completion
  peripheral.discoverServices(nil)

didDiscoverServices
  guard completion exists, no error
  pendingDiscovery[deviceId] = services.count
  forEach service → discoverCharacteristics(nil, for: service)

didDiscoverCharacteristicsFor service
  guard completion exists
  let chars = service.characteristics ?? []
  pendingDiscovery[deviceId] += chars.count - 1  // service 1 → chars.count
  forEach char → discoverDescriptors(for: char)
  finishIfDone()

didDiscoverDescriptorsFor char
  pendingDiscovery[deviceId] -= 1
  finishIfDone()

finishIfDone()
  guard pendingDiscovery[deviceId] == 0, let completion
  handleRegistry.clear(deviceId: deviceId)   // 既存 handles を破棄
  rebuildHandles(peripheral: peripheral)      // 新規採番
  completion(.success(serviceMessages))
```

#### rebuildHandles

```swift
for service in peripheral.services ?? [] {
    handleRegistry.allocate(object: service, deviceId: deviceId)
    for char in service.characteristics ?? [] {
        handleRegistry.allocate(object: char, deviceId: deviceId)
        for desc in char.descriptors ?? [] {
            handleRegistry.allocate(object: desc, deviceId: deviceId)
        }
    }
}
```

`ServiceMessage` / `CharacteristicMessage` / `DescriptorMessage` は
`handleRegistry.handle(for:)` で取得した handle を使って組み立てる。

#### GATT 操作（read / write / setNotify / readDescriptor / writeDescriptor / readRssi）

```
readCharacteristic(target, strictRead)
  1. guard epoch isCurrent + connectedPeripheral
  2. guard handleRegistry.object → CBCharacteristic
  3. strictRead && ch.isNotifying → fail(.readAmbiguousWhileNotifying)
  4. opQueue.enqueue(charKey(target)) == false → fail(.failed, "already in-flight")
  5. readCompletions[charKey(target)] = completion
  6. peripheral.readValue(for: ch)
```

read 完了 callback（`didUpdateValueFor characteristic`）:
- `readCompletions[key]` が存在する → read 応答として完了
  - notify 有効なら同値を `onCharacteristicValue` にも流す
- 存在しない → notify イベントとして `onCharacteristicValue` を emit
- どちらの場合も `opQueue.complete(key)` を呼ぶ

write with response / setNotify / readDescriptor / writeDescriptor も同様に
`opQueue.enqueue` → completion 格納 → 操作発行 → callback で `opQueue.complete`。

write without response は完了 callback がないため `opQueue` は使わない。
`canSendWriteWithoutResponse` で送信可能を確認し、不可なら `.bufferFull` を返す。

readRssi は characteristic handle を持たないため、キーを `"deviceId|epoch|rssi"` とする。
`rssiCompletions[deviceId]` で completion を管理し、`didReadRSSI` で `opQueue.complete` する。

`setNotify` は `type == .disable` で `setNotifyValue(false, for: ch)`、それ以外は `true`。

#### タイムアウト処理

```swift
private func handleOperationTimeout(deviceId: String, epoch: Int64) {
    // 1. Dart にタイムアウトを通知
    activeCallbacks?.onOperationTimeout(deviceId: deviceId, connectionEpoch: epoch) { _ in }

    // 2. in-flight 完了ハンドラを全部エラーで閉じる（discoverCompletions, readCompletions 等）
    failPendingOperations(deviceId: deviceId)

    // 3. GattOperationQueue を清掃
    opQueue.cancelAll(deviceId: deviceId, epoch: epoch)

    // 4. epoch を退役
    _ = state.disconnectRequested(deviceId: deviceId, epoch: epoch)

    // 5. peripheral を切断
    if let peripheral = peripheralsByDeviceId[deviceId] {
        central?.cancelPeripheralConnection(peripheral)
    }

    // 6. 切断状態を通知
    emitConnectionState(
        deviceId: deviceId, epoch: epoch,
        state: .disconnected, reason: .operationTimeout)
}
```

#### epoch 退役時の HandleRegistry クリア

`disconnectRequested` / `acceptCallback(state: .disconnected)` 後に `handleRegistry.clear(deviceId:)` を呼ぶ。

## テスト設計

`IosNativeOwnerStateTests.swift` に追記（同ファイルで HandleRegistry と GattOperationQueue を検証）。

```
HandleRegistry テスト:
  - 属性が handle を採番する
  - 同一 ObjectIdentifier は同一 handle を返す
  - handle で逆引きできる
  - 重複 UUID の属性が異なる handle を持つ
  - clear 後は逆引きが nil

GattOperationQueue テスト:
  - enqueue が true を返す（初回）
  - 同一 key の 2 回目 enqueue が false を返す
  - complete 後に同一 key を再 enqueue できる
  - cancelAll で in-flight がすべて解除される
  - timeout 後に onTimeout が呼ばれる（short timeout = 0.1s でテスト）
```

## ファイル一覧

| 操作 | パス |
|------|------|
| 新規 | `plugins/deepsky_bluetooth_ios/ios/deepsky_bluetooth_ios/Sources/deepsky_bluetooth_ios/HandleRegistry.swift` |
| 新規 | `.../GattOperationQueue.swift` |
| 更新 | `.../IosBleProcessOwner.swift` |
| 更新 | `.../Tests/deepsky_bluetooth_iosTests/IosNativeOwnerStateTests.swift` |
