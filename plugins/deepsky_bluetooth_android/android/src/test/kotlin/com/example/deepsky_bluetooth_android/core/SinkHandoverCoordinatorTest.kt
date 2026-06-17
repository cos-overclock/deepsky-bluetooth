package com.example.deepsky_bluetooth_android.core

import com.example.deepsky_bluetooth_android.ConnectionStateMessage
import com.example.deepsky_bluetooth_android.DisconnectReasonMessage
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

internal class SinkHandoverCoordinatorTest {

    @Test
    fun candidateDoesNotReplaceActiveSinkBeforeSnapshotAck() {
        val coordinator = coordinator()

        coordinator.attachCandidate("headless")
        val firstSnapshot = coordinator.onDartReady("headless")
        coordinator.ackStateResync("headless", firstSnapshot!!.snapshotId)
        assertEquals("headless", coordinator.activeToken)

        coordinator.attachCandidate("ui")
        val uiSnapshot = coordinator.onDartReady("ui")

        assertEquals("headless", coordinator.activeToken)
        assertEquals("ui", coordinator.candidateToken)

        val ack = coordinator.ackStateResync("ui", uiSnapshot!!.snapshotId)

        assertEquals("ui", coordinator.activeToken)
        assertEquals("headless", ack.retiredToken)
        assertNull(coordinator.candidateToken)
        assertTrue(ack.bufferedEvents.isEmpty())
    }

    @Test
    fun dartReadyBuildsSnapshotFromLatestConnectionState() {
        val coordinator = coordinator()
        coordinator.recordConnectionState(
            deviceId = "AA:BB:CC:DD:EE:FF",
            connectionEpoch = 7,
            state = ConnectionStateMessage.CONNECTING,
            disconnectReason = null,
        )
        coordinator.recordConnectionState(
            deviceId = "AA:BB:CC:DD:EE:FF",
            connectionEpoch = 7,
            state = ConnectionStateMessage.DISCONNECTED,
            disconnectReason = DisconnectReasonMessage.CONNECTION_LOST,
        )

        coordinator.attachCandidate("ui")
        val snapshot = coordinator.onDartReady("ui")!!

        assertEquals(1, snapshot.devices.size)
        assertEquals(ConnectionStateMessage.DISCONNECTED, snapshot.devices.single().state)
        assertEquals(
            DisconnectReasonMessage.CONNECTION_LOST,
            snapshot.devices.single().disconnectReason,
        )
    }

    @Test
    fun eventsAfterSnapshotAreFlushedInOrderAfterAck() {
        val coordinator = coordinator()
        coordinator.attachCandidate("headless")
        coordinator.ackStateResync("headless", coordinator.onDartReady("headless")!!.snapshotId)

        coordinator.attachCandidate("ui")
        val snapshot = coordinator.onDartReady("ui")!!

        val first = HandoverEvent.DeviceAppeared("AA:AA:AA:AA:AA:AA")
        val second = HandoverEvent.CharacteristicValue("AA:AA:AA:AA:AA:AA", 1, 10, byteArrayOf(1))
        assertFalse(coordinator.recordEvent(first).deliverImmediately)
        assertFalse(coordinator.recordEvent(second).deliverImmediately)

        val ack = coordinator.ackStateResync("ui", snapshot.snapshotId)

        assertEquals(listOf(first, second), ack.bufferedEvents)
    }

    @Test
    fun bufferDropsOldestDroppableEventsWhenOverCapacity() {
        val coordinator = coordinator(capacity = 2)
        coordinator.attachCandidate("headless")
        coordinator.ackStateResync("headless", coordinator.onDartReady("headless")!!.snapshotId)
        coordinator.attachCandidate("ui")
        val snapshot = coordinator.onDartReady("ui")!!

        coordinator.recordEvent(HandoverEvent.DeviceAppeared("11:11:11:11:11:11"))
        coordinator.recordEvent(HandoverEvent.DeviceAppeared("22:22:22:22:22:22"))
        coordinator.recordEvent(HandoverEvent.DeviceAppeared("33:33:33:33:33:33"))

        val ack = coordinator.ackStateResync("ui", snapshot.snapshotId)

        assertEquals(
            listOf(
                HandoverEvent.DeviceAppeared("22:22:22:22:22:22"),
                HandoverEvent.DeviceAppeared("33:33:33:33:33:33"),
            ),
            ack.bufferedEvents,
        )
    }

    @Test
    fun connectionStateOverflowUpdatesSnapshotInsteadOfDroppingLatestState() {
        val coordinator = coordinator(capacity = 1)
        coordinator.attachCandidate("headless")
        coordinator.ackStateResync("headless", coordinator.onDartReady("headless")!!.snapshotId)
        coordinator.attachCandidate("ui")
        val snapshot = coordinator.onDartReady("ui")!!

        coordinator.recordEvent(HandoverEvent.DeviceAppeared("11:11:11:11:11:11"))
        coordinator.recordConnectionState(
            deviceId = "AA:BB:CC:DD:EE:FF",
            connectionEpoch = 3,
            state = ConnectionStateMessage.CONNECTED,
            disconnectReason = null,
        )
        coordinator.recordConnectionState(
            deviceId = "AA:BB:CC:DD:EE:FF",
            connectionEpoch = 3,
            state = ConnectionStateMessage.DISCONNECTED,
            disconnectReason = DisconnectReasonMessage.CONNECTION_LOST,
        )

        val ack = coordinator.ackStateResync("ui", snapshot.snapshotId)

        assertEquals(listOf(HandoverEvent.DeviceAppeared("11:11:11:11:11:11")), ack.bufferedEvents)
        assertEquals(1, ack.followUpSnapshot?.devices?.size)
        assertEquals(ConnectionStateMessage.DISCONNECTED, ack.followUpSnapshot!!.devices.single().state)
    }

    @Test
    fun eventsBeforeSnapshotContinueToActiveSinkAndAreNotReplayedAfterAck() {
        val coordinator = coordinator()
        coordinator.attachCandidate("headless")
        coordinator.ackStateResync("headless", coordinator.onDartReady("headless")!!.snapshotId)

        coordinator.attachCandidate("ui")
        val event = HandoverEvent.DeviceAppeared("AA:AA:AA:AA:AA:AA")

        assertTrue(coordinator.recordEvent(event).deliverImmediately)
        val snapshot = coordinator.onDartReady("ui")!!
        val ack = coordinator.ackStateResync("ui", snapshot.snapshotId)

        assertTrue(ack.bufferedEvents.isEmpty())
    }

    @Test
    fun connectionStateBeforeSnapshotContinuesToActiveSink() {
        val coordinator = coordinator()
        coordinator.attachCandidate("headless")
        coordinator.ackStateResync("headless", coordinator.onDartReady("headless")!!.snapshotId)

        coordinator.attachCandidate("ui")

        assertTrue(
            coordinator.recordConnectionState(
                deviceId = "AA:BB:CC:DD:EE:FF",
                connectionEpoch = 1,
                state = ConnectionStateMessage.CONNECTED,
                disconnectReason = null,
            ).deliverImmediately,
        )
    }

    @Test
    fun resetClearsActiveCandidateAndSnapshots() {
        val coordinator = coordinator()
        coordinator.recordConnectionState(
            deviceId = "AA:BB:CC:DD:EE:FF",
            connectionEpoch = 1,
            state = ConnectionStateMessage.CONNECTED,
            disconnectReason = null,
        )
        coordinator.attachCandidate("headless")
        coordinator.ackStateResync("headless", coordinator.onDartReady("headless")!!.snapshotId)
        coordinator.attachCandidate("ui")

        coordinator.reset()

        assertNull(coordinator.activeToken)
        assertNull(coordinator.candidateToken)
        assertTrue(coordinator.currentSnapshot().devices.isEmpty())
    }

    @Test
    fun handoverTimesOutAndKeepsOldActiveSink() {
        var now = 0L
        val coordinator = coordinator(clock = { now })
        coordinator.attachCandidate("headless")
        coordinator.ackStateResync("headless", coordinator.onDartReady("headless")!!.snapshotId)

        coordinator.attachCandidate("ui")
        coordinator.onDartReady("ui")
        now = SinkHandoverCoordinator.DEFAULT_TIMEOUT_MILLIS + 1

        assertTrue(coordinator.expireTimedOutHandover())
        assertEquals("headless", coordinator.activeToken)
        assertNull(coordinator.candidateToken)
    }

    @Test
    fun lateAckAfterTimeoutDoesNotReplaceOldActiveSink() {
        var now = 0L
        val coordinator = coordinator(clock = { now })
        coordinator.attachCandidate("headless")
        coordinator.ackStateResync("headless", coordinator.onDartReady("headless")!!.snapshotId)

        coordinator.attachCandidate("ui")
        val snapshot = coordinator.onDartReady("ui")!!
        now = SinkHandoverCoordinator.DEFAULT_TIMEOUT_MILLIS + 1

        val ack = coordinator.ackStateResync("ui", snapshot.snapshotId)

        assertEquals("headless", coordinator.activeToken)
        assertNull(ack.retiredToken)
        assertNull(coordinator.candidateToken)
    }

    private fun coordinator(
        capacity: Int = SinkHandoverCoordinator.DEFAULT_BUFFER_CAPACITY,
        clock: () -> Long = { 0L },
    ) = SinkHandoverCoordinator(
        bufferCapacity = capacity,
        clockMillis = clock,
        snapshotIdFactory = object : SnapshotIdFactory {
            private var next = 0
            override fun nextSnapshotId(): String = "snapshot-${++next}"
        },
    )
}
