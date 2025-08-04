import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class RouteService {
  static const String _routeKey = 'selectedRoute';

  /// Save the selected route to SharedPreferences
  static Future<void> saveRoute(Map<String, dynamic> route) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Create a serializable copy of the route data
      final routeData = Map<String, dynamic>.from(route);

      // Convert LatLng objects to serializable format
      if (routeData['origin_coordinates'] != null) {
        final origin = routeData['origin_coordinates'] as LatLng;
        routeData['origin_coordinates'] = {
          'latitude': origin.latitude,
          'longitude': origin.longitude,
        };
      }

      if (routeData['destination_coordinates'] != null) {
        final dest = routeData['destination_coordinates'] as LatLng;
        routeData['destination_coordinates'] = {
          'latitude': dest.latitude,
          'longitude': dest.longitude,
        };
      }

      if (routeData['polyline_coordinates'] != null) {
        final polyline = routeData['polyline_coordinates'] as List<LatLng>;
        routeData['polyline_coordinates'] = polyline
            .map((point) => {
                  'latitude': point.latitude,
                  'longitude': point.longitude,
                })
            .toList();
      }

      await prefs.setString(_routeKey, jsonEncode(routeData));
      debugPrint('Route saved successfully: ${routeData['route_name']}');
    } catch (e) {
      debugPrint('Error saving route: $e');
    }
  }

  /// Load the selected route from SharedPreferences
  static Future<Map<String, dynamic>?> loadRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routeJson = prefs.getString(_routeKey);

      if (routeJson == null) return null;

      final routeData = jsonDecode(routeJson) as Map<String, dynamic>;

      // Convert serialized coordinates back to LatLng objects
      if (routeData['origin_coordinates'] != null) {
        final origin = routeData['origin_coordinates'] as Map<String, dynamic>;
        routeData['origin_coordinates'] = LatLng(
          origin['latitude'] as double,
          origin['longitude'] as double,
        );
      }

      if (routeData['destination_coordinates'] != null) {
        final dest =
            routeData['destination_coordinates'] as Map<String, dynamic>;
        routeData['destination_coordinates'] = LatLng(
          dest['latitude'] as double,
          dest['longitude'] as double,
        );
      }

      if (routeData['polyline_coordinates'] != null) {
        final polylineData = routeData['polyline_coordinates'] as List<dynamic>;
        routeData['polyline_coordinates'] = polylineData.map((point) {
          final p = point as Map<String, dynamic>;
          return LatLng(p['latitude'] as double, p['longitude'] as double);
        }).toList();
      }

      debugPrint('Route loaded successfully: ${routeData['route_name']}');
      return routeData;
    } catch (e) {
      debugPrint('Error loading route: $e');
      // Clear invalid route data
      await clearRoute();
      return null;
    }
  }

  /// Clear the saved route from SharedPreferences
  static Future<void> clearRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_routeKey);
      debugPrint('Route cleared successfully');
    } catch (e) {
      debugPrint('Error clearing route: $e');
    }
  }

  /// Check if a route is currently saved
  static Future<bool> hasRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_routeKey);
    } catch (e) {
      debugPrint('Error checking for saved route: $e');
      return false;
    }
  }
}
