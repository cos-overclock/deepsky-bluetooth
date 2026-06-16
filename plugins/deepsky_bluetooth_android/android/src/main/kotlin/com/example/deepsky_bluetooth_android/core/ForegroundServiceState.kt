package com.example.deepsky_bluetooth_android.core

import com.example.deepsky_bluetooth_android.NotificationConfigMessage

/** Process-wide foreground service request/running state. */
internal object ForegroundServiceState {
    @Volatile
    private var snapshot = Snapshot()

    val isStartRequested: Boolean
        get() = snapshot.isStartRequested

    val isRunning: Boolean
        get() = snapshot.isRunning

    val currentNotification: NotificationConfigMessage?
        get() = snapshot.notification

    @Synchronized
    fun markStartRequested(notification: NotificationConfigMessage) {
        snapshot = Snapshot(
            isStartRequested = true,
            isRunning = false,
            notification = notification,
        )
    }

    @Synchronized
    fun markServiceRunning(notification: NotificationConfigMessage) {
        snapshot = Snapshot(
            isStartRequested = true,
            isRunning = true,
            notification = notification,
        )
    }

    @Synchronized
    fun markServiceDestroyed() {
        snapshot = snapshot.copy(isRunning = false)
    }

    @Synchronized
    fun markStopRequested() {
        snapshot = Snapshot()
    }

    @Synchronized
    fun resetForTest() {
        snapshot = Snapshot()
    }

    private data class Snapshot(
        val isStartRequested: Boolean = false,
        val isRunning: Boolean = false,
        val notification: NotificationConfigMessage? = null,
    )
}
