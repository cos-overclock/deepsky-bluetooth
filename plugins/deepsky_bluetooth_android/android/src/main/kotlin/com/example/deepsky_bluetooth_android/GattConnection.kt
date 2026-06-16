package com.example.deepsky_bluetooth_android

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.os.Handler
import android.os.Looper
import com.example.deepsky_bluetooth_android.core.HandleRegistry

/**
 * 1 device = 1 `BluetoothGatt` の接続実体。
 *
 * #20 で `connectGatt(autoConnect = false)` / `disconnect` と接続状態 callback を扱い、
 * #21 で service discovery と探索時の handle 採番を追加した。GATT 操作 FIFO queue・
 * read/write/notify は後続 issue(#23)で本クラスを拡張して実装する。
 *
 * 接続状態は常に [owner] 経由で通知し、owner が epoch guard で古い世代の callback を
 * 破棄する(Review guide §9)。探索した属性は接続(=epoch)寿命の [handles] に探索順で登録し、
 * UUID ではなく handle で逆引きできるようにする(Review guide §9 / §11)。
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

    // 探索した属性の handle → native object 逆引き。接続(=epoch)寿命で、close 時に clear する。
    private val handles = HandleRegistry<Any>()
    private var discoverCallback: ((Result<List<ServiceMessage>>) -> Unit)? = null

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

    /**
     * service/characteristic/descriptor を探索し、探索順に handle を採番した DTO tree を返す。
     *
     * 同じ UUID の属性も別 handle で区別する。再探索を開始した時点で [handles] を clear するため、
     * 探索中・探索失敗のいずれでも古い tree の handle は new object へ付け替わらず NotFound のまま
     * になる(Review guide §11)。
     */
    fun discoverServices(callback: (Result<List<ServiceMessage>>) -> Unit) {
        val g = gatt
        if (g == null || !isConnected) {
            callback(Result.failure(bleError(BleErrorCode.NOT_CONNECTED, "Not connected")))
            return
        }
        if (discoverCallback != null) {
            callback(Result.failure(
                bleError(BleErrorCode.REJECTED, "Service discovery already in progress")))
            return
        }
        // discoverServices() は BLUETOOTH_CONNECT が実行時に剥奪されると SecurityException 等を
        // 投げ得るため、クラッシュさせず FAILED として返す(connect() の connectGatt と同様)。
        val started = try {
            g.discoverServices()
        } catch (e: Exception) {
            callback(Result.failure(
                bleError(BleErrorCode.FAILED, "Failed to start service discovery: ${e.message}")))
            return
        }
        if (!started) {
            callback(Result.failure(
                bleError(BleErrorCode.FAILED, "Failed to start service discovery")))
            return
        }
        // 再探索を開始した時点で旧 tree の handle を無効化する。counter は戻さないため、進行中も
        // 失敗時も古い handle は解決できない(Review guide §11)。
        handles.clear()
        discoverCallback = callback
    }

    /** [characteristicHandle] に対応する characteristic。未探索・clear 済みなら NotFound。 */
    internal fun characteristicFor(characteristicHandle: Long): BluetoothGattCharacteristic {
        if (!isConnected) throw bleError(BleErrorCode.NOT_CONNECTED, "Not connected")
        return handles.resolve(characteristicHandle) as? BluetoothGattCharacteristic
            ?: throw bleError(BleErrorCode.NOT_FOUND, "Unknown characteristic handle")
    }

    /** [descriptorHandle] に対応する descriptor。未探索・clear 済みなら NotFound。 */
    internal fun descriptorFor(descriptorHandle: Long): BluetoothGattDescriptor {
        if (!isConnected) throw bleError(BleErrorCode.NOT_CONNECTED, "Not connected")
        return handles.resolve(descriptorHandle) as? BluetoothGattDescriptor
            ?: throw bleError(BleErrorCode.NOT_FOUND, "Unknown descriptor handle")
    }

    /** GATT を閉じる。callback は発火させない(退役は owner が epoch guard で扱う)。 */
    fun close() {
        gatt?.close()
        gatt = null
        isConnected = false
        // epoch 退役で handle registry を clear し、古い handle を二度と解決させない(Review guide §11)。
        handles.clear()
        // 探索中に切断した場合は宙ぶらりんにせず NotConnected で完了させる。
        discoverCallback?.invoke(
            Result.failure(bleError(BleErrorCode.NOT_CONNECTED, "Not connected")))
        discoverCallback = null
    }

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
            val callback = discoverCallback ?: return@post
            discoverCallback = null
            if (status != BluetoothGatt.GATT_SUCCESS) {
                // 探索開始時に clear 済みのため、失敗時は handle が空のまま = 全 handle NotFound。
                callback(Result.failure(
                    bleError(BleErrorCode.FAILED, "Service discovery failed (status=$status)")))
                return@post
            }
            // handle は discoverServices() 開始時に clear 済み。ここでは探索順に採番し直す。
            callback(Result.success(g.services.map { it.toMessage() }))
        }
    }

    // 探索順に handle を採番しつつ DTO tree へ変換する。重複 UUID もそのまま保持する(Review guide §9)。
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
}
