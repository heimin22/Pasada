import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pasada_passenger_app/services/location_permission_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Callback to receive updated device locations
typedef LocationCallback = void Function(LatLng);

class MapLocationService {
  final Location _location = Location();
  StreamSubscription<LocationData>? _subscription;

  /// Initializes location permissions, loads cached location, fetches initial location,
  /// and streams subsequent updates to [onLocation].
  Future<void> initialize(LocationCallback onLocation) async {
    // Optimize settings for quicker initial locks and efficient updates
    try {
      // Start with high accuracy briefly for the first fix
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 3000,
      );
      await _location.enableBackgroundMode(enable: true);
    } catch (_) {}
    // Load cached location
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('last_latitude');
    final lng = prefs.getDouble('last_longitude');
    if (lat != null && lng != null) {
      onLocation(LatLng(lat, lng));
    }

    // Use centralized location permission manager to prevent multiple prompts
    final locationManager = LocationPermissionManager.instance;
    final locationReady = await locationManager.ensureLocationReady();
    if (!locationReady) return;

    // Fetch fresh location
    try {
      final locData = await _location.getLocation().timeout(
            const Duration(seconds: 5),
          );
      if (locData.latitude != null && locData.longitude != null) {
        final pos = LatLng(locData.latitude!, locData.longitude!);
        onLocation(pos);
        // Cache for next app start
        await prefs.setDouble('last_latitude', pos.latitude);
        await prefs.setDouble('last_longitude', pos.longitude);
      }
    } catch (_) {
      // Fallback to first stream event with slightly longer timeout
      try {
        final data = await _location.onLocationChanged.first
            .timeout(const Duration(seconds: 8));
        if (data.latitude != null && data.longitude != null) {
          final pos = LatLng(data.latitude!, data.longitude!);
          onLocation(pos);
          await prefs.setDouble('last_latitude', pos.latitude);
          await prefs.setDouble('last_longitude', pos.longitude);
        }
      } catch (_) {}
    }

    // Stream updates
    _subscription?.cancel();
    // Revert to balanced for the ongoing stream
    try {
      await _location.changeSettings(
        accuracy: LocationAccuracy.balanced,
        interval: 5000,
      );
    } catch (_) {}

    _subscription = _location.onLocationChanged.listen((data) async {
      if (data.latitude != null && data.longitude != null) {
        final pos = LatLng(data.latitude!, data.longitude!);
        onLocation(pos);
        // Update cache
        await prefs.setDouble('last_latitude', pos.latitude);
        await prefs.setDouble('last_longitude', pos.longitude);
      }
    });
  }

  /// Stops streaming location updates.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
