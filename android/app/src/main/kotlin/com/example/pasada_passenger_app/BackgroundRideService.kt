package com.example.pasada_passenger_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel

class BackgroundRideService : Service(), LocationListener {
    companion object {
        private const val TAG = "BackgroundRideService"
        private const val CHANNEL_ID = "ride_tracking_service"
        private const val CHANNEL_NAME = "Ride Tracking Service"
        private const val NOTIFICATION_ID = 9999
    }
    
    private val binder = LocalBinder()
    private var locationManager: LocationManager? = null
    private var methodChannel: MethodChannel? = null
    private var isTracking = false
    
    inner class LocalBinder : Binder() {
        fun getService(): BackgroundRideService = this@BackgroundRideService
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "BackgroundRideService created")
        
        // Initialize location manager
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        
        // Create notification channel
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "BackgroundRideService started")
        
        // Start foreground service with notification
        startForegroundService()
        
        // Start location tracking
        startLocationTracking()
        
        return START_STICKY // Restart service if killed
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "BackgroundRideService destroyed")
        
        // Stop location tracking
        stopLocationTracking()
    }

    override fun onBind(intent: Intent?): IBinder = binder

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps the app running in background during active rides"
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun startForegroundService() {
        // Create intent for notification tap
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Create beautiful notification with rich formatting
        val notification = createBeautifulRideNotification(
            eta = "05:17 AM",
            destination = "Dra Evelyn B Reyes Clinic",
            progress = 60,
            pendingIntent = pendingIntent
        )

        // Start foreground service
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun startLocationTracking() {
        if (isTracking) return
        
        try {
            // Request location updates
            locationManager?.let { manager ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    if (checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) == 
                        android.content.pm.PackageManager.PERMISSION_GRANTED) {
                        
                        manager.requestLocationUpdates(
                            LocationManager.GPS_PROVIDER,
                            10000L, // 10 seconds
                            10f, // 10 meters
                            this,
                            Looper.getMainLooper()
                        )
                        
                        manager.requestLocationUpdates(
                            LocationManager.NETWORK_PROVIDER,
                            10000L, // 10 seconds
                            10f, // 10 meters
                            this,
                            Looper.getMainLooper()
                        )
                        
                        isTracking = true
                        Log.d(TAG, "Location tracking started")
                    }
                } else {
                    manager.requestLocationUpdates(
                        LocationManager.GPS_PROVIDER,
                        10000L, // 10 seconds
                        10f, // 10 meters
                        this,
                        Looper.getMainLooper()
                    )
                    
                    manager.requestLocationUpdates(
                        LocationManager.NETWORK_PROVIDER,
                        10000L, // 10 seconds
                        10f, // 10 meters
                        this,
                        Looper.getMainLooper()
                    )
                    
                    isTracking = true
                    Log.d(TAG, "Location tracking started")
                }
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Location permission not granted", e)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting location tracking", e)
        }
    }

    private fun stopLocationTracking() {
        if (!isTracking) return
        
        try {
            locationManager?.removeUpdates(this)
            isTracking = false
            Log.d(TAG, "Location tracking stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping location tracking", e)
        }
    }

    override fun onLocationChanged(location: Location) {
        Log.d(TAG, "Location updated: ${location.latitude}, ${location.longitude}")
        
        // Send location update to Flutter
        methodChannel?.invokeMethod("onLocationUpdate", doubleArrayOf(
            location.latitude,
            location.longitude,
            location.accuracy.toDouble()
        ))
    }

    override fun onProviderEnabled(provider: String) {
        Log.d(TAG, "Location provider enabled: $provider")
    }

    override fun onProviderDisabled(provider: String) {
        Log.d(TAG, "Location provider disabled: $provider")
    }

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
    }

    fun updateNotification(title: String, content: String, eta: String? = null, destination: String? = null, progress: Int = 0) {
        // Create intent for notification tap
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Create beautiful notification with updated data
        val notification = createBeautifulRideNotification(
            eta = eta ?: "05:17 AM",
            destination = destination ?: "Destination",
            progress = progress,
            pendingIntent = pendingIntent
        )

        // Update notification
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun createBeautifulRideNotification(eta: String, destination: String, progress: Int, pendingIntent: PendingIntent): Notification {
        // Create progress status with emojis
        val progressStatus = when {
            progress < 25 -> "🚗 Driver found"
            progress < 60 -> "🛣️ On the way"
            progress < 100 -> "📍 Almost there"
            else -> "✅ Arrived"
        }
        
        // Create visual progress bar
        val progressBar = "█".repeat(progress / 5) + "░".repeat(20 - progress / 5)
        
        // Create beautiful notification content
        val bigText = """
            🚌 PASADA - Ride in Progress
            
            ⏰ You will arrive at $eta
            📍 $destination
            
            $progressStatus
            Progress: $progressBar $progress%
            
            🎯 Your ride is being tracked in the background
        """.trimIndent()
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🚌 PASADA")
            .setContentText("Ride in progress - $progress% complete")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText(bigText)
                .setSummaryText("Ride tracking active"))
            .build()
    }

}
