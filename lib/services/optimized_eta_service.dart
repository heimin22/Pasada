import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
// Removed unused foundation import
import 'package:pasada_passenger_app/utils/app_logger.dart';

import 'roads_api_service.dart';

// Cache entry for ETA results
class _CachedOptimizedETA {
  final int etaSeconds;
  final DateTime timestamp;
  final String bookingStatus;

  _CachedOptimizedETA(this.etaSeconds, this.timestamp, this.bookingStatus);

  bool isValid(Duration ttl) {
    return DateTime.now().difference(timestamp) < ttl;
  }
}

/// Optimized ETA service that uses Roads API for accepted/ongoing rides
/// and Directions API for other cases to reduce costs
class OptimizedETAService {
  static final OptimizedETAService _instance = OptimizedETAService._internal();

  factory OptimizedETAService() => _instance;

  OptimizedETAService._internal();

  final String _apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;
  final RoadsApiService _roadsService = RoadsApiService();

  // In-memory cache for ETA results
  static final Map<String, _CachedOptimizedETA> _etaCache = {};

  // Cache TTL: 3 minutes for ETA data (shorter for active rides)
  static const Duration _cacheTTL = Duration(minutes: 3);

  // Request deduplication - prevent multiple identical requests
  static final Map<String, Future<Map<String, dynamic>>> _pendingRequests = {};

  /// Compute ETA with optimized API usage based on booking status
  Future<Map<String, dynamic>> getETA({
    required Map<String, dynamic> origin,
    required Map<String, dynamic> destination,
    String bookingStatus = 'requested', // Default to requested for new bookings
    LatLng?
        driverLocation, // Current driver location for accepted/ongoing rides
  }) async {
    // Create cache key with booking status
    final cacheKey = _createCacheKey(origin, destination, bookingStatus);

    // Check cache first
    final cached = _etaCache[cacheKey];
    if (cached != null && cached.isValid(_cacheTTL)) {
      AppLogger.debug('Returning cached ETA for $cacheKey',
          tag: 'ETA', throttle: true);
      return {'eta_seconds': cached.etaSeconds};
    }

    // Check if there's already a pending request for this route
    if (_pendingRequests.containsKey(cacheKey)) {
      AppLogger.debug('Waiting for pending request $cacheKey', tag: 'ETA');
      return await _pendingRequests[cacheKey]!;
    }

    // Create new request and store it
    final request = _fetchETAWithOptimizedAPI(
        origin, destination, bookingStatus, driverLocation, cacheKey);
    _pendingRequests[cacheKey] = request;

    try {
      final result = await request;
      return result;
    } finally {
      // Remove from pending requests
      _pendingRequests.remove(cacheKey);
    }
  }

  Future<Map<String, dynamic>> _fetchETAWithOptimizedAPI(
      Map<String, dynamic> origin,
      Map<String, dynamic> destination,
      String bookingStatus,
      LatLng? driverLocation,
      String cacheKey) async {
    try {
      // Use Roads API for accepted/ongoing rides with driver location
      if ((bookingStatus == 'accepted' || bookingStatus == 'ongoing') &&
          driverLocation != null) {
        return await _getETAWithRoadsAPI(
            origin, destination, driverLocation, cacheKey);
      }

      // Use optimized Directions API for other cases
      return await _getETAWithDirectionsAPI(origin, destination, cacheKey);
    } catch (e) {
      AppLogger.warn('Error fetching ETA: $e', tag: 'ETA');
      // Try to return cached data even if expired
      final cached = _etaCache[cacheKey];
      if (cached != null) {
        AppLogger.debug('Returning expired cache due to API error', tag: 'ETA');
        return {'eta_seconds': cached.etaSeconds};
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getETAWithRoadsAPI(
      Map<String, dynamic> origin,
      Map<String, dynamic> destination,
      LatLng driverLocation,
      String cacheKey) async {
    try {
      // Snap driver location to road for more accurate tracking
      final snappedDriverLocation =
          await _roadsService.snapToRoad(driverLocation);
      final actualDriverLocation = snappedDriverLocation ?? driverLocation;

      // Use Roads API to get speed limits and road conditions
      final speedLimits =
          await _roadsService.getSpeedLimits([actualDriverLocation]);

      // Calculate distance using Haversine formula (more efficient than API call)
      final distance = _calculateDistance(
        actualDriverLocation.latitude,
        actualDriverLocation.longitude,
        destination['lat'] as double,
        destination['lng'] as double,
      );

      // Estimate ETA based on distance and typical speeds
      // Use speed limits if available, otherwise use default speeds
      double avgSpeedKmh = 30.0; // Default speed in km/h

      if (speedLimits != null && speedLimits['speedLimits'] != null) {
        final speedLimitData = speedLimits['speedLimits'] as List<dynamic>;
        if (speedLimitData.isNotEmpty) {
          final speedLimit = speedLimitData.first['speedLimit'] as int?;
          if (speedLimit != null) {
            // Use 80% of speed limit as realistic average speed
            avgSpeedKmh = speedLimit * 0.8;
          }
        }
      }

      // Calculate ETA in seconds
      final etaHours = distance / avgSpeedKmh;
      final etaSeconds = (etaHours * 3600).round();

      // Cache the result
      _etaCache[cacheKey] =
          _CachedOptimizedETA(etaSeconds, DateTime.now(), 'accepted');

      AppLogger.debug(
          'ETA via Roads: ${etaSeconds}s ${distance.toStringAsFixed(2)}km @ ${avgSpeedKmh.toStringAsFixed(1)}km/h',
          tag: 'ETA',
          throttle: true);

      return {'eta_seconds': etaSeconds};
    } catch (e) {
      AppLogger.warn('Roads API calculation error: $e', tag: 'ETA');
      // Fallback to Directions API
      return await _getETAWithDirectionsAPI(origin, destination, cacheKey);
    }
  }

  Future<Map<String, dynamic>> _getETAWithDirectionsAPI(
      Map<String, dynamic> origin,
      Map<String, dynamic> destination,
      String cacheKey) async {
    try {
      // Use the new Routes API v2 for better performance and lower costs
      final uri = Uri.parse(
          'https://routes.googleapis.com/directions/v2:computeRoutes');

      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
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
      AppLogger.debug('Directions API response for $cacheKey', tag: 'ETA');

      // Parse response from new API format
      int seconds = _parseDurationFromNewAPI(data);

      // Cache the result
      _etaCache[cacheKey] =
          _CachedOptimizedETA(seconds, DateTime.now(), 'requested');

      return {'eta_seconds': seconds};
    } catch (e) {
      AppLogger.warn('Directions API error: $e', tag: 'ETA');
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
      AppLogger.warn('Error parsing duration: $e', tag: 'ETA');
      return 0;
    }
  }

  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double R = 6371; // Earth's radius in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    final double c = 2 * asin(sqrt(a));

    return R * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  String _createCacheKey(Map<String, dynamic> origin,
      Map<String, dynamic> destination, String bookingStatus) {
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

    return 'optimized_eta_${roundedOriginLat}_${roundedOriginLng}_${roundedDestLat}_${roundedDestLng}_$bookingStatus';
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
