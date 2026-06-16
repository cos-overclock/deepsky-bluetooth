package com.example.deepsky_bluetooth_android.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

internal class HandleRegistryTest {

    @Test
    fun register_returnsStrictlyIncreasingHandlesStartingAtFirstHandle() {
        val registry = HandleRegistry<String>()

        assertEquals(HandleRegistry.FIRST_HANDLE, registry.register("a"))
        assertEquals(HandleRegistry.FIRST_HANDLE + 1L, registry.register("b"))
        assertEquals(HandleRegistry.FIRST_HANDLE + 2L, registry.register("c"))
    }

    @Test
    fun register_givesDistinctHandlesToEqualValues() {
        // 同一 UUID の属性が複数あっても、それぞれ別 handle で操作できる(Review guide §9)。
        val registry = HandleRegistry<String>()
        val uuid = "0000180d-0000-1000-8000-00805f9b34fb"

        val first = registry.register(uuid)
        val second = registry.register(uuid)

        assertNotEquals(first, second)
        assertEquals(uuid, registry.resolve(first))
        assertEquals(uuid, registry.resolve(second))
    }

    @Test
    fun resolve_returnsTheRegisteredInstance() {
        val registry = HandleRegistry<Any>()
        val obj = Any()

        val handle = registry.register(obj)

        assertSame(obj, registry.resolve(handle))
    }

    @Test
    fun resolve_returnsNullForUnknownHandle() {
        val registry = HandleRegistry<String>()
        registry.register("a")

        assertNull(registry.resolve(9999L))
    }

    @Test
    fun contains_reflectsRegistration() {
        val registry = HandleRegistry<String>()
        val handle = registry.register("a")

        assertTrue(registry.contains(handle))
        assertFalse(registry.contains(handle + 1L))
    }

    @Test
    fun clear_dropsAllMappings() {
        // epoch 退役時に registry が clear される(Review guide §11)。
        val registry = HandleRegistry<String>()
        val handle = registry.register("a")

        registry.clear()

        assertNull(registry.resolve(handle))
        assertFalse(registry.contains(handle))
    }

    @Test
    fun clear_doesNotReuseHandlesSoStaleHandlesStayInvalid() {
        // 同一 epoch 内で再探索しても、古い tree の handle は new object へ付け替わらず
        // NotFound になる(Review guide §11: UUID だけの自動付け替えはしない)。
        val registry = HandleRegistry<String>()
        val stale = registry.register("a")

        registry.clear()
        val fresh = registry.register("b")

        assertNotEquals(stale, fresh)
        assertNull(registry.resolve(stale))
        assertEquals("b", registry.resolve(fresh))
    }
}
