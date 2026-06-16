package com.example.deepsky_bluetooth_android

import android.content.Context

/**
 * Flutter からの [BleHostApi] 呼び出しをプロセスグローバルな [BleProcessOwner] へ委譲する。
 *
 * このスライス(#20)のスコープ外メソッド(service discovery / read / write / notify /
 * descriptor / MTU / RSSI / associate / presence / background)は、後続 issue で本実装に
 * 置き換える前提の暫定エラーを返す。
 */
class BleCentralManager(private val context: Context) : BleHostApi {

    override fun initialize(request: InitializeRequestMessage): String {
        BleProcessOwner.attach(context)
        if (request.isBackground) {
            // background strategy(Foreground Service / Companion Device)は #25-#27。
            throw bleError(BleErrorCode.FAILED, "Background mode is not implemented yet (#25-#27)")
        }
        return "engine-${System.identityHashCode(this)}"
    }

    override fun notifyDartReady(engineToken: String) {
        // state snapshot handover は #29。現状は現在の adapter 状態だけ通知する。
        BleProcessOwner.emitCurrentAdapterState()
    }

    override fun ackStateResync(engineToken: String, snapshotId: String) {
        // sink handover protocol は #29 で実装する。
    }

    override fun startScan(filter: ScanFilterMessage?, settings: AndroidScanSettingsMessage) =
        BleProcessOwner.startScan(filter, settings)

    override fun stopScan() = BleProcessOwner.stopScan()

    override fun connect(deviceId: String, callback: (Result<ConnectionAttemptMessage>) -> Unit) =
        BleProcessOwner.connect(deviceId, callback)

    override fun disconnect(
        deviceId: String,
        connectionEpoch: Long,
        callback: (Result<Unit>) -> Unit,
    ) = BleProcessOwner.disconnect(deviceId, connectionEpoch, callback)

    override fun discoverServices(
        deviceId: String,
        connectionEpoch: Long,
        callback: (Result<List<ServiceMessage>>) -> Unit,
    ) = callback(notImplemented("discoverServices", "#21"))

    override fun readCharacteristic(
        target: CharacteristicTargetMessage,
        strictRead: Boolean,
        callback: (Result<ByteArray>) -> Unit,
    ) = callback(notImplemented("readCharacteristic", "#23"))

    override fun writeCharacteristic(
        target: CharacteristicTargetMessage,
        value: ByteArray,
        withResponse: Boolean,
        callback: (Result<Unit>) -> Unit,
    ) = callback(notImplemented("writeCharacteristic", "#23"))

    override fun setNotify(
        target: CharacteristicTargetMessage,
        type: NotifyTypeMessage,
        callback: (Result<Unit>) -> Unit,
    ) = callback(notImplemented("setNotify", "#23"))

    override fun readDescriptor(
        target: DescriptorTargetMessage,
        callback: (Result<ByteArray>) -> Unit,
    ) = callback(notImplemented("readDescriptor", "#23"))

    override fun writeDescriptor(
        target: DescriptorTargetMessage,
        value: ByteArray,
        callback: (Result<Unit>) -> Unit,
    ) = callback(notImplemented("writeDescriptor", "#23"))

    override fun requestMtu(
        deviceId: String,
        connectionEpoch: Long,
        mtu: Long,
        callback: (Result<Long>) -> Unit,
    ) = callback(notImplemented("requestMtu", "#23"))

    override fun readRssi(
        deviceId: String,
        connectionEpoch: Long,
        callback: (Result<Long>) -> Unit,
    ) = callback(notImplemented("readRssi", "#23"))

    override fun associate(filter: ScanFilterMessage?, callback: (Result<String>) -> Unit) =
        callback(notImplemented("associate", "#26"))

    override fun setDevicePresenceObservation(deviceId: String, enabled: Boolean) {
        throw bleError(
            BleErrorCode.FAILED, "setDevicePresenceObservation is not implemented yet (#27)")
    }

    override fun dispose() = BleProcessOwner.dispose()

    private fun <T> notImplemented(method: String, issue: String): Result<T> =
        Result.failure(bleError(BleErrorCode.FAILED, "$method is not implemented yet ($issue)"))
}
