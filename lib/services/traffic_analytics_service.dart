import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pasada_passenger_app/models/traffic_analytics.dart';
import 'package:pasada_passenger_app/network/networkUtilities.dart';

/// Service for fetching today's route traffic analytics from the backend
class TrafficAnalyticsService {
  static final TrafficAnalyticsService _instance =
      TrafficAnalyticsService._internal();

  factory TrafficAnalyticsService() {
    return _instance;
  }

  TrafficAnalyticsService._internal();

  /// Fetch today's traffic analytics for all routes
  Future<TodayRouteTrafficResponse?> getTodayTrafficAnalytics({
    int? routeId,
  }) async {
    try {
      final String? apiUrl = dotenv.env['API_URL'];
      if (apiUrl == null || apiUrl.isEmpty) {
        debugPrint('TrafficAnalyticsService: API_URL not configured');
        return null;
      }

      // Build the endpoint URL with optional route ID
      final endpoint = routeId != null
          ? '$apiUrl/api/analytics/traffic/today/$routeId'
          : '$apiUrl/api/analytics/traffic/today';

      final uri = Uri.parse(endpoint);
      final headers = {
        'Content-Type': 'application/json',
      };

      debugPrint('TrafficAnalyticsService: Fetching from $endpoint');

      final response = await NetworkUtility.fetchUrl(uri, headers: headers);

      if (response == null) {
        debugPrint('TrafficAnalyticsService: No response from server');
        return null;
      }

      final dynamic data = json.decode(response);

      if (data is Map<String, dynamic>) {
        final trafficResponse = TodayRouteTrafficResponse.fromJson(data);
        debugPrint(
            'TrafficAnalyticsService: Successfully fetched ${trafficResponse.routes.length} routes');
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

  /// Fetch traffic analytics for a specific route by ID
  Future<RouteTrafficToday?> getRouteTrafficById(int routeId) async {
    final response = await getTodayTrafficAnalytics(routeId: routeId);
    if (response != null && response.routes.isNotEmpty) {
      return response.routes.first;
    }
    return null;
  }

  /// Fetch traffic analytics for a specific route by name
  Future<RouteTrafficToday?> getRouteTrafficByName(String routeName) async {
    final response = await getTodayTrafficAnalytics();
    return response?.getRouteByName(routeName);
  }

  /// Check if a route has heavy traffic (high or severe status)
  Future<bool> isRouteHeavyTraffic(int routeId) async {
    final routeData = await getRouteTrafficById(routeId);
    if (routeData == null) return false;

    return routeData.currentStatus == TrafficStatus.high ||
        routeData.currentStatus == TrafficStatus.severe;
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
