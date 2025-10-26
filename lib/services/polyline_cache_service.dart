import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/network/networkUtilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Cache entry for polyline data
class _CachedPolyline {
  final List<LatLng> coordinates;
  final DateTime timestamp;

  _CachedPolyline(this.coordinates, this.timestamp);

  bool isValid(Duration ttl) {
    return DateTime.now().difference(timestamp) < ttl;
  }
}

/// Service for caching polyline data to reduce Google Maps API calls
class PolylineCacheService {
  static final PolylineCacheService _instance =
      PolylineCacheService._internal();

  factory PolylineCacheService() => _instance;

  PolylineCacheService._internal();

  // In-memory cache for polylines
  static final Map<String, _CachedPolyline> _polylineCache = {};

  // Cache TTL: 30 minutes for polyline data (routes don't change often)
  static const Duration _cacheTTL = Duration(minutes: 30);

  // Request deduplication - prevent multiple identical requests
  static final Map<String, Future<List<LatLng>>> _pendingRequests = {};

  final String _apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;

  /// Get polyline coordinates for a route, with caching and deduplication
  Future<List<LatLng>> getPolylineCoordinates({
    required LatLng origin,
    required LatLng destination,
    List<dynamic>? intermediatePoints,
  }) async {
    final cacheKey = _createCacheKey(origin, destination, intermediatePoints);

    // Check cache first
    final cached = _polylineCache[cacheKey];
    if (cached != null && cached.isValid(_cacheTTL)) {
      debugPrint(
          'PolylineCacheService: Returning cached polyline for $cacheKey');
      return cached.coordinates;
    }

    // Check if there's already a pending request for this route
    if (_pendingRequests.containsKey(cacheKey)) {
      debugPrint(
          'PolylineCacheService: Waiting for pending request for $cacheKey');
      return await _pendingRequests[cacheKey]!;
    }

    // Create new request and store it
    final request = _fetchPolylineFromAPI(
        origin, destination, intermediatePoints, cacheKey);
    _pendingRequests[cacheKey] = request;

    try {
      final result = await request;
      return result;
    } finally {
      // Remove from pending requests
      _pendingRequests.remove(cacheKey);
    }
  }

  Future<List<LatLng>> _fetchPolylineFromAPI(LatLng origin, LatLng destination,
      List<dynamic>? intermediatePoints, String cacheKey) async {
    try {
      // Convert intermediate coordinates to waypoints format
      List<Map<String, dynamic>> intermediates = [];
      if (intermediatePoints != null && intermediatePoints.isNotEmpty) {
        for (var point in intermediatePoints) {
          if (point is Map &&
              point.containsKey('lat') &&
              point.containsKey('lng')) {
            intermediates.add({
              'location': {
                'latLng': {
                  'latitude': double.parse(point['lat'].toString()),
                  'longitude': double.parse(point['lng'].toString())
                }
              }
            });
          }
        }
      }

      // Routes API request
      final uri = Uri.parse(
          'https://routes.googleapis.com/directions/v2:computeRoutes');
      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
      };

      final body = jsonEncode({
        'origin': {
          'location': {
            'latLng': {
              'latitude': origin.latitude,
              'longitude': origin.longitude,
            },
          },
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destination.latitude,
              'longitude': destination.longitude,
            },
          },
        },
        'intermediates': intermediates,
        'travelMode': 'DRIVE',
        'polylineEncoding': 'ENCODED_POLYLINE',
        'computeAlternativeRoutes': false,
        'routingPreference': 'TRAFFIC_AWARE',
      });

      final response =
          await NetworkUtility.postUrl(uri, headers: headers, body: body);

      if (response == null) {
        debugPrint('PolylineCacheService: No response from server');
        return [];
      }

      final data = json.decode(response);

      // Add response validation
      if (data['routes'] == null || data['routes'].isEmpty) {
        debugPrint('PolylineCacheService: No routes found');
        return [];
      }

      // Null checking for nested properties
      final polyline = data['routes'][0]['polyline']?['encodedPolyline'];
      if (polyline == null) {
        debugPrint('PolylineCacheService: No polyline found in the response');
        return [];
      }

      // Decode the polyline
      List<PointLatLng> decodedPolyline =
          PolylinePoints.decodePolyline(polyline);
      List<LatLng> polylineCoordinates = decodedPolyline
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      // Cache the result
      _polylineCache[cacheKey] =
          _CachedPolyline(polylineCoordinates, DateTime.now());

      // Persist to SharedPreferences for longer-term caching
      await _persistPolylineToCache(cacheKey, polylineCoordinates);

      debugPrint(
          'PolylineCacheService: Cached polyline for $cacheKey with ${polylineCoordinates.length} points');
      return polylineCoordinates;
    } catch (e) {
      debugPrint('PolylineCacheService: Error fetching polyline: $e');
      // Try to return cached data even if expired
      final cached = _polylineCache[cacheKey];
      if (cached != null) {
        debugPrint(
            'PolylineCacheService: Returning expired cache due to API error');
        return cached.coordinates;
      }
      return [];
    }
  }

  String _createCacheKey(
      LatLng origin, LatLng destination, List<dynamic>? intermediatePoints) {
    // Round coordinates to reduce cache misses for nearby locations
    final roundedOriginLat = (origin.latitude * 10000).round() / 10000;
    final roundedOriginLng = (origin.longitude * 10000).round() / 10000;
    final roundedDestLat = (destination.latitude * 10000).round() / 10000;
    final roundedDestLng = (destination.longitude * 10000).round() / 10000;

    String key =
        'polyline_${roundedOriginLat}_${roundedOriginLng}_${roundedDestLat}_$roundedDestLng';

    // Add intermediate points to cache key if present
    if (intermediatePoints != null && intermediatePoints.isNotEmpty) {
      final intermediateKeys = intermediatePoints
          .map((point) {
            if (point is Map &&
                point.containsKey('lat') &&
                point.containsKey('lng')) {
              final lat =
                  (double.parse(point['lat'].toString()) * 10000).round() /
                      10000;
              final lng =
                  (double.parse(point['lng'].toString()) * 10000).round() /
                      10000;
              return '${lat}_$lng';
            }
            return '';
          })
          .where((k) => k.isNotEmpty)
          .join('_');

      if (intermediateKeys.isNotEmpty) {
        key += '_$intermediateKeys';
      }
    }

    return key;
  }

  Future<void> _persistPolylineToCache(
      String cacheKey, List<LatLng> coordinates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'coordinates': coordinates
            .map((latLng) => {
                  'latitude': latLng.latitude,
                  'longitude': latLng.longitude,
                })
            .toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString('polyline_cache_$cacheKey', jsonEncode(cacheData));
    } catch (e) {
      debugPrint('PolylineCacheService: Failed to persist polyline cache: $e');
    }
  }

  /// Clear all cached polyline data
  static void clearCache() {
    _polylineCache.clear();
    _pendingRequests.clear();
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'cached_polylines': _polylineCache.length,
      'pending_requests': _pendingRequests.length,
      'cache_ttl_minutes': _cacheTTL.inMinutes,
    };
  }
}
