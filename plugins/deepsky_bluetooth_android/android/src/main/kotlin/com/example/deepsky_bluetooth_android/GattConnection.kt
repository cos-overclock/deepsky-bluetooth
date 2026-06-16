package com.example.deepsky_bluetooth_android

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.os.Handler
import android.os.Looper

/**
 * 1 device = 1 `BluetoothGatt` の接続実体。
 *
 * このスライス(#20)では `connectGatt(autoConnect = false)` / `disconnect` と接続状態
 * callback だけを扱う。GATT 操作 FIFO queue・service discovery・read/write/notify は後続
 * issue(#21-#23)で本クラスを拡張して実装する。
 *
 * 接続状態は常に [owner] 経由で通知し、owner が epoch guard で古い世代の callback を
 * 破棄する(Review guide §9)。
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

    /** GATT を閉じる。callback は発火させない(退役は owner が epoch guard で扱う)。 */
    fun close() {
        gatt?.close()
        gatt = null
        isConnected = false
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
}
