package com.example.deepsky_bluetooth_android

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.IBinder
import com.example.deepsky_bluetooth_android.core.ForegroundServiceState

/** Keeps the process in a foreground-service lifecycle while BLE ownership stays in BleProcessOwner. */
class DeepskyForegroundService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notificationConfig = intent.toNotificationConfig()

        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                notificationConfig.channelId,
                notificationConfig.channelName,
                NotificationManager.IMPORTANCE_LOW,
            ),
        )

        try {
            startForeground(
                NOTIFICATION_ID,
                buildNotification(notificationConfig),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE,
            )
        } catch (error: RuntimeException) {
            // startForeground can fail (invalid notification/channel or FGS start not allowed);
            // keep the process-wide state honest instead of claiming the service is running.
            ForegroundServiceState.markStopRequested()
            stopSelf()
            throw error
        }

        ForegroundServiceState.markServiceRunning(notificationConfig)
        return START_STICKY
    }

    override fun onDestroy() {
        ForegroundServiceState.markServiceDestroyed()
        super.onDestroy()
    }

    private fun buildNotification(config: NotificationConfigMessage): Notification =
        Notification.Builder(this, config.channelId)
            .setContentTitle(config.title)
            .setContentText(config.text)
            .setSmallIcon(notificationIcon())
            .setOngoing(true)
            .build()

    private fun notificationIcon(): Int =
        if (applicationInfo.icon != 0) applicationInfo.icon else android.R.drawable.stat_notify_sync

    companion object {
        private const val NOTIFICATION_ID = 0x0B1E
        private const val EXTRA_CHANNEL_ID = "channelId"
        private const val EXTRA_CHANNEL_NAME = "channelName"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_TEXT = "text"

        val isStartRequested: Boolean
            get() = ForegroundServiceState.isStartRequested

        val isRunning: Boolean
            get() = ForegroundServiceState.isRunning

        fun start(context: Context, config: NotificationConfigMessage) {
            ForegroundServiceState.markStartRequested(config)
            try {
                context.startForegroundService(
                    Intent(context, DeepskyForegroundService::class.java)
                        .putExtra(EXTRA_CHANNEL_ID, config.channelId)
                        .putExtra(EXTRA_CHANNEL_NAME, config.channelName)
                        .putExtra(EXTRA_TITLE, config.title)
                        .putExtra(EXTRA_TEXT, config.text),
                )
            } catch (error: RuntimeException) {
                ForegroundServiceState.markStopRequested()
                throw error
            }
        }

        fun stop(context: Context) {
            ForegroundServiceState.markStopRequested()
            context.stopService(Intent(context, DeepskyForegroundService::class.java))
        }

        private fun Intent?.toNotificationConfig(): NotificationConfigMessage =
            NotificationConfigMessage(
                channelId = this?.getStringExtra(EXTRA_CHANNEL_ID) ?: "deepsky_bluetooth",
                channelName = this?.getStringExtra(EXTRA_CHANNEL_NAME) ?: "Bluetooth",
                title = this?.getStringExtra(EXTRA_TITLE) ?: "Bluetooth active",
                text = this?.getStringExtra(EXTRA_TEXT) ?: "Maintaining BLE connection",
            )
    }
}
