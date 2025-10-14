import 'dart:async';

import 'package:location/location.dart';

/// Centralized manager for location permissions and services to prevent multiple prompts
class LocationPermissionManager {
  static LocationPermissionManager? _instance;
  static LocationPermissionManager get instance =>
      _instance ??= LocationPermissionManager._();

  LocationPermissionManager._();

  final Location _location = Location();

  // State tracking
  bool _isRequestingService = false;
  bool _isRequestingPermission = false;
  bool? _lastServiceEnabledState;
  PermissionStatus? _lastPermissionState;
  DateTime? _lastServiceCheck;
  DateTime? _lastPermissionCheck;

  // Cache duration for checks (avoid spamming the system)
  static const Duration _cacheDuration = Duration(seconds: 5);

  Future<bool> ensureLocationServiceEnabled() async {
    // Use cached result if recent
    if (_lastServiceEnabledState != null &&
        _lastServiceCheck != null &&
        DateTime.now().difference(_lastServiceCheck!) < _cacheDuration) {
      return _lastServiceEnabledState!;
    }

    // Prevent multiple simultaneous requests
    if (_isRequestingService) {
      // Wait for ongoing request to complete
      while (_isRequestingService) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _lastServiceEnabledState ?? false;
    }

    _isRequestingService = true;

    try {
      bool serviceEnabled = await _location.serviceEnabled();

      if (!serviceEnabled) {
        // Only request if not already requesting
        serviceEnabled = await _location.requestService();
      }

      _lastServiceEnabledState = serviceEnabled;
      _lastServiceCheck = DateTime.now();

      return serviceEnabled;
    } catch (e) {
      _lastServiceEnabledState = false;
      _lastServiceCheck = DateTime.now();
      return false;
    } finally {
      _isRequestingService = false;
    }
  }

  Future<PermissionStatus> ensureLocationPermissionGranted() async {
    // Use cached result if recent
    if (_lastPermissionState != null &&
        _lastPermissionCheck != null &&
        DateTime.now().difference(_lastPermissionCheck!) < _cacheDuration) {
      return _lastPermissionState!;
    }

    // Prevent multiple simultaneous requests
    if (_isRequestingPermission) {
      // Wait for ongoing request to complete
      while (_isRequestingPermission) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _lastPermissionState ?? PermissionStatus.denied;
    }

    _isRequestingPermission = true;

    try {
      PermissionStatus status = await _location.hasPermission();

      if (status != PermissionStatus.granted) {
        status = await _location.requestPermission();
      }

      _lastPermissionState = status;
      _lastPermissionCheck = DateTime.now();

      return status;
    } catch (e) {
      _lastPermissionState = PermissionStatus.denied;
      _lastPermissionCheck = DateTime.now();
      return PermissionStatus.denied;
    } finally {
      _isRequestingPermission = false;
    }
  }

  Future<bool> ensureLocationReady() async {
    final serviceEnabled = await ensureLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final permissionStatus = await ensureLocationPermissionGranted();
    return permissionStatus == PermissionStatus.granted;
  }

  // Non-blocking checks that DO NOT prompt system dialogs
  Future<bool> isServiceEnabledNoPrompt() async {
    try {
      final enabled = await _location.serviceEnabled();
      return enabled;
    } catch (_) {
      return false;
    }
  }

  Future<PermissionStatus> getPermissionStatusNoPrompt() async {
    try {
      final status = await _location.hasPermission();
      return status;
    } catch (_) {
      return PermissionStatus.denied;
    }
  }

  /// Get current location if permissions are ready
  Future<LocationData?> getCurrentLocation() async {
    final ready = await ensureLocationReady();
    if (!ready) return null;

    try {
      return await _location.getLocation();
    } catch (e) {
      return null;
    }
  }

  /// Clear cache to force fresh checks (useful after user changes settings)
  void clearCache() {
    _lastServiceEnabledState = null;
    _lastPermissionState = null;
    _lastServiceCheck = null;
    _lastPermissionCheck = null;
  }

  /// Check if location services are currently enabled (cached)
  bool get isServiceEnabled => _lastServiceEnabledState ?? false;

  /// Check if location permission is currently granted (cached)
  bool get isPermissionGranted =>
      _lastPermissionState == PermissionStatus.granted;

  /// Check if location is ready to use (cached)
  bool get isLocationReady => isServiceEnabled && isPermissionGranted;
}
