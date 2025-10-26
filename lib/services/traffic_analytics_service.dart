import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pasada_passenger_app/models/traffic_analytics.dart';
import 'package:pasada_passenger_app/network/networkUtilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// Generic cache entry for AI responses
class _CachedAny {
  final Object data;
  final DateTime timestamp;

  _CachedAny(this.data, this.timestamp);

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

  // AI response caches (simple in-memory)
  final Map<String, _CachedAny> _aiExplainTableCache = {};
  final Map<String, _CachedAny> _aiExplainRoutesCache = {};

  // Persist last known human-friendly names per routeId to avoid regressions
  final Map<int, String> _lastKnownRouteNames = {};

  // Cache time-to-live: 5 minutes (traffic data updates frequently)
  static const Duration _cacheTTL = Duration(minutes: 5);
  // No client-side timeout for analytics endpoints; we prefer fresh results
  static const String _prefsDailyCacheKey = 'traffic_analytics_daily_cache_v1';

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
    // 1) Try persisted daily cache (only for all routes)
    if (!forceRefresh && routeId == null) {
      final persisted = await _readDailyCache();
      if (persisted != null && _isSameDay(persisted.date, DateTime.now())) {
        debugPrint('TrafficAnalyticsService: Returning persisted daily cache');
        _cache[null] = _CachedTrafficAnalytics(persisted, DateTime.now());
        return persisted;
      }
    }

    // 2) Fallback to in-memory short TTL cache
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

      // Build endpoint with routeId parameter and query parameters
      final endpointBase = '$analyticsApiUrl/api/analytics/traffic/today';
      final endpoint =
          routeId != null ? '$endpointBase/$routeId' : endpointBase;

      final queryParams = <String, String>{};
      if (fast) {
        queryParams['fast'] = '1';
        queryParams['mode'] = 'fast';
      }

      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
      final headers = {
        'Content-Type': 'application/json',
      };

      debugPrint('TrafficAnalyticsService: Fetching from $uri');

      final String? response = await NetworkUtility.fetchUrl(
        uri,
        headers: headers,
      );

      if (response == null) {
        debugPrint('TrafficAnalyticsService: No response from server');
        return null;
      }

      final dynamic responseData = json.decode(response);

      if (responseData is Map<String, dynamic>) {
        // Check if response has success field (new API format)
        if (responseData.containsKey('success') &&
            responseData.containsKey('data')) {
          final success = responseData['success'] as bool;
          if (!success) {
            debugPrint('TrafficAnalyticsService: API returned success=false');
            return null;
          }
          final parsed = TodayRouteTrafficResponse.fromJson(responseData);
          final trafficResponse = _stabilizeRouteNames(parsed);
          debugPrint(
              'TrafficAnalyticsService: Successfully fetched ${trafficResponse.routes.length} routes');

          // Cache the response
          _cache[routeId] =
              _CachedTrafficAnalytics(trafficResponse, DateTime.now());
          debugPrint(
              'TrafficAnalyticsService: Cached data for ${routeId ?? "all routes"}');

          // Persist for the day (all routes only)
          if (routeId == null &&
              _isSameDay(trafficResponse.date, DateTime.now())) {
            await _writeDailyCache(trafficResponse);
          }

          // Optionally refresh in background (db) if server indicates mode,
          // but we will still run background refresh to ensure freshness.
          _refreshInBackground(endpointBase,
              headers: headers, routeId: routeId);

          return trafficResponse;
        } else {
          // Fallback to old format for backward compatibility
          final parsed = TodayRouteTrafficResponse.fromJson(responseData);
          final trafficResponse = _stabilizeRouteNames(parsed);
          debugPrint(
              'TrafficAnalyticsService: Successfully fetched ${trafficResponse.routes.length} routes (legacy format)');

          // Cache the response
          _cache[routeId] =
              _CachedTrafficAnalytics(trafficResponse, DateTime.now());
          debugPrint(
              'TrafficAnalyticsService: Cached data for ${routeId ?? "all routes"}');

          // Persist for the day (all routes only)
          if (routeId == null &&
              _isSameDay(trafficResponse.date, DateTime.now())) {
            await _writeDailyCache(trafficResponse);
          }

          // Optionally refresh in background (db) if server indicates mode,
          // but we will still run background refresh to ensure freshness.
          _refreshInBackground(endpointBase,
              headers: headers, routeId: routeId);

          return trafficResponse;
        }
      } else {
        debugPrint(
            'TrafficAnalyticsService: Unexpected response format: ${responseData.runtimeType}');
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
        // Build endpoint with routeId parameter
        final endpoint =
            routeId != null ? '$endpointBase/$routeId' : endpointBase;
        final uri = Uri.parse(endpoint);
        final response = await NetworkUtility.fetchUrl(
          uri,
          headers: headers,
        );
        if (response == null) return;
        final responseData = json.decode(response);
        if (responseData is! Map<String, dynamic>) return;

        // Handle new API format with success/data wrapper
        if (responseData.containsKey('success') &&
            responseData.containsKey('data')) {
          final success = responseData['success'] as bool;
          if (!success) return;
        }

        final parsed = TodayRouteTrafficResponse.fromJson(responseData);
        final fresh = _stabilizeRouteNames(parsed);
        // Only overwrite cache on success
        _cache[routeId] = _CachedTrafficAnalytics(fresh, DateTime.now());
        debugPrint('TrafficAnalyticsService: Background cache refreshed');

        if (routeId == null && _isSameDay(fresh.date, DateTime.now())) {
          await _writeDailyCache(fresh);
        }
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

  // -------------------- Daily persistence helpers --------------------

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<TodayRouteTrafficResponse?> _readDailyCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsDailyCacheKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final model = TodayRouteTrafficResponse.fromJson(decoded);
      return _stabilizeRouteNames(model);
    } catch (e) {
      debugPrint('TrafficAnalyticsService: Failed to read daily cache: $e');
      return null;
    }
  }

  Future<void> _writeDailyCache(TodayRouteTrafficResponse response) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = json.encode(response.toJson());
      await prefs.setString(_prefsDailyCacheKey, raw);
    } catch (e) {
      debugPrint('TrafficAnalyticsService: Failed to write daily cache: $e');
    }
  }

  // -------------------- AI Explanation Endpoints --------------------

  /// Stabilize route names using last known friendly names when backend returns
  /// generic placeholders like "Route 1". Also record new good names.
  TodayRouteTrafficResponse _stabilizeRouteNames(
      TodayRouteTrafficResponse input) {
    final List<RouteTrafficToday> updated = [];
    for (final route in input.routes) {
      final isGeneric = _looksGenericRouteName(route.routeName);
      final lastKnown = _lastKnownRouteNames[route.routeId];

      // Only use last known name if current name is generic AND last known name is not generic
      final effectiveName =
          isGeneric && lastKnown != null && !_looksGenericRouteName(lastKnown)
              ? lastKnown
              : route.routeName;

      // If name looks non-generic, remember it
      if (!_looksGenericRouteName(effectiveName)) {
        _lastKnownRouteNames[route.routeId] = effectiveName;
      }

      if (effectiveName == route.routeName) {
        updated.add(route);
      } else {
        updated.add(RouteTrafficToday(
          routeId: route.routeId,
          routeName: effectiveName,
          currentStatus: route.currentStatus,
          avgTrafficDensity: route.avgTrafficDensity,
          avgSpeedKmh: route.avgSpeedKmh,
          latestUpdate: route.latestUpdate,
          totalMeasurements: route.totalMeasurements,
          peakTrafficTime: route.peakTrafficTime,
          hourlyBreakdown: route.hourlyBreakdown,
          confidenceScore: route.confidenceScore,
          aiInsights: route.aiInsights,
        ));
      }
    }

    return TodayRouteTrafficResponse(
      date: input.date,
      routes: updated,
      mode: input.mode,
    );
  }

  bool _looksGenericRouteName(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    if (normalized.startsWith('route ')) return true;
    if (RegExp(r'^route\s*\d+$').hasMatch(normalized)) return true;
    return false;
  }

  /// Explain the traffic analytics table; optionally filter by [routeId].
  /// Uses last [days] (default 7). Set [includeExamples] to true to include sample rows.
  Future<AiExplainTableResponse?> explainTrafficTable({
    int? routeId,
    int days = 7,
    bool includeExamples = false,
    Duration? timeout,
  }) async {
    try {
      final String? analyticsApiUrl = dotenv.env['ANALYTICS_API_URL'];
      if (analyticsApiUrl == null || analyticsApiUrl.isEmpty) {
        debugPrint('TrafficAnalyticsService: ANALYTICS_API_URL not configured');
        return null;
      }

      // Build endpoint and query
      final base = '$analyticsApiUrl/api/ai/traffic/explain-table';
      final queryParams = <String, String>{
        'days': days.toString(),
      };
      if (routeId != null) queryParams['routeId'] = routeId.toString();
      if (includeExamples) queryParams['includeExamples'] = '1';
      final uri = Uri.parse(base).replace(queryParameters: queryParams);

      final cacheKey = uri.toString();
      // Reuse traffic cache wrapper to hold timestamps generically
      final cached = _aiExplainTableCache[cacheKey];
      if (cached != null && cached.isValid(_cacheTTL)) {
        final cachedData = cached.data;
        if (cachedData is AiExplainTableResponse) return cachedData;
      }

      final headers = {
        'Content-Type': 'application/json',
      };
      final effectiveTimeout = timeout ?? Duration(seconds: 12);
      debugPrint('TrafficAnalyticsService: AI explain-table GET $uri');
      final response = await NetworkUtility.fetchUrlWithTimeout(
        uri,
        headers: headers,
        timeout: effectiveTimeout,
      );
      if (response == null) return null;
      final decoded = json.decode(response);
      if (decoded is! Map<String, dynamic>) return null;
      final ai = AiExplainTableResponse.fromJson(decoded);
      _aiExplainTableCache[cacheKey] = _CachedAny(ai, DateTime.now());
      // Immediately return the parsed AI model instead of the wrapper
      return ai;
    } catch (e) {
      debugPrint('TrafficAnalyticsService: Error in explainTrafficTable: $e');
      return null;
    }
  }

  /// Get friendly, per-route summaries including peak hour and best-time tip.
  /// Uses last [days] (default 7) and limits to [maxRoutes] (default 20).
  Future<AiExplainRoutesResponse?> explainTrafficRoutes({
    int days = 7,
    int maxRoutes = 20,
    Duration? timeout,
  }) async {
    try {
      final String? analyticsApiUrl = dotenv.env['ANALYTICS_API_URL'];
      if (analyticsApiUrl == null || analyticsApiUrl.isEmpty) {
        debugPrint('TrafficAnalyticsService: ANALYTICS_API_URL not configured');
        return null;
      }

      final base = '$analyticsApiUrl/api/ai/traffic/explain-routes';
      final queryParams = <String, String>{
        'days': days.toString(),
        'maxRoutes': maxRoutes.toString(),
      };
      final uri = Uri.parse(base).replace(queryParameters: queryParams);

      final cacheKey = uri.toString();
      final cached = _aiExplainRoutesCache[cacheKey];
      if (cached != null && cached.isValid(_cacheTTL)) {
        final cachedData = cached.data;
        if (cachedData is AiExplainRoutesResponse) return cachedData;
      }

      final headers = {
        'Content-Type': 'application/json',
      };
      final effectiveTimeout = timeout ?? Duration(seconds: 12);
      debugPrint('TrafficAnalyticsService: AI explain-routes GET $uri');
      final response = await NetworkUtility.fetchUrlWithTimeout(
        uri,
        headers: headers,
        timeout: effectiveTimeout,
      );
      if (response == null) return null;
      final decoded = json.decode(response);
      if (decoded is! Map<String, dynamic>) return null;
      final ai = AiExplainRoutesResponse.fromJson(decoded);
      _aiExplainRoutesCache[cacheKey] = _CachedAny(ai, DateTime.now());
      return ai;
    } catch (e) {
      debugPrint('TrafficAnalyticsService: Error in explainTrafficRoutes: $e');
      return null;
    }
  }

  /// Clear AI explanation caches
  void clearAiExplanationCaches() {
    _aiExplainTableCache.clear();
    _aiExplainRoutesCache.clear();
  }

  /// Clear all caches including route names
  void clearAllCaches() {
    _cache.clear();
    _aiExplainTableCache.clear();
    _aiExplainRoutesCache.clear();
    _lastKnownRouteNames.clear();
  }
}
