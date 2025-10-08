import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/slow_internet_warning_service.dart';

/// Utility class to test and debug slow internet warning functionality
class TestSlowInternetWarning {
  static final SlowInternetWarningService _service =
      SlowInternetWarningService();

  /// Test the slow internet warning service
  static Future<void> testService() async {
    debugPrint('=== Testing Slow Internet Warning Service ===');

    // Initialize the service
    await _service.initialize();
    debugPrint('Service initialized');

    // Check current status
    debugPrint('Is online: ${_service.isOnline}');
    debugPrint('Is slow connection: ${_service.isSlowConnection}');
    debugPrint('Connection quality: ${_service.connectionQuality}');
    debugPrint(
        'Quality description: ${_service.getConnectionQualityDescription()}');
    debugPrint('Recommended action: ${_service.getRecommendedAction()}');

    // Listen to connection changes
    _service.isOnlineStream.listen((isOnline) {
      debugPrint(
          'Connection status changed: ${isOnline ? "Online" : "Offline"}');
    });

    _service.isSlowConnectionStream.listen((isSlow) {
      debugPrint(
          'Slow connection status changed: ${isSlow ? "Slow" : "Normal"}');
    });

    _service.connectionQualityStream.listen((quality) {
      debugPrint('Connection quality changed: $quality');
    });

    debugPrint('=== Test Complete ===');
  }

  /// Manually trigger a connection test
  static Future<void> triggerConnectionTest() async {
    debugPrint('=== Triggering Manual Connection Test ===');
    await _service.testConnection();
    debugPrint('Test complete');
  }

  /// Get current connection info
  static void logCurrentConnectionInfo() {
    debugPrint('=== Current Connection Info ===');
    debugPrint('Is online: ${_service.isOnline}');
    debugPrint('Is slow: ${_service.isSlowConnection}');
    debugPrint('Quality: ${_service.connectionQuality}');
    debugPrint('Description: ${_service.getConnectionQualityDescription()}');
    debugPrint('Recommendation: ${_service.getRecommendedAction()}');
  }
}
