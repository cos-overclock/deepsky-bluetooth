package com.example.deepsky_bluetooth_android.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

internal class PendingPresenceBufferTest {

    private fun event(id: String, appeared: Boolean = true) = CompanionPresenceEvent(id, appeared)

    @Test
    fun drain_returnsRecordedEventsInFifoOrder() {
        val buffer = PendingPresenceBuffer()
        buffer.record(event("AA:AA:AA:AA:AA:AA"))
        buffer.record(event("BB:BB:BB:BB:BB:BB", appeared = false))

        assertEquals(
            listOf(event("AA:AA:AA:AA:AA:AA"), event("BB:BB:BB:BB:BB:BB", appeared = false)),
            buffer.drain(),
        )
    }

    @Test
    fun drain_emptiesTheBuffer() {
        val buffer = PendingPresenceBuffer()
        buffer.record(event("AA:AA:AA:AA:AA:AA"))

        buffer.drain()

        assertTrue(buffer.drain().isEmpty())
    }

    @Test
    fun drain_onEmptyBufferReturnsEmptyList() {
        assertTrue(PendingPresenceBuffer().drain().isEmpty())
    }

    @Test
    fun record_dropsOldestWhenOverCapacity() {
        val buffer = PendingPresenceBuffer(capacity = 2)
        buffer.record(event("11:11:11:11:11:11"))
        buffer.record(event("22:22:22:22:22:22"))
        buffer.record(event("33:33:33:33:33:33")) // 最古(11..)を破棄

        assertEquals(
            listOf(event("22:22:22:22:22:22"), event("33:33:33:33:33:33")),
            buffer.drain(),
        )
    }
}
