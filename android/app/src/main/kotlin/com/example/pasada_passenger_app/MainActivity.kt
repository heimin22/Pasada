package com.example.pasada_passenger_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Build
import android.os.Build.VERSION_CODES
import com.example.pasada_passenger_app.RideTrackingService

class MainActivity: FlutterActivity() {
    private val CHANNEL = "ride_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startRide" -> {
                    val intent = Intent(this, RideTrackingService::class.java)
                    if (Build.VERSION.SDK_INT >= VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "updateRide" -> {
                    val eta = call.argument<String>("eta")
                    val destination = call.argument<String>("destination")
                    val progress = call.argument<Int>("progress") ?: 0
                    val intent = Intent(this, RideTrackingService::class.java).apply {
                        putExtra("eta", eta)
                        putExtra("destination", destination)
                        putExtra("progress", progress)
                    }
                    if (Build.VERSION.SDK_INT >= VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
