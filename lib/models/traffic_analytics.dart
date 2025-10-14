/// Models for Today's Route Traffic Analytics API
library;

class HourlyBreakdown {
  final int hour;
  final double avgDensity;
  final double avgSpeedKmh;
  final int samples;

  HourlyBreakdown({
    required this.hour,
    required this.avgDensity,
    required this.avgSpeedKmh,
    required this.samples,
  });

  factory HourlyBreakdown.fromJson(Map<String, dynamic> json) {
    return HourlyBreakdown(
      hour: json['hour'] as int,
      avgDensity: (json['avg_density'] as num).toDouble(),
      avgSpeedKmh: (json['avg_speed_kmh'] as num).toDouble(),
      samples: json['samples'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'avg_density': avgDensity,
      'avg_speed_kmh': avgSpeedKmh,
      'samples': samples,
    };
  }
}

enum TrafficStatus {
  low,
  moderate,
  high,
  severe;

  static TrafficStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'low':
        return TrafficStatus.low;
      case 'moderate':
        return TrafficStatus.moderate;
      case 'high':
        return TrafficStatus.high;
      case 'severe':
        return TrafficStatus.severe;
      default:
        return TrafficStatus.low;
    }
  }

  String get displayName {
    switch (this) {
      case TrafficStatus.low:
        return 'Light';
      case TrafficStatus.moderate:
        return 'Moderate';
      case TrafficStatus.high:
        return 'Heavy';
      case TrafficStatus.severe:
        return 'Severe';
    }
  }
}

class RouteTrafficToday {
  final int routeId;
  final String routeName;
  final TrafficStatus currentStatus;
  final double avgTrafficDensity;
  final double avgSpeedKmh;
  final DateTime latestUpdate;
  final int totalMeasurements;
  final String peakTrafficTime;
  final List<HourlyBreakdown> hourlyBreakdown;

  RouteTrafficToday({
    required this.routeId,
    required this.routeName,
    required this.currentStatus,
    required this.avgTrafficDensity,
    required this.avgSpeedKmh,
    required this.latestUpdate,
    required this.totalMeasurements,
    required this.peakTrafficTime,
    required this.hourlyBreakdown,
  });

  factory RouteTrafficToday.fromJson(Map<String, dynamic> json) {
    return RouteTrafficToday(
      routeId: json['route_id'] as int,
      routeName: json['route_name'] as String,
      currentStatus: TrafficStatus.fromString(json['current_status'] as String),
      avgTrafficDensity: (json['avg_traffic_density'] as num).toDouble(),
      avgSpeedKmh: (json['avg_speed_kmh'] as num).toDouble(),
      latestUpdate: DateTime.parse(json['latest_update'] as String),
      totalMeasurements: json['total_measurements'] as int,
      peakTrafficTime: json['peak_traffic_time'] as String,
      hourlyBreakdown: (json['hourly_breakdown'] as List<dynamic>)
          .map((item) => HourlyBreakdown.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_id': routeId,
      'route_name': routeName,
      'current_status': currentStatus.name,
      'avg_traffic_density': avgTrafficDensity,
      'avg_speed_kmh': avgSpeedKmh,
      'latest_update': latestUpdate.toIso8601String(),
      'total_measurements': totalMeasurements,
      'peak_traffic_time': peakTrafficTime,
      'hourly_breakdown': hourlyBreakdown.map((item) => item.toJson()).toList(),
    };
  }

  /// Get density as percentage (0-100)
  int get densityPercentage => (avgTrafficDensity * 100).round();

  /// Get a human-readable summary of the traffic conditions
  String get summary {
    final speedText = avgSpeedKmh >= 50
        ? 'moving smoothly'
        : avgSpeedKmh >= 30
            ? 'moving moderately'
            : 'moving slowly';

    return '${currentStatus.displayName} traffic ($densityPercentage%). '
        'Average speed ${avgSpeedKmh.toStringAsFixed(1)} km/h, $speedText. '
        'Peak traffic expected at $peakTrafficTime.';
  }
}

class TodayRouteTrafficResponse {
  final DateTime date;
  final List<RouteTrafficToday> routes;
  final String? mode; // "db", "fast", or "fast-fallback"

  TodayRouteTrafficResponse({
    required this.date,
    required this.routes,
    this.mode,
  });

  factory TodayRouteTrafficResponse.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] as Map<String, dynamic>;
    final metadata = json['metadata'] as Map<String, dynamic>?;

    return TodayRouteTrafficResponse(
      date: DateTime.parse(dataMap['date'] as String),
      routes: (dataMap['routes'] as List<dynamic>)
          .map((item) =>
              RouteTrafficToday.fromJson(item as Map<String, dynamic>))
          .toList(),
      mode: metadata != null ? metadata['mode'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'date': date.toIso8601String().split('T')[0],
        'routes': routes.map((route) => route.toJson()).toList(),
      },
      if (mode != null) 'metadata': {'mode': mode},
    };
  }

  /// Get traffic data for a specific route by ID
  RouteTrafficToday? getRouteById(int routeId) {
    try {
      return routes.firstWhere((route) => route.routeId == routeId);
    } catch (e) {
      return null;
    }
  }

  /// Get traffic data for a specific route by name
  RouteTrafficToday? getRouteByName(String routeName) {
    try {
      return routes.firstWhere(
        (route) => route.routeName.toLowerCase() == routeName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
