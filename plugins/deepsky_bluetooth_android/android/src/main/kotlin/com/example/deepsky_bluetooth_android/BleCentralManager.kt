package com.example.deepsky_bluetooth_android

import android.content.Context

/**
 * Flutter からの [BleHostApi] 呼び出しをプロセスグローバルな [BleProcessOwner] へ委譲する。
 *
 * scan / connect / disconnect / service discovery / GATT operations(read / write / notify /
 * descriptor / MTU / RSSI)、associate / presence 監視を [BleProcessOwner] へ委譲する。
 * Companion Device の世代差分は controller 内へ閉じ込められ、ここからは見えない(#26)。
 * background callback handle の永続化と `COMPANION_DEVICE` strategy の受理は #28 で扱う
 * (handle は [HeadlessEngineLauncher] が保存し、process 死後の headless 復活に使う)。
 */
class BleCentralManager(
    private val context: Context,
    private val engineToken: String,
) : BleHostApi {

    override fun initialize(request: InitializeRequestMessage): String {
        return observe("initialize", mapOf("isBackground" to request.isBackground)) {
            BleProcessOwner.attach(context)
            // Persist the dedicated background entry-point handle so the headless engine can be
            // revived after process death (#28). Registration originates from Dart's
            // background(onBackgroundRelaunch:) (Task 17) and arrives via this request.
            request.backgroundCallbackHandle?.let {
                HeadlessEngineLauncher.storeBackgroundHandle(context, it)
            }
            if (request.isBackground) {
                when (request.strategy) {
                    BackgroundStrategyMessage.FOREGROUND_SERVICE -> {
                        val notification = request.notification
                            ?: throw bleError(
                                BleErrorCode.BACKGROUND_CONFIG_MISSING,
                                "Foreground service notification config is required",
                            )
                        BleProcessOwner.startForegroundService(notification)
                    }
                    // Companion Device drives reconnection via presence events delivered to the
                    // CompanionDeviceService (#27); the headless engine is revived there (#28).
                    // Presence observation is enabled per device via associate, not at init
                    // (Review guide §8), so initialize only attaches the owner here.
                    BackgroundStrategyMessage.COMPANION_DEVICE -> Unit
                    null -> throw bleError(
                        BleErrorCode.BACKGROUND_CONFIG_MISSING,
                        "Android background strategy is required",
                    )
                }
            }
            engineToken
        }
    }

    override fun notifyDartReady(engineToken: String) {
        observe("notifyDartReady", mapOf("engineToken" to engineToken)) {
            BleProcessOwner.notifyDartReady(engineToken)
            BleProcessOwner.emitCurrentAdapterState()
        }
    }

    override fun ackStateResync(engineToken: String, snapshotId: String) {
        observe(
            "ackStateResync",
            mapOf("engineToken" to engineToken, "snapshotId" to snapshotId),
        ) {
            val retiredToken = BleProcessOwner.ackStateResync(engineToken, snapshotId)
            if (retiredToken != null) HeadlessEngineLauncher.onUiHandoverAcknowledged()
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
            BleProcessOwner.associate(filter, it)
        }

    override fun setDevicePresenceObservation(deviceId: String, enabled: Boolean) {
        observe(
            "setDevicePresenceObservation",
            mapOf("deviceId" to deviceId, "enabled" to enabled),
        ) {
            BleProcessOwner.setDevicePresenceObservation(deviceId, enabled)
        }
    }

    override fun dispose() = observe("dispose") { BleProcessOwner.dispose() }

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
