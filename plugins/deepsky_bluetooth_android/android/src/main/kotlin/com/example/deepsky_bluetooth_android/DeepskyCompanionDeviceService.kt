package com.example.deepsky_bluetooth_android

import android.annotation.SuppressLint
import android.companion.AssociationInfo
import android.companion.CompanionDeviceService
import android.companion.DevicePresenceEvent

/**
 * CDM が device の出現/消失を通知する `CompanionDeviceService`。process 死後にもシステムから
 * 起動され得る(Review guide §12)。
 *
 * API 世代で callback が異なる(31-32: `String` / 33-35: `AssociationInfo` / 36+:
 * `DevicePresenceEvent`)ため、3 系すべてを override して生プリミティブを抽出し、[BleProcessOwner]
 * の受け口へ転送するだけの薄い adapter に保つ。正規化(単一内部 event 化)・配送・buffer は owner と
 * 純粋層(`core/`)が行う。`@Deprecated` / `@SuppressLint` はここに隔離する。
 *
 * 本 PR(#27)では event の正規化・保持・配送までを担う。headless `FlutterEngine` の実生成は
 * background handle 登録(Task 17)に依存するため後続 #29 で追加し、ここに `ensureEngine` を差し込む。
 */
class DeepskyCompanionDeviceService : CompanionDeviceService() {

    // --- 31-32: String 経路(API 33 で deprecated) ---

    @Deprecated("Deprecated in API 33; superseded by onDeviceAppeared(AssociationInfo)")
    @Suppress("OVERRIDE_DEPRECATION")
    override fun onDeviceAppeared(address: String) {
        BleProcessOwner.ensureAttached(applicationContext)
        BleProcessOwner.onCompanionDeviceAppeared(address)
    }

    @Deprecated("Deprecated in API 33; superseded by onDeviceDisappeared(AssociationInfo)")
    @Suppress("OVERRIDE_DEPRECATION")
    override fun onDeviceDisappeared(address: String) {
        BleProcessOwner.ensureAttached(applicationContext)
        BleProcessOwner.onCompanionDeviceDisappeared(address)
    }

    // --- 33-35: AssociationInfo 経路 ---

    @SuppressLint("NewApi")
    override fun onDeviceAppeared(associationInfo: AssociationInfo) {
        BleProcessOwner.ensureAttached(applicationContext)
        BleProcessOwner.onCompanionAssociationEvent(
            deviceAddress = associationInfo.deviceMacAddress?.toString(),
            associationId = associationInfo.id,
            appeared = true,
        )
    }

    @SuppressLint("NewApi")
    override fun onDeviceDisappeared(associationInfo: AssociationInfo) {
        BleProcessOwner.ensureAttached(applicationContext)
        BleProcessOwner.onCompanionAssociationEvent(
            deviceAddress = associationInfo.deviceMacAddress?.toString(),
            associationId = associationInfo.id,
            appeared = false,
        )
    }

    // --- 36+: DevicePresenceEvent 経路 ---

    @SuppressLint("NewApi")
    override fun onDevicePresenceEvent(event: DevicePresenceEvent) {
        BleProcessOwner.ensureAttached(applicationContext)
        BleProcessOwner.onCompanionPresenceEvent(
            associationId = event.associationId,
            eventType = event.event,
        )
    }
}
