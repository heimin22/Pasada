import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/network/networkUtilities.dart';
import 'package:pasada_passenger_app/services/polyline_service.dart';

// Cache entry model for traffic results
class _CachedTraffic {
  final bool isHeavy;
  final DateTime timestamp;
  _CachedTraffic(this.isHeavy, this.timestamp);
}

/// A service that provides traffic information based on route coordinates.
class TrafficService {
  // In-memory cache to reduce API calls
  static final Map<String, _CachedTraffic> _trafficCache = {};
  // Time-to-live for cached entries - increased to 10 minutes to reduce API calls
  static const Duration _cacheTTL = Duration(minutes: 10);
  final _apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;

  // Request deduplication - prevent multiple identical requests
  static final Map<String, Future<bool>> _pendingRequests = {};

  /// Returns true if the average speed for the route between [start] and [end]
  /// is below the specified [speedThresholdKmph], indicating heavy traffic.
  Future<bool> isRouteUnderHeavyTraffic(
    LatLng start,
    LatLng end, {
    double speedThresholdKmph = 20.0,
  }) async {
    // Construct cache key with rounded coordinates to reduce cache misses
    final cacheKey = _createCacheKey(start, end);

    // Return cached result if not expired
    final cacheEntry = _trafficCache[cacheKey];
    if (cacheEntry != null &&
        DateTime.now().difference(cacheEntry.timestamp) < _cacheTTL) {
      debugPrint('TrafficService: Returning cached result for $cacheKey');
      return cacheEntry.isHeavy;
    }

    // Check if there's already a pending request for this route
    if (_pendingRequests.containsKey(cacheKey)) {
      debugPrint('TrafficService: Waiting for pending request for $cacheKey');
      return await _pendingRequests[cacheKey]!;
    }

    // Create new request and store it
    final request =
        _fetchTrafficFromAPI(start, end, speedThresholdKmph, cacheKey);
    _pendingRequests[cacheKey] = request;

    try {
      final result = await request;
      return result;
    } finally {
      // Remove from pending requests
      _pendingRequests.remove(cacheKey);
    }
  }

  Future<bool> _fetchTrafficFromAPI(LatLng start, LatLng end,
      double speedThresholdKmph, String cacheKey) async {
    try {
      final polyService = PolylineService();
      final distanceKm = await polyService.calculateRouteDistanceKm(start, end);

      // Fetch traffic-aware duration for the route
      final uri = Uri.parse(
          'https://routes.googleapis.com/directions/v2:computeRoutes');
      final body = jsonEncode({
        'origin': {
          'location': {
            'latLng': {'latitude': start.latitude, 'longitude': start.longitude}
          }
        },
        'destination': {
          'location': {
            'latLng': {'latitude': end.latitude, 'longitude': end.longitude}
          }
        },
        'travelMode': 'DRIVE',
        'routingPreference': 'TRAFFIC_AWARE',
      });
      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': 'routes.legs.duration.seconds',
      };
      final resp =
          await NetworkUtility.postUrl(uri, headers: headers, body: body);
      if (resp == null) return false;

      debugPrint('TrafficService: API response for $cacheKey');
      // Ensure decoded response is a JSON object
      final decoded = json.decode(resp);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('Unexpected traffic data type: ${decoded.runtimeType}');
        return false;
      }
      final data = decoded;

      // Handle routes as List or Map
      dynamic routesData = data['routes'];
      if (routesData is! List && routesData is! Map<String, dynamic>) {
        debugPrint('Unexpected routesData type: ${routesData.runtimeType}');
        return false;
      }
      List<dynamic> routesList;
      if (routesData is List) {
        routesList = routesData;
      } else if (routesData is Map) {
        routesList = routesData.values.toList();
      } else {
        return false;
      }
      if (routesList.isEmpty) return false;
      // Ensure first route is a Map before indexing
      if (routesList.first is! Map<String, dynamic>) {
        debugPrint(
            'Unexpected route element type: ${routesList.first.runtimeType}');
        return false;
      }

      // Handle legs as List or Map
      dynamic legsData = routesList[0]['legs'];
      List<dynamic> legsList;
      if (legsData is List) {
        legsList = legsData;
      } else if (legsData is Map) {
        legsList = legsData.values.toList();
      } else {
        return false;
      }
      if (legsList.isEmpty) return false;

      // Safe extraction of seconds
      dynamic durationData = legsList[0]['duration'];
      if (durationData == null) return false;
      int secs;
      if (durationData is String) {
        // Parse string durations like "408s"
        final match = RegExp(r'^(\d+)s\$').firstMatch(durationData);
        if (match != null) {
          secs = int.parse(match.group(1)!);
        } else {
          // Fallback: extract digits only
          secs = int.tryParse(durationData.replaceAll(RegExp(r'\D'), '')) ?? 0;
        }
      } else if (durationData is Map<String, dynamic>) {
        dynamic secsVal = durationData['seconds'];
        if (secsVal is int) {
          secs = secsVal;
        } else if (secsVal is String) {
          secs = int.tryParse(secsVal) ?? 0;
        } else {
          return false;
        }
      } else {
        return false;
      }
      if (secs == 0) return false;

      final durationHours = secs / 3600.0;
      final avgSpeed = distanceKm / durationHours;
      final isHeavyTraffic = avgSpeed < speedThresholdKmph;

      // Cache the computed traffic result
      _trafficCache[cacheKey] = _CachedTraffic(isHeavyTraffic, DateTime.now());
      debugPrint(
          'TrafficService: Cached result for $cacheKey: $isHeavyTraffic');
      return isHeavyTraffic;
    } catch (e) {
      debugPrint('Error checking traffic density: $e');
      // Try to return cached data even if expired
      final cached = _trafficCache[cacheKey];
      if (cached != null) {
        debugPrint('TrafficService: Returning expired cache due to API error');
        return cached.isHeavy;
      }
      return false;
    }
  }

  String _createCacheKey(LatLng start, LatLng end) {
    // Round coordinates to reduce cache misses for nearby locations
    // Round to 4 decimal places (~11m precision)
    final roundedStartLat = (start.latitude * 10000).round() / 10000;
    final roundedStartLng = (start.longitude * 10000).round() / 10000;
    final roundedEndLat = (end.latitude * 10000).round() / 10000;
    final roundedEndLng = (end.longitude * 10000).round() / 10000;

    return 'traffic_${roundedStartLat}_${roundedStartLng}_${roundedEndLat}_$roundedEndLng';
  }

  /// Clear all cached traffic data
  static void clearCache() {
    _trafficCache.clear();
    _pendingRequests.clear();
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'cached_traffic': _trafficCache.length,
      'pending_requests': _pendingRequests.length,
      'cache_ttl_minutes': _cacheTTL.inMinutes,
    };
  }
}
