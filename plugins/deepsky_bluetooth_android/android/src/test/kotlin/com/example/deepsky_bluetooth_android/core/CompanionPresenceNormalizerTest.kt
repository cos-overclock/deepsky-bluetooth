package com.example.deepsky_bluetooth_android.core

import com.example.deepsky_bluetooth_android.core.CompanionAssociationResolver.AssociationEntry
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class CompanionPresenceNormalizerTest {

    private val associations = listOf(
        AssociationEntry(associationId = 7, deviceAddress = "aa:bb:cc:dd:ee:ff"),
    )

    // --- 31-32: String 経路 (fromAddress) ---

    @Test
    fun fromAddress_appearedNormalizesToCanonicalDeviceId() {
        assertEquals(
            CompanionPresenceEvent("AA:BB:CC:DD:EE:FF", appeared = true),
            CompanionPresenceNormalizer.fromAddress("aa:bb:cc:dd:ee:ff", appeared = true),
        )
    }

    @Test
    fun fromAddress_disappearedCarriesAppearedFalse() {
        assertEquals(
            CompanionPresenceEvent("AA:BB:CC:DD:EE:FF", appeared = false),
            CompanionPresenceNormalizer.fromAddress("AA:BB:CC:DD:EE:FF", appeared = false),
        )
    }

    @Test
    fun fromAddress_returnsNullForMalformedAddress() {
        assertNull(CompanionPresenceNormalizer.fromAddress("not-a-mac", appeared = true))
        assertNull(CompanionPresenceNormalizer.fromAddress(null, appeared = true))
    }

    // --- 33-35: AssociationInfo 経路 (fromAssociation) ---

    @Test
    fun fromAssociation_prefersDeviceMacAddress() {
        assertEquals(
            CompanionPresenceEvent("AA:BB:CC:DD:EE:FF", appeared = true),
            CompanionPresenceNormalizer.fromAssociation(
                deviceAddress = "aa:bb:cc:dd:ee:ff",
                associationId = 7,
                associations = associations,
                appeared = true,
            ),
        )
    }

    @Test
    fun fromAssociation_fallsBackToAssociationIdWhenAddressMissing() {
        // deviceMacAddress 非公開でも associationId から逆引きして deviceId を得る。
        assertEquals(
            CompanionPresenceEvent("AA:BB:CC:DD:EE:FF", appeared = false),
            CompanionPresenceNormalizer.fromAssociation(
                deviceAddress = null,
                associationId = 7,
                associations = associations,
                appeared = false,
            ),
        )
    }

    @Test
    fun fromAssociation_returnsNullWhenNeitherResolves() {
        assertNull(
            CompanionPresenceNormalizer.fromAssociation(
                deviceAddress = null,
                associationId = null,
                associations = associations,
                appeared = true,
            ),
        )
        assertNull(
            CompanionPresenceNormalizer.fromAssociation(
                deviceAddress = null,
                associationId = 999,
                associations = associations,
                appeared = true,
            ),
        )
    }

    // --- 36+: DevicePresenceEvent 経路 (fromPresenceEvent) ---

    @Test
    fun fromPresenceEvent_mapsBleAppearedToAppearedTrue() {
        assertEquals(
            CompanionPresenceEvent("AA:BB:CC:DD:EE:FF", appeared = true),
            CompanionPresenceNormalizer.fromPresenceEvent(
                associationId = 7,
                eventType = CompanionPresenceNormalizer.EVENT_BLE_APPEARED,
                associations = associations,
            ),
        )
    }

    @Test
    fun fromPresenceEvent_mapsBleDisappearedToAppearedFalse() {
        assertEquals(
            CompanionPresenceEvent("AA:BB:CC:DD:EE:FF", appeared = false),
            CompanionPresenceNormalizer.fromPresenceEvent(
                associationId = 7,
                eventType = CompanionPresenceNormalizer.EVENT_BLE_DISAPPEARED,
                associations = associations,
            ),
        )
    }

    @Test
    fun fromPresenceEvent_returnsNullForNonBleEventTypes() {
        // BT classic / self-managed の event type は BLE presence の対象外。
        for (type in listOf(0, 1, 4, 5, 42)) {
            assertNull(
                CompanionPresenceNormalizer.fromPresenceEvent(7, type, associations),
                "event type $type should be ignored",
            )
        }
    }

    @Test
    fun fromPresenceEvent_returnsNullForUnknownAssociationId() {
        assertNull(
            CompanionPresenceNormalizer.fromPresenceEvent(
                associationId = 999,
                eventType = CompanionPresenceNormalizer.EVENT_BLE_APPEARED,
                associations = associations,
            ),
        )
    }

    // --- 受け入れ条件: 31-32 / 33-35 / 36+ が同じ内部 event になる ---

    @Test
    fun allGenerationsProduceTheSameInternalEvent() {
        val legacy = CompanionPresenceNormalizer.fromAddress("aa:bb:cc:dd:ee:ff", appeared = true)
        val mid = CompanionPresenceNormalizer.fromAssociation(
            deviceAddress = "aa:bb:cc:dd:ee:ff", associationId = 7,
            associations = associations, appeared = true,
        )
        val modern = CompanionPresenceNormalizer.fromPresenceEvent(
            associationId = 7,
            eventType = CompanionPresenceNormalizer.EVENT_BLE_APPEARED,
            associations = associations,
        )

        val expected = CompanionPresenceEvent("AA:BB:CC:DD:EE:FF", appeared = true)
        assertEquals(expected, legacy)
        assertEquals(expected, mid)
        assertEquals(expected, modern)
    }
}
