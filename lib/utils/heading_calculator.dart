import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utility class for calculating heading/bearing between GPS coordinates
class HeadingCalculator {
  /// Calculate bearing between two points in degrees (0-360)
  /// Returns the direction from point1 to point2
  static double calculateBearing(LatLng from, LatLng to) {
    final double lat1 = from.latitude * math.pi / 180;
    final double lat2 = to.latitude * math.pi / 180;
    final double deltaLon = (to.longitude - from.longitude) * math.pi / 180;

    final double y = math.sin(deltaLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLon);

    double bearing = math.atan2(y, x) * 180 / math.pi;

    // Normalize to 0-360 degrees
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  /// Calculate distance between two points in meters
  static double calculateDistance(LatLng from, LatLng to) {
    const double earthRadius = 6371000; // Earth radius in meters
    final double lat1 = from.latitude * math.pi / 180;
    final double lat2 = to.latitude * math.pi / 180;
    final double deltaLat = (to.latitude - from.latitude) * math.pi / 180;
    final double deltaLon = (to.longitude - from.longitude) * math.pi / 180;

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Smooth heading calculation with multiple points to reduce noise
  static double calculateSmoothedHeading(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    if (points.length == 2) {
      return calculateBearing(points[0], points[1]);
    }

    // Use the last 3 points for smoothing
    final recentPoints =
        points.length > 3 ? points.sublist(points.length - 3) : points;

    double totalBearing = 0.0;
    int validBearings = 0;

    for (int i = 1; i < recentPoints.length; i++) {
      final double distance =
          calculateDistance(recentPoints[i - 1], recentPoints[i]);

      // Only consider points that are far enough apart to have meaningful direction
      if (distance > 5.0) {
        // At least 5 meters apart
        final double bearing =
            calculateBearing(recentPoints[i - 1], recentPoints[i]);
        totalBearing += bearing;
        validBearings++;
      }
    }

    if (validBearings == 0) {
      // Fallback to simple bearing between first and last point
      return calculateBearing(recentPoints.first, recentPoints.last);
    }

    return totalBearing / validBearings;
  }

  /// Check if two headings are similar (within threshold)
  static bool areHeadingsSimilar(double heading1, double heading2,
      {double threshold = 30.0}) {
    double diff = (heading1 - heading2).abs();
    if (diff > 180) {
      diff = 360 - diff;
    }
    return diff <= threshold;
  }

  /// Get heading direction as a string (N, NE, E, SE, S, SW, W, NW)
  static String getHeadingDirection(double heading) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final int index = ((heading + 22.5) % 360 / 45).floor();
    return directions[index];
  }
}
