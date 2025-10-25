package com.example.pasada_passenger_app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "background_ride_service"
    private var backgroundService: BackgroundRideService? = null

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
                    updateServiceNotification(title, content)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startBackgroundService() {
        val intent = Intent(this, BackgroundRideService::class.java)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopBackgroundService() {
        val intent = Intent(this, BackgroundRideService::class.java)
        stopService(intent)
    }

    private fun updateServiceNotification(title: String, content: String) {
        // This will be handled by the service itself
    }
}