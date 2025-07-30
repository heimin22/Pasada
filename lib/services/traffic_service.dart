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
  // Time-to-live for cached entries
  static const Duration _cacheTTL = Duration(minutes: 5);
  final _apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;

  /// Returns true if the average speed for the route between [start] and [end]
  /// is below the specified [speedThresholdKmph], indicating heavy traffic.
  Future<bool> isRouteUnderHeavyTraffic(
    LatLng start,
    LatLng end, {
    double speedThresholdKmph = 20.0,
  }) async {
    // Construct cache key based on start/end coordinates
    final cacheKey =
        '${start.latitude}_${start.longitude}_${end.latitude}_${end.longitude}';
    // Return cached result if not expired
    final cacheEntry = _trafficCache[cacheKey];
    if (cacheEntry != null &&
        DateTime.now().difference(cacheEntry.timestamp) < _cacheTTL) {
      return cacheEntry.isHeavy;
    }
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
      // Debug raw API response
      debugPrint('Traffic raw response: $resp');
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
      return isHeavyTraffic;
    } catch (e) {
      debugPrint('Error checking traffic density: $e');
      return false;
    }
  }
}
