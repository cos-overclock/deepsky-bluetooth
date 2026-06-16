package com.example.deepsky_bluetooth_android

import android.content.Context

/**
 * Flutter からの [BleHostApi] 呼び出しをプロセスグローバルな [BleProcessOwner] へ委譲する。
 *
 * scan / connect / disconnect / service discovery / GATT operations(read / write / notify /
 * descriptor / MTU / RSSI)を [BleProcessOwner] へ委譲する。残るスコープ外メソッド(associate /
 * presence / background)は、後続 issue で本実装に置き換える前提の暫定エラーを返す。
 */
class BleCentralManager(private val context: Context) : BleHostApi {

    override fun initialize(request: InitializeRequestMessage): String {
        return observe("initialize", mapOf("isBackground" to request.isBackground)) {
            BleProcessOwner.attach(context)
            if (request.isBackground) {
                // background strategy(Foreground Service / Companion Device)は #25-#27。
                throw bleError(BleErrorCode.FAILED, "Background mode is not implemented yet (#25-#27)")
            }
            "engine-${System.identityHashCode(this)}"
        }
    }

    override fun notifyDartReady(engineToken: String) {
        observe("notifyDartReady", mapOf("engineToken" to engineToken)) {
            // state snapshot handover は #29。現状は現在の adapter 状態だけ通知する。
            BleProcessOwner.emitCurrentAdapterState()
        }
    }

    override fun ackStateResync(engineToken: String, snapshotId: String) {
        observe(
            "ackStateResync",
            mapOf("engineToken" to engineToken, "snapshotId" to snapshotId),
        ) {
            // sink handover protocol は #29 で実装する。
        }
    }

    override fun startScan(filter: ScanFilterMessage?, settings: AndroidScanSettingsMessage) =
        observe("startScan") { BleProcessOwner.startScan(filter, settings) }

    override fun stopScan() = observe("stopScan") { BleProcessOwner.stopScan() }

    override fun connect(deviceId: String, callback: (Result<ConnectionAttemptMessage>) -> Unit) =
        observeAsync("connect", mapOf("deviceId" to deviceId), callback) {
            BleProcessOwner.connect(deviceId, it)
        }

    override fun disconnect(
        deviceId: String,
        connectionEpoch: Long,
        callback: (Result<Unit>) -> Unit,
    ) = observeAsync(
        "disconnect",
        mapOf("deviceId" to deviceId, "connectionEpoch" to connectionEpoch),
        callback,
    ) {
        BleProcessOwner.disconnect(deviceId, connectionEpoch, it)
    }

    override fun discoverServices(
        deviceId: String,
        connectionEpoch: Long,
        callback: (Result<List<ServiceMessage>>) -> Unit,
    ) = observeAsync(
        "discoverServices",
        mapOf("deviceId" to deviceId, "connectionEpoch" to connectionEpoch),
        callback,
    ) {
        BleProcessOwner.discoverServices(deviceId, connectionEpoch, it)
    }

    override fun readCharacteristic(
        target: CharacteristicTargetMessage,
        strictRead: Boolean,
        callback: (Result<ByteArray>) -> Unit,
    ) = observeAsync("readCharacteristic", targetPayload(target), callback) {
        BleProcessOwner.readCharacteristic(target, strictRead, it)
    }

    override fun writeCharacteristic(
        target: CharacteristicTargetMessage,
        value: ByteArray,
        withResponse: Boolean,
        callback: (Result<Unit>) -> Unit,
    ) = observeAsync("writeCharacteristic", targetPayload(target), callback) {
        BleProcessOwner.writeCharacteristic(target, value, withResponse, it)
    }

    override fun setNotify(
        target: CharacteristicTargetMessage,
        type: NotifyTypeMessage,
        callback: (Result<Unit>) -> Unit,
    ) = observeAsync("setNotify", targetPayload(target) + ("type" to type), callback) {
        BleProcessOwner.setNotify(target, type, it)
    }

    override fun readDescriptor(
        target: DescriptorTargetMessage,
        callback: (Result<ByteArray>) -> Unit,
    ) = observeAsync("readDescriptor", targetPayload(target), callback) {
        BleProcessOwner.readDescriptor(target, it)
    }

    override fun writeDescriptor(
        target: DescriptorTargetMessage,
        value: ByteArray,
        callback: (Result<Unit>) -> Unit,
    ) = observeAsync("writeDescriptor", targetPayload(target), callback) {
        BleProcessOwner.writeDescriptor(target, value, it)
    }

    override fun requestMtu(
        deviceId: String,
        connectionEpoch: Long,
        mtu: Long,
        callback: (Result<Long>) -> Unit,
    ) = observeAsync(
        "requestMtu",
        mapOf("deviceId" to deviceId, "connectionEpoch" to connectionEpoch, "mtu" to mtu),
        callback,
    ) {
        BleProcessOwner.requestMtu(deviceId, connectionEpoch, mtu, it)
    }

    override fun readRssi(
        deviceId: String,
        connectionEpoch: Long,
        callback: (Result<Long>) -> Unit,
    ) = observeAsync(
        "readRssi",
        mapOf("deviceId" to deviceId, "connectionEpoch" to connectionEpoch),
        callback,
    ) {
        BleProcessOwner.readRssi(deviceId, connectionEpoch, it)
    }

    override fun associate(filter: ScanFilterMessage?, callback: (Result<String>) -> Unit) =
        observeAsync("associate", callback = callback) {
            it(notImplemented("associate", "#26"))
        }

    override fun setDevicePresenceObservation(deviceId: String, enabled: Boolean) {
        observe(
            "setDevicePresenceObservation",
            mapOf("deviceId" to deviceId, "enabled" to enabled),
        ) {
            throw bleError(
                BleErrorCode.FAILED, "setDevicePresenceObservation is not implemented yet (#27)")
        }
    }

    override fun dispose() = observe("dispose") { BleProcessOwner.dispose() }

    private fun <T> notImplemented(method: String, issue: String): Result<T> =
        Result.failure(bleError(BleErrorCode.FAILED, "$method is not implemented yet ($issue)"))

    private fun <T> observe(
        method: String,
        payload: Map<String, Any?> = emptyMap(),
        block: () -> T,
    ): T = BleNativeObservers.observeMethod(method, payload, block)

    private fun <T> observeAsync(
        method: String,
        payload: Map<String, Any?> = emptyMap(),
        callback: (Result<T>) -> Unit,
        block: ((Result<T>) -> Unit) -> Unit,
    ) {
        BleNativeObservers.observeCallbackMethod(method, payload, callback, block)
    }

    private fun targetPayload(target: CharacteristicTargetMessage): Map<String, Any?> = mapOf(
        "deviceId" to target.deviceId,
        "connectionEpoch" to target.connectionEpoch,
        "characteristicHandle" to target.characteristicHandle,
    )

    private fun targetPayload(target: DescriptorTargetMessage): Map<String, Any?> = mapOf(
        "deviceId" to target.deviceId,
        "connectionEpoch" to target.connectionEpoch,
        "descriptorHandle" to target.descriptorHandle,
    )
}
