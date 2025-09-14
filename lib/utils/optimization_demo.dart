import 'package:flutter/material.dart';

import '../services/asset_optimizer_service.dart';
import '../services/enhanced_asset_compression_service.dart';
import '../services/lazy_initialization_service.dart';
import '../services/performance_monitoring_service.dart';
import 'adaptive_memory_manager.dart';

/// Demo class to showcase the new optimization features
/// This can be used to test and demonstrate the performance improvements
class OptimizationDemo {
  static final OptimizationDemo _instance = OptimizationDemo._internal();
  factory OptimizationDemo() => _instance;
  OptimizationDemo._internal();

  /// Run a comprehensive optimization demo
  static Future<void> runOptimizationDemo() async {
    debugPrint('\n🚀 STARTING OPTIMIZATION DEMO 🚀');
    debugPrint('=====================================');

    // 1. Asset Optimization Demo
    await _demoAssetOptimization();

    // 2. Memory Management Demo
    await _demoMemoryManagement();

    // 3. Performance Monitoring Demo
    await _demoPerformanceMonitoring();

    // 4. Lazy Initialization Demo
    await _demoLazyInitialization();

    // 5. Asset Compression Demo
    await _demoAssetCompression();

    debugPrint('\n✅ OPTIMIZATION DEMO COMPLETED ✅');
    debugPrint('=====================================\n');
  }

  /// Demo asset optimization features
  static Future<void> _demoAssetOptimization() async {
    debugPrint('\n📦 ASSET OPTIMIZATION DEMO');
    debugPrint('---------------------------');

    final assetOptimizer = AssetOptimizerService();

    // Print asset optimization report
    assetOptimizer.printAssetOptimizationReport();

    // Generate optimized assets section
    final optimizedAssets = assetOptimizer.generateOptimizedAssetsSection();
    debugPrint('Optimized assets section for pubspec.yaml:');
    debugPrint(optimizedAssets);

    // Check if specific assets are used
    final testAssets = [
      'assets/svg/pasadaLogoWithoutText.svg',
      'assets/svg/Ellipse.svg', // This should be unused
      'assets/png/bus.png',
    ];

    for (final asset in testAssets) {
      final isUsed = assetOptimizer.isAssetUsed(asset);
      debugPrint('Asset $asset: ${isUsed ? "✅ Used" : "❌ Unused"}');
    }
  }

  /// Demo memory management features
  static Future<void> _demoMemoryManagement() async {
    debugPrint('\n🧠 MEMORY MANAGEMENT DEMO');
    debugPrint('--------------------------');

    final memoryManager = AdaptiveMemoryManager();

    // Initialize the adaptive memory manager
    await memoryManager.initialize();

    // Print device capability info
    final deviceInfo = memoryManager.getDeviceCapabilityInfo();
    debugPrint('Device Capability Info:');
    for (final entry in deviceInfo.entries) {
      debugPrint('  ${entry.key}: ${entry.value}');
    }

    // Print adaptive memory report
    memoryManager.printAdaptiveMemoryReport();

    // Test adaptive concurrency limits
    final priorities = [
      AssetPriority.critical,
      AssetPriority.high,
      AssetPriority.medium,
      AssetPriority.low
    ];
    debugPrint('\nAdaptive Concurrency Limits:');
    for (final priority in priorities) {
      final limit = memoryManager.getConcurrencyLimit(priority);
      debugPrint('  ${priority.name}: $limit');
    }
  }

  /// Demo performance monitoring features
  static Future<void> _demoPerformanceMonitoring() async {
    debugPrint('\n📊 PERFORMANCE MONITORING DEMO');
    debugPrint('-------------------------------');

    final performanceMonitor = PerformanceMonitoringService();

    // Initialize performance monitoring
    performanceMonitor.initialize();

    // Record some startup milestones
    performanceMonitor.recordStartupMilestone('demo_started');
    await Future.delayed(const Duration(milliseconds: 100));
    performanceMonitor.recordStartupMilestone('demo_phase_1_complete');

    // Simulate asset loading
    final loadingId1 =
        performanceMonitor.startAssetLoading('assets/svg/bus.svg');
    await Future.delayed(const Duration(milliseconds: 50));
    performanceMonitor.completeAssetLoading(loadingId1);

    final loadingId2 =
        performanceMonitor.startAssetLoading('assets/png/bus.png');
    await Future.delayed(const Duration(milliseconds: 30));
    performanceMonitor.completeAssetLoading(loadingId2);

    // Record a performance metric
    performanceMonitor.recordMetric(
        'demo_operation', const Duration(milliseconds: 200));

    // Print performance report
    performanceMonitor.printPerformanceReport();
  }

  /// Demo lazy initialization features
  static Future<void> _demoLazyInitialization() async {
    debugPrint('\n⏰ LAZY INITIALIZATION DEMO');
    debugPrint('----------------------------');

    final lazyInitService = LazyInitializationService();

    // Check initial status
    debugPrint('Initial status:');
    debugPrint('  Is initializing: ${lazyInitService.isInitializing}');
    debugPrint('  Is complete: ${lazyInitService.isInitializationComplete}');
    debugPrint(
        '  Progress: ${(lazyInitService.initializationProgress * 100).toStringAsFixed(1)}%');

    // Start lazy initialization
    debugPrint('\nStarting lazy initialization...');
    await lazyInitService.startLazyInitialization();

    // Check final status
    debugPrint('\nFinal status:');
    debugPrint('  Is initializing: ${lazyInitService.isInitializing}');
    debugPrint('  Is complete: ${lazyInitService.isInitializationComplete}');
    debugPrint(
        '  Progress: ${(lazyInitService.initializationProgress * 100).toStringAsFixed(1)}%');

    // Print service status report
    lazyInitService.printLazyInitializationReport();
  }

  /// Demo asset compression features
  static Future<void> _demoAssetCompression() async {
    debugPrint('\n🗜️  ASSET COMPRESSION DEMO');
    debugPrint('---------------------------');

    final compressionService = EnhancedAssetCompressionService();

    // Print current compression stats
    compressionService.printAssetCompressionReport();

    // Simulate pre-compressing critical assets
    debugPrint('\nPre-compressing critical assets...');
    await compressionService.preCompressCriticalAssets();

    // Print updated stats
    debugPrint('\nUpdated compression stats:');
    compressionService.printAssetCompressionReport();
  }

  /// Get optimization summary
  static Map<String, dynamic> getOptimizationSummary() {
    final assetOptimizer = AssetOptimizerService();
    final memoryManager = AdaptiveMemoryManager();
    final performanceMonitor = PerformanceMonitoringService();
    final lazyInitService = LazyInitializationService();
    final compressionService = EnhancedAssetCompressionService();

    return {
      'asset_optimization': assetOptimizer.getAssetStats(),
      'memory_management': memoryManager.getDeviceCapabilityInfo(),
      'performance_monitoring': performanceMonitor.getPerformanceStats(),
      'lazy_initialization': lazyInitService.getServiceStatusReport(),
      'asset_compression': compressionService.getAssetCompressionStats(),
    };
  }

  /// Print comprehensive optimization summary
  static void printOptimizationSummary() {
    final summary = getOptimizationSummary();

    debugPrint('\n📋 OPTIMIZATION SUMMARY 📋');
    debugPrint('===========================');

    for (final category in summary.entries) {
      debugPrint('\n${category.key.toUpperCase()}:');
      final data = category.value as Map<String, dynamic>;
      for (final entry in data.entries) {
        debugPrint('  ${entry.key}: ${entry.value}');
      }
    }

    debugPrint('\n===========================');
  }
}
