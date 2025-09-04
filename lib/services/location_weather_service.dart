import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'package:pasada_passenger_app/providers/weather_provider.dart';
import 'package:pasada_passenger_app/services/location_permission_manager.dart';

/// Service that automatically fetches weather based on device location
class LocationWeatherService {
  static final Location _location = Location();
  static StreamSubscription<LocationData>? _locationSubscription;
  static DateTime? _lastLocationUpdate;
  static const Duration _locationUpdateThreshold = Duration(minutes: 1);
  static const Duration _locationTimeout = Duration(seconds: 15);

  /// Initializes location permissions, fetches current weather, and subscribes to updates
  static Future<bool> fetchAndSubscribe(WeatherProvider provider) async {
    try {
      // Use centralized location permission manager to prevent multiple prompts
      final locationManager = LocationPermissionManager.instance;
      final locationReady = await locationManager.ensureLocationReady();
      if (!locationReady) {
        debugPrint('Location not ready, cannot fetch weather');
        return false;
      }

      // Get initial location with optimized timeout (since location should already be ready)
      final locData = await _location.getLocation().timeout(
        const Duration(seconds: 5), // Reduced timeout since location should be ready
      );
      
      if (locData.latitude != null && locData.longitude != null) {
        // Fetch weather immediately for better user experience
        await provider.fetchWeather(locData.latitude!, locData.longitude!);
        _lastLocationUpdate = DateTime.now();
        debugPrint('Weather fetched for location: ${locData.latitude}, ${locData.longitude}');
      } else {
        debugPrint('Location data is null despite location being ready');
        return false;
      }

      // Cancel existing subscription if any
      await _locationSubscription?.cancel();

      // Subscribe to location changes with smart throttling
      _locationSubscription = _location.onLocationChanged.listen(
        (data) => _handleLocationUpdate(data, provider),
        onError: (error) {
          debugPrint('Location subscription error: $error');
          // Don't stop the subscription for intermittent errors
        },
      );

      return true;
    } catch (e) {
      debugPrint('Error initializing location weather service: $e');
      return false;
    }
  }

  /// Handle location updates with smart throttling
  static void _handleLocationUpdate(LocationData data, WeatherProvider provider) {
    if (data.latitude == null || data.longitude == null) return;

    final now = DateTime.now();
    
    // Throttle location updates to avoid excessive API calls
    if (_lastLocationUpdate != null &&
        now.difference(_lastLocationUpdate!) < _locationUpdateThreshold) {
      return;
    }

    _lastLocationUpdate = now;
    
    // Use background weather fetch to avoid blocking UI
    provider.fetchWeather(data.latitude!, data.longitude!).catchError((error) {
      debugPrint('Background weather fetch error: $error');
      // Don't propagate error to UI for background updates
    });
  }

  /// Force refresh weather with current location
  static Future<bool> refreshWeatherNow(WeatherProvider provider) async {
    try {
      final locationManager = LocationPermissionManager.instance;
      final locationReady = await locationManager.ensureLocationReady();
      if (!locationReady) return false;

      final locData = await _location.getLocation().timeout(_locationTimeout);
      if (locData.latitude != null && locData.longitude != null) {
        await provider.fetchWeather(
          locData.latitude!, 
          locData.longitude!, 
          forceRefresh: true
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error refreshing weather: $e');
      return false;
    }
  }

  /// Clean up resources
  static Future<void> dispose() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _lastLocationUpdate = null;
  }
}
