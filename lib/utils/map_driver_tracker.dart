import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/services/ride_service.dart';

class MapDriverTracker {
  // Cache for driver route polylines to avoid excessive API calls
  List<LatLng>? _cachedDriverRoute;
  List<LatLng>? _originalRoute; // Store original full route for reference
  LatLng? _lastDriverRouteLocation;
  String? _lastRideStatus;
  LatLng? _lastTargetLocation;

  // Distance threshold in meters for route deviation (not movement)
  static const double _ROUTE_DEVIATION_THRESHOLD =
      150.0; // Increased threshold for route deviation
  static const double _ROUTE_PROGRESS_THRESHOLD =
      50.0; // Distance for route trimming

  late final RideService _rideService;

  // Callbacks
  Function(LatLng, List<LatLng>)? onDriverRouteUpdated;
  Function(String)? onError;

  MapDriverTracker({
    this.onDriverRouteUpdated,
    this.onError,
  }) {
    _rideService = RideService();
  }

  /// Update driver location and generate/trim route to target
  Future<void> updateDriverLocation(
    LatLng driverLocation,
    String rideStatus, {
    LatLng? pickupLocation,
    LatLng? dropoffLocation,
  }) async {
    // Determine target location based on ride status
    LatLng? targetLocation;
    if (rideStatus == 'accepted') {
      targetLocation = pickupLocation;
    } else if (rideStatus == 'ongoing') {
      targetLocation = dropoffLocation;
    }

    // Only generate polyline for accepted or ongoing rides
    if (targetLocation == null) return;

    // Check if we need to regenerate the route completely
    bool shouldRegenerateRoute =
        _shouldRegenerateRoute(driverLocation, rideStatus, targetLocation);

    List<LatLng> route = [];

    if (shouldRegenerateRoute) {
      try {
        // Generate new route and cache it
        route = await _rideService.getRoute(driverLocation, targetLocation);
        if (route.isNotEmpty) {
          _cachedDriverRoute = route;
          _originalRoute = List.from(route); // Store original for reference
          _lastDriverRouteLocation = driverLocation;
          _lastRideStatus = rideStatus;
          _lastTargetLocation = targetLocation;
        }
      } catch (e) {
        onError?.call('Failed to generate driver route: ${e.toString()}');
        return;
      }
    } else if (_cachedDriverRoute != null) {
      // Trim the route instead of regenerating
      route = _trimRouteFromDriverPosition(driverLocation);
    }

    if (route.isNotEmpty) {
      onDriverRouteUpdated?.call(driverLocation, route);
    }
  }

  /// Check if route should be regenerated based on deviation, not movement
  bool _shouldRegenerateRoute(
    LatLng currentLocation,
    String rideStatus,
    LatLng targetLocation,
  ) {
    // Always regenerate if status changed
    if (_lastRideStatus != rideStatus) {
      // Clear cached route when status changes
      _clearCache();
      return true;
    }

    // Always regenerate if target changed
    if (_lastTargetLocation == null ||
        _lastTargetLocation!.latitude != targetLocation.latitude ||
        _lastTargetLocation!.longitude != targetLocation.longitude) {
      return true;
    }

    // Regenerate if no cached route exists
    if (_cachedDriverRoute == null || _originalRoute == null) {
      return true;
    }

    // Check if driver has deviated significantly from the route
    double distanceFromRoute =
        _getDistanceFromRoute(currentLocation, _originalRoute!);

    // Only regenerate if driver deviated from the route, not just moved along it
    return distanceFromRoute > _ROUTE_DEVIATION_THRESHOLD;
  }

  /// Calculate distance between two points in meters
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth radius in meters
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Trim route from driver's current position to destination
  List<LatLng> _trimRouteFromDriverPosition(LatLng driverLocation) {
    if (_originalRoute == null || _originalRoute!.isEmpty) {
      return _cachedDriverRoute ?? [];
    }

    // Find the closest point on the original route to the driver's position
    int closestIndex = _findClosestPointIndex(driverLocation, _originalRoute!);

    // Return the route from the closest point to the destination
    if (closestIndex >= 0 && closestIndex < _originalRoute!.length) {
      List<LatLng> trimmedRoute = _originalRoute!.sublist(closestIndex);
      // Update cached route to the trimmed version
      _cachedDriverRoute = trimmedRoute;
      return trimmedRoute;
    }

    return _cachedDriverRoute ?? [];
  }

  /// Find the closest point on the route to the driver's position
  int _findClosestPointIndex(LatLng driverLocation, List<LatLng> route) {
    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < route.length; i++) {
      double distance = _calculateDistance(
        driverLocation.latitude,
        driverLocation.longitude,
        route[i].latitude,
        route[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  /// Get minimum distance from driver location to any point on the route
  double _getDistanceFromRoute(LatLng driverLocation, List<LatLng> route) {
    double minDistance = double.infinity;

    for (LatLng routePoint in route) {
      double distance = _calculateDistance(
        driverLocation.latitude,
        driverLocation.longitude,
        routePoint.latitude,
        routePoint.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  /// Clear all cached data
  void _clearCache() {
    _cachedDriverRoute = null;
    _originalRoute = null;
    _lastDriverRouteLocation = null;
    _lastRideStatus = null;
    _lastTargetLocation = null;
  }

  /// Get current cached route
  List<LatLng>? get cachedRoute => _cachedDriverRoute;

  /// Get last known driver location
  LatLng? get lastDriverLocation => _lastDriverRouteLocation;

  /// Get last ride status
  String? get lastRideStatus => _lastRideStatus;

  /// Get last target location
  LatLng? get lastTargetLocation => _lastTargetLocation;

  /// Check if route is cached
  bool get hasRoute => _cachedDriverRoute?.isNotEmpty == true;

  /// Get route deviation threshold in meters
  double get routeDeviationThreshold => _ROUTE_DEVIATION_THRESHOLD;

  /// Get route progress threshold in meters
  double get routeProgressThreshold => _ROUTE_PROGRESS_THRESHOLD;

  /// Force clear cache (useful for ride completion)
  void clearCache() {
    _clearCache();
  }

  /// Check if driver has deviated significantly from route
  bool hasDriverDeviatedFromRoute(LatLng currentLocation) {
    if (_originalRoute == null) return true;

    double distanceFromRoute =
        _getDistanceFromRoute(currentLocation, _originalRoute!);
    return distanceFromRoute > _ROUTE_DEVIATION_THRESHOLD;
  }

  /// Get distance from last route generation point
  double? getDistanceFromLastRoutePoint(LatLng currentLocation) {
    if (_lastDriverRouteLocation == null) return null;

    return _calculateDistance(
      currentLocation.latitude,
      currentLocation.longitude,
      _lastDriverRouteLocation!.latitude,
      _lastDriverRouteLocation!.longitude,
    );
  }

  /// Get original full route (for debugging or analysis)
  List<LatLng>? get originalRoute => _originalRoute;

  /// Check if route is being trimmed vs regenerated
  bool get isRouteTrimmed =>
      _originalRoute != null &&
      _cachedDriverRoute != null &&
      _cachedDriverRoute!.length < _originalRoute!.length;

  /// Dispose resources
  void dispose() {
    _clearCache();
  }
}
