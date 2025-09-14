import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../utils/adaptive_memory_manager.dart';

/// Service for monitoring and tracking performance metrics
class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance =
      PerformanceMonitoringService._internal();
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();

  final AdaptiveMemoryManager _memoryManager = AdaptiveMemoryManager();

  // Performance tracking data
  final Map<String, PerformanceMetric> _metrics = {};
  final Queue<PerformanceEvent> _eventHistory = Queue<PerformanceEvent>();
  final int _maxEventHistory = 1000; // Keep last 1000 events

  // Asset loading performance tracking
  final Map<String, AssetLoadingMetric> _assetMetrics = {};

  // App startup performance tracking
  DateTime? _appStartTime;
  final Map<String, DateTime> _startupMilestones = {};
  final Map<String, Duration> _startupDurations = {};

  /// Initialize performance monitoring
  void initialize() {
    _appStartTime = DateTime.now();
    _recordStartupMilestone('app_initialization_start');
    debugPrint('Performance monitoring initialized');
  }

  /// Record a startup milestone
  void recordStartupMilestone(String milestoneName) {
    _recordStartupMilestone(milestoneName);
  }

  void _recordStartupMilestone(String milestoneName) {
    final now = DateTime.now();
    _startupMilestones[milestoneName] = now;

    if (_appStartTime != null) {
      final duration = now.difference(_appStartTime!);
      _startupDurations[milestoneName] = duration;
      debugPrint(
          'Startup milestone: $milestoneName - ${duration.inMilliseconds}ms');
    }
  }

  /// Start tracking an asset loading operation
  String startAssetLoading(String assetPath) {
    final loadingId = '${assetPath}_${DateTime.now().millisecondsSinceEpoch}';
    _assetMetrics[loadingId] = AssetLoadingMetric(
      assetPath: assetPath,
      startTime: DateTime.now(),
    );
    return loadingId;
  }

  /// Complete tracking an asset loading operation
  void completeAssetLoading(String loadingId,
      {bool success = true, String? error}) {
    final metric = _assetMetrics[loadingId];
    if (metric != null) {
      metric.endTime = DateTime.now();
      metric.success = success;
      metric.error = error;
      metric.duration = metric.endTime!.difference(metric.startTime);

      _recordEvent(PerformanceEvent(
        type: 'asset_loading',
        name: metric.assetPath,
        duration: metric.duration!,
        success: success,
        metadata: {
          'asset_path': metric.assetPath,
          'loading_id': loadingId,
          if (error != null) 'error': error,
        },
      ));

      debugPrint(
          'Asset loading completed: ${metric.assetPath} - ${metric.duration!.inMilliseconds}ms');
    }
  }

  /// Record a performance metric
  void recordMetric(String name, Duration duration,
      {Map<String, dynamic>? metadata, bool success = true}) {
    final metric = PerformanceMetric(
      name: name,
      duration: duration,
      timestamp: DateTime.now(),
      success: success,
      metadata: metadata ?? {},
    );

    _metrics[name] = metric;
    _recordEvent(PerformanceEvent(
      type: 'metric',
      name: name,
      duration: duration,
      success: success,
      metadata: metadata ?? {},
    ));
  }

  /// Record a performance event
  void _recordEvent(PerformanceEvent event) {
    _eventHistory.add(event);

    // Maintain event history size
    if (_eventHistory.length > _maxEventHistory) {
      _eventHistory.removeFirst();
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final assetStats = _calculateAssetStats();
    final startupStats = _calculateStartupStats();
    final memoryStats = _memoryManager.memoryStats;

    return {
      'startup_performance': startupStats,
      'asset_loading_performance': assetStats,
      'memory_performance': memoryStats,
      'total_events': _eventHistory.length,
      'total_metrics': _metrics.length,
      'total_asset_loads': _assetMetrics.length,
    };
  }

  /// Calculate asset loading statistics
  Map<String, dynamic> _calculateAssetStats() {
    if (_assetMetrics.isEmpty) {
      return {
        'total_assets_loaded': 0,
        'average_loading_time_ms': 0,
        'fastest_loading_time_ms': 0,
        'slowest_loading_time_ms': 0,
        'success_rate': 0.0,
        'failed_loads': 0,
      };
    }

    final completedMetrics =
        _assetMetrics.values.where((m) => m.duration != null).toList();
    final successfulLoads = completedMetrics.where((m) => m.success).length;
    final failedLoads = completedMetrics.where((m) => !m.success).length;

    final loadingTimes =
        completedMetrics.map((m) => m.duration!.inMilliseconds).toList();
    loadingTimes.sort();

    final averageTime = loadingTimes.isEmpty
        ? 0
        : loadingTimes.reduce((a, b) => a + b) / loadingTimes.length;
    final fastestTime = loadingTimes.isEmpty ? 0 : loadingTimes.first;
    final slowestTime = loadingTimes.isEmpty ? 0 : loadingTimes.last;

    return {
      'total_assets_loaded': completedMetrics.length,
      'average_loading_time_ms': averageTime.round(),
      'fastest_loading_time_ms': fastestTime,
      'slowest_loading_time_ms': slowestTime,
      'success_rate': completedMetrics.isEmpty
          ? 0.0
          : (successfulLoads / completedMetrics.length),
      'failed_loads': failedLoads,
      'successful_loads': successfulLoads,
    };
  }

  /// Calculate startup performance statistics
  Map<String, dynamic> _calculateStartupStats() {
    if (_startupDurations.isEmpty) {
      return {
        'total_startup_time_ms': 0,
        'milestones': {},
      };
    }

    final totalStartupTime = _appStartTime != null
        ? DateTime.now().difference(_appStartTime!).inMilliseconds
        : 0;

    return {
      'total_startup_time_ms': totalStartupTime,
      'milestones': _startupDurations
          .map((key, value) => MapEntry(key, value.inMilliseconds)),
    };
  }

  /// Get slowest asset loading operations
  List<AssetLoadingMetric> getSlowestAssetLoads({int limit = 10}) {
    final completedMetrics =
        _assetMetrics.values.where((m) => m.duration != null).toList();

    completedMetrics.sort((a, b) => b.duration!.compareTo(a.duration!));
    return completedMetrics.take(limit).toList();
  }

  /// Get failed asset loading operations
  List<AssetLoadingMetric> getFailedAssetLoads() {
    return _assetMetrics.values
        .where((m) => m.duration != null && !m.success)
        .toList();
  }

  /// Print comprehensive performance report
  void printPerformanceReport() {
    final stats = getPerformanceStats();
    final assetStats =
        stats['asset_loading_performance'] as Map<String, dynamic>;
    final startupStats = stats['startup_performance'] as Map<String, dynamic>;
    final memoryStats = stats['memory_performance'] as Map<String, dynamic>;

    debugPrint('\nPERFORMANCE MONITORING REPORT');
    debugPrint('=====================================');

    // Startup Performance
    debugPrint('STARTUP PERFORMANCE:');
    debugPrint(
        '   Total Startup Time: ${startupStats['total_startup_time_ms']}ms');
    debugPrint('   Milestones:');
    final milestones = startupStats['milestones'] as Map<String, dynamic>;
    for (final entry in milestones.entries) {
      debugPrint('     ${entry.key}: ${entry.value}ms');
    }

    // Asset Loading Performance
    debugPrint('\nASSET LOADING PERFORMANCE:');
    debugPrint('   Total Assets Loaded: ${assetStats['total_assets_loaded']}');
    debugPrint(
        '   Average Loading Time: ${assetStats['average_loading_time_ms']}ms');
    debugPrint(
        '   Fastest Loading Time: ${assetStats['fastest_loading_time_ms']}ms');
    debugPrint(
        '   Slowest Loading Time: ${assetStats['slowest_loading_time_ms']}ms');
    debugPrint(
        '   Success Rate: ${(assetStats['success_rate'] * 100).toStringAsFixed(1)}%');
    debugPrint('   Failed Loads: ${assetStats['failed_loads']}');

    // Memory Performance
    debugPrint('\nMEMORY PERFORMANCE:');
    debugPrint(
        '   Cache Size: ${memoryStats['cache_size']}/${memoryStats['cache_limit']}');
    debugPrint('   Memory Status: ${memoryStats['memory_status']}');
    debugPrint('   Cache Efficiency: ${memoryStats['efficiency_percentage']}%');
    debugPrint(
        '   Cache Hit Ratio: ${(memoryStats['cache_hit_ratio'] * 100).toStringAsFixed(1)}%');

    // Slowest Operations
    final slowestLoads = getSlowestAssetLoads();
    if (slowestLoads.isNotEmpty) {
      debugPrint('\nSLOWEST ASSET LOADS:');
      for (final load in slowestLoads) {
        debugPrint('   ${load.assetPath}: ${load.duration!.inMilliseconds}ms');
      }
    }

    // Failed Operations
    final failedLoads = getFailedAssetLoads();
    if (failedLoads.isNotEmpty) {
      debugPrint('\nFAILED ASSET LOADS:');
      for (final load in failedLoads) {
        debugPrint('   ${load.assetPath}: ${load.error ?? 'Unknown error'}');
      }
    }

    debugPrint('=====================================\n');
  }

  /// Export performance data for analysis
  Map<String, dynamic> exportPerformanceData() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'performance_stats': getPerformanceStats(),
      'event_history': _eventHistory.map((e) => e.toMap()).toList(),
      'asset_metrics':
          _assetMetrics.map((key, value) => MapEntry(key, value.toMap())),
      'startup_milestones': _startupMilestones
          .map((key, value) => MapEntry(key, value.toIso8601String())),
    };
  }

  /// Clear performance data
  void clearPerformanceData() {
    _metrics.clear();
    _eventHistory.clear();
    _assetMetrics.clear();
    _startupMilestones.clear();
    _startupDurations.clear();
    _appStartTime = null;
    debugPrint('Performance monitoring data cleared');
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String name;
  final Duration duration;
  final DateTime timestamp;
  final bool success;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.name,
    required this.duration,
    required this.timestamp,
    required this.success,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'duration_ms': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'success': success,
      'metadata': metadata,
    };
  }
}

/// Asset loading metric data class
class AssetLoadingMetric {
  final String assetPath;
  final DateTime startTime;
  DateTime? endTime;
  Duration? duration;
  bool success = true;
  String? error;

  AssetLoadingMetric({
    required this.assetPath,
    required this.startTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'asset_path': assetPath,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_ms': duration?.inMilliseconds,
      'success': success,
      'error': error,
    };
  }
}

/// Performance event data class
class PerformanceEvent {
  final String type;
  final String name;
  final Duration duration;
  final bool success;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  PerformanceEvent({
    required this.type,
    required this.name,
    required this.duration,
    required this.success,
    required this.metadata,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'name': name,
      'duration_ms': duration.inMilliseconds,
      'success': success,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
