package com.example.deepsky_bluetooth_android.core

/**
 * 既存の CDM 関連付け一覧から、対象 deviceId に対応する associationId を解決する純粋ヘルパ。
 *
 * API 36+ の presence 監視は device address ではなく associationId を要求するため、
 * `getMyAssociations()` 由来のエントリと対象 deviceId を [DeviceAddressNormalizer] で正規化して
 * 大小無視で照合する。一致が無ければ null を返し、呼び出し側が `notAssociated` へ変換する。
 */
object CompanionAssociationResolver {

    /** `AssociationInfo` から抽出した照合対象。`deviceAddress` は非公開なら null。 */
    data class AssociationEntry(
        val associationId: Int,
        val deviceAddress: String?,
    )

    /** 対象 deviceId に一致する associationId。無ければ null。 */
    fun resolveAssociationId(associations: List<AssociationEntry>, deviceId: String): Int? {
        val target = DeviceAddressNormalizer.normalize(deviceId) ?: return null
        return associations.firstOrNull { entry ->
            DeviceAddressNormalizer.normalize(entry.deviceAddress) == target
        }?.associationId
    }
}
