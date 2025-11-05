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
    try {
      return HourlyBreakdown(
        hour: json['hour'] as int? ?? 0,
        avgDensity: (json['avg_density'] as num?)?.toDouble() ?? 0.0,
        avgSpeedKmh: (json['avg_speed_kmh'] as num?)?.toDouble() ?? 0.0,
        samples: json['samples'] as int? ?? 0,
      );
    } catch (e) {
      // Return default if parsing fails
      return HourlyBreakdown(
        hour: 0,
        avgDensity: 0.0,
        avgSpeedKmh: 0.0,
        samples: 0,
      );
    }
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
    try {
      final now = DateTime.now();
      return RouteTrafficToday(
        routeId: json['route_id'] as int? ?? 0,
        routeName: (json['route_name'] as String?) ?? '',
        currentStatus: TrafficStatus.fromString(
            (json['current_status'] as String?) ?? 'low'),
        avgTrafficDensity:
            (json['avg_traffic_density'] as num?)?.toDouble() ?? 0.0,
        avgSpeedKmh: (json['avg_speed_kmh'] as num?)?.toDouble() ?? 0.0,
        latestUpdate: _parseDateTime(json['latest_update'] as String?, now),
        totalMeasurements: json['total_measurements'] as int? ?? 0,
        peakTrafficTime: (json['peak_traffic_time'] as String?) ?? '',
        hourlyBreakdown: _parseHourlyBreakdown(json['hourly_breakdown']),
        confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
        aiInsights: (json['ai_insights'] as String?) ?? '',
      );
    } catch (e) {
      // Return default route data if parsing fails
      final now = DateTime.now();
      return RouteTrafficToday(
        routeId: 0,
        routeName: '',
        currentStatus: TrafficStatus.low,
        avgTrafficDensity: 0.0,
        avgSpeedKmh: 0.0,
        latestUpdate: now,
        totalMeasurements: 0,
        peakTrafficTime: '',
        hourlyBreakdown: [],
        confidenceScore: 0.0,
        aiInsights: '',
      );
    }
  }

  static DateTime _parseDateTime(String? dateStr, DateTime fallback) {
    if (dateStr == null || dateStr.isEmpty) return fallback;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return fallback;
    }
  }

  static List<HourlyBreakdown> _parseHourlyBreakdown(dynamic data) {
    if (data == null) return [];
    if (data is! List<dynamic>) return [];
    try {
      return data
          .map((item) {
            if (item is Map<String, dynamic>) {
              return HourlyBreakdown.fromJson(item);
            }
            return null;
          })
          .whereType<HourlyBreakdown>()
          .toList();
    } catch (e) {
      return [];
    }
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
    try {
      final now = DateTime.now();
      return AnalyticsMetadata(
        routeId: (json['routeId'] as String?) ?? 'all',
        date: (json['date'] as String?) ?? now.toIso8601String().split('T')[0],
        routesCount: json['routesCount'] as int? ?? 0,
        generatedAt:
            _parseDateTimeForMetadata(json['generatedAt'] as String?, now),
        mode: (json['mode'] as String?) ?? 'unknown',
      );
    } catch (e) {
      final now = DateTime.now();
      return AnalyticsMetadata(
        routeId: 'all',
        date: now.toIso8601String().split('T')[0],
        routesCount: 0,
        generatedAt: now,
        mode: 'unknown',
      );
    }
  }

  static DateTime _parseDateTimeForMetadata(
      String? dateStr, DateTime fallback) {
    if (dateStr == null || dateStr.isEmpty) return fallback;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return fallback;
    }
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
    try {
      final now = DateTime.now();
      final dataMap = json['data'];
      Map<String, dynamic> safeDataMap = {};

      if (dataMap is Map<String, dynamic>) {
        safeDataMap = dataMap;
      }

      final metadata = json['metadata'];
      Map<String, dynamic>? safeMetadata;
      if (metadata is Map<String, dynamic>) {
        safeMetadata = metadata;
      }

      String? dateStr;
      if (safeDataMap['date'] is String) {
        dateStr = safeDataMap['date'] as String;
      }

      DateTime parsedDate = now;
      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          parsedDate = DateTime.parse(dateStr);
        } catch (e) {
          parsedDate = now;
        }
      }

      List<RouteTrafficToday> parsedRoutes = [];
      final routesData = safeDataMap['routes'];
      if (routesData is List<dynamic>) {
        parsedRoutes = routesData
            .map((item) {
              if (item is Map<String, dynamic>) {
                return RouteTrafficToday.fromJson(item);
              }
              return null;
            })
            .whereType<RouteTrafficToday>()
            .toList();
      }

      return TodayRouteTrafficResponse(
        date: parsedDate,
        routes: parsedRoutes,
        mode: safeMetadata?['mode'] as String?,
        overallAiAnalysis: safeDataMap['overall_ai_analysis'] as String?,
        aiExplanation: json['aiExplanation'] as String?,
        metadata: safeMetadata != null
            ? AnalyticsMetadata.fromJson(safeMetadata)
            : null,
      );
    } catch (e) {
      // Return default response if parsing completely fails
      return TodayRouteTrafficResponse(
        date: DateTime.now(),
        routes: [],
        mode: null,
        overallAiAnalysis: null,
        aiExplanation: null,
        metadata: null,
      );
    }
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
