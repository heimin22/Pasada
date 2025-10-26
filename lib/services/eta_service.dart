import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Cache entry for ETA results
class _CachedETA {
  final int etaSeconds;
  final DateTime timestamp;

  _CachedETA(this.etaSeconds, this.timestamp);

  bool isValid(Duration ttl) {
    return DateTime.now().difference(timestamp) < ttl;
  }
}

class ETAService {
  // Google Routes API key
  final String apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;

  // In-memory cache for ETA results
  static final Map<String, _CachedETA> _etaCache = {};

  // Cache TTL: 5 minutes for ETA data
  static const Duration _cacheTTL = Duration(minutes: 5);

  // Request deduplication - prevent multiple identical requests
  static final Map<String, Future<Map<String, dynamic>>> _pendingRequests = {};

  /// Compute ETA (duration) via Google Routes API for given origin/destination
  /// Now includes caching and request deduplication to reduce API costs
  Future<Map<String, dynamic>> getETA(Map<String, dynamic> features) async {
    // features must contain 'origin' and 'destination' maps with 'lat' and 'lng'
    final origin = features['origin'] as Map<String, dynamic>;
    final destination = features['destination'] as Map<String, dynamic>;

    // Create cache key with rounded coordinates to reduce cache misses
    final cacheKey = _createCacheKey(origin, destination);

    // Check cache first
    final cached = _etaCache[cacheKey];
    if (cached != null && cached.isValid(_cacheTTL)) {
      debugPrint('ETAService: Returning cached ETA for $cacheKey');
      return {'eta_seconds': cached.etaSeconds};
    }

    // Check if there's already a pending request for this route
    if (_pendingRequests.containsKey(cacheKey)) {
      debugPrint('ETAService: Waiting for pending request for $cacheKey');
      return await _pendingRequests[cacheKey]!;
    }

    // Create new request and store it
    final request = _fetchETAFromAPI(origin, destination, cacheKey);
    _pendingRequests[cacheKey] = request;

    try {
      final result = await request;
      return result;
    } finally {
      // Remove from pending requests
      _pendingRequests.remove(cacheKey);
    }
  }

  Future<Map<String, dynamic>> _fetchETAFromAPI(Map<String, dynamic> origin,
      Map<String, dynamic> destination, String cacheKey) async {
    try {
      // Use the new Routes API v2 for better performance and lower costs
      final uri = Uri.parse(
          'https://routes.googleapis.com/directions/v2:computeRoutes');

      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'routes.legs.duration.seconds',
      };

      final body = jsonEncode({
        'origin': {
          'location': {
            'latLng': {'latitude': origin['lat'], 'longitude': origin['lng']}
          }
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destination['lat'],
              'longitude': destination['lng']
            }
          }
        },
        'travelMode': 'DRIVE',
        'routingPreference': 'TRAFFIC_AWARE',
      });

      final resp = await http.post(uri, headers: headers, body: body);
      if (resp.statusCode != 200) {
        throw Exception('Failed to get ETA: ${resp.statusCode}');
      }

      final data = json.decode(resp.body) as Map<String, dynamic>;
      debugPrint('ETAService: API response for $cacheKey');

      // Parse response from new API format
      int seconds = _parseDurationFromNewAPI(data);

      // Cache the result
      _etaCache[cacheKey] = _CachedETA(seconds, DateTime.now());

      // Persist to SharedPreferences for longer-term caching
      await _persistETAToCache(cacheKey, seconds);

      return {'eta_seconds': seconds};
    } catch (e) {
      debugPrint('ETAService: Error fetching ETA: $e');
      // Try to return cached data even if expired
      final cached = _etaCache[cacheKey];
      if (cached != null) {
        debugPrint('ETAService: Returning expired cache due to API error');
        return {'eta_seconds': cached.etaSeconds};
      }
      rethrow;
    }
  }

  int _parseDurationFromNewAPI(Map<String, dynamic> data) {
    try {
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        throw Exception('No routes found in response');
      }

      final route = routes[0] as Map<String, dynamic>;
      final legs = route['legs'] as List<dynamic>?;
      if (legs == null || legs.isEmpty) {
        throw Exception('No legs found in route');
      }

      final leg = legs[0] as Map<String, dynamic>;
      final duration = leg['duration'] as String?;

      if (duration == null) {
        throw Exception('No duration found in leg');
      }

      // Parse duration string like "408s"
      final match = RegExp(r'^(\d+)s$').firstMatch(duration);
      if (match != null) {
        return int.parse(match.group(1)!);
      } else {
        // Fallback: extract digits only
        return int.tryParse(duration.replaceAll(RegExp(r'\D'), '')) ?? 0;
      }
    } catch (e) {
      debugPrint('ETAService: Error parsing duration: $e');
      return 0;
    }
  }

  String _createCacheKey(
      Map<String, dynamic> origin, Map<String, dynamic> destination) {
    // Round coordinates to reduce cache misses for nearby locations
    final originLat = (origin['lat'] as num).toDouble();
    final originLng = (origin['lng'] as num).toDouble();
    final destLat = (destination['lat'] as num).toDouble();
    final destLng = (destination['lng'] as num).toDouble();

    // Round to 4 decimal places (~11m precision)
    final roundedOriginLat = (originLat * 10000).round() / 10000;
    final roundedOriginLng = (originLng * 10000).round() / 10000;
    final roundedDestLat = (destLat * 10000).round() / 10000;
    final roundedDestLng = (destLng * 10000).round() / 10000;

    return 'eta_${roundedOriginLat}_${roundedOriginLng}_${roundedDestLat}_$roundedDestLng';
  }

  Future<void> _persistETAToCache(String cacheKey, int etaSeconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'eta_seconds': etaSeconds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString('eta_cache_$cacheKey', jsonEncode(cacheData));
    } catch (e) {
      debugPrint('ETAService: Failed to persist ETA cache: $e');
    }
  }

  /// Clear all cached ETA data
  static void clearCache() {
    _etaCache.clear();
    _pendingRequests.clear();
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'cached_etas': _etaCache.length,
      'pending_requests': _pendingRequests.length,
      'cache_ttl_minutes': _cacheTTL.inMinutes,
    };
  }
}
