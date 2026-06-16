package com.example.deepsky_bluetooth_android.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

internal class EpochRegistryTest {
    private val deviceA = "AA:AA:AA:AA:AA:AA"
    private val deviceB = "BB:BB:BB:BB:BB:BB"

    @Test
    fun allocate_returnsStrictlyIncreasingEpochsPerDevice() {
        val registry = EpochRegistry()

        assertEquals(1L, registry.allocate(deviceA))
        assertEquals(2L, registry.allocate(deviceA))
        assertEquals(3L, registry.allocate(deviceA))
    }

    @Test
    fun allocate_isIndependentPerDevice() {
        val registry = EpochRegistry()

        assertEquals(1L, registry.allocate(deviceA))
        assertEquals(1L, registry.allocate(deviceB))
        assertEquals(2L, registry.allocate(deviceA))
        assertEquals(2L, registry.allocate(deviceB))
    }

    @Test
    fun allocate_staysMonotonicAcrossRetire() {
        val registry = EpochRegistry()

        assertEquals(1L, registry.allocate(deviceA))
        registry.retire(deviceA)
        assertEquals(2L, registry.allocate(deviceA))
    }

    @Test
    fun isCurrent_trueOnlyForLatestEpoch() {
        val registry = EpochRegistry()

        val first = registry.allocate(deviceA)
        val second = registry.allocate(deviceA)

        assertFalse(registry.isCurrent(deviceA, first))
        assertTrue(registry.isCurrent(deviceA, second))
    }

    @Test
    fun isCurrent_falseAfterRetire() {
        val registry = EpochRegistry()

        val epoch = registry.allocate(deviceA)
        registry.retire(deviceA)

        assertFalse(registry.isCurrent(deviceA, epoch))
    }

    @Test
    fun isCurrent_falseForUnknownDevice() {
        val registry = EpochRegistry()

        assertFalse(registry.isCurrent(deviceA, 1L))
    }

    @Test
    fun current_isNullBeforeAllocationAndAfterRetire() {
        val registry = EpochRegistry()

        assertNull(registry.current(deviceA))

        val epoch = registry.allocate(deviceA)
        assertEquals(epoch, registry.current(deviceA))

        registry.retire(deviceA)
        assertNull(registry.current(deviceA))
    }
}
