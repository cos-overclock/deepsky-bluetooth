package com.example.deepsky_bluetooth_android.core

import com.example.deepsky_bluetooth_android.core.CompanionApiGeneration.AssociateApi
import com.example.deepsky_bluetooth_android.core.CompanionApiGeneration.PresenceApi
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

internal class CompanionApiGenerationTest {

    @Test
    fun sdk31And32_useLegacyAssociateAndLegacyPresence() {
        // API 31-32 は onDeviceFound(IntentSender) と device address 版 presence。
        for (sdk in listOf(31, 32)) {
            val selection = CompanionApiGeneration.forSdk(sdk)
            assertTrue(selection.isSupported, "sdk=$sdk")
            assertEquals(AssociateApi.LEGACY_31_32, selection.associateApi, "sdk=$sdk")
            assertEquals(PresenceApi.LEGACY_31_35, selection.presenceApi, "sdk=$sdk")
        }
    }

    @Test
    fun sdk33To35_useModernAssociateButLegacyPresence() {
        // 33+ で AssociationInfo 経路へ、presence は 36 未満なので device address 版のまま。
        for (sdk in listOf(33, 34, 35)) {
            val selection = CompanionApiGeneration.forSdk(sdk)
            assertTrue(selection.isSupported, "sdk=$sdk")
            assertEquals(AssociateApi.MODERN_33_PLUS, selection.associateApi, "sdk=$sdk")
            assertEquals(PresenceApi.LEGACY_31_35, selection.presenceApi, "sdk=$sdk")
        }
    }

    @Test
    fun sdk36AndAbove_useModernAssociateAndModernPresence() {
        // 36+ は ObservingDevicePresenceRequest(associationId) 版。
        for (sdk in listOf(36, 37, 100)) {
            val selection = CompanionApiGeneration.forSdk(sdk)
            assertTrue(selection.isSupported, "sdk=$sdk")
            assertEquals(AssociateApi.MODERN_33_PLUS, selection.associateApi, "sdk=$sdk")
            assertEquals(PresenceApi.MODERN_36_PLUS, selection.presenceApi, "sdk=$sdk")
        }
    }

    @Test
    fun sdkBelow31_isUnsupportedWithNoApis() {
        // minSdk は 31。万一それ未満で呼ばれても owner が機能不可へ変換できるよう null を返す。
        for (sdk in listOf(30, 29, 1)) {
            val selection = CompanionApiGeneration.forSdk(sdk)
            assertFalse(selection.isSupported, "sdk=$sdk")
            assertNull(selection.associateApi, "sdk=$sdk")
            assertNull(selection.presenceApi, "sdk=$sdk")
        }
    }
}
