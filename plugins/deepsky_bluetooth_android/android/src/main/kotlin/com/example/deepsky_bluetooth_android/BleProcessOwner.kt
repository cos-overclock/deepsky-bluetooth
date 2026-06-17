package com.example.deepsky_bluetooth_android

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.ParcelUuid
import com.example.deepsky_bluetooth_android.core.CompanionPresenceEvent
import com.example.deepsky_bluetooth_android.core.CompanionPresenceNormalizer
import com.example.deepsky_bluetooth_android.core.DeviceAddressNormalizer
import com.example.deepsky_bluetooth_android.core.EpochRegistry
import com.example.deepsky_bluetooth_android.core.PendingPresenceBuffer
import com.example.deepsky_bluetooth_android.core.ReconnectDriver
import com.example.deepsky_bluetooth_android.core.ReconnectDriverSelector
import com.example.deepsky_bluetooth_android.core.HandoverEvent
import com.example.deepsky_bluetooth_android.core.SinkHandoverCoordinator

/**
 * プロセスグローバルな BLE owner singleton。
 *
 * BLE 接続・接続 epoch・scan・adapter state 監視を Flutter engine から独立して保持する。
 * engine ごとの plugin instance は messenger sink を提供するだけで、接続の所有権は常に本
 * singleton が一意に持つ(Review guide §12)。engine detach では sink を解除するのみで、
 * 接続・scan・epoch は破棄しない。BLE 接続の解放は明示的な [dispose] だけが行う。
 *
 * このスライス(#20)の責務:
 * - scan / filter と adapter state 監視
 * - `connectGatt(autoConnect = false)` / disconnect
 * - device 単位 [EpochRegistry] と、古い epoch の connection callback を破棄する guard
 *
 * GATT operation queue・service discovery・read/write/notify は後続 issue(#21-#23)。
 */
@SuppressLint("MissingPermission")
object BleProcessOwner {
    private val epochs = EpochRegistry()
    private val connections = mutableMapOf<String, GattConnection>()

    private var appContext: Context? = null

    private val handover = SinkHandoverCoordinator()
    private val sinks = mutableMapOf<String, BleCallbacksApi>()
    private var scanCallback: ScanCallback? = null
    private var adapterReceiverRegistered = false

    // Companion Device の関連付けと presence 監視。世代差分は controller 内へ閉じ込め、owner は
    // 委譲するだけにする(Review guide §§8, 14)。チューザ起動に要る Activity 参照も保持する。
    @Volatile
    private var activity: Activity? = null
    private var companion: CompanionDeviceController? = null

    // presence event を sink 不在時に保持するバッファと、presence 監視が有効な device 集合。
    // 前者は headless 復活時の取りこぼし防止、後者は再接続駆動源 A/C の判定に使う(Review guide §8/§12)。
    private val pendingPresence = PendingPresenceBuffer()
    private val presenceEnabledDevices = mutableSetOf<String>()

    private val adapter: BluetoothAdapter?
        get() = (appContext?.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter

    // --- lifecycle / sink ------------------------------------------------

    /** plugin attach 時に呼ぶ。最初の context を保持し adapter 監視を開始する。 */
    fun attach(context: Context) {
        ensureContext(context)
        registerAdapterReceiver()
    }

    /** appContext だけを確保する。receiver 登録などの副作用は持たない（[ensureAttached] と共用）。 */
    @Synchronized
    private fun ensureContext(context: Context) {
        if (appContext == null) appContext = context.applicationContext
    }

    /** engine attach 時の sink 登録。ack までは candidate として保持する(Review guide §12)。 */
    @Synchronized
    fun registerSink(engineToken: String, callbacks: BleCallbacksApi) {
        sinks[engineToken] = callbacks
        handover.attachCandidate(engineToken)
    }

    /**
     * engine detach 時の sink 解除。接続・scan・epoch はそのまま保持し、自分が active な
     * 場合だけ sink を外す。
     */
    @Synchronized
    fun unregisterSink(engineToken: String, callbacks: BleCallbacksApi) {
        if (sinks[engineToken] === callbacks) sinks.remove(engineToken)
        handover.detach(engineToken)
    }

    /** notifyDartReady 時に candidate sink へ state snapshot を送る。 */
    fun notifyDartReady(engineToken: String) {
        val delivery = synchronized(this) {
            val snapshot = handover.onDartReady(engineToken) ?: return
            val candidate = sinks[engineToken] ?: return
            candidate to snapshot
        }
        BleNativeObservers.emitCallback(
            "onStateResync",
            mapOf("snapshotId" to delivery.second.snapshotId),
        )
        delivery.first.onStateResync(delivery.second) {}
    }

    /** snapshot ack 後に candidate を active 化し、buffer を順序通り flush する。 */
    fun ackStateResync(engineToken: String, snapshotId: String): String? {
        val delivery = synchronized(this) {
            val ack = handover.ackStateResync(engineToken, snapshotId)
            ack.retiredToken?.let { sinks.remove(it) }
            val active = handover.activeToken?.let { sinks[it] }
            Triple(active, ack, pendingPresence.drain())
        }
        val active = delivery.first ?: return delivery.second.retiredToken
        delivery.third.forEach { emitPresence(active, it) }
        delivery.second.followUpSnapshot?.let {
            BleNativeObservers.emitCallback("onStateResync", mapOf("snapshotId" to it.snapshotId))
            active.onStateResync(it) {}
        }
        delivery.second.bufferedEvents.forEach { deliverEvent(active, it) }
        return delivery.second.retiredToken
    }

    /** notifyDartReady 時などに現在の adapter 状態を sink へ通知する。 */
    fun emitCurrentAdapterState() {
        val state = currentAdapterState()
        deliverOrBuffer(HandoverEvent.AdapterStateChanged(state))
    }

    // --- foreground service ---------------------------------------------

    fun startForegroundService(notification: NotificationConfigMessage) {
        val ctx = appContext
            ?: throw BleErrorMapping.bluetoothUnavailable("Owner not attached")
        DeepskyForegroundService.start(ctx, notification)
    }

    // --- companion device ------------------------------------------------

    /** ActivityAware から Activity を供給/解除する。接続・epoch は process-global のまま保持する。 */
    fun setActivity(activity: Activity?) {
        this.activity = activity
    }

    /**
     * device を関連付け、確定 deviceId を [callback] へ返す。世代分岐は controller が持つ。
     */
    fun associate(filter: ScanFilterMessage?, callback: (Result<String>) -> Unit) {
        val controller = companionController()
        if (controller == null) {
            callback(Result.failure(
                BleErrorMapping.bluetoothUnavailable("Owner not attached")))
            return
        }
        controller.associate(filter, activity, callback)
    }

    /**
     * presence 監視の開始/停止。世代分岐と associationId 解決は controller が持つ。controller 呼び出しが
     * 成功した場合だけ presence 有効集合を更新し、再接続駆動源 A/C の判定([reconnectDriver])へ反映する。
     */
    fun setDevicePresenceObservation(deviceId: String, enabled: Boolean) {
        val controller = companionController()
            ?: throw BleErrorMapping.bluetoothUnavailable("Owner not attached")
        controller.setDevicePresenceObservation(deviceId, enabled)
        // ここに到達＝controller が例外を投げずに監視要求を受理した。正準 id で集合を更新する。
        val id = DeviceAddressNormalizer.normalize(deviceId) ?: return
        synchronized(presenceEnabledDevices) {
            if (enabled) presenceEnabledDevices.add(id) else presenceEnabledDevices.remove(id)
        }
    }

    /**
     * 対象 device の再接続駆動源(Review guide §8)。presence 有効なら C、無効でも UI engine 生存中なら
     * A、headless かつ presence 無効なら NONE(presence 必須だが不在)。後続 Task 17 の状態マシンが使う。
     */
    fun reconnectDriver(deviceId: String): ReconnectDriver {
        val id = DeviceAddressNormalizer.normalize(deviceId) ?: deviceId
        val enabled = synchronized(presenceEnabledDevices) { presenceEnabledDevices.contains(id) }
        val hasEngine = synchronized(this) {
            handover.activeToken != null || handover.candidateToken != null
        }
        return ReconnectDriverSelector.select(presenceEnabled = enabled, hasUiEngine = hasEngine)
    }

    // --- CompanionDeviceService presence callback の受け口(#27) ---------
    //
    // service(別プロセス起動あり)が世代別 callback から抽出した生プリミティブを渡す。owner は
    // controller の関連付け一覧で正規化し、sink があれば配送、無ければ buffer する。世代差分は
    // 純粋な CompanionPresenceNormalizer が吸収し、3 世代が同じ内部 event になる(受け入れ条件)。

    /** 31-32: `onDeviceAppeared(String)`。 */
    fun onCompanionDeviceAppeared(rawAddress: String?) {
        deliverPresence(CompanionPresenceNormalizer.fromAddress(rawAddress, appeared = true))
    }

    /** 31-32: `onDeviceDisappeared(String)`。 */
    fun onCompanionDeviceDisappeared(rawAddress: String?) {
        deliverPresence(CompanionPresenceNormalizer.fromAddress(rawAddress, appeared = false))
    }

    /** 33-35: `onDeviceAppeared/Disappeared(AssociationInfo)`。 */
    fun onCompanionAssociationEvent(deviceAddress: String?, associationId: Int?, appeared: Boolean) {
        deliverPresence(
            CompanionPresenceNormalizer.fromAssociation(
                deviceAddress = deviceAddress,
                associationId = associationId,
                associations = companionController()?.associationEntries() ?: emptyList(),
                appeared = appeared,
            ),
        )
    }

    /** 36+: `onDevicePresenceEvent(DevicePresenceEvent)`。 */
    fun onCompanionPresenceEvent(associationId: Int, eventType: Int) {
        deliverPresence(
            CompanionPresenceNormalizer.fromPresenceEvent(
                associationId = associationId,
                eventType = eventType,
                associations = companionController()?.associationEntries() ?: emptyList(),
            ),
        )
    }

    /**
     * 正規化済み event を sink へ配送する。sink 不在なら buffer に保持する(Review guide §12)。
     *
     * sink の確認と record/emit は [registerSink] の「sink 設定 → drain」と同じ monitor 上で atomic に
     * する。さもないと sink==null を観測した直後に registerSink が drain を終え、その後 record した event
     * が次の registerSink まで滞留する race が起きる。
     */
    private fun deliverPresence(event: CompanionPresenceEvent?) {
        if (event == null) return
        val delivery = synchronized(this) {
            if (handover.activeToken == null && handover.candidateToken == null) {
                pendingPresence.record(event)
                return
            }
            val handoverEvent = if (event.appeared) {
                HandoverEvent.DeviceAppeared(event.deviceId)
            } else {
                HandoverEvent.DeviceDisappeared(event.deviceId)
            }
            val decision = handover.recordEvent(handoverEvent)
            if (decision.deliverImmediately) activeSinkLocked() to handoverEvent else null
        }
        delivery?.let { deliverEvent(it.first ?: return, it.second) }
    }

    private fun emitPresence(s: BleCallbacksApi, event: CompanionPresenceEvent) {
        if (event.appeared) {
            BleNativeObservers.emitCallback("onDeviceAppeared", mapOf("deviceId" to event.deviceId))
            s.onDeviceAppeared(event.deviceId) {}
        } else {
            BleNativeObservers.emitCallback("onDeviceDisappeared", mapOf("deviceId" to event.deviceId))
            s.onDeviceDisappeared(event.deviceId) {}
        }
    }

    private fun deliverOrBuffer(event: HandoverEvent) {
        val target = synchronized(this) {
            val decision = handover.recordEvent(event)
            if (decision.deliverImmediately) activeSinkLocked() else null
        }
        target?.let { deliverEvent(it, event) }
    }

    private fun activeSinkLocked(): BleCallbacksApi? =
        handover.activeToken?.let { sinks[it] }

    private fun deliverEvent(s: BleCallbacksApi, event: HandoverEvent) {
        when (event) {
            is HandoverEvent.ScanResult -> {
                BleNativeObservers.emitCallback(
                    "onScanResult",
                    mapOf("deviceId" to event.result.deviceId),
                )
                s.onScanResult(event.result) {}
            }
            is HandoverEvent.ScanFailed -> {
                BleNativeObservers.emitCallback("onScanFailed", mapOf("code" to event.code))
                s.onScanFailed(event.code, event.message) {}
            }
            is HandoverEvent.AdapterStateChanged -> {
                BleNativeObservers.emitCallback(
                    "onAdapterStateChanged",
                    mapOf("state" to event.state),
                )
                s.onAdapterStateChanged(event.state) {}
            }
            is HandoverEvent.CharacteristicValue -> {
                BleNativeObservers.emitCallback(
                    "onCharacteristicValue",
                    mapOf(
                        "deviceId" to event.deviceId,
                        "connectionEpoch" to event.connectionEpoch,
                        "characteristicHandle" to event.characteristicHandle,
                    ),
                )
                s.onCharacteristicValue(
                    event.deviceId,
                    event.connectionEpoch,
                    event.characteristicHandle,
                    event.value,
                ) {}
            }
            is HandoverEvent.OperationTimeout -> {
                BleNativeObservers.emitCallback(
                    "onOperationTimeout",
                    mapOf(
                        "deviceId" to event.deviceId,
                        "connectionEpoch" to event.connectionEpoch,
                    ),
                )
                s.onOperationTimeout(event.deviceId, event.connectionEpoch) {}
            }
            is HandoverEvent.DeviceAppeared -> {
                BleNativeObservers.emitCallback(
                    "onDeviceAppeared",
                    mapOf("deviceId" to event.deviceId),
                )
                s.onDeviceAppeared(event.deviceId) {}
            }
            is HandoverEvent.DeviceDisappeared -> {
                BleNativeObservers.emitCallback(
                    "onDeviceDisappeared",
                    mapOf("deviceId" to event.deviceId),
                )
                s.onDeviceDisappeared(event.deviceId) {}
            }
        }
    }

    /** ActivityResultListener から転送する associate チューザ結果。処理したら true。 */
    fun handleCompanionActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean =
        companion?.handleActivityResult(requestCode, resultCode, data) ?: false

    /**
     * service など engine 外の経路から呼ばれても controller を組めるよう appContext だけを確保する。
     * process 復活直後は plugin attach 前で appContext が無いことがあるため。adapter receiver 登録は
     * plugin の [attach] に任せ、service スレッドからの二重登録を避ける。
     */
    fun ensureAttached(context: Context) {
        ensureContext(context)
    }

    private fun companionController(): CompanionDeviceController? {
        val ctx = appContext ?: return null
        return companion ?: CompanionDeviceController(ctx).also { companion = it }
    }

    // --- scan ------------------------------------------------------------

    /** ネイティブ `ScanFilter`(1 エントリ=1 ScanFilter、リスト全体で OR)で scan を開始する。 */
    fun startScan(filter: ScanFilterMessage?, settings: AndroidScanSettingsMessage) {
        val ctx = appContext
            ?: throw BleErrorMapping.bluetoothUnavailable("Owner not attached")
        if (!hasPermission(Manifest.permission.BLUETOOTH_SCAN)) {
            throw BleErrorMapping.permissionDenied(Manifest.permission.BLUETOOTH_SCAN)
        }
        if (!ctx.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            throw BleErrorMapping.bluetoothUnavailable("Bluetooth LE unsupported")
        }
        val a = adapter ?: throw BleErrorMapping.bluetoothUnavailable("No Bluetooth adapter")
        if (!a.isEnabled) throw BleErrorMapping.bluetoothOff()
        if (scanCallback != null) throw bleError(BleErrorCode.ALREADY_SCANNING, "Scan already running")

        val cb = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                deliverOrBuffer(HandoverEvent.ScanResult(result.toMessage()))
            }

            // reportDelayMillis > 0 の場合はバッチで届く。
            override fun onBatchScanResults(results: MutableList<ScanResult>?) {
                results?.forEach { onScanResult(0, it) }
            }

            override fun onScanFailed(errorCode: Int) {
                scanCallback = null
                deliverOrBuffer(
                    HandoverEvent.ScanFailed(
                        BleErrorCode.FAILED,
                        "Scan failed (errorCode=$errorCode)",
                    ),
                )
            }
        }
        a.bluetoothLeScanner.startScan(filter.toScanFilters(), settings.toScanSettings(), cb)
        scanCallback = cb
    }

    fun stopScan() {
        val cb = scanCallback ?: return
        // scanner を止めてから状態を更新する。stop が失敗した場合は scanning 中のままにし、
        // 単一 scan 不変条件を壊さない。
        adapter?.bluetoothLeScanner?.stopScan(cb)
        scanCallback = null
    }

    // --- connect / disconnect -------------------------------------------

    fun connect(deviceId: String, callback: (Result<ConnectionAttemptMessage>) -> Unit) {
        val ctx = appContext
        if (ctx == null) {
            callback(Result.failure(
                BleErrorMapping.bluetoothUnavailable("Owner not attached")))
            return
        }
        if (!hasPermission(Manifest.permission.BLUETOOTH_CONNECT)) {
            callback(Result.failure(
                BleErrorMapping.permissionDenied(Manifest.permission.BLUETOOTH_CONNECT)))
            return
        }
        if (!ctx.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            callback(Result.failure(
                BleErrorMapping.bluetoothUnavailable("Bluetooth LE unsupported")))
            return
        }
        val a = adapter
        if (a == null) {
            callback(Result.failure(
                BleErrorMapping.bluetoothUnavailable("No Bluetooth adapter")))
            return
        }
        if (!a.isEnabled) {
            callback(Result.failure(BleErrorMapping.bluetoothOff()))
            return
        }
        // 有効な device identity を構築できない場合だけ deviceNotFound(Review guide §6)。
        val device = try {
            a.getRemoteDevice(deviceId)
        } catch (e: IllegalArgumentException) {
            callback(Result.failure(
                BleErrorMapping.invalidDeviceId(deviceId)))
            return
        }
        // 接続実体を生成するたびに新しい epoch を採番する(Review guide §9)。既存接続は退役させ、
        // その古い callback は epoch guard で破棄される。
        connections.remove(deviceId)?.close()
        val epoch = epochs.allocate(deviceId)
        val connection = GattConnection(ctx, device, epoch, this)
        connections[deviceId] = connection
        connection.connect()
        // attempt の arm 完了で即返す。接続成否は epoch 付き state callback で通知する(Review guide §6)。
        callback(Result.success(ConnectionAttemptMessage(connectionEpoch = epoch)))
    }

    fun disconnect(deviceId: String, connectionEpoch: Long, callback: (Result<Unit>) -> Unit) {
        val c = connections[deviceId]
        if (c == null || c.connectionEpoch != connectionEpoch) {
            callback(Result.failure(BleErrorMapping.notConnected()))
            return
        }
        c.disconnect(callback)
    }

    // --- service discovery ----------------------------------------------

    /**
     * 現在 epoch の接続に対してだけ service discovery を行う。接続が無い、または epoch が
     * 古い要求は NotConnected で拒否する(Review guide §9 / §11)。
     */
    fun discoverServices(
        deviceId: String,
        connectionEpoch: Long,
        callback: (Result<List<ServiceMessage>>) -> Unit,
    ) {
        val c = connections[deviceId]
        if (c == null || c.connectionEpoch != connectionEpoch) {
            callback(Result.failure(BleErrorMapping.notConnected()))
            return
        }
        c.discoverServices { result ->
            result.getOrNull()?.let { services ->
                handover.recordServices(deviceId, connectionEpoch, services)
            }
            callback(result)
        }
    }

    // --- GATT operations -------------------------------------------------

    fun readCharacteristic(
        target: CharacteristicTargetMessage,
        strictRead: Boolean,
        callback: (Result<ByteArray>) -> Unit,
    ) {
        val c = connectionFor(target.deviceId, target.connectionEpoch) {
            callback(Result.failure(BleErrorMapping.notConnected()))
        } ?: return
        c.readCharacteristic(target.characteristicHandle, strictRead, callback)
    }

    fun writeCharacteristic(
        target: CharacteristicTargetMessage,
        value: ByteArray,
        withResponse: Boolean,
        callback: (Result<Unit>) -> Unit,
    ) {
        val c = connectionFor(target.deviceId, target.connectionEpoch) {
            callback(Result.failure(BleErrorMapping.notConnected()))
        } ?: return
        c.writeCharacteristic(target.characteristicHandle, value, withResponse, callback)
    }

    fun setNotify(
        target: CharacteristicTargetMessage,
        type: NotifyTypeMessage,
        callback: (Result<Unit>) -> Unit,
    ) {
        val c = connectionFor(target.deviceId, target.connectionEpoch) {
            callback(Result.failure(BleErrorMapping.notConnected()))
        } ?: return
        c.setNotify(target.characteristicHandle, type) { result ->
            if (result.isSuccess) {
                handover.recordNotifyState(
                    deviceId = target.deviceId,
                    connectionEpoch = target.connectionEpoch,
                    characteristicHandle = target.characteristicHandle,
                    enabled = type != NotifyTypeMessage.DISABLE,
                )
            }
            callback(result)
        }
    }

    fun readDescriptor(
        target: DescriptorTargetMessage,
        callback: (Result<ByteArray>) -> Unit,
    ) {
        val c = connectionFor(target.deviceId, target.connectionEpoch) {
            callback(Result.failure(BleErrorMapping.notConnected()))
        } ?: return
        c.readDescriptor(target.descriptorHandle, callback)
    }

    fun writeDescriptor(
        target: DescriptorTargetMessage,
        value: ByteArray,
        callback: (Result<Unit>) -> Unit,
    ) {
        val c = connectionFor(target.deviceId, target.connectionEpoch) {
            callback(Result.failure(BleErrorMapping.notConnected()))
        } ?: return
        c.writeDescriptor(target.descriptorHandle, value, callback)
    }

    fun requestMtu(
        deviceId: String,
        connectionEpoch: Long,
        mtu: Long,
        callback: (Result<Long>) -> Unit,
    ) {
        val c = connectionFor(deviceId, connectionEpoch) {
            callback(Result.failure(BleErrorMapping.notConnected()))
        } ?: return
        c.requestMtu(mtu, callback)
    }

    fun readRssi(deviceId: String, connectionEpoch: Long, callback: (Result<Long>) -> Unit) {
        val c = connectionFor(deviceId, connectionEpoch) {
            callback(Result.failure(BleErrorMapping.notConnected()))
        } ?: return
        c.readRssi(callback)
    }

    /** 現在 epoch の接続を返す。接続が無い・epoch が古ければ [onMissing] を呼び null を返す。 */
    private inline fun connectionFor(
        deviceId: String,
        connectionEpoch: Long,
        onMissing: () -> Unit,
    ): GattConnection? {
        val c = connections[deviceId]
        if (c == null || c.connectionEpoch != connectionEpoch) {
            onMissing()
            return null
        }
        return c
    }

    // --- connection callback guard --------------------------------------

    /**
     * [GattConnection] からの接続状態を epoch guard 越しに sink へ転送する。現在 epoch と
     * 一致しない(=古い世代の)callback はここで破棄する(Review guide §9)。
     */
    internal fun emitConnectionState(
        deviceId: String,
        epoch: Long,
        state: ConnectionStateMessage,
        reason: DisconnectReasonMessage?,
    ) {
        if (!epochs.isCurrent(deviceId, epoch)) return
        val target = synchronized(this) {
            val decision = handover.recordConnectionState(deviceId, epoch, state, reason)
            if (decision.deliverImmediately) activeSinkLocked() else null
        }
        target?.let {
            BleNativeObservers.emitCallback(
                "onConnectionStateChanged",
                mapOf(
                    "deviceId" to deviceId,
                    "connectionEpoch" to epoch,
                    "state" to state,
                    "reason" to reason,
                ),
            )
            it.onConnectionStateChanged(deviceId, epoch, state, reason) {}
        }
    }

    /**
     * notify/indicate の値を epoch guard 越しに通知ストリームへ転送する。古い世代の characteristic
     * からの遅延通知はここで破棄する(Review guide §9 / §10)。
     */
    internal fun emitCharacteristicValue(
        deviceId: String,
        epoch: Long,
        characteristicHandle: Long,
        value: ByteArray,
    ) {
        if (!epochs.isCurrent(deviceId, epoch)) return
        deliverOrBuffer(
            HandoverEvent.CharacteristicValue(deviceId, epoch, characteristicHandle, value),
        )
    }

    /** 操作 timeout を epoch guard 越しに通知する。退役前に呼ぶこと(Review guide §10)。 */
    internal fun onOperationTimeout(deviceId: String, epoch: Long) {
        if (!epochs.isCurrent(deviceId, epoch)) return
        deliverOrBuffer(HandoverEvent.OperationTimeout(deviceId, epoch))
    }

    /** 接続実体が閉じたときに呼ぶ。現在 epoch なら退役させ map から外す。 */
    internal fun onConnectionClosed(deviceId: String, epoch: Long) {
        if (epochs.isCurrent(deviceId, epoch)) {
            epochs.retire(deviceId)
            connections.remove(deviceId)
        }
    }

    // --- dispose ---------------------------------------------------------

    /** 利用者による明示的な破棄。ここでのみ接続・scan・adapter 監視を解放する。 */
    fun dispose() {
        stopScan()
        // 接続を閉じるだけでなく epoch も退役させ、dispose 後に遅延 callback が current 扱いで
        // 新しい sink へ配送されないようにする(Review guide §9)。
        connections.forEach { (deviceId, connection) ->
            connection.close()
            epochs.retire(deviceId)
        }
        connections.clear()
        val ctx = appContext
        if (adapterReceiverRegistered && ctx != null) {
            try {
                ctx.unregisterReceiver(adapterStateReceiver)
            } catch (_: IllegalArgumentException) {
                // 既に解除済み。
            }
            adapterReceiverRegistered = false
        }
        sinks.clear()
        handover.reset()
        activity = null
        companion = null
        // presence の保留 event と有効集合も明示破棄で手放す(dispose 後に古い presence が残らない)。
        pendingPresence.drain()
        synchronized(presenceEnabledDevices) { presenceEnabledDevices.clear() }
        appContext?.let { DeepskyForegroundService.stop(it) }
    }

    // --- internals -------------------------------------------------------

    private fun registerAdapterReceiver() {
        if (adapterReceiverRegistered) return
        val ctx = appContext ?: return
        ctx.registerReceiver(
            adapterStateReceiver, IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED))
        adapterReceiverRegistered = true
    }

    // STATE_OFF/STATE_ON を全 device 共通の adapter state callback へ流す。
    // adapter null / LE 非対応は unavailable であり poweredOff と混同しない(Review guide §6)。
    private val adapterStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action != BluetoothAdapter.ACTION_STATE_CHANGED) return
            when (intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)) {
                BluetoothAdapter.STATE_ON -> {
                    deliverOrBuffer(HandoverEvent.AdapterStateChanged(AdapterStateMessage.POWERED_ON))
                }
                BluetoothAdapter.STATE_OFF -> {
                    deliverOrBuffer(HandoverEvent.AdapterStateChanged(AdapterStateMessage.POWERED_OFF))
                }
            }
        }
    }

    private fun currentAdapterState(): AdapterStateMessage {
        val ctx = appContext
        return when {
            ctx == null ||
                !ctx.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE) ||
                adapter == null -> AdapterStateMessage.UNAVAILABLE
            adapter?.isEnabled == true -> AdapterStateMessage.POWERED_ON
            else -> AdapterStateMessage.POWERED_OFF
        }
    }

    private fun hasPermission(permission: String): Boolean =
        appContext?.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun ScanFilterMessage?.toScanFilters(): List<ScanFilter> {
        if (this == null) return emptyList()
        val filters = mutableListOf<ScanFilter>()
        addresses.forEach {
            filters.add(ScanFilter.Builder().setDeviceAddress(it.uppercase()).build())
        }
        names.forEach { filters.add(ScanFilter.Builder().setDeviceName(it).build()) }
        manufacturerData.forEach {
            filters.add(ScanFilter.Builder()
                .setManufacturerData(it.manufacturerId.toInt(), it.data).build())
        }
        serviceData.forEach {
            filters.add(ScanFilter.Builder()
                .setServiceData(ParcelUuid.fromString(it.serviceUuid), it.data).build())
        }
        serviceUuids.forEach {
            filters.add(ScanFilter.Builder().setServiceUuid(ParcelUuid.fromString(it)).build())
        }
        return filters
    }

    private fun AndroidScanSettingsMessage.toScanSettings(): ScanSettings {
        val builder = ScanSettings.Builder()
            .setScanMode(when (mode) {
                ScanModeMessage.LOW_POWER -> ScanSettings.SCAN_MODE_LOW_POWER
                ScanModeMessage.BALANCED -> ScanSettings.SCAN_MODE_BALANCED
                ScanModeMessage.LOW_LATENCY -> ScanSettings.SCAN_MODE_LOW_LATENCY
                ScanModeMessage.OPPORTUNISTIC -> ScanSettings.SCAN_MODE_OPPORTUNISTIC
            })
            .setCallbackType(when (callbackType) {
                ScanCallbackTypeMessage.ALL_MATCHES -> ScanSettings.CALLBACK_TYPE_ALL_MATCHES
                ScanCallbackTypeMessage.FIRST_MATCH -> ScanSettings.CALLBACK_TYPE_FIRST_MATCH
                ScanCallbackTypeMessage.MATCH_LOST -> ScanSettings.CALLBACK_TYPE_MATCH_LOST
                ScanCallbackTypeMessage.FIRST_MATCH_AND_MATCH_LOST ->
                    ScanSettings.CALLBACK_TYPE_FIRST_MATCH or ScanSettings.CALLBACK_TYPE_MATCH_LOST
            })
            .setLegacy(onlyLegacy)
            .setMatchMode(when (matchMode) {
                ScanMatchModeMessage.AGGRESSIVE -> ScanSettings.MATCH_MODE_AGGRESSIVE
                ScanMatchModeMessage.STICKY -> ScanSettings.MATCH_MODE_STICKY
            })
            .setNumOfMatches(when (numOfMatch) {
                ScanNumOfMatchMessage.ONE -> ScanSettings.MATCH_NUM_ONE_ADVERTISEMENT
                ScanNumOfMatchMessage.FEW -> ScanSettings.MATCH_NUM_FEW_ADVERTISEMENT
                ScanNumOfMatchMessage.MAX -> ScanSettings.MATCH_NUM_MAX_ADVERTISEMENT
            })
            .setReportDelay(reportDelayMillis)
        if (!onlyLegacy) {
            builder.setPhy(when (phy) {
                ScanPhyMessage.LE1M -> BluetoothDevice.PHY_LE_1M
                ScanPhyMessage.LE_CODED -> BluetoothDevice.PHY_LE_CODED
                ScanPhyMessage.ALL_SUPPORTED -> ScanSettings.PHY_LE_ALL_SUPPORTED
            })
        }
        return builder.build()
    }

    private fun ScanResult.toMessage(): ScanResultMessage = ScanResultMessage(
        deviceId = device.address,
        name = scanRecord?.deviceName,
        rssi = rssi.toLong(),
        serviceUuids = scanRecord?.serviceUuids?.map { it.toString() } ?: emptyList(),
        manufacturerData = firstManufacturerData(),
        raw = scanRecord?.bytes,
    )

    private fun ScanResult.firstManufacturerData(): ByteArray? {
        val sparse = scanRecord?.manufacturerSpecificData ?: return null
        return if (sparse.size() > 0) sparse.valueAt(0) else null
    }
}
