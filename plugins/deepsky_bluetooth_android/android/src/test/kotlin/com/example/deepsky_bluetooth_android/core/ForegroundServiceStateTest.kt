package com.example.deepsky_bluetooth_android.core

import com.example.deepsky_bluetooth_android.NotificationConfigMessage
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

internal class ForegroundServiceStateTest {
    @AfterTest
    fun tearDown() {
        ForegroundServiceState.resetForTest()
    }

    @Test
    fun markStartRequestedStoresNotificationAndDoesNotPretendServiceIsRunning() {
        val config = notification()

        ForegroundServiceState.markStartRequested(config)

        assertTrue(ForegroundServiceState.isStartRequested)
        assertFalse(ForegroundServiceState.isRunning)
        assertEquals(config, ForegroundServiceState.currentNotification)
    }

    @Test
    fun markServiceRunningMarksRunningOnlyAfterServiceStarts() {
        val config = notification(title = "Active")

        ForegroundServiceState.markStartRequested(config)
        ForegroundServiceState.markServiceRunning(config)

        assertTrue(ForegroundServiceState.isStartRequested)
        assertTrue(ForegroundServiceState.isRunning)
        assertEquals(config, ForegroundServiceState.currentNotification)
    }

    @Test
    fun markServiceDestroyedKeepsStartRequestSoItDiffersFromExplicitStop() {
        val config = notification()

        ForegroundServiceState.markStartRequested(config)
        ForegroundServiceState.markServiceRunning(config)
        ForegroundServiceState.markServiceDestroyed()

        assertTrue(ForegroundServiceState.isStartRequested)
        assertFalse(ForegroundServiceState.isRunning)
        assertEquals(config, ForegroundServiceState.currentNotification)
    }

    @Test
    fun markStopRequestedClearsRequestRunningAndNotification() {
        val config = notification()

        ForegroundServiceState.markStartRequested(config)
        ForegroundServiceState.markServiceRunning(config)
        ForegroundServiceState.markStopRequested()

        assertFalse(ForegroundServiceState.isStartRequested)
        assertFalse(ForegroundServiceState.isRunning)
        assertNull(ForegroundServiceState.currentNotification)
    }

    private fun notification(
        channelId: String = "ble",
        channelName: String = "BLE",
        title: String = "Connected",
        text: String = "Maintaining BLE link",
    ) = NotificationConfigMessage(channelId, channelName, title, text)
}
