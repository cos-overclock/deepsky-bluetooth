package com.example.deepsky_bluetooth_android

import android.bluetooth.BluetoothStatusCodes
import kotlin.test.Test
import kotlin.test.assertEquals

internal class BleErrorMappingTest {
    @Test
    fun invalidDeviceIdAndOutOfRangeConnectionMapToDifferentReasons() {
        val invalidIdError = BleErrorMapping.invalidDeviceId("not-a-mac-address")

        assertEquals(BleErrorCode.NOT_FOUND, invalidIdError.code)
        assertEquals(
            DisconnectReasonMessage.DEVICE_NOT_FOUND,
            BleErrorMapping.disconnectReasonForInvalidDeviceId(),
        )
        assertEquals(
            DisconnectReasonMessage.CONNECT_FAILED,
            BleErrorMapping.disconnectReasonForConnectionClosed(
                wasConnecting = true,
                pendingReason = null,
            ),
        )
    }

    @Test
    fun bluetoothPermissionAndAvailabilityFailuresMapToStablePigeonCodes() {
        assertEquals(
            BleErrorCode.PERMISSION_DENIED,
            BleErrorMapping.permissionDenied("BLUETOOTH_SCAN").code,
        )
        assertEquals(BleErrorCode.BLUETOOTH_OFF, BleErrorMapping.bluetoothOff().code)
        assertEquals(
            BleErrorCode.BLUETOOTH_UNAVAILABLE,
            BleErrorMapping.bluetoothUnavailable("No Bluetooth adapter").code,
        )
    }

    @Test
    fun gattWriteBusyMapsToBufferFull() {
        val error = BleErrorMapping.gattWriteStartStatus(
            BluetoothStatusCodes.ERROR_GATT_WRITE_REQUEST_BUSY,
            "Characteristic write",
        )

        assertEquals(BleErrorCode.BUFFER_FULL, error.code)
    }
}
