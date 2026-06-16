package com.example.deepsky_bluetooth_android.core

/**
 * `Build.VERSION.SDK_INT` から CompanionDeviceManager で使用すべき API 世代を選ぶ純粋セレクタ。
 *
 * CDM の associate と presence 監視は世代ごとに到達経路が違う(Review guide §§8, 14)。世代判定を
 * ここへ集約し、[com.example.deepsky_bluetooth_android.CompanionDeviceController] は判定結果に
 * 従って実 API を呼ぶだけにする。owner は世代差分を一切持たない。
 */
object CompanionApiGeneration {

    /** associate の到達経路。 */
    enum class AssociateApi {
        /** API 31-32: `Callback.onDeviceFound(IntentSender)` 経路。 */
        LEGACY_31_32,

        /** API 33+: `onAssociationPending` + `onAssociationCreated(AssociationInfo)` 経路。 */
        MODERN_33_PLUS,
    }

    /** presence 監視の到達経路。 */
    enum class PresenceApi {
        /** API 31-35: `startObservingDevicePresence(String)`(deprecated)。 */
        LEGACY_31_35,

        /** API 36+: `ObservingDevicePresenceRequest`(associationId 指定)。 */
        MODERN_36_PLUS,
    }

    /** 世代判定結果。非対応 SDK では各 API が null。 */
    data class Selection(
        val isSupported: Boolean,
        val associateApi: AssociateApi?,
        val presenceApi: PresenceApi?,
    )

    /** CDM が利用可能な最小 SDK(Android 12 / S)。 */
    private const val MIN_SDK = 31

    /** AssociationInfo 経路が使える最小 SDK(Android 13 / T)。 */
    private const val ASSOCIATION_INFO_SDK = 33

    /** ObservingDevicePresenceRequest 経路が使える最小 SDK(Android 16 / Baklava)。 */
    private const val PRESENCE_REQUEST_SDK = 36

    fun forSdk(sdkInt: Int): Selection {
        if (sdkInt < MIN_SDK) {
            return Selection(isSupported = false, associateApi = null, presenceApi = null)
        }
        val associateApi =
            if (sdkInt >= ASSOCIATION_INFO_SDK) AssociateApi.MODERN_33_PLUS
            else AssociateApi.LEGACY_31_32
        val presenceApi =
            if (sdkInt >= PRESENCE_REQUEST_SDK) PresenceApi.MODERN_36_PLUS
            else PresenceApi.LEGACY_31_35
        return Selection(isSupported = true, associateApi = associateApi, presenceApi = presenceApi)
    }
}
