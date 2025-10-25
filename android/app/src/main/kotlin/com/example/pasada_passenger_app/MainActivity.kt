package com.example.pasada_passenger_app

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.IBinder
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "background_ride_service"
    private var backgroundService: BackgroundRideService? = null
    private var serviceBound = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBackgroundService" -> {
                    startBackgroundService()
                    result.success(null)
                }
                "stopBackgroundService" -> {
                    stopBackgroundService()
                    result.success(null)
                }
                "updateServiceNotification" -> {
                    val title = call.argument<String>("title") ?: "Pasada - Ride in Progress"
                    val content = call.argument<String>("content") ?: "Your ride is being tracked"
                    val eta = call.argument<String>("eta")
                    val destination = call.argument<String>("destination")
                    val progress = call.argument<Int>("progress") ?: 0
                    updateServiceNotification(title, content, eta, destination, progress)
                    result.success(null)
                }
                "showArrivingNotification" -> {
                    val etaMinutes = call.argument<Int>("etaMinutes") ?: 5
                    val destination = call.argument<String>("destination") ?: "Destination"
                    val driverName = call.argument<String>("driverName")
                    showArrivingNotification(etaMinutes, destination, driverName)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as BackgroundRideService.LocalBinder
            backgroundService = binder.getService()
            serviceBound = true
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            backgroundService = null
            serviceBound = false
        }
    }

    private fun startBackgroundService() {
        val intent = Intent(this, BackgroundRideService::class.java)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        
        // Bind to the service to get the service instance
        bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    private fun stopBackgroundService() {
        if (serviceBound) {
            unbindService(serviceConnection)
            serviceBound = false
        }
        val intent = Intent(this, BackgroundRideService::class.java)
        stopService(intent)
    }

    private fun updateServiceNotification(title: String, content: String, eta: String?, destination: String?, progress: Int) {
        backgroundService?.updateNotification(title, content, eta, destination, progress)
    }

    private fun showArrivingNotification(etaMinutes: Int, destination: String, driverName: String?) {
        // Start the background service if not already running
        startBackgroundService()
        
        // Get the service instance and show the arriving notification
        backgroundService?.showArrivingNotification(etaMinutes, destination, driverName)
    }
}