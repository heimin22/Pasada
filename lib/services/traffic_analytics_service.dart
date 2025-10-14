import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pasada_passenger_app/models/traffic_analytics.dart';
import 'package:pasada_passenger_app/network/networkUtilities.dart';

/// Cache entry model for storing traffic analytics with timestamp
class _CachedTrafficAnalytics {
  final TodayRouteTrafficResponse data;
  final DateTime timestamp;

  _CachedTrafficAnalytics(this.data, this.timestamp);

  /// Check if the cache entry is still valid based on TTL
  bool isValid(Duration ttl) {
    return DateTime.now().difference(timestamp) < ttl;
  }
}

/// Service for fetching today's route traffic analytics from the backend
class TrafficAnalyticsService {
  static final TrafficAnalyticsService _instance =
      TrafficAnalyticsService._internal();

  factory TrafficAnalyticsService() {
    return _instance;
  }

  TrafficAnalyticsService._internal();

  // Cache storage: key is routeId (null for all routes)
  final Map<int?, _CachedTrafficAnalytics> _cache = {};

  // Cache time-to-live: 5 minutes (traffic data updates frequently)
  static const Duration _cacheTTL = Duration(minutes: 5);
  static const Duration _backgroundTimeout = Duration(seconds: 10);

  /// Get the current cache TTL
  Duration get cacheTTL => _cacheTTL;

  /// Fetch today's traffic analytics for all routes
  ///
  /// If [forceRefresh] is true, bypasses cache and fetches fresh data
  /// If [routeId] is provided, fetches data for specific route only
  Future<TodayRouteTrafficResponse?> getTodayTrafficAnalytics({
    int? routeId,
    bool forceRefresh = false,
    bool fast = false,
    Duration? timeout,
  }) async {
    // Check cache first if not forcing refresh
    if (!forceRefresh) {
      final cachedEntry = _cache[routeId];
      if (cachedEntry != null && cachedEntry.isValid(_cacheTTL)) {
        debugPrint(
            'TrafficAnalyticsService: Returning cached data for ${routeId ?? "all routes"}');
        return cachedEntry.data;
      }
    }

    try {
      final String? analyticsApiUrl = dotenv.env['ANALYTICS_API_URL'];
      if (analyticsApiUrl == null || analyticsApiUrl.isEmpty) {
        debugPrint('TrafficAnalyticsService: ANALYTICS_API_URL not configured');
        return null;
      }

      // Always use the all-routes endpoint as per new analytics API usage
      // Support optional fast mode via query param (?fast=1)
      final endpointBase = '$analyticsApiUrl/api/analytics/traffic/today';
      final endpoint = fast ? '$endpointBase?fast=1' : endpointBase;

      final uri = Uri.parse(endpoint);
      final headers = {
        'Content-Type': 'application/json',
      };

      debugPrint('TrafficAnalyticsService: Fetching from $endpoint');

      String? response;
      try {
        // Default timeouts: foreground 8s if not specified; fast mode 6s
        final effectiveTimeout = timeout ?? Duration(seconds: fast ? 6 : 8);
        response = await NetworkUtility.fetchUrlWithTimeout(
          uri,
          headers: headers,
          timeout: effectiveTimeout,
        );
      } on TimeoutException {
        // If normal mode times out, immediately retry with fast mode
        if (!fast) {
          debugPrint(
              'TrafficAnalyticsService: Timed out. Retrying with fast=1');
          final fastUri = Uri.parse('$endpointBase?fast=1');
          response = await NetworkUtility.fetchUrlWithTimeout(
            fastUri,
            headers: headers,
            timeout: Duration(seconds: 6),
          );
        } else {
          rethrow;
        }
      }

      if (response == null) {
        debugPrint('TrafficAnalyticsService: No response from server');
        return null;
      }

      final dynamic data = json.decode(response);

      if (data is Map<String, dynamic>) {
        final trafficResponse = TodayRouteTrafficResponse.fromJson(data);
        debugPrint(
            'TrafficAnalyticsService: Successfully fetched ${trafficResponse.routes.length} routes');

        // Cache the response
        _cache[routeId] =
            _CachedTrafficAnalytics(trafficResponse, DateTime.now());
        debugPrint(
            'TrafficAnalyticsService: Cached data for ${routeId ?? "all routes"}');

        // If served from fast or fast-fallback, refresh in background (db)
        if (trafficResponse.mode == 'fast' ||
            trafficResponse.mode == 'fast-fallback') {
          _refreshInBackground(endpointBase,
              headers: headers, routeId: routeId);
        }

        return trafficResponse;
      } else {
        debugPrint(
            'TrafficAnalyticsService: Unexpected response format: ${data.runtimeType}');
        return null;
      }
    } catch (e) {
      debugPrint('TrafficAnalyticsService: Error fetching analytics: $e');
      return null;
    }
  }

  void _refreshInBackground(String endpointBase,
      {required Map<String, String> headers, int? routeId}) async {
    unawaited(() async {
      try {
        final uri = Uri.parse(endpointBase);
        final response = await NetworkUtility.fetchUrlWithTimeout(
          uri,
          headers: headers,
          timeout: _backgroundTimeout,
        );
        if (response == null) return;
        final data = json.decode(response);
        if (data is! Map<String, dynamic>) return;
        final fresh = TodayRouteTrafficResponse.fromJson(data);
        // Only overwrite cache on success
        _cache[routeId] = _CachedTrafficAnalytics(fresh, DateTime.now());
        debugPrint('TrafficAnalyticsService: Background cache refreshed');
      } catch (e) {
        debugPrint('TrafficAnalyticsService: Background refresh failed: $e');
      }
    }());
  }

  /// Fetch traffic analytics for a specific route by ID
  ///
  /// If [forceRefresh] is true, bypasses cache and fetches fresh data
  Future<RouteTrafficToday?> getRouteTrafficById(
    int routeId, {
    bool forceRefresh = false,
  }) async {
    final response = await getTodayTrafficAnalytics(
      routeId: routeId,
      forceRefresh: forceRefresh,
    );
    if (response != null && response.routes.isNotEmpty) {
      return response.routes.first;
    }
    return null;
  }

  /// Fetch traffic analytics for a specific route by name
  ///
  /// If [forceRefresh] is true, bypasses cache and fetches fresh data
  Future<RouteTrafficToday?> getRouteTrafficByName(
    String routeName, {
    bool forceRefresh = false,
  }) async {
    final response = await getTodayTrafficAnalytics(forceRefresh: forceRefresh);
    return response?.getRouteByName(routeName);
  }

  /// Check if a route has heavy traffic (high or severe status)
  ///
  /// If [forceRefresh] is true, bypasses cache and fetches fresh data
  Future<bool> isRouteHeavyTraffic(
    int routeId, {
    bool forceRefresh = false,
  }) async {
    final routeData = await getRouteTrafficById(
      routeId,
      forceRefresh: forceRefresh,
    );
    if (routeData == null) return false;

    return routeData.currentStatus == TrafficStatus.high ||
        routeData.currentStatus == TrafficStatus.severe;
  }

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
    debugPrint('TrafficAnalyticsService: Cache cleared');
  }

  /// Clear cached data for a specific route
  void clearRouteCache(int? routeId) {
    _cache.remove(routeId);
    debugPrint(
        'TrafficAnalyticsService: Cache cleared for ${routeId ?? "all routes"}');
  }

  /// Check if cached data exists and is still valid
  bool hasCachedData({int? routeId}) {
    final cachedEntry = _cache[routeId];
    return cachedEntry != null && cachedEntry.isValid(_cacheTTL);
  }

  /// Get the timestamp of cached data if it exists
  DateTime? getCacheTimestamp({int? routeId}) {
    return _cache[routeId]?.timestamp;
  }

  /// Get time remaining until cache expires
  Duration? getCacheTimeRemaining({int? routeId}) {
    final cachedEntry = _cache[routeId];
    if (cachedEntry == null) return null;

    final elapsed = DateTime.now().difference(cachedEntry.timestamp);
    final remaining = _cacheTTL - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get traffic status color for UI display
  static int getStatusColor(TrafficStatus status) {
    switch (status) {
      case TrafficStatus.low:
        return 0xFF00CC58; // Green
      case TrafficStatus.moderate:
        return 0xFFFF9800; // Orange
      case TrafficStatus.high:
        return 0xFFFF5722; // Red
      case TrafficStatus.severe:
        return 0xFFD32F2F; // Dark Red
    }
  }
}
