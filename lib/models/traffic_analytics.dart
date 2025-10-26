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
  final double confidenceScore;
  final String aiInsights;

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
    required this.confidenceScore,
    required this.aiInsights,
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
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      aiInsights: json['ai_insights'] as String,
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
      'confidence_score': confidenceScore,
      'ai_insights': aiInsights,
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

class AnalyticsMetadata {
  final String routeId;
  final String date;
  final int routesCount;
  final DateTime generatedAt;
  final String mode;

  AnalyticsMetadata({
    required this.routeId,
    required this.date,
    required this.routesCount,
    required this.generatedAt,
    required this.mode,
  });

  factory AnalyticsMetadata.fromJson(Map<String, dynamic> json) {
    return AnalyticsMetadata(
      routeId: json['routeId'] as String,
      date: json['date'] as String,
      routesCount: json['routesCount'] as int,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      mode: json['mode'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routeId': routeId,
      'date': date,
      'routesCount': routesCount,
      'generatedAt': generatedAt.toIso8601String(),
      'mode': mode,
    };
  }
}

class TodayRouteTrafficResponse {
  final DateTime date;
  final List<RouteTrafficToday> routes;
  final String? mode; // "db", "fast", or "fast-fallback"
  final String? overallAiAnalysis;
  final String? aiExplanation;
  final AnalyticsMetadata? metadata;

  TodayRouteTrafficResponse({
    required this.date,
    required this.routes,
    this.mode,
    this.overallAiAnalysis,
    this.aiExplanation,
    this.metadata,
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
      overallAiAnalysis: dataMap['overall_ai_analysis'] as String?,
      aiExplanation: json['aiExplanation'] as String?,
      metadata: metadata != null ? AnalyticsMetadata.fromJson(metadata) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'date': date.toIso8601String().split('T')[0],
        'routes': routes.map((route) => route.toJson()).toList(),
        if (overallAiAnalysis != null) 'overall_ai_analysis': overallAiAnalysis,
      },
      if (aiExplanation != null) 'aiExplanation': aiExplanation,
      if (metadata != null) 'metadata': metadata!.toJson(),
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

/// AI explanation models (Manong-backed endpoints)

class AiExplainTableResponse {
  final String explanation;
  final List<Map<String, dynamic>>? samples;
  final String? mode;

  AiExplainTableResponse({
    required this.explanation,
    this.samples,
    this.mode,
  });

  static String _extractExplanation(Map<String, dynamic> json) {
    // Flexible parsing for common shapes
    // 1) { data: { explanation: "...", samples: [...] }, metadata: { mode } }
    // 2) { explanation: "...", samples: [...] }
    // 3) { message: "..." } or { text: "..." }
    if (json.containsKey('data')) {
      final data = json['data'];
      if (data is Map<String, dynamic> && data['explanation'] is String) {
        return data['explanation'] as String;
      }
    }
    if (json['explanation'] is String) {
      return json['explanation'] as String;
    }
    if (json['message'] is String) {
      return json['message'] as String;
    }
    if (json['text'] is String) {
      return json['text'] as String;
    }
    return '';
  }

  static List<Map<String, dynamic>>? _extractSamples(
      Map<String, dynamic> json) {
    List<dynamic>? raw;
    if (json.containsKey('data')) {
      final data = json['data'];
      if (data is Map<String, dynamic> && data['samples'] is List) {
        raw = data['samples'] as List<dynamic>;
      }
    }
    raw ??= json['samples'] is List ? json['samples'] as List<dynamic> : null;
    if (raw == null) return null;
    return raw
        .whereType<Map<String, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  factory AiExplainTableResponse.fromJson(Map<String, dynamic> json) {
    String? mode;
    final metadata = json['metadata'];
    if (metadata is Map<String, dynamic>) {
      mode = metadata['mode'] as String?;
    }
    return AiExplainTableResponse(
      explanation: _extractExplanation(json),
      samples: _extractSamples(json),
      mode: mode,
    );
  }
}

class AiExplainRouteItem {
  final int? routeId;
  final String routeName;
  final String summary;
  final String? peakHour;
  final String? bestTime;

  AiExplainRouteItem({
    required this.routeName,
    required this.summary,
    this.routeId,
    this.peakHour,
    this.bestTime,
  });

  factory AiExplainRouteItem.fromJson(Map<String, dynamic> json) {
    // Accept various key casings: route_id / routeId, peak_hour / peakHour, etc.
    int? rid;
    final ridVal =
        json.containsKey('route_id') ? json['route_id'] : json['routeId'];
    if (ridVal is int) rid = ridVal;
    if (ridVal is String) {
      final parsed = int.tryParse(ridVal);
      if (parsed != null) rid = parsed;
    }

    final rn = (json['route_name'] ?? json['routeName'] ?? '') as String;
    final sum = (json['summary'] ?? json['explanation'] ?? json['text'] ?? '')
        as String;
    final ph = (json['peak_hour'] ?? json['peakHour']) as String?;
    final bt = (json['best_time'] ?? json['bestTime']) as String?;

    return AiExplainRouteItem(
      routeId: rid,
      routeName: rn,
      summary: sum,
      peakHour: ph,
      bestTime: bt,
    );
  }
}

class AiExplainRoutesResponse {
  final List<AiExplainRouteItem> routes;
  final String? preface;
  final String? mode;

  AiExplainRoutesResponse({
    required this.routes,
    this.preface,
    this.mode,
  });

  factory AiExplainRoutesResponse.fromJson(Map<String, dynamic> json) {
    // Shapes handled:
    // { data: { routes: [ {...} ], preface: "..." }, metadata: { mode } }
    // { routes: [ {...} ] }
    List<dynamic>? rawRoutes;
    String? preface;
    String? mode;

    if (json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;
      if (data['routes'] is List) rawRoutes = data['routes'] as List<dynamic>;
      if (data['preface'] is String) preface = data['preface'] as String;
    }

    rawRoutes ??=
        json['routes'] is List ? json['routes'] as List<dynamic> : null;

    if (json['metadata'] is Map<String, dynamic>) {
      mode = (json['metadata'] as Map<String, dynamic>)['mode'] as String?;
    }

    final items = (rawRoutes ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((e) => AiExplainRouteItem.fromJson(e))
        .toList();

    return AiExplainRoutesResponse(
      routes: items,
      preface: preface,
      mode: mode,
    );
  }
}
