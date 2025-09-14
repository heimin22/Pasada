import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/asset_preloader_service.dart'
    as asset_preloader;
import 'package:pasada_passenger_app/services/image_compression_service.dart';
import 'package:pasada_passenger_app/utils/adaptive_memory_manager.dart';

/// Service for lazy initialization of non-critical features
/// This allows the app to start faster by deferring non-essential services
class LazyInitializationService {
  static final LazyInitializationService _instance =
      LazyInitializationService._internal();
  factory LazyInitializationService() => _instance;
  LazyInitializationService._internal();

  final AdaptiveMemoryManager _memoryManager = AdaptiveMemoryManager();
  bool _isInitializing = false;
  bool _initializationComplete = false;
  final Map<String, bool> _serviceStatus = {};

  // Services that can be initialized lazily
  static const List<String> _lazyServices = [
    'weather_service',
    'medium_priority_assets',
    'low_priority_assets',
    'image_compression_cache',
    'memory_optimization',
    'background_analytics',
    'offline_sync',
  ];

  /// Start lazy initialization after the app is fully loaded
  Future<void> startLazyInitialization() async {
    if (_isInitializing || _initializationComplete) return;

    _isInitializing = true;
    debugPrint('Starting lazy initialization of non-critical services...');

    try {
      // Initialize services in parallel but with lower priority
      await Future.wait([
        _initializeWeatherService(),
        _preloadMediumPriorityAssets(),
        _preloadLowPriorityAssets(),
        _initializeImageCompressionCache(),
        _optimizeMemorySettings(),
        _initializeBackgroundAnalytics(),
        _initializeOfflineSync(),
      ]);

      _initializationComplete = true;
      _memoryManager.addToCache('lazy_initialization_complete', true);
      debugPrint('Lazy initialization completed successfully');
    } catch (e) {
      debugPrint('Lazy initialization partial failure: $e');
    } finally {
      _isInitializing = false;
    }
  }

  /// Initialize weather service (if location is available)
  Future<void> _initializeWeatherService() async {
    try {
      // Check if location is available before initializing weather
      final locationAvailable =
          _memoryManager.getFromCache('location_available') ?? false;

      if (locationAvailable) {
        // Simulate weather service initialization
        await Future.delayed(const Duration(milliseconds: 500));
        _serviceStatus['weather_service'] = true;
        debugPrint('Weather service initialized');
      } else {
        debugPrint('Weather service skipped - location not available');
        _serviceStatus['weather_service'] = false;
      }
    } catch (e) {
      debugPrint('Weather service initialization failed: $e');
      _serviceStatus['weather_service'] = false;
    }
  }

  /// Preload medium priority assets
  Future<void> _preloadMediumPriorityAssets() async {
    try {
      final preloaderService = asset_preloader.AssetPreloaderService();
      await preloaderService.preloadAssets(maxPriority: AssetPriority.medium);
      _serviceStatus['medium_priority_assets'] = true;
      debugPrint('Medium priority assets preloaded');
    } catch (e) {
      debugPrint('Medium priority assets preloading failed: $e');
      _serviceStatus['medium_priority_assets'] = false;
    }
  }

  /// Preload low priority assets
  Future<void> _preloadLowPriorityAssets() async {
    try {
      final preloaderService = asset_preloader.AssetPreloaderService();
      await preloaderService.preloadAssets(maxPriority: AssetPriority.low);
      _serviceStatus['low_priority_assets'] = true;
      debugPrint('Low priority assets preloaded');
    } catch (e) {
      debugPrint('Low priority assets preloading failed: $e');
      _serviceStatus['low_priority_assets'] = false;
    }
  }

  /// Initialize image compression cache
  Future<void> _initializeImageCompressionCache() async {
    try {
      final compressionService = ImageCompressionService();
      // Pre-warm the compression cache
      await compressionService.optimizeStorage(maxAgeHours: 24);
      _serviceStatus['image_compression_cache'] = true;
      debugPrint('Image compression cache initialized');
    } catch (e) {
      debugPrint('Image compression cache initialization failed: $e');
      _serviceStatus['image_compression_cache'] = false;
    }
  }

  /// Optimize memory settings based on device capabilities
  Future<void> _optimizeMemorySettings() async {
    try {
      // Simulate memory optimization
      await Future.delayed(const Duration(milliseconds: 200));

      // Force a memory pressure check and cleanup
      _memoryManager.forceMemoryPressureCheck();

      _serviceStatus['memory_optimization'] = true;
      debugPrint('Memory settings optimized');
    } catch (e) {
      debugPrint('Memory optimization failed: $e');
      _serviceStatus['memory_optimization'] = false;
    }
  }

  /// Initialize background analytics
  Future<void> _initializeBackgroundAnalytics() async {
    try {
      // Simulate analytics initialization
      await Future.delayed(const Duration(milliseconds: 300));
      _serviceStatus['background_analytics'] = true;
      debugPrint('Background analytics initialized');
    } catch (e) {
      debugPrint('Background analytics initialization failed: $e');
      _serviceStatus['background_analytics'] = false;
    }
  }

  /// Initialize offline sync capabilities
  Future<void> _initializeOfflineSync() async {
    try {
      // Simulate offline sync initialization
      await Future.delayed(const Duration(milliseconds: 400));
      _serviceStatus['offline_sync'] = true;
      debugPrint('Offline sync initialized');
    } catch (e) {
      debugPrint('Offline sync initialization failed: $e');
      _serviceStatus['offline_sync'] = false;
    }
  }

  /// Check if a specific service is initialized
  bool isServiceInitialized(String serviceName) {
    return _serviceStatus[serviceName] ?? false;
  }

  /// Check if lazy initialization is complete
  bool get isInitializationComplete => _initializationComplete;

  /// Check if lazy initialization is in progress
  bool get isInitializing => _isInitializing;

  /// Get initialization progress (0.0 to 1.0)
  double get initializationProgress {
    if (_lazyServices.isEmpty) return 1.0;
    final completedServices =
        _serviceStatus.values.where((status) => status).length;
    return completedServices / _lazyServices.length;
  }

  /// Get service status report
  Map<String, dynamic> getServiceStatusReport() {
    return {
      'initialization_complete': _initializationComplete,
      'initialization_in_progress': _isInitializing,
      'progress_percentage': (initializationProgress * 100).round(),
      'services': Map.from(_serviceStatus),
      'total_services': _lazyServices.length,
      'completed_services':
          _serviceStatus.values.where((status) => status).length,
    };
  }

  /// Print lazy initialization report
  void printLazyInitializationReport() {
    final report = getServiceStatusReport();

    debugPrint('\nLAZY INITIALIZATION REPORT');
    debugPrint('===============================');
    debugPrint(
        'Status: ${report['initialization_complete'] ? 'Complete' : 'In Progress'}');
    debugPrint('Progress: ${report['progress_percentage']}%');
    debugPrint(
        'Services: ${report['completed_services']}/${report['total_services']}');
    debugPrint('\nService Status:');

    for (final service in _lazyServices) {
      final status = _serviceStatus[service] ?? false;
      final icon = status ? 'OK' : 'FAIL';
      debugPrint('  $icon $service');
    }
    debugPrint('===============================\n');
  }

  /// Force initialization of a specific service
  Future<bool> forceInitializeService(String serviceName) async {
    if (!_lazyServices.contains(serviceName)) {
      debugPrint('❌ Unknown service: $serviceName');
      return false;
    }

    try {
      switch (serviceName) {
        case 'weather_service':
          await _initializeWeatherService();
          break;
        case 'medium_priority_assets':
          await _preloadMediumPriorityAssets();
          break;
        case 'low_priority_assets':
          await _preloadLowPriorityAssets();
          break;
        case 'image_compression_cache':
          await _initializeImageCompressionCache();
          break;
        case 'memory_optimization':
          await _optimizeMemorySettings();
          break;
        case 'background_analytics':
          await _initializeBackgroundAnalytics();
          break;
        case 'offline_sync':
          await _initializeOfflineSync();
          break;
      }

      debugPrint('Forced initialization of $serviceName');
      return true;
    } catch (e) {
      debugPrint('Failed to force initialize $serviceName: $e');
      return false;
    }
  }

  /// Reset initialization state (useful for testing)
  void reset() {
    _isInitializing = false;
    _initializationComplete = false;
    _serviceStatus.clear();
    _memoryManager.clearCacheItem('lazy_initialization_complete');
    debugPrint('Lazy initialization service reset');
  }
}
