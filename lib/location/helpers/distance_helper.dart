import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Helper class for distance calculations and caching
class DistanceHelper {
  final Map<String, double> _distanceCache = {};

  /// Get cached distance or calculate and cache it
  double getCachedDistance(LatLng from, LatLng to) {
    final cacheKey =
        '${from.latitude}_${from.longitude}_${to.latitude}_${to.longitude}';

    if (_distanceCache.containsKey(cacheKey)) {
      return _distanceCache[cacheKey]!;
    }

    final distance = calculateDistance(from, to);
    _distanceCache[cacheKey] = distance;
    return distance;
  }

  /// Clear distance cache
  void clearCache() {
    _distanceCache.clear();
  }

  /// Calculate distance between two points using Haversine formula
  double calculateDistance(LatLng p1, LatLng p2) {
    // Using the Haversine formula to calculate distance
    const double earthRadius = 6371000; // Earth radius in meters
    final double lat1 = p1.latitude * pi / 180;
    final double lat2 = p2.latitude * pi / 180;
    final double dLat = (p2.latitude - p1.latitude) * pi / 180;
    final double dLon = (p2.longitude - p1.longitude) * pi / 180;

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Check if a location is within a certain radius of another location
  bool isWithinRadius(LatLng point1, LatLng point2, double radiusMeters) {
    final distance = calculateDistance(point1, point2);
    return distance <= radiusMeters;
  }

  /// Get distance in a human-readable format
  String getFormattedDistance(double distanceMeters) {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()}m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
  }
}
