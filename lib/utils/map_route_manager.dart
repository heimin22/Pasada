import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/services/fare_service.dart';
import 'package:pasada_passenger_app/services/polyline_service.dart';
import 'package:pasada_passenger_app/utils/map_utils.dart';
import 'package:pasada_passenger_app/utils/optimized_polyline_manager.dart';

class MapRouteManager {
  // Polylines storage (kept for backward compatibility)
  Map<PolylineId, Polyline> polylines = {};

  // Optimized polyline manager for better performance
  final OptimizedPolylineManager? _optimizedPolylineManager;

  // Callbacks
  Function(double)? onFareUpdated;
  Function(String)? onError;
  Function()? onStateChanged;

  MapRouteManager({
    this.onFareUpdated,
    this.onError,
    this.onStateChanged,
    OptimizedPolylineManager? optimizedPolylineManager,
  }) : _optimizedPolylineManager = optimizedPolylineManager;

  /// Render route between two locations
  Future<List<LatLng>> renderRouteBetween(
    LatLng start,
    LatLng destination, {
    bool updateFare = true,
    Color? polylineColor,
    int polylineWidth = 4,
  }) async {
    try {
      final polyService = PolylineService();
      final List<LatLng> polylineCoordinates =
          await polyService.generateBetween(start, destination);

      if (polylineCoordinates.isEmpty) {
        onError?.call('Could not generate route');
        return [];
      }

      // Calculate fare if requested
      if (updateFare) {
        final double routeDistance =
            await polyService.calculateRouteDistanceKm(start, destination);
        final double fare = FareService.calculateFare(routeDistance);
        onFareUpdated?.call(fare);
      }

      // Animate route drawing
      animateRouteDrawing(
        const PolylineId('route'),
        polylineCoordinates,
        polylineColor ?? const Color.fromARGB(255, 4, 197, 88),
        polylineWidth,
      );

      return polylineCoordinates;
    } catch (e) {
      onError?.call('Route generation failed: ${e.toString()}');
      return [];
    }
  }

  /// Render route along existing polyline (for bus routes)
  Future<List<LatLng>> renderRouteAlongPolyline(
    LatLng start,
    LatLng destination,
    List<LatLng> routePolyline, {
    Color? polylineColor,
    int polylineWidth = 4,
  }) async {
    try {
      final polyService = PolylineService();
      final segment = polyService.generateAlongRoute(
        start,
        destination,
        routePolyline,
      );

      if (segment.isEmpty) {
        onError?.call('Could not generate route segment');
        return [];
      }

      // Calculate fare for the segment
      final fare = FareService.calculateFareForPolyline(segment);
      onFareUpdated?.call(fare);

      // Animate route drawing
      animateRouteDrawing(
        const PolylineId('route'),
        segment,
        polylineColor ?? const Color(0xFFFFCE21),
        polylineWidth,
      );

      return segment;
    } catch (e) {
      onError?.call('Route segment generation failed: ${e.toString()}');
      return [];
    }
  }

  /// Animate drawing a polyline point-by-point
  void animateRouteDrawing(
    PolylineId id,
    List<LatLng> fullRoute,
    Color color,
    int width,
  ) {
    // Use optimized polyline manager if available
    if (_optimizedPolylineManager != null) {
      _optimizedPolylineManager.updatePolyline(
        id,
        fullRoute,
        color: color,
        width: width,
        animate: true,
      );
      return;
    }

    // Fallback to legacy method
    // Cancel any existing polyline with this id
    polylines.remove(id);

    int count = 0;
    final total = fullRoute.length;

    Timer.periodic(const Duration(milliseconds: 26), (timer) {
      count += 2;
      final int currentCount = count.clamp(0, total);
      final segment = fullRoute.sublist(0, currentCount);

      polylines[id] = Polyline(
        polylineId: id,
        points: segment,
        color: color,
        width: width,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      );

      onStateChanged?.call();

      if (count >= total) {
        timer.cancel();
      }
    });
  }

  /// Add static polyline without animation
  void addPolyline(
    PolylineId id,
    List<LatLng> points,
    Color color,
    int width,
  ) {
    // Use optimized polyline manager if available
    if (_optimizedPolylineManager != null) {
      _optimizedPolylineManager.updatePolyline(
        id,
        points,
        color: color,
        width: width,
        animate: false,
      );
      return;
    }

    // Fallback to legacy method
    polylines[id] = Polyline(
      polylineId: id,
      points: points,
      color: color,
      width: width,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
    );
    onStateChanged?.call();
  }

  /// Remove specific polyline
  void removePolyline(PolylineId id) {
    // Use optimized polyline manager if available
    if (_optimizedPolylineManager != null) {
      _optimizedPolylineManager.removePolyline(id);
      return;
    }

    // Fallback to legacy method
    polylines.remove(id);
    onStateChanged?.call();
  }

  /// Clear all polylines
  void clearAllPolylines() {
    // Use optimized polyline manager if available
    if (_optimizedPolylineManager != null) {
      _optimizedPolylineManager.clearAllPolylines();
      return;
    }

    // Fallback to legacy method
    polylines.clear();
    onStateChanged?.call();
  }

  /// Find nearest point on route polyline
  LatLng findNearestPointOnRoute(LatLng point, List<LatLng> routePolyline) {
    if (routePolyline.isEmpty) return point;

    double minDistance = double.infinity;
    LatLng nearestPoint = routePolyline.first;

    for (int i = 0; i < routePolyline.length - 1; i++) {
      final LatLng start = routePolyline[i];
      final LatLng end = routePolyline[i + 1];

      // Find the nearest point on this segment
      final LatLng nearestOnSegment =
          findNearestPointOnSegment(point, start, end);
      final double distance = calculateDistanceKm(point, nearestOnSegment);

      if (distance < minDistance) {
        minDistance = distance;
        nearestPoint = nearestOnSegment;
      }
    }

    return nearestPoint;
  }

  /// Find nearest point on a line segment
  LatLng findNearestPointOnSegment(LatLng point, LatLng start, LatLng end) {
    final double x = point.latitude;
    final double y = point.longitude;
    final double x1 = start.latitude;
    final double y1 = start.longitude;
    final double x2 = end.latitude;
    final double y2 = end.longitude;

    // Calculate squared length of segment
    final double l2 = (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1);
    if (l2 == 0) return start; // If segment is a point, return that point

    // Calculate projection of point onto line
    final double t = math.max(
        0, math.min(1, ((x - x1) * (x2 - x1) + (y - y1) * (y2 - y1)) / l2));

    // Calculate nearest point on line segment
    final double projX = x1 + t * (x2 - x1);
    final double projY = y1 + t * (y2 - y1);

    return LatLng(projX, projY);
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(LatLng point1, LatLng point2) {
    return calculateDistanceKm(point1, point2);
  }

  /// Get all current polylines
  Set<Polyline> get allPolylines => Set<Polyline>.of(polylines.values);

  /// Check if specific polyline exists
  bool hasPolyline(PolylineId id) => polylines.containsKey(id);

  /// Get polyline by ID
  Polyline? getPolyline(PolylineId id) => polylines[id];

  /// Update existing polyline
  void updatePolyline(
    PolylineId id,
    List<LatLng> newPoints, {
    Color? color,
    int? width,
  }) {
    final existingPolyline = polylines[id];
    if (existingPolyline != null) {
      polylines[id] = existingPolyline.copyWith(
        pointsParam: newPoints,
        colorParam: color,
        widthParam: width,
      );
      onStateChanged?.call();
    }
  }

  /// Get total number of polylines
  int get polylineCount => polylines.length;

  /// Dispose resources
  void dispose() {
    clearAllPolylines();
  }
}
