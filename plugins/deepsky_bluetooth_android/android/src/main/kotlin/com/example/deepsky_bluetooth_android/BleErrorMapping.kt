package com.example.deepsky_bluetooth_android

import android.bluetooth.BluetoothStatusCodes

/** Stable native-to-Pigeon error mapping helpers. */
internal object BleErrorMapping {
    fun permissionDenied(permission: String): FlutterError =
        bleError(BleErrorCode.PERMISSION_DENIED, "$permission denied")

    fun bluetoothOff(): FlutterError =
        bleError(BleErrorCode.BLUETOOTH_OFF, "Bluetooth is off")

    fun bluetoothUnavailable(message: String): FlutterError =
        bleError(BleErrorCode.BLUETOOTH_UNAVAILABLE, message)

    fun invalidDeviceId(deviceId: String): FlutterError =
        bleError(BleErrorCode.NOT_FOUND, "Invalid device id: $deviceId")

    fun notConnected(): FlutterError =
        bleError(BleErrorCode.NOT_CONNECTED, "Not connected")

    fun disconnectReasonForConnectionClosed(
        wasConnecting: Boolean,
        pendingReason: DisconnectReasonMessage?,
    ): DisconnectReasonMessage =
        pendingReason ?: if (wasConnecting) {
            DisconnectReasonMessage.CONNECT_FAILED
        } else {
            DisconnectReasonMessage.CONNECTION_LOST
        }

    fun gattStatusFailure(operation: String, status: Int): FlutterError =
        bleError(BleErrorCode.FAILED, "$operation failed (status=$status)")

    fun gattWriteStartStatus(status: Int, operation: String): FlutterError =
        if (status == BluetoothStatusCodes.ERROR_GATT_WRITE_REQUEST_BUSY) {
            bleError(BleErrorCode.BUFFER_FULL, "$operation buffer full")
        } else {
            bleError(BleErrorCode.FAILED, "$operation failed (status=$status)")
        }
}
