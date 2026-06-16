package com.example.deepsky_bluetooth_android

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothStatusCodes
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.example.deepsky_bluetooth_android.core.CallbackKind
import com.example.deepsky_bluetooth_android.core.HandleRegistry
import com.example.deepsky_bluetooth_android.core.OperationKind
import com.example.deepsky_bluetooth_android.core.OperationQueueState
import java.util.UUID

/**
 * 1 device = 1 `BluetoothGatt` の接続実体。
 *
 * #20 で `connectGatt(autoConnect = false)` / `disconnect` と接続状態 callback を、
 * #21 で service discovery と探索時の handle 採番を、#23 で GATT 操作の FIFO 直列化
 * (read/write/notify・descriptor・MTU・RSSI)を追加した。
 *
 * 接続状態は常に [owner] 経由で通知し、owner が epoch guard で古い世代の callback を
 * 破棄する(Review guide §9)。探索した属性は接続(=epoch)寿命の [handles] に探索順で登録し、
 * UUID ではなく handle で逆引きする(Review guide §9 / §11)。
 *
 * GATT 操作は device(=この接続)単位の [queue] で同時1件に直列化する(Review guide §10)。
 * 要求は [queue] 末尾へ enqueue し、先頭1件だけを実行する。GATT callback は現行 epoch と
 * 先頭操作の種別が一致した場合だけ先頭を完了させ、次をディスパッチする。各操作には watchdog
 * timer を張り、満了したら接続全体を破棄して epoch を退役させる(同じ GATT でキューを続行しない)。
 * notify/indicate(`onCharacteristicChanged`)は要求応答ではないためキューに載せず、handle を
 * 逆引きして通知ストリームへ直送する。
 *
 * Pigeon 生成の callback / `BluetoothGatt` callback はいずれも main looper に直列化され、
 * [queue]([OperationQueueState])は単一スレッド前提で扱う。
 */
@SuppressLint("MissingPermission")
class GattConnection(
    private val context: Context,
    private val device: BluetoothDevice,
    val connectionEpoch: Long,
    private val owner: BleProcessOwner,
) : BluetoothGattCallback() {
    private val main = Handler(Looper.getMainLooper())
    private val deviceId: String = device.address
    private var gatt: BluetoothGatt? = null
    private var isConnecting = false
    private var disconnectCallback: ((Result<Unit>) -> Unit)? = null
    private var pendingDisconnectReason: DisconnectReasonMessage? = null

    // 探索した属性の handle <-> native object。接続(=epoch)寿命で、退役時に clear する。
    private val handles = HandleRegistry<Any>()

    // device 単位の GATT 操作 FIFO queue。payload に completer/native action を載せた [GattOp]。
    private val queue = OperationQueueState<GattOp<*>>(connectionEpoch)
    private val watchdog = Runnable { handleOperationTimeout() }

    var isConnected = false
        private set

    fun connect() {
        isConnecting = true
        owner.emitConnectionState(
            deviceId, connectionEpoch, ConnectionStateMessage.CONNECTING, null)
        // 自動再接続は body 所有のため autoConnect は常に false(Review guide §8/§14)。
        val g = try {
            device.connectGatt(context, false, this, BluetoothDevice.TRANSPORT_LE)
        } catch (e: Exception) {
            null
        }
        if (g == null) {
            // connectGatt が同期失敗(null 返却/例外)した場合は CONNECTING のまま固まらないよう、
            // 終端 DISCONNECTED(connectFailed) を通知して owner に epoch を退役させる(Review guide §6)。
            isConnecting = false
            isConnected = false
            owner.emitConnectionState(
                deviceId, connectionEpoch,
                ConnectionStateMessage.DISCONNECTED, DisconnectReasonMessage.CONNECT_FAILED)
            owner.onConnectionClosed(deviceId, connectionEpoch)
            return
        }
        gatt = g
    }

    fun disconnect(callback: (Result<Unit>) -> Unit) {
        val g = gatt
        if (g == null || !isConnected) {
            callback(Result.failure(bleError(BleErrorCode.NOT_CONNECTED, "Not connected")))
            return
        }
        disconnectCallback = callback
        pendingDisconnectReason = DisconnectReasonMessage.USER_REQUESTED
        owner.emitConnectionState(
            deviceId, connectionEpoch, ConnectionStateMessage.DISCONNECTING, null)
        g.disconnect()
    }

    // --- queued GATT operations -----------------------------------------

    /**
     * service/characteristic/descriptor を探索し、探索順に handle を採番した DTO tree を返す。
     *
     * discovery も FIFO queue を通す(Review guide §10)。探索開始時に [handles] を clear し、
     * counter は戻さないため、進行中・失敗いずれでも古い tree の handle は new object へ付け替わらず
     * NotFound のままになる(Review guide §11)。
     */
    fun discoverServices(callback: (Result<List<ServiceMessage>>) -> Unit) {
        if (!isConnected) {
            callback(Result.failure(bleError(BleErrorCode.NOT_CONNECTED, "Not connected")))
            return
        }
        enqueueAndDispatch(OperationKind.DISCOVER_SERVICES, GattOp(callback) { g ->
            // 再探索を開始した時点で旧 tree の handle を無効化する。
            // BLUETOOTH_CONNECT 剥奪時の例外は dispatchNext() の共通捕捉で Rejected になる。
            handles.clear()
            if (g.discoverServices()) StartOutcome.Issued
            else StartOutcome.Rejected(
                bleError(BleErrorCode.FAILED, "Failed to start service discovery"))
        })
    }

    fun readCharacteristic(
        characteristicHandle: Long,
        @Suppress("UNUSED_PARAMETER") strictRead: Boolean,
        callback: (Result<ByteArray>) -> Unit,
    ) {
        // Android は read と notify の callback が別なので strictRead は無効(Review guide §10)。
        val c = resolveCharacteristic(characteristicHandle) { callback(Result.failure(it)); return }
        enqueueAndDispatch(OperationKind.READ_CHARACTERISTIC, GattOp(callback) { g ->
            if (g.readCharacteristic(c)) StartOutcome.Issued
            else StartOutcome.Rejected(bleError(BleErrorCode.REJECTED, "Characteristic read rejected"))
        })
    }

    fun writeCharacteristic(
        characteristicHandle: Long,
        value: ByteArray,
        withResponse: Boolean,
        callback: (Result<Unit>) -> Unit,
    ) {
        val c = resolveCharacteristic(characteristicHandle) { callback(Result.failure(it)); return }
        enqueueAndDispatch(OperationKind.WRITE_CHARACTERISTIC, GattOp(callback) { g ->
            startCharacteristicWrite(g, c, value, withResponse)
        })
    }

    fun setNotify(
        characteristicHandle: Long,
        type: NotifyTypeMessage,
        callback: (Result<Unit>) -> Unit,
    ) {
        val c = resolveCharacteristic(characteristicHandle) { callback(Result.failure(it)); return }
        val cccd = c.getDescriptor(CCCD_UUID)
        if (cccd == null) {
            callback(Result.failure(
                bleError(BleErrorCode.NOT_SUPPORTED, "Characteristic has no CCCD descriptor")))
            return
        }
        // setNotify は「local 通知有効化 + CCCD descriptor write」を1操作としてキューを通す。
        enqueueAndDispatch(OperationKind.SET_NOTIFY, GattOp(callback) { g ->
            val enable = type != NotifyTypeMessage.DISABLE
            if (!g.setCharacteristicNotification(c, enable)) {
                return@GattOp StartOutcome.Rejected(
                    bleError(BleErrorCode.FAILED, "Failed to toggle characteristic notification"))
            }
            val cccdValue = when (type) {
                NotifyTypeMessage.NOTIFY -> BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                NotifyTypeMessage.INDICATE -> BluetoothGattDescriptor.ENABLE_INDICATION_VALUE
                NotifyTypeMessage.DISABLE -> BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
            }
            startDescriptorWrite(g, cccd, cccdValue)
        })
    }

    fun readDescriptor(
        descriptorHandle: Long,
        callback: (Result<ByteArray>) -> Unit,
    ) {
        val d = resolveDescriptor(descriptorHandle) { callback(Result.failure(it)); return }
        enqueueAndDispatch(OperationKind.READ_DESCRIPTOR, GattOp(callback) { g ->
            if (g.readDescriptor(d)) StartOutcome.Issued
            else StartOutcome.Rejected(bleError(BleErrorCode.REJECTED, "Descriptor read rejected"))
        })
    }

    fun writeDescriptor(
        descriptorHandle: Long,
        value: ByteArray,
        callback: (Result<Unit>) -> Unit,
    ) {
        val d = resolveDescriptor(descriptorHandle) { callback(Result.failure(it)); return }
        enqueueAndDispatch(OperationKind.WRITE_DESCRIPTOR, GattOp(callback) { g ->
            startDescriptorWrite(g, d, value)
        })
    }

    fun requestMtu(mtu: Long, callback: (Result<Long>) -> Unit) {
        if (!isConnected) {
            callback(Result.failure(bleError(BleErrorCode.NOT_CONNECTED, "Not connected")))
            return
        }
        enqueueAndDispatch(OperationKind.REQUEST_MTU, GattOp(callback) { g ->
            if (g.requestMtu(mtu.toInt())) StartOutcome.Issued
            else StartOutcome.Rejected(bleError(BleErrorCode.FAILED, "Failed to request MTU"))
        })
    }

    fun readRssi(callback: (Result<Long>) -> Unit) {
        if (!isConnected) {
            callback(Result.failure(bleError(BleErrorCode.NOT_CONNECTED, "Not connected")))
            return
        }
        enqueueAndDispatch(OperationKind.READ_RSSI, GattOp(callback) { g ->
            if (g.readRemoteRssi()) StartOutcome.Issued
            else StartOutcome.Rejected(bleError(BleErrorCode.FAILED, "Failed to read RSSI"))
        })
    }

    /** GATT を閉じる。callback は発火させず、未完了操作だけ NotConnected で完了する。 */
    fun close() {
        failQueue(bleError(BleErrorCode.NOT_CONNECTED, "Not connected"))
        releaseGatt()
        // 探索中の callback は queue 退役で NotConnected 完了済み。
        disconnectCallback = null
    }

    // --- callbacks ------------------------------------------------------

    override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
        main.post {
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    isConnecting = false
                    isConnected = true
                    owner.emitConnectionState(
                        deviceId, connectionEpoch, ConnectionStateMessage.CONNECTED, null)
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    val wasConnecting = isConnecting
                    isConnecting = false
                    isConnected = false
                    disconnectCallback?.invoke(Result.success(Unit))
                    disconnectCallback = null
                    // 有効 address への connectGatt 後の確立失敗は connectFailed、
                    // 確立後の予期しない切断は connectionLost(Review guide §6)。
                    val reason = pendingDisconnectReason
                        ?: if (wasConnecting) DisconnectReasonMessage.CONNECT_FAILED
                        else DisconnectReasonMessage.CONNECTION_LOST
                    pendingDisconnectReason = null
                    owner.emitConnectionState(
                        deviceId, connectionEpoch, ConnectionStateMessage.DISCONNECTED, reason)
                    close()
                    owner.onConnectionClosed(deviceId, connectionEpoch)
                }
            }
        }
    }

    override fun onServicesDiscovered(g: BluetoothGatt, status: Int) {
        main.post {
            completeInFlight<List<ServiceMessage>>(CallbackKind.SERVICES_DISCOVERED) { op ->
                if (status != BluetoothGatt.GATT_SUCCESS) {
                    // 探索開始時に clear 済みのため、失敗時は handle が空のまま = 全 handle NotFound。
                    op.fail(bleError(
                        BleErrorCode.FAILED, "Service discovery failed (status=$status)"))
                    return@completeInFlight
                }
                // handle は discovery 開始時に clear 済み。ここで探索順に採番し直す。
                op.succeed(g.services.map { it.toMessage() })
            }
        }
    }

    override fun onCharacteristicRead(
        g: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        value: ByteArray,
        status: Int,
    ) {
        // API 33+ は値引数付き callback。値は read 操作の戻り値として返す(Review guide §5/§10)。
        main.post { completeRead(value, status) }
    }

    @Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
    override fun onCharacteristicRead(
        g: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        status: Int,
    ) {
        val value = characteristic.value ?: ByteArray(0)
        main.post { completeRead(value, status) }
    }

    override fun onCharacteristicWrite(
        g: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        status: Int,
    ) {
        main.post {
            completeInFlight<Unit>(CallbackKind.CHARACTERISTIC_WRITE) { op ->
                op.completeUnit(status, "Characteristic write failed")
            }
        }
    }

    override fun onDescriptorRead(
        g: BluetoothGatt,
        descriptor: BluetoothGattDescriptor,
        status: Int,
        value: ByteArray,
    ) {
        main.post { completeDescriptorRead(value, status) }
    }

    @Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
    override fun onDescriptorRead(
        g: BluetoothGatt,
        descriptor: BluetoothGattDescriptor,
        status: Int,
    ) {
        val value = descriptor.value ?: ByteArray(0)
        main.post { completeDescriptorRead(value, status) }
    }

    override fun onDescriptorWrite(
        g: BluetoothGatt,
        descriptor: BluetoothGattDescriptor,
        status: Int,
    ) {
        // setNotify(CCCD write)も通常の descriptor write も同じ callback で完了する。
        main.post {
            completeInFlight<Unit>(CallbackKind.DESCRIPTOR_WRITE) { op ->
                op.completeUnit(status, "Descriptor write failed")
            }
        }
    }

    override fun onMtuChanged(g: BluetoothGatt, mtu: Int, status: Int) {
        main.post {
            completeInFlight<Long>(CallbackKind.MTU_CHANGED) { op ->
                if (status == BluetoothGatt.GATT_SUCCESS) op.succeed(mtu.toLong())
                else op.fail(bleError(BleErrorCode.FAILED, "MTU request failed (status=$status)"))
            }
        }
    }

    override fun onReadRemoteRssi(g: BluetoothGatt, rssi: Int, status: Int) {
        main.post {
            completeInFlight<Long>(CallbackKind.RSSI_READ) { op ->
                if (status == BluetoothGatt.GATT_SUCCESS) op.succeed(rssi.toLong())
                else op.fail(bleError(BleErrorCode.FAILED, "RSSI read failed (status=$status)"))
            }
        }
    }

    override fun onCharacteristicChanged(
        g: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        value: ByteArray,
    ) {
        // notify/indicate はキューに載せず、handle を逆引きして通知ストリームへ直送する(Review guide §10)。
        main.post { deliverNotification(characteristic, value) }
    }

    @Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
    override fun onCharacteristicChanged(
        g: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
    ) {
        val value = characteristic.value ?: ByteArray(0)
        main.post { deliverNotification(characteristic, value) }
    }

    // --- queue plumbing -------------------------------------------------

    private fun <R> enqueueAndDispatch(kind: OperationKind, op: GattOp<R>) {
        if (queue.isRetired) {
            op.fail(bleError(BleErrorCode.NOT_CONNECTED, "Not connected"))
            return
        }
        queue.enqueue(kind, op)
        dispatchNext()
    }

    private fun dispatchNext() {
        val g = gatt ?: return
        val next = queue.startNext() ?: return
        @Suppress("UNCHECKED_CAST")
        val op = next.payload as GattOp<Any?>
        // start() は native GATT 呼び出しを発行する。BLUETOOTH_CONNECT 実行時剥奪の SecurityException
        // や framework の IllegalStateException で例外になり得るため、捕捉して Rejected と同等に扱う。
        // 捕捉しないと startNext() で立てた inFlight が残り、watchdog も張られず queue が固まる。
        val outcome = try {
            op.start(g)
        } catch (e: Exception) {
            StartOutcome.Rejected(
                bleError(BleErrorCode.FAILED, "Failed to start GATT operation: ${e.message}"))
        }
        when (outcome) {
            StartOutcome.Issued -> armWatchdog()
            is StartOutcome.Rejected -> {
                // 実行を開始できなかった先頭はキューから外し、次へ進む(接続は保持する)。
                queue.abortCurrent()
                op.fail(outcome.error)
                dispatchNext()
            }
        }
    }

    /**
     * 先頭操作を到着 callback で完了する。現行 epoch と先頭 kind が [callbackKind] に整合した場合
     * だけ [deliver] を呼び、watchdog を解除して次をディスパッチする。遅延・旧 epoch・想定外
     * callback は何も完了しない(Review guide §10)。
     */
    private fun <R> completeInFlight(callbackKind: CallbackKind, deliver: (GattOp<R>) -> Unit) {
        val op = queue.completeCurrent(connectionEpoch, callbackKind) ?: return
        cancelWatchdog()
        @Suppress("UNCHECKED_CAST")
        deliver(op.payload as GattOp<R>)
        dispatchNext()
    }

    private fun completeRead(value: ByteArray, status: Int) {
        completeInFlight<ByteArray>(CallbackKind.CHARACTERISTIC_READ) { op ->
            if (status == BluetoothGatt.GATT_SUCCESS) op.succeed(value)
            else op.fail(bleError(BleErrorCode.FAILED, "Characteristic read failed (status=$status)"))
        }
    }

    private fun completeDescriptorRead(value: ByteArray, status: Int) {
        completeInFlight<ByteArray>(CallbackKind.DESCRIPTOR_READ) { op ->
            if (status == BluetoothGatt.GATT_SUCCESS) op.succeed(value)
            else op.fail(bleError(BleErrorCode.FAILED, "Descriptor read failed (status=$status)"))
        }
    }

    private fun deliverNotification(characteristic: BluetoothGattCharacteristic, value: ByteArray) {
        // 探索した instance から handle を逆引き。未探索なら handle が無く、取り違えを避けて破棄する。
        val handle = handles.handleOf(characteristic) ?: return
        owner.emitCharacteristicValue(deviceId, connectionEpoch, handle, value)
    }

    private fun armWatchdog() {
        main.postDelayed(watchdog, OPERATION_TIMEOUT_MS)
    }

    private fun cancelWatchdog() {
        main.removeCallbacks(watchdog)
    }

    /**
     * 操作 timeout。同じ接続でキューを続行せず、接続実体を破棄し epoch を退役させる(Review guide §10)。
     * 1) 未完了操作を timeout で完了 → 2) GATT を破棄 → 3) DISCONNECTED(operationTimeout) 通知 →
     * 4) onOperationTimeout 通知 → 5) epoch 退役。再接続は body 側が新 epoch で行う。
     */
    private fun handleOperationTimeout() {
        if (queue.isRetired) return
        failQueue(bleError(BleErrorCode.TIMEOUT, "GATT operation timed out"))
        releaseGatt()
        owner.emitConnectionState(
            deviceId, connectionEpoch,
            ConnectionStateMessage.DISCONNECTED, DisconnectReasonMessage.OPERATION_TIMEOUT)
        owner.onOperationTimeout(deviceId, connectionEpoch)
        owner.onConnectionClosed(deviceId, connectionEpoch)
    }

    /** queue を退役させ、未完了操作を [error] で完了する。冪等。 */
    private fun failQueue(error: FlutterError) {
        if (queue.isRetired) return
        for (op in queue.retire()) {
            @Suppress("UNCHECKED_CAST")
            (op.payload as GattOp<Any?>).fail(error)
        }
    }

    /** native GATT リソースと handle を解放する。watchdog も止める。 */
    private fun releaseGatt() {
        cancelWatchdog()
        gatt?.close()
        gatt = null
        isConnected = false
        handles.clear()
    }

    // --- attribute resolution -------------------------------------------

    private inline fun resolveCharacteristic(
        characteristicHandle: Long,
        onError: (FlutterError) -> Nothing,
    ): BluetoothGattCharacteristic {
        if (!isConnected) onError(bleError(BleErrorCode.NOT_CONNECTED, "Not connected"))
        return handles.resolve(characteristicHandle) as? BluetoothGattCharacteristic
            ?: onError(bleError(BleErrorCode.NOT_FOUND, "Unknown characteristic handle"))
    }

    private inline fun resolveDescriptor(
        descriptorHandle: Long,
        onError: (FlutterError) -> Nothing,
    ): BluetoothGattDescriptor {
        if (!isConnected) onError(bleError(BleErrorCode.NOT_CONNECTED, "Not connected"))
        return handles.resolve(descriptorHandle) as? BluetoothGattDescriptor
            ?: onError(bleError(BleErrorCode.NOT_FOUND, "Unknown descriptor handle"))
    }

    // --- native write compatibility (API 31-32 / 33+) -------------------

    /**
     * characteristic write を API 差分を吸収して発行する。busy(buffer-full)を正規化する:
     * API 33+ は int 戻り値の `ERROR_GATT_WRITE_REQUEST_BUSY`、31-32 は boolean 版の `false` を
     * いずれも [BleErrorCode.BUFFER_FULL] へ対応させる(Review guide §14 / Plan Task 9)。
     */
    @Suppress("DEPRECATION")
    private fun startCharacteristicWrite(
        g: BluetoothGatt,
        c: BluetoothGattCharacteristic,
        value: ByteArray,
        withResponse: Boolean,
    ): StartOutcome {
        val writeType = if (withResponse) {
            BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
        } else {
            BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
        }
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            outcomeForWriteStatus(g.writeCharacteristic(c, value, writeType))
        } else {
            c.writeType = writeType
            c.value = value
            // 31-32 の boolean 版は busy を区別できないため、false を buffer-full へ正規化する。
            if (g.writeCharacteristic(c)) StartOutcome.Issued
            else StartOutcome.Rejected(
                bleError(BleErrorCode.BUFFER_FULL, "Characteristic write buffer full"))
        }
    }

    @Suppress("DEPRECATION")
    private fun startDescriptorWrite(
        g: BluetoothGatt,
        d: BluetoothGattDescriptor,
        value: ByteArray,
    ): StartOutcome {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            outcomeForWriteStatus(g.writeDescriptor(d, value))
        } else {
            d.value = value
            if (g.writeDescriptor(d)) StartOutcome.Issued
            else StartOutcome.Rejected(
                bleError(BleErrorCode.BUFFER_FULL, "Descriptor write buffer full"))
        }
    }

    private fun outcomeForWriteStatus(status: Int): StartOutcome = when (status) {
        BluetoothStatusCodes.SUCCESS -> StartOutcome.Issued
        BluetoothStatusCodes.ERROR_GATT_WRITE_REQUEST_BUSY ->
            StartOutcome.Rejected(bleError(BleErrorCode.BUFFER_FULL, "Write request busy"))
        else ->
            StartOutcome.Rejected(bleError(BleErrorCode.FAILED, "Write failed (status=$status)"))
    }

    // --- DTO 変換(探索順に handle 採番)--------------------------------

    private fun BluetoothGattService.toMessage(): ServiceMessage {
        val serviceHandle = handles.register(this)
        return ServiceMessage(
            handle = serviceHandle,
            uuid = uuid.toString(),
            characteristics = characteristics.map { it.toMessage(serviceHandle) },
        )
    }

    private fun BluetoothGattCharacteristic.toMessage(serviceHandle: Long): CharacteristicMessage {
        val p = properties
        return CharacteristicMessage(
            handle = handles.register(this),
            serviceHandle = serviceHandle,
            uuid = uuid.toString(),
            canRead = p and BluetoothGattCharacteristic.PROPERTY_READ != 0,
            canWriteWithResponse = p and BluetoothGattCharacteristic.PROPERTY_WRITE != 0,
            canWriteWithoutResponse =
                p and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE != 0,
            canNotify = p and BluetoothGattCharacteristic.PROPERTY_NOTIFY != 0,
            canIndicate = p and BluetoothGattCharacteristic.PROPERTY_INDICATE != 0,
            descriptors = descriptors.map { it.toMessage() },
        )
    }

    private fun BluetoothGattDescriptor.toMessage(): DescriptorMessage = DescriptorMessage(
        handle = handles.register(this),
        uuid = uuid.toString(),
    )

    companion object {
        /** 操作 watchdog。満了で接続を破棄し epoch を退役させる(Review guide §10)。 */
        private const val OPERATION_TIMEOUT_MS = 10_000L

        /** Client Characteristic Configuration Descriptor(notify/indicate 有効化)。 */
        private val CCCD_UUID: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }
}

/** queue 先頭操作の実行(`start`)結果。`Issued` は callback 待ち、`Rejected` は即時失敗。 */
internal sealed interface StartOutcome {
    object Issued : StartOutcome
    data class Rejected(val error: FlutterError) : StartOutcome
}

/**
 * queue に載せる GATT 操作1件。[start] で native GATT 呼び出しを発行し、到着 callback または
 * timeout/切断で [completer] を1度だけ完了する。[completer] の値型 [R] は操作 kind ごとに固定。
 */
internal class GattOp<R>(
    private val completer: (Result<R>) -> Unit,
    val start: (BluetoothGatt) -> StartOutcome,
) {
    private var done = false

    fun succeed(value: R) {
        if (done) return
        done = true
        completer(Result.success(value))
    }

    fun fail(error: FlutterError) {
        if (done) return
        done = true
        completer(Result.failure(error))
    }
}

/** Unit 完了操作(write / setNotify)の status 完了ヘルパ。 */
private fun GattOp<Unit>.completeUnit(status: Int, failMessage: String) {
    if (status == BluetoothGatt.GATT_SUCCESS) succeed(Unit)
    else fail(bleError(BleErrorCode.FAILED, "$failMessage (status=$status)"))
}
