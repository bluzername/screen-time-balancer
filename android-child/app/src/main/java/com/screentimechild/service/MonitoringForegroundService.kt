package com.screentimechild.service

import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.screentimechild.MainActivity
import com.screentimechild.R
import com.screentimechild.ScreenTimeChildApp
import com.screentimechild.enforcement.EnforcementEngine
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.*
import javax.inject.Inject

@AndroidEntryPoint
class MonitoringForegroundService : Service() {

    @Inject
    lateinit var enforcementEngine: EnforcementEngine

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var refreshJob: Job? = null

    override fun onCreate() {
        super.onCreate()
        startForeground(NOTIFICATION_ID, createNotification())
        startPeriodicRefresh()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        refreshJob?.cancel()
        serviceScope.cancel()
    }

    private fun createNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, ScreenTimeChildApp.MONITORING_CHANNEL_ID)
            .setContentTitle("Screen Time Active")
            .setContentText("Monitoring app usage")
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun startPeriodicRefresh() {
        refreshJob = serviceScope.launch {
            while (isActive) {
                try {
                    enforcementEngine.refreshRules()
                    enforcementEngine.refreshState()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                delay(REFRESH_INTERVAL_MS)
            }
        }
    }

    companion object {
        private const val NOTIFICATION_ID = 1
        private const val REFRESH_INTERVAL_MS = 60_000L // 1 minute

        fun start(context: android.content.Context) {
            val intent = Intent(context, MonitoringForegroundService::class.java)
            context.startForegroundService(intent)
        }

        fun stop(context: android.content.Context) {
            val intent = Intent(context, MonitoringForegroundService::class.java)
            context.stopService(intent)
        }
    }
}
