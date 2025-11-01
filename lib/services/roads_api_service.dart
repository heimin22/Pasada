import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Service for using Google Roads API to snap vehicle locations to roads
/// This is more cost-effective than Directions API for tracking vehicle positions
class RoadsApiService {
  static final RoadsApiService _instance = RoadsApiService._internal();

  factory RoadsApiService() => _instance;

  RoadsApiService._internal();

  final String _apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;

  // Cache for snapped points to avoid duplicate API calls
  static final Map<String, _SnappedPoint> _snappedPointsCache = {};

  // Cache TTL: 1 hour for snapped points (they don't change often)
  static const Duration _cacheTTL = Duration(hours: 1);
  
  // Flag to track if speed limits API is disabled (due to 403 permission error)
  static bool _speedLimitsDisabled = false;

  /// Snap a vehicle location to the nearest road
  /// Returns the snapped coordinates or null if snapping fails
  Future<LatLng?> snapToRoad(LatLng location) async {
    try {
      // Create cache key for this location
      final cacheKey = _createCacheKey(location);

      // Check cache first
      final cached = _snappedPointsCache[cacheKey];
      if (cached != null && cached.isValid(_cacheTTL)) {
        debugPrint(
            'RoadsApiService: Returning cached snapped point for $cacheKey');
        return cached.snappedLocation;
      }

      // Make API call to snap the point
      final snappedLocation = await _snapPointToRoad(location);

      if (snappedLocation != null) {
        // Cache the result
        _snappedPointsCache[cacheKey] =
            _SnappedPoint(snappedLocation, DateTime.now());
        debugPrint('RoadsApiService: Cached snapped point for $cacheKey');
      }

      return snappedLocation;
    } catch (e) {
      debugPrint('RoadsApiService: Error snapping point to road: $e');
      return null;
    }
  }

  /// Snap multiple vehicle locations to roads in a single API call
  /// This is more efficient than individual calls
  Future<List<LatLng?>> snapToRoads(List<LatLng> locations) async {
    if (locations.isEmpty) return [];

    try {
      // Build the path parameter for the API
      final path =
          locations.map((loc) => '${loc.latitude},${loc.longitude}').join('|');

      final uri = Uri.https(
        'roads.googleapis.com',
        '/v1/snapToRoads',
        {
          'path': path,
          'interpolate': 'true', // Interpolate missing points
          'key': _apiKey,
        },
      );

      debugPrint(
          'RoadsApiService: Snapping ${locations.length} points to roads');

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        debugPrint(
            'RoadsApiService: API error ${response.statusCode}: ${response.body}');
        return List.filled(locations.length, null);
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final snappedPoints = data['snappedPoints'] as List<dynamic>? ?? [];

      // Create result list with same length as input
      final result = List<LatLng?>.filled(locations.length, null);

      for (int i = 0; i < snappedPoints.length && i < locations.length; i++) {
        final snappedPoint = snappedPoints[i] as Map<String, dynamic>;
        final location = snappedPoint['location'] as Map<String, dynamic>?;

        if (location != null) {
          final lat = location['latitude'] as double?;
          final lng = location['longitude'] as double?;

          if (lat != null && lng != null) {
            result[i] = LatLng(lat, lng);

            // Cache individual snapped points
            final originalLocation = locations[i];
            final cacheKey = _createCacheKey(originalLocation);
            _snappedPointsCache[cacheKey] =
                _SnappedPoint(result[i]!, DateTime.now());
          }
        }
      }

      debugPrint(
          'RoadsApiService: Successfully snapped ${result.where((loc) => loc != null).length} out of ${locations.length} points');
      return result;
    } catch (e) {
      debugPrint('RoadsApiService: Error snapping points to roads: $e');
      return List.filled(locations.length, null);
    }
  }

  /// Get speed limits for a road segment
  /// This can be useful for calculating ETA more accurately
  Future<Map<String, dynamic>?> getSpeedLimits(List<LatLng> path) async {
    if (path.isEmpty) return null;
    
    // Skip API call if speed limits are disabled due to permission error
    if (_speedLimitsDisabled) {
      return null;
    }

    try {
      // Build the path parameter for the API
      final pathString =
          path.map((loc) => '${loc.latitude},${loc.longitude}').join('|');

      final uri = Uri.https(
        'roads.googleapis.com',
        '/v1/speedLimits',
        {
          'path': pathString,
          'key': _apiKey,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        // Check for 403 permission denied error
        if (response.statusCode == 403) {
          try {
            final errorData = json.decode(response.body) as Map<String, dynamic>;
            final error = errorData['error'] as Map<String, dynamic>?;
            final status = error?['status'] as String?;
            
            if (status == 'PERMISSION_DENIED') {
              // Set flag to disable future calls and log only once
              _speedLimitsDisabled = true;
              debugPrint(
                  'RoadsApiService: Speed limits API not available (403 PERMISSION_DENIED). '
                  'This feature requires special permissions in Google Cloud Console. '
                  'Speed limits will be disabled for this session.');
              return null;
            }
          } catch (_) {
            // If JSON parsing fails, still disable and log once
            _speedLimitsDisabled = true;
            debugPrint(
                'RoadsApiService: Speed limits API returned 403. Disabling speed limits feature.');
            return null;
          }
        }
        
        // For other errors, log once but don't disable completely
        debugPrint(
            'RoadsApiService: Speed limits API error ${response.statusCode}: ${response.body}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      debugPrint('RoadsApiService: Error getting speed limits: $e');
      return null;
    }
  }

  /// Get the nearest roads for a location
  /// This can help determine if a vehicle is on a road
  Future<List<Map<String, dynamic>>?> getNearestRoads(LatLng location) async {
    try {
      final uri = Uri.https(
        'roads.googleapis.com',
        '/v1/nearestRoads',
        {
          'points': '${location.latitude},${location.longitude}',
          'key': _apiKey,
        },
      );

      debugPrint(
          'RoadsApiService: Getting nearest roads for ${location.latitude},${location.longitude}');

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        debugPrint(
            'RoadsApiService: Nearest roads API error ${response.statusCode}: ${response.body}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final snappedPoints = data['snappedPoints'] as List<dynamic>? ?? [];

      return snappedPoints
          .map((point) => point as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('RoadsApiService: Error getting nearest roads: $e');
      return null;
    }
  }

  Future<LatLng?> _snapPointToRoad(LatLng location) async {
    try {
      final uri = Uri.https(
        'roads.googleapis.com',
        '/v1/snapToRoads',
        {
          'path': '${location.latitude},${location.longitude}',
          'interpolate': 'true',
          'key': _apiKey,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        debugPrint(
            'RoadsApiService: Snap to road API error ${response.statusCode}: ${response.body}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final snappedPoints = data['snappedPoints'] as List<dynamic>? ?? [];

      if (snappedPoints.isNotEmpty) {
        final snappedPoint = snappedPoints.first as Map<String, dynamic>;
        final locationData = snappedPoint['location'] as Map<String, dynamic>?;

        if (locationData != null) {
          final lat = locationData['latitude'] as double?;
          final lng = locationData['longitude'] as double?;

          if (lat != null && lng != null) {
            return LatLng(lat, lng);
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('RoadsApiService: Error in _snapPointToRoad: $e');
      return null;
    }
  }

  String _createCacheKey(LatLng location) {
    // Round coordinates to reduce cache misses for nearby locations
    final roundedLat = (location.latitude * 10000).round() / 10000;
    final roundedLng = (location.longitude * 10000).round() / 10000;

    return 'snapped_${roundedLat}_$roundedLng';
  }

  /// Clear all cached snapped points
  static void clearCache() {
    _snappedPointsCache.clear();
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'cached_snapped_points': _snappedPointsCache.length,
      'cache_ttl_hours': _cacheTTL.inHours,
    };
  }
}

// Cache entry for snapped points
class _SnappedPoint {
  final LatLng snappedLocation;
  final DateTime timestamp;

  _SnappedPoint(this.snappedLocation, this.timestamp);

  bool isValid(Duration ttl) {
    return DateTime.now().difference(timestamp) < ttl;
  }
}
