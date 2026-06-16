package com.example.deepsky_bluetooth_android.core

/**
 * MAC アドレス文字列を正準 DeepskyDeviceId へ正規化・検証する純粋ヘルパ。
 *
 * 既存実装(`BleProcessOwner.connect` の `getRemoteDevice(deviceId)`、scan が返す
 * `device.address`)に合わせ、正準形は大文字の `XX:XX:XX:XX:XX:XX`(6 オクテット)とする。
 * CDM から得る `BluetoothDevice.address` / `AssociationInfo.deviceMacAddress`(`MacAddress`、
 * `toString()` は小文字)をこの正準形へ揃える。
 */
object DeviceAddressNormalizer {

    private val MAC_REGEX = Regex("^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$")

    /** 正準 MAC を返す。null・空・不正フォーマットは [normalize] 不能として null。 */
    fun normalize(raw: String?): String? {
        val trimmed = raw?.trim() ?: return null
        if (!MAC_REGEX.matches(trimmed)) return null
        return trimmed.uppercase()
    }
}
