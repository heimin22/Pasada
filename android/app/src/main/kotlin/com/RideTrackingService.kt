package com.example.pasada_passenger_app

import android.app.Service
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.content.Context
import android.os.IBinder
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat

class RideTrackingService : Service() {
    companion object {
        const val CHANNEL_ID = "ride_tracking_channel"
        const val NOTIFICATION_ID = 1

        @volatile
        private var instance: RideTrackingService? = null

        fun getInstance(): RideTrackingService? = instance
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification("00:00", "Starting...", 0))
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Ongoing na po!",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Please wait! Ongoing na po ang ride niyo."
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(
        eta: String,
        destination: String,
        progress: Int
    ): Notification {
        val contentView = RemoteViews(packageName, R.layout.notification_ride)

        contentView.setTextViewText(R.id.eta, "Arriving at $eta")
        contentView.setTextViewText(R.id.destination, destination)
        
        contentView.setProgressBar(R.id.progressBar, 100, progress, false)

        val density = resources.displayMetrics.density
        val barWidthDp = 300
        val barWidthPx = (barWidthDp * density).toInt()
        val offset = (barWidthPx * (progress / 100.0f)).toInt()

        contentView.setFloat(R.id.carIcon, "setTranslationX", offset.toFloat())

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setCustomContentView(contentView)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()
    }

    fun updateRide(eta: String, destination: String, progress: Int) {
        val notification = buildNotification(eta, destination, progress)
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, notification)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let {
            val eta = it.getStringExtra("eta")
            val destination = it.getStringExtra("destination")
            val progress = it.getIntExtra("progress", 0)
            if (eta != null && destination != null) {
                updateRide(eta, destination, progress)
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }
}