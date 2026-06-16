package com.example.deepsky_bluetooth_android.core

import com.example.deepsky_bluetooth_android.core.CompanionAssociationResolver.AssociationEntry

/**
 * `CompanionDeviceService` の presence callback を表す正規化済み内部 event。
 *
 * API 31-32（`String`）/ 33-35（`AssociationInfo`）/ 36+（`DevicePresenceEvent`）の 3 経路は
 * すべてこの型へ収束する（Issue #27 受け入れ条件「同じ内部 event」）。`deviceId` は正準 MAC、
 * `appeared` は出現 true / 消失 false。
 */
data class CompanionPresenceEvent(val deviceId: String, val appeared: Boolean)

/**
 * `CompanionDeviceService` の世代別 callback 生入力を、単一の [CompanionPresenceEvent] へ正規化する
 * 純粋ヘルパ（Review guide §§8, 14）。framework 型には触れず、抽出済みプリミティブだけを受け取る
 * ことで、世代差分のない内部 event を JVM テスト可能な形で組み立てる。
 *
 * 正規化・解決不能（不正 MAC、未関連付け associationId、対象外 event type）はすべて null とし、
 * 呼び出し側で静かに破棄する（presence event は best-effort）。
 */
object CompanionPresenceNormalizer {

    /**
     * `DevicePresenceEvent.EVENT_BLE_APPEARED`（API 36+）。BLE device が出現した event type。
     * framework 定数は public かつ安定値のため、純粋層に文書化して持たせ unit test 可能にする。
     */
    const val EVENT_BLE_APPEARED = 2

    /** `DevicePresenceEvent.EVENT_BLE_DISAPPEARED`（API 36+）。BLE device が消失した event type。 */
    const val EVENT_BLE_DISAPPEARED = 3

    /** 31-32: `String` address からの正規化。 */
    fun fromAddress(rawAddress: String?, appeared: Boolean): CompanionPresenceEvent? {
        val deviceId = DeviceAddressNormalizer.normalize(rawAddress) ?: return null
        return CompanionPresenceEvent(deviceId, appeared)
    }

    /**
     * 33-35: `AssociationInfo` からの正規化。`deviceMacAddress` を優先し、非公開なら
     * [associationId] を [associations] から逆引きする。
     */
    fun fromAssociation(
        deviceAddress: String?,
        associationId: Int?,
        associations: List<AssociationEntry>,
        appeared: Boolean,
    ): CompanionPresenceEvent? {
        val deviceId = DeviceAddressNormalizer.normalize(deviceAddress)
            ?: associationId?.let { CompanionAssociationResolver.resolveDeviceId(associations, it) }
            ?: return null
        return CompanionPresenceEvent(deviceId, appeared)
    }

    /**
     * 36+: `DevicePresenceEvent` からの正規化。BLE 出現/消失 event type だけを写像し、それ以外は
     * 対象外として null。[associationId] を逆引きして deviceId を得る。
     */
    fun fromPresenceEvent(
        associationId: Int,
        eventType: Int,
        associations: List<AssociationEntry>,
    ): CompanionPresenceEvent? {
        val appeared = when (eventType) {
            EVENT_BLE_APPEARED -> true
            EVENT_BLE_DISAPPEARED -> false
            else -> return null
        }
        val deviceId = CompanionAssociationResolver.resolveDeviceId(associations, associationId)
            ?: return null
        return CompanionPresenceEvent(deviceId, appeared)
    }
}
