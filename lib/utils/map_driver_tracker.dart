import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/services/ride_service.dart';

class MapDriverTracker {
  // Cache for driver route polylines to avoid excessive API calls
  List<LatLng>? _cachedDriverRoute;
  LatLng? _lastDriverRouteLocation;
  String? _lastRideStatus;
  LatLng? _lastTargetLocation;

  // Distance threshold in meters for polyline regeneration
  static const double _ROUTE_UPDATE_THRESHOLD = 100.0;

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

  /// Update driver location and generate route to target
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

    // Check if we need to regenerate the route
    bool shouldRegenerateRoute =
        _shouldRegenerateRoute(driverLocation, rideStatus, targetLocation);

    List<LatLng> route = [];

    if (shouldRegenerateRoute) {
      try {
        // Generate new route and cache it
        route = await _rideService.getRoute(driverLocation, targetLocation);
        if (route.isNotEmpty) {
          _cachedDriverRoute = route;
          _lastDriverRouteLocation = driverLocation;
          _lastRideStatus = rideStatus;
          _lastTargetLocation = targetLocation;
        }
      } catch (e) {
        onError?.call('Failed to generate driver route: ${e.toString()}');
        return;
      }
    } else if (_cachedDriverRoute != null) {
      // Use cached route
      route = _cachedDriverRoute!;
    }

    if (route.isNotEmpty) {
      onDriverRouteUpdated?.call(driverLocation, route);
    }
  }

  /// Check if route should be regenerated based on distance and status changes
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
    if (_cachedDriverRoute == null || _lastDriverRouteLocation == null) {
      return true;
    }

    // Calculate distance from last route generation point
    double distance = _calculateDistance(
      currentLocation.latitude,
      currentLocation.longitude,
      _lastDriverRouteLocation!.latitude,
      _lastDriverRouteLocation!.longitude,
    );

    // Regenerate if driver moved significantly
    return distance > _ROUTE_UPDATE_THRESHOLD;
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

  /// Clear all cached data
  void _clearCache() {
    _cachedDriverRoute = null;
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

  /// Get route update threshold in meters
  double get routeUpdateThreshold => _ROUTE_UPDATE_THRESHOLD;

  /// Force clear cache (useful for ride completion)
  void clearCache() {
    _clearCache();
  }

  /// Check if driver has moved significantly since last update
  bool hasDriverMovedSignificantly(LatLng currentLocation) {
    if (_lastDriverRouteLocation == null) return true;

    double distance = _calculateDistance(
      currentLocation.latitude,
      currentLocation.longitude,
      _lastDriverRouteLocation!.latitude,
      _lastDriverRouteLocation!.longitude,
    );

    return distance > _ROUTE_UPDATE_THRESHOLD;
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

  /// Update route update threshold (for testing or configuration)
  void setRouteUpdateThreshold(double newThreshold) {
    // This would require making _ROUTE_UPDATE_THRESHOLD non-const
    // For now, this is just a placeholder for future flexibility
  }

  /// Dispose resources
  void dispose() {
    _clearCache();
  }
}
