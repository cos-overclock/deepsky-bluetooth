package com.example.deepsky_bluetooth_android

import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothDevice
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.companion.AssociationInfo
import android.companion.AssociationRequest
import android.companion.BluetoothLeDeviceFilter
import android.companion.CompanionDeviceManager
import android.companion.ObservingDevicePresenceRequest
import android.content.Context
import android.content.Intent
import android.content.IntentSender
import android.os.Build
import android.os.ParcelUuid
import com.example.deepsky_bluetooth_android.core.CompanionApiGeneration
import com.example.deepsky_bluetooth_android.core.CompanionAssociationResolver
import com.example.deepsky_bluetooth_android.core.DeviceAddressNormalizer

/**
 * CompanionDeviceManager(CDM)の API 世代差分(associate: 31-32 / 33+、presence: 31-35 / 36+)を
 * 単一箇所へ閉じ込める薄い adapter(Review guide §§8, 14)。
 *
 * 世代判定は純粋な [CompanionApiGeneration] が担い、本クラスはその結果に従って実 CDM API を呼ぶ
 * だけにする。deprecated API(`startObservingDevicePresence(String)` ほか)と `@SuppressLint`
 * はすべてここに隔離し、[BleProcessOwner] からは世代差分も deprecated 警告も見えないようにする。
 *
 * 実 CDM 呼び出し・チューザ起動・ActivityResult は framework 依存のため実機/platform 検証
 * 対象(§16)。世代分岐と正規化の純粋ロジックは `core/` 側で local JVM テストする。
 */
class CompanionDeviceController(
    private val context: Context,
    private val generation: CompanionApiGeneration.Selection =
        CompanionApiGeneration.forSdk(Build.VERSION.SDK_INT),
) {
    companion object {
        /** associate チューザ結果を受け取る `startIntentSenderForResult` の requestCode。 */
        const val REQUEST_CODE_ASSOCIATE = 0xC0DE
    }

    private val manager: CompanionDeviceManager? =
        context.getSystemService(CompanionDeviceManager::class.java)

    /** 進行中の associate の Flutter callback。多重 associate を防ぐ。 */
    private var pendingAssociate: ((Result<String>) -> Unit)? = null

    // --- associate -------------------------------------------------------

    /**
     * device を関連付け、確定後の deviceId(正準 MAC)を [callback] へ返す。チューザ起動には
     * [activity] が要る。Activity 不在・多重要求・未対応 SDK は即エラーで返す。
     */
    fun associate(
        filter: ScanFilterMessage?,
        activity: Activity?,
        callback: (Result<String>) -> Unit,
    ) {
        if (!generation.isSupported) {
            callback(Result.failure(
                bleError(BleErrorCode.NOT_SUPPORTED, "Companion Device is unavailable on this SDK")))
            return
        }
        val cdm = manager
        if (cdm == null) {
            callback(Result.failure(
                bleError(BleErrorCode.BLUETOOTH_UNAVAILABLE, "CompanionDeviceManager unavailable")))
            return
        }
        if (activity == null) {
            callback(Result.failure(
                bleError(BleErrorCode.FAILED, "Activity required for association")))
            return
        }
        if (pendingAssociate != null) {
            callback(Result.failure(
                bleError(BleErrorCode.FAILED, "Association already in progress")))
            return
        }
        pendingAssociate = callback
        val request = buildAssociationRequest(filter)
        when (generation.associateApi) {
            CompanionApiGeneration.AssociateApi.LEGACY_31_32 ->
                cdm.associate(request, legacyCallback(activity), null)
            CompanionApiGeneration.AssociateApi.MODERN_33_PLUS ->
                associateModern(cdm, request, activity)
            null -> completeAssociate(Result.failure(
                bleError(BleErrorCode.NOT_SUPPORTED, "Companion Device is unavailable on this SDK")))
        }
    }

    /**
     * plugin の ActivityResultListener から転送する。associate の requestCode を処理したら true。
     * 33+ は [onAssociationCreated] が先に解決するのが通常で、ここは fallback。
     */
    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE_ASSOCIATE) return false
        if (pendingAssociate == null) return true
        if (resultCode != Activity.RESULT_OK || data == null) {
            completeAssociate(Result.failure(
                bleError(BleErrorCode.REJECTED, "Association cancelled")))
            return true
        }
        val deviceId = when (generation.associateApi) {
            CompanionApiGeneration.AssociateApi.MODERN_33_PLUS -> deviceIdFromAssociationResult(data)
            else -> deviceIdFromLegacyResult(data)
        }
        completeAssociate(resultFor(deviceId))
        return true
    }

    @Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
    private fun legacyCallback(activity: Activity): CompanionDeviceManager.Callback =
        object : CompanionDeviceManager.Callback() {
            override fun onDeviceFound(intentSender: IntentSender) {
                launchChooser(activity, intentSender)
            }

            override fun onFailure(error: CharSequence?) {
                completeAssociate(Result.failure(
                    bleError(BleErrorCode.FAILED, "Association failed: ${error ?: "unknown"}")))
            }
        }

    @SuppressLint("NewApi")
    private fun associateModern(
        cdm: CompanionDeviceManager,
        request: AssociationRequest,
        activity: Activity,
    ) {
        val callback = object : CompanionDeviceManager.Callback() {
            override fun onAssociationPending(intentSender: IntentSender) {
                launchChooser(activity, intentSender)
            }

            override fun onAssociationCreated(associationInfo: AssociationInfo) {
                completeAssociate(resultFor(associationInfo.deviceMacAddress?.toString()))
            }

            override fun onFailure(error: CharSequence?) {
                completeAssociate(Result.failure(
                    bleError(BleErrorCode.FAILED, "Association failed: ${error ?: "unknown"}")))
            }
        }
        cdm.associate(request, context.mainExecutor, callback)
    }

    private fun launchChooser(activity: Activity, intentSender: IntentSender) {
        try {
            activity.startIntentSenderForResult(intentSender, REQUEST_CODE_ASSOCIATE, null, 0, 0, 0)
        } catch (e: IntentSender.SendIntentException) {
            completeAssociate(Result.failure(
                bleError(BleErrorCode.FAILED, "Failed to launch association chooser: ${e.message}")))
        }
    }

    @SuppressLint("NewApi")
    private fun deviceIdFromAssociationResult(data: Intent): String? {
        val association: AssociationInfo? =
            data.getParcelableExtra(CompanionDeviceManager.EXTRA_ASSOCIATION, AssociationInfo::class.java)
        return association?.deviceMacAddress?.toString()
    }

    @Suppress("DEPRECATION")
    private fun deviceIdFromLegacyResult(data: Intent): String? {
        val device: Any? = data.getParcelableExtra(CompanionDeviceManager.EXTRA_DEVICE)
        return when (device) {
            is ScanResult -> device.device?.address
            is BluetoothDevice -> device.address
            else -> null
        }
    }

    private fun resultFor(rawAddress: String?): Result<String> {
        val deviceId = DeviceAddressNormalizer.normalize(rawAddress)
        return if (deviceId != null) {
            Result.success(deviceId)
        } else {
            Result.failure(
                bleError(BleErrorCode.FAILED, "Associated device has no usable address"))
        }
    }

    /** 一度だけ Flutter callback を解決し、pending を解放する。 */
    private fun completeAssociate(result: Result<String>) {
        val callback = pendingAssociate ?: return
        pendingAssociate = null
        callback(result)
    }

    // --- presence --------------------------------------------------------

    /**
     * presence 監視の開始/停止を世代正規化して呼ぶ。36+ は associationId を解決する。失敗は
     * [FlutterError] を投げ、owner/Flutter へ正規化済みエラーとして伝える。
     *
     * presence event 自体の受領・配送(CompanionDeviceService callback)は本 issue の範囲外(#27)。
     */
    fun setDevicePresenceObservation(deviceId: String, enabled: Boolean) {
        if (!generation.isSupported) {
            throw bleError(BleErrorCode.NOT_SUPPORTED, "Companion Device is unavailable on this SDK")
        }
        val cdm = manager
            ?: throw bleError(BleErrorCode.BLUETOOTH_UNAVAILABLE, "CompanionDeviceManager unavailable")
        when (generation.presenceApi) {
            CompanionApiGeneration.PresenceApi.LEGACY_31_35 ->
                observeByAddress(cdm, deviceId, enabled)
            CompanionApiGeneration.PresenceApi.MODERN_36_PLUS ->
                observeByAssociationId(cdm, deviceId, enabled)
            null ->
                throw bleError(BleErrorCode.NOT_SUPPORTED, "Companion Device is unavailable on this SDK")
        }
    }

    @Suppress("DEPRECATION")
    private fun observeByAddress(cdm: CompanionDeviceManager, deviceId: String, enabled: Boolean) {
        if (enabled) cdm.startObservingDevicePresence(deviceId)
        else cdm.stopObservingDevicePresence(deviceId)
    }

    @SuppressLint("NewApi")
    private fun observeByAssociationId(
        cdm: CompanionDeviceManager,
        deviceId: String,
        enabled: Boolean,
    ) {
        val associationId = CompanionAssociationResolver.resolveAssociationId(
            cdm.myAssociations.map {
                CompanionAssociationResolver.AssociationEntry(it.id, it.deviceMacAddress?.toString())
            },
            deviceId,
        ) ?: throw bleError(
            BleErrorCode.NOT_ASSOCIATED, "No association for device $deviceId")
        val request = ObservingDevicePresenceRequest.Builder()
            .setAssociationId(associationId)
            .build()
        if (enabled) cdm.startObservingDevicePresence(request)
        else cdm.stopObservingDevicePresence(request)
    }

    // --- request building ------------------------------------------------

    private fun buildAssociationRequest(filter: ScanFilterMessage?): AssociationRequest {
        val builder = AssociationRequest.Builder()
        filter?.toScanFilters()?.forEach { scanFilter ->
            builder.addDeviceFilter(
                BluetoothLeDeviceFilter.Builder().setScanFilter(scanFilter).build())
        }
        return builder.build()
    }

    private fun ScanFilterMessage.toScanFilters(): List<ScanFilter> {
        val filters = mutableListOf<ScanFilter>()
        addresses.forEach {
            filters.add(ScanFilter.Builder().setDeviceAddress(it.uppercase()).build())
        }
        names.forEach { filters.add(ScanFilter.Builder().setDeviceName(it).build()) }
        serviceUuids.forEach {
            filters.add(ScanFilter.Builder().setServiceUuid(ParcelUuid.fromString(it)).build())
        }
        return filters
    }
}
