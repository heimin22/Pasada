import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pasada_passenger_app/services/error_logging_service.dart';
import 'package:pasada_passenger_app/services/location_permission_manager.dart';
import 'package:pasada_passenger_app/utils/exception_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapLocationManager {
  final Location location = Location();
  StreamSubscription<LocationData>? locationSubscription;

  bool isLocationInitialized = false;
  bool isScreenActive = true;

  // Optional pre-prompt callbacks to show app-styled dialogs BEFORE OS prompts
  Future<bool> Function()? onPrePromptLocationPermission;
  Future<bool> Function()? onPrePromptLocationService;

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
    this.onPrePromptLocationPermission,
    this.onPrePromptLocationService,
  });

  /// Initialize location services and start tracking
  Future<void> initializeLocation() async {
    if (isLocationInitialized) return;

    // Use centralized location permission manager to prevent multiple prompts
    final locationManager = LocationPermissionManager.instance;

    // First, check status WITHOUT prompting the OS
    final serviceEnabled = await locationManager.isServiceEnabledNoPrompt();
    final permissionStatus =
        await locationManager.getPermissionStatusNoPrompt();

    // If both service and permission are already granted, skip all dialogs and proceed
    if (serviceEnabled && permissionStatus == PermissionStatus.granted) {
      await getLocationUpdates();
      isLocationInitialized = true;
      return;
    }

    // Check if user has already been prompted for location permissions
    final hasBeenPrompted =
        await locationManager.hasUserBeenPromptedForLocation();
    if (hasBeenPrompted) {
      // Still try to get location updates even if previously prompted
      await getLocationUpdates();
      isLocationInitialized = true;
      return;
    }

    // Mark that user has been prompted for location permissions
    await locationManager.markLocationPermissionPrompted();

    // If services are disabled, show an app pre-prompt before requesting OS dialog
    if (!serviceEnabled) {
      bool proceed = true;
      if (onPrePromptLocationService != null) {
        proceed = await onPrePromptLocationService!.call();
      }
      if (!proceed) {
        onLocationServiceDisabled?.call();
        return;
      }
      final enabled = await locationManager.ensureLocationServiceEnabled();
      if (!enabled) {
        onLocationServiceDisabled?.call();
        return;
      }
    }

    // If permission not granted, show an app pre-prompt before OS permission dialog
    if (permissionStatus != PermissionStatus.granted) {
      bool proceed = true;
      if (onPrePromptLocationPermission != null) {
        proceed = await onPrePromptLocationPermission!.call();
      }
      if (!proceed) {
        onLocationPermissionDenied?.call();
        return;
      }
      final perm = await locationManager.ensureLocationPermissionGranted();
      if (perm != PermissionStatus.granted) {
        onLocationPermissionDenied?.call();
        return;
      }
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
      ExceptionHandler.handleLocationException(
        e,
        'MapLocationManager.getLocationUpdates',
        userMessage: 'Failed to get location updates',
        showToast: false,
      );
      ErrorLoggingService.logLocationError(
        error: e.toString(),
        context: 'MapLocationManager.getLocationUpdates',
      );
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
      ExceptionHandler.handleGenericException(
        e,
        'MapLocationManager.getCachedLocation',
        userMessage: 'Failed to load cached location',
        showToast: false,
      );
      ErrorLoggingService.logError(
        error: e.toString(),
        context: 'MapLocationManager.getCachedLocation',
      );
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
      ExceptionHandler.handleGenericException(
        e,
        'MapLocationManager._cacheLocation',
        userMessage: 'Failed to cache location',
        showToast: false,
      );
      ErrorLoggingService.logError(
        error: e.toString(),
        context: 'MapLocationManager._cacheLocation',
      );
      onError?.call('Failed to cache location: ${e.toString()}');
    }
  }

  /// Dispose resources
  void dispose() {
    locationSubscription?.cancel();
    locationSubscription = null;
  }
}
