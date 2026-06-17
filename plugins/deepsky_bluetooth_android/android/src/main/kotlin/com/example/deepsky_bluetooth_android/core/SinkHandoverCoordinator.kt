package com.example.deepsky_bluetooth_android.core

import com.example.deepsky_bluetooth_android.AdapterStateMessage
import com.example.deepsky_bluetooth_android.ConnectionStateMessage
import com.example.deepsky_bluetooth_android.DisconnectReasonMessage
import com.example.deepsky_bluetooth_android.ScanResultMessage
import com.example.deepsky_bluetooth_android.ServiceMessage
import com.example.deepsky_bluetooth_android.StateResyncMessage
import com.example.deepsky_bluetooth_android.StateSnapshotMessage
import java.util.ArrayDeque
import java.util.UUID

internal interface SnapshotIdFactory {
    fun nextSnapshotId(): String
}

internal object UuidSnapshotIdFactory : SnapshotIdFactory {
    override fun nextSnapshotId(): String = UUID.randomUUID().toString()
}

internal sealed class HandoverEvent {
    data class ScanResult(val result: ScanResultMessage) : HandoverEvent()
    data class ScanFailed(val code: String, val message: String) : HandoverEvent()
    data class AdapterStateChanged(val state: AdapterStateMessage) : HandoverEvent()
    data class CharacteristicValue(
        val deviceId: String,
        val connectionEpoch: Long,
        val characteristicHandle: Long,
        val value: ByteArray,
    ) : HandoverEvent()
    data class OperationTimeout(val deviceId: String, val connectionEpoch: Long) : HandoverEvent()
    data class DeviceAppeared(val deviceId: String) : HandoverEvent()
    data class DeviceDisappeared(val deviceId: String) : HandoverEvent()
}

internal data class HandoverDelivery(val deliverImmediately: Boolean)

internal data class HandoverAck(
    val retiredToken: String?,
    val bufferedEvents: List<HandoverEvent>,
    val followUpSnapshot: StateResyncMessage?,
)

/**
 * Coordinates candidate/active Flutter callback sinks during engine handover.
 *
 * The old active sink remains active until Dart on the candidate engine receives a state snapshot
 * and acknowledges it. Non-state events that arrive after the snapshot are buffered and flushed in
 * FIFO order after ack. Connection state is maintained as the latest per-device snapshot so it is
 * never discarded by the bounded event buffer.
 */
internal class SinkHandoverCoordinator(
    private val bufferCapacity: Int = DEFAULT_BUFFER_CAPACITY,
    private val timeoutMillis: Long = DEFAULT_TIMEOUT_MILLIS,
    private val clockMillis: () -> Long = System::currentTimeMillis,
    private val snapshotIdFactory: SnapshotIdFactory = UuidSnapshotIdFactory,
) {
    init {
        require(bufferCapacity > 0) { "bufferCapacity must be positive, was $bufferCapacity" }
        require(timeoutMillis > 0) { "timeoutMillis must be positive, was $timeoutMillis" }
    }

    private val latestDevices = linkedMapOf<String, DeviceSnapshot>()
    private val bufferedEvents = ArrayDeque<HandoverEvent>()

    private var handoverStartedAt: Long? = null
    private var pendingSnapshotId: String? = null
    private var followUpSnapshotDirty = false

    var activeToken: String? = null
        private set

    var candidateToken: String? = null
        private set

    @Synchronized
    fun attachCandidate(engineToken: String) {
        if (engineToken == activeToken && candidateToken == null) return
        candidateToken = engineToken
        handoverStartedAt = clockMillis()
        pendingSnapshotId = null
        followUpSnapshotDirty = false
        bufferedEvents.clear()
    }

    @Synchronized
    fun detach(engineToken: String) {
        if (candidateToken == engineToken) clearCandidate()
        if (activeToken == engineToken) activeToken = null
    }

    @Synchronized
    fun onDartReady(engineToken: String): StateResyncMessage? {
        expireTimedOutHandover()
        if (!isCurrentCandidate(engineToken)) return null
        val snapshotId = snapshotIdFactory.nextSnapshotId()
        pendingSnapshotId = snapshotId
        followUpSnapshotDirty = false
        return buildSnapshot(snapshotId)
    }

    @Synchronized
    fun ackStateResync(engineToken: String, snapshotId: String): HandoverAck {
        expireTimedOutHandover()
        if (!isCurrentCandidate(engineToken) || pendingSnapshotId != snapshotId) {
            return HandoverAck(retiredToken = null, bufferedEvents = emptyList(), followUpSnapshot = null)
        }
        val oldActive = activeToken
        activeToken = engineToken
        clearCandidate()
        val events = bufferedEvents.toList()
        bufferedEvents.clear()
        val followUp = if (followUpSnapshotDirty) {
            buildSnapshot(snapshotIdFactory.nextSnapshotId())
        } else {
            null
        }
        followUpSnapshotDirty = false
        return HandoverAck(retiredToken = oldActive, bufferedEvents = events, followUpSnapshot = followUp)
    }

    @Synchronized
    fun expireTimedOutHandover(): Boolean {
        val started = handoverStartedAt ?: return false
        if (clockMillis() - started <= timeoutMillis) return false
        clearCandidate()
        bufferedEvents.clear()
        return true
    }

    @Synchronized
    fun recordConnectionState(
        deviceId: String,
        connectionEpoch: Long,
        state: ConnectionStateMessage,
        disconnectReason: DisconnectReasonMessage?,
    ): HandoverDelivery {
        expireTimedOutHandover()
        latestDevices[deviceId] = latestDevices[deviceId]
            ?.copy(
                connectionEpoch = connectionEpoch,
                state = state,
                disconnectReason = disconnectReason,
                activeNotifyHandles = if (state == ConnectionStateMessage.DISCONNECTED) {
                    emptySet()
                } else {
                    latestDevices[deviceId]?.activeNotifyHandles ?: emptySet()
                },
                services = if (state == ConnectionStateMessage.DISCONNECTED) {
                    null
                } else {
                    latestDevices[deviceId]?.services
                },
            )
            ?: DeviceSnapshot(
                deviceId = deviceId,
                connectionEpoch = connectionEpoch,
                state = state,
                disconnectReason = disconnectReason,
            )
        if (isAwaitingAck()) {
            followUpSnapshotDirty = true
            if (bufferedEvents.size >= bufferCapacity) bufferedEvents.pollFirst()
        }
        return HandoverDelivery(deliverImmediately = shouldDeliverImmediately())
    }

    @Synchronized
    fun recordServices(deviceId: String, connectionEpoch: Long, services: List<ServiceMessage>) {
        expireTimedOutHandover()
        val current = latestDevices[deviceId] ?: return
        if (current.connectionEpoch != connectionEpoch) return
        latestDevices[deviceId] = current.copy(services = services)
        if (isAwaitingAck()) followUpSnapshotDirty = true
    }

    @Synchronized
    fun recordNotifyState(
        deviceId: String,
        connectionEpoch: Long,
        characteristicHandle: Long,
        enabled: Boolean,
    ) {
        expireTimedOutHandover()
        val current = latestDevices[deviceId] ?: return
        if (current.connectionEpoch != connectionEpoch) return
        val handles = current.activeNotifyHandles.toMutableSet()
        if (enabled) handles.add(characteristicHandle) else handles.remove(characteristicHandle)
        latestDevices[deviceId] = current.copy(activeNotifyHandles = handles)
        if (isAwaitingAck()) followUpSnapshotDirty = true
    }

    @Synchronized
    fun recordEvent(event: HandoverEvent): HandoverDelivery {
        expireTimedOutHandover()
        if (isInHandover()) {
            appendBuffered(event)
            return HandoverDelivery(deliverImmediately = false)
        }
        return HandoverDelivery(deliverImmediately = activeToken != null)
    }

    @Synchronized
    fun currentSnapshot(): StateResyncMessage = buildSnapshot(snapshotIdFactory.nextSnapshotId())

    private fun appendBuffered(event: HandoverEvent) {
        if (bufferedEvents.size >= bufferCapacity) bufferedEvents.pollFirst()
        bufferedEvents.addLast(event)
    }

    private fun shouldDeliverImmediately(): Boolean = activeToken != null && !isInHandover()

    private fun isInHandover(): Boolean = candidateToken != null

    private fun isAwaitingAck(): Boolean = candidateToken != null && pendingSnapshotId != null

    private fun isCurrentCandidate(engineToken: String): Boolean = candidateToken == engineToken

    private fun clearCandidate() {
        candidateToken = null
        pendingSnapshotId = null
        handoverStartedAt = null
    }

    private fun buildSnapshot(snapshotId: String): StateResyncMessage =
        StateResyncMessage(
            snapshotId = snapshotId,
            devices = latestDevices.values.map { it.toMessage(restored = true) },
        )

    private data class DeviceSnapshot(
        val deviceId: String,
        val connectionEpoch: Long,
        val state: ConnectionStateMessage,
        val disconnectReason: DisconnectReasonMessage?,
        val activeNotifyHandles: Set<Long> = emptySet(),
        val services: List<ServiceMessage>? = null,
    ) {
        fun toMessage(restored: Boolean): StateSnapshotMessage =
            StateSnapshotMessage(
                deviceId = deviceId,
                connectionEpoch = connectionEpoch,
                state = state,
                disconnectReason = disconnectReason,
                activeNotifyHandles = activeNotifyHandles.toList(),
                services = services,
                restored = restored,
            )
    }

    companion object {
        const val DEFAULT_BUFFER_CAPACITY = 256
        const val DEFAULT_TIMEOUT_MILLIS = 30_000L
    }
}
