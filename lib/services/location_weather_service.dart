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
      // Optimize settings and background mode to warm up GPS
      try {
        // Temporarily boost to high for the first fix
        await _location.changeSettings(
          accuracy: LocationAccuracy.high,
          interval: 3000,
        );
        await _location.enableBackgroundMode(enable: true);
      } catch (_) {}
      // Use centralized location permission manager to prevent multiple prompts
      final locationManager = LocationPermissionManager.instance;
      final locationReady = await locationManager.ensureLocationReady();
      if (!locationReady) {
        debugPrint('Location not ready, cannot fetch weather');
        return false;
      }

      // Get initial location with fast path and fallbacks
      LocationData? locData;
      try {
        locData = await _location.getLocation().timeout(
              const Duration(seconds: 5),
            );
      } catch (_) {
        // Fallback: take first update from stream (often faster to get a fresh fix)
        try {
          locData = await _location.onLocationChanged.first
              .timeout(const Duration(seconds: 8));
        } catch (_) {}
      }

      if (locData?.latitude != null && locData?.longitude != null) {
        await provider.fetchWeather(locData!.latitude!, locData.longitude!);
        _lastLocationUpdate = DateTime.now();
        debugPrint(
            'Weather fetched for location: ${locData.latitude}, ${locData.longitude}');
      } else {
        debugPrint('Initial location unavailable; proceeding to subscribe');
      }

      // Cancel existing subscription if any
      await _locationSubscription?.cancel();

      // Subscribe to location changes with smart throttling
      // Revert to balanced for ongoing updates
      try {
        await _location.changeSettings(
          accuracy: LocationAccuracy.balanced,
          interval: 5000,
        );
      } catch (_) {}

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
  static void _handleLocationUpdate(
      LocationData data, WeatherProvider provider) {
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
        await provider.fetchWeather(locData.latitude!, locData.longitude!,
            forceRefresh: true);
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
