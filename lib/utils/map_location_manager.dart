import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pasada_passenger_app/services/location_permission_manager.dart';

class MapLocationManager {
  final Location location = Location();
  StreamSubscription<LocationData>? locationSubscription;

  bool isLocationInitialized = false;
  bool isScreenActive = true;

  // Callbacks
  Function(LatLng)? onLocationUpdated;
  Function(String)? onError;
  Function()? onLocationPermissionDenied;
  Function()? onLocationServiceDisabled;

  MapLocationManager({
    this.onLocationUpdated,
    this.onError,
    this.onLocationPermissionDenied,
    this.onLocationServiceDisabled,
  });

  /// Initialize location services and start tracking
  Future<void> initializeLocation() async {
    if (isLocationInitialized) return;

    // Use centralized location permission manager to prevent multiple prompts
    final locationManager = LocationPermissionManager.instance;
    final locationReady = await locationManager.ensureLocationReady();

    if (!locationReady) {
      // Check specifically what failed to call appropriate callbacks
      if (!locationManager.isServiceEnabled) {
        onLocationServiceDisabled?.call();
      } else if (!locationManager.isPermissionGranted) {
        onLocationPermissionDenied?.call();
      }
      return;
    }

    // Fetch updates
    await getLocationUpdates();
    isLocationInitialized = true;
  }

  // Note: checkLocationService and verifyLocationPermissions methods removed
  // as they are now handled by the centralized LocationPermissionManager

  /// Get initial location and start listening for updates
  Future<void> getLocationUpdates() async {
    try {
      // Get current location
      LocationData locationData = await location.getLocation();

      // Cache this location for next app start
      await _cacheLocation(locationData);

      final currentLocation =
          LatLng(locationData.latitude!, locationData.longitude!);
      onLocationUpdated?.call(currentLocation);

      // Start listening for location changes
      startLocationTracking();
    } catch (e) {
      onError?.call('Location Error: ${e.toString()}');
    }
  }

  /// Start continuous location tracking
  void startLocationTracking() {
    // Cancel previous subscription to avoid duplicates
    locationSubscription?.cancel();

    locationSubscription = location.onLocationChanged
        .where((data) => data.latitude != null && data.longitude != null)
        .listen((newLocation) {
      if (isScreenActive) {
        final currentLocation =
            LatLng(newLocation.latitude!, newLocation.longitude!);
        onLocationUpdated?.call(currentLocation);
      }
    });
  }

  /// Stop location tracking
  void stopLocationTracking() {
    locationSubscription?.cancel();
    locationSubscription = null;
  }

  /// Pause location tracking
  void pauseLocationTracking() {
    locationSubscription?.pause();
  }

  /// Resume location tracking
  void resumeLocationTracking() {
    locationSubscription?.resume();
  }

  /// Set screen active state for battery optimization
  void setScreenActive(bool active) {
    isScreenActive = active;
    if (active) {
      locationSubscription?.resume();
    } else {
      locationSubscription?.pause();
    }
  }

  /// Get cached location from SharedPreferences
  Future<LatLng?> getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('last_latitude');
      final lng = prefs.getDouble('last_longitude');

      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    } catch (e) {
      onError?.call('Failed to load cached location: ${e.toString()}');
    }
    return null;
  }

  /// Cache current location for faster app startup
  Future<void> _cacheLocation(LocationData locationData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_latitude', locationData.latitude!);
      await prefs.setDouble('last_longitude', locationData.longitude!);
    } catch (e) {
      onError?.call('Failed to cache location: ${e.toString()}');
    }
  }

  /// Dispose resources
  void dispose() {
    locationSubscription?.cancel();
    locationSubscription = null;
  }
}
