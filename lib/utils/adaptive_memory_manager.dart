import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'memory_manager.dart';

/// Enhanced memory manager that adapts to device capabilities
class AdaptiveMemoryManager extends MemoryManager {
  static final AdaptiveMemoryManager _instance =
      AdaptiveMemoryManager._privateConstructor();
  factory AdaptiveMemoryManager() => _instance;
  AdaptiveMemoryManager._privateConstructor() : super.privateConstructor();

  // Device capability detection
  int? _deviceMemoryMB;
  String? _deviceModel;
  DeviceCapability? _deviceCapability;

  // Adaptive cache limits based on device capability
  late int _adaptiveCacheLimit;
  late int _adaptiveConcurrencyLimit;
  late Duration _adaptiveCleanupInterval;

  @override
  int get cacheSizeLimit => _adaptiveCacheLimit;

  /// Initialize adaptive memory management
  Future<void> initialize() async {
    await _detectDeviceCapabilities();
    _configureAdaptiveSettings();
    _logAdaptiveConfiguration();
  }

  /// Detect device capabilities
  Future<void> _detectDeviceCapabilities() async {
    try {
      // Get device memory information
      _deviceMemoryMB = await _getDeviceMemoryMB();

      // Get device model for additional context
      _deviceModel = await _getDeviceModel();

      // Determine device capability tier
      _deviceCapability = _determineDeviceCapability();

      debugPrint('Device Capability Detection:');
      debugPrint('   Memory: ${_deviceMemoryMB}MB');
      debugPrint('   Model: $_deviceModel');
      debugPrint('   Capability: ${_deviceCapability?.name}');
    } catch (e) {
      debugPrint('Device capability detection failed: $e');
      // Fallback to conservative settings
      _deviceCapability = DeviceCapability.lowEnd;
    }
  }

  /// Get device memory in MB
  Future<int> _getDeviceMemoryMB() async {
    try {
      if (Platform.isAndroid) {
        // Use Android system properties to get memory info
        const platform = MethodChannel('device_info');
        final result = await platform.invokeMethod('getTotalMemoryMB');
        return result as int? ?? 2048; // Default to 2GB if detection fails
      } else if (Platform.isIOS) {
        // iOS memory detection
        const platform = MethodChannel('device_info');
        final result = await platform.invokeMethod('getTotalMemoryMB');
        return result as int? ?? 2048; // Default to 2GB if detection fails
      }
    } catch (e) {
      debugPrint('Memory detection failed: $e');
    }

    // Fallback: estimate based on platform
    return Platform.isAndroid ? 2048 : 3072; // Conservative estimates
  }

  /// Get device model
  Future<String> _getDeviceModel() async {
    try {
      const platform = MethodChannel('device_info');
      final result = await platform.invokeMethod('getDeviceModel');
      return result as String? ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Determine device capability based on memory and other factors
  DeviceCapability _determineDeviceCapability() {
    final memory = _deviceMemoryMB ?? 2048;

    if (memory >= 6144) {
      // 6GB+
      return DeviceCapability.highEnd;
    } else if (memory >= 4096) {
      // 4-6GB
      return DeviceCapability.midRange;
    } else if (memory >= 3072) {
      // 3-4GB
      return DeviceCapability.lowMid;
    } else {
      // <3GB
      return DeviceCapability.lowEnd;
    }
  }

  /// Configure adaptive settings based on device capability
  void _configureAdaptiveSettings() {
    switch (_deviceCapability!) {
      case DeviceCapability.highEnd:
        _adaptiveCacheLimit = 400; // High-end devices can handle more
        _adaptiveConcurrencyLimit = 12;
        _adaptiveCleanupInterval = const Duration(minutes: 10);
        break;
      case DeviceCapability.midRange:
        _adaptiveCacheLimit = 250; // Standard cache size
        _adaptiveConcurrencyLimit = 8;
        _adaptiveCleanupInterval = const Duration(minutes: 7);
        break;
      case DeviceCapability.lowMid:
        _adaptiveCacheLimit = 150; // Reduced cache for lower-end devices
        _adaptiveConcurrencyLimit = 6;
        _adaptiveCleanupInterval = const Duration(minutes: 5);
        break;
      case DeviceCapability.lowEnd:
        _adaptiveCacheLimit = 100; // Conservative cache for low-end devices
        _adaptiveConcurrencyLimit = 4;
        _adaptiveCleanupInterval = const Duration(minutes: 3);
        break;
    }
  }

  /// Log adaptive configuration
  void _logAdaptiveConfiguration() {
    debugPrint('Adaptive Memory Configuration:');
    debugPrint('   Cache Limit: $_adaptiveCacheLimit items');
    debugPrint('   Concurrency Limit: $_adaptiveConcurrencyLimit');
    debugPrint(
        '   Cleanup Interval: ${_adaptiveCleanupInterval.inMinutes} minutes');
  }

  /// Get adaptive concurrency limit for asset loading
  int getConcurrencyLimit(AssetPriority priority) {
    final baseLimit = _adaptiveConcurrencyLimit;

    switch (priority) {
      case AssetPriority.critical:
        return (baseLimit * 0.3)
            .round()
            .clamp(1, 4); // Conservative for critical
      case AssetPriority.high:
        return (baseLimit * 0.5).round().clamp(2, 6); // Balanced
      case AssetPriority.medium:
        return (baseLimit * 0.7).round().clamp(3, 8); // More aggressive
      case AssetPriority.low:
        return baseLimit; // Maximum concurrency
    }
  }

  /// Get adaptive memory pressure thresholds
  Map<String, double> getAdaptivePressureThresholds() {
    switch (_deviceCapability!) {
      case DeviceCapability.highEnd:
        return {
          'low': 0.4, // 40%
          'medium': 0.7, // 70%
          'high': 0.85, // 85%
        };
      case DeviceCapability.midRange:
        return {
          'low': 0.3, // 30%
          'medium': 0.6, // 60%
          'high': 0.8, // 80%
        };
      case DeviceCapability.lowMid:
        return {
          'low': 0.25, // 25%
          'medium': 0.5, // 50%
          'high': 0.7, // 70%
        };
      case DeviceCapability.lowEnd:
        return {
          'low': 0.2, // 20%
          'medium': 0.4, // 40%
          'high': 0.6, // 60%
        };
    }
  }

  /// Get device capability information
  Map<String, dynamic> getDeviceCapabilityInfo() {
    return {
      'device_memory_mb': _deviceMemoryMB,
      'device_model': _deviceModel,
      'device_capability': _deviceCapability?.name,
      'adaptive_cache_limit': _adaptiveCacheLimit,
      'adaptive_concurrency_limit': _adaptiveConcurrencyLimit,
      'adaptive_cleanup_interval_minutes': _adaptiveCleanupInterval.inMinutes,
      'pressure_thresholds': getAdaptivePressureThresholds(),
    };
  }

  /// Print comprehensive adaptive memory report
  void printAdaptiveMemoryReport() {
    final capabilityInfo = getDeviceCapabilityInfo();
    final memStats = super.memoryStats;

    debugPrint('\nADAPTIVE MEMORY REPORT');
    debugPrint('===============================');
    debugPrint('Device Information:');
    debugPrint('  Memory: ${capabilityInfo['device_memory_mb']}MB');
    debugPrint('  Model: ${capabilityInfo['device_model']}');
    debugPrint('  Capability: ${capabilityInfo['device_capability']}');
    debugPrint('\nAdaptive Settings:');
    debugPrint(
        '  Cache Limit: ${capabilityInfo['adaptive_cache_limit']} items');
    debugPrint(
        '  Concurrency: ${capabilityInfo['adaptive_concurrency_limit']}');
    debugPrint(
        '  Cleanup Interval: ${capabilityInfo['adaptive_cleanup_interval_minutes']} minutes');
    debugPrint('\nMemory Status:');
    debugPrint(
        '  Current Usage: ${memStats['cache_size']}/${memStats['cache_limit']}');
    debugPrint('  Memory Status: ${memStats['memory_status']}');
    debugPrint('  Cache Efficiency: ${memStats['efficiency_percentage']}%');
    debugPrint('===============================\n');
  }

  /// Override dispose to include adaptive information
  void disposeAdaptive() {
    printAdaptiveMemoryReport();
    super.dispose();
  }
}

/// Device capability tiers
enum DeviceCapability {
  lowEnd, // <3GB RAM
  lowMid, // 3-4GB RAM
  midRange, // 4-6GB RAM
  highEnd, // 6GB+ RAM
}

/// Asset priority levels for adaptive concurrency
enum AssetPriority {
  critical,
  high,
  medium,
  low,
}
