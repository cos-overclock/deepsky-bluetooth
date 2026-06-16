package com.example.deepsky_bluetooth_android.core

import com.example.deepsky_bluetooth_android.core.CompanionAssociationResolver.AssociationEntry
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class CompanionAssociationResolverTest {

    @Test
    fun resolve_returnsAssociationIdForMatchingDevice() {
        val associations = listOf(
            AssociationEntry(associationId = 7, deviceAddress = "AA:BB:CC:DD:EE:FF"),
        )

        assertEquals(7, CompanionAssociationResolver.resolveAssociationId(associations, "AA:BB:CC:DD:EE:FF"))
    }

    @Test
    fun resolve_matchesCaseInsensitivelyAfterNormalization() {
        // MacAddress.toString() は小文字なので、正規化して大小無視で照合する。
        val associations = listOf(
            AssociationEntry(associationId = 3, deviceAddress = "aa:bb:cc:dd:ee:ff"),
        )

        assertEquals(3, CompanionAssociationResolver.resolveAssociationId(associations, "AA:BB:CC:DD:EE:FF"))
    }

    @Test
    fun resolve_picksTheMatchingEntryAmongMany() {
        val associations = listOf(
            AssociationEntry(associationId = 1, deviceAddress = "11:11:11:11:11:11"),
            AssociationEntry(associationId = 2, deviceAddress = "22:22:22:22:22:22"),
            AssociationEntry(associationId = 3, deviceAddress = "33:33:33:33:33:33"),
        )

        assertEquals(2, CompanionAssociationResolver.resolveAssociationId(associations, "22:22:22:22:22:22"))
    }

    @Test
    fun resolve_returnsNullWhenNoEntryMatches() {
        val associations = listOf(
            AssociationEntry(associationId = 1, deviceAddress = "11:11:11:11:11:11"),
        )

        assertNull(CompanionAssociationResolver.resolveAssociationId(associations, "99:99:99:99:99:99"))
    }

    @Test
    fun resolve_skipsEntriesWithNullAddress() {
        // address 非公開の関連付けは照合不能としてスキップする。
        val associations = listOf(
            AssociationEntry(associationId = 1, deviceAddress = null),
            AssociationEntry(associationId = 2, deviceAddress = "22:22:22:22:22:22"),
        )

        assertEquals(2, CompanionAssociationResolver.resolveAssociationId(associations, "22:22:22:22:22:22"))
        assertNull(CompanionAssociationResolver.resolveAssociationId(associations, "11:11:11:11:11:11"))
    }

    @Test
    fun resolve_returnsNullForInvalidTargetDeviceId() {
        val associations = listOf(
            AssociationEntry(associationId = 1, deviceAddress = "11:11:11:11:11:11"),
        )

        assertNull(CompanionAssociationResolver.resolveAssociationId(associations, "not-a-mac"))
    }

    @Test
    fun resolve_returnsNullForEmptyAssociations() {
        assertNull(CompanionAssociationResolver.resolveAssociationId(emptyList(), "11:11:11:11:11:11"))
    }
}
