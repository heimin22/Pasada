import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';

// Enhanced cache item with TTL support
class CacheItem {
  final dynamic value;
  final DateTime createdAt;
  final Duration? ttl;

  CacheItem(this.value, {this.ttl}) : createdAt = DateTime.now();

  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(createdAt) > ttl!;
  }
}

// this class is used to manage the memory of the app
class MemoryManager {
  MemoryManager._privateConstructor() : cacheSizeLimit = 250 {
    // Increased from 100
    cache = LinkedHashMap<String, CacheItem>();
    _initializeMemoryMonitoring();
    _startTTLCleanupTimer();
  }

  static final MemoryManager instance = MemoryManager._privateConstructor();

  factory MemoryManager() {
    return instance;
  }

  // maximum number of items in the cache (increased for better performance)
  final int cacheSizeLimit;

  // internal cache storage using linked hash map para sa LRU behavior
  late final LinkedHashMap<String, CacheItem> cache;

  // TTL cleanup timer
  Timer? _ttlCleanupTimer;

  // Memory pressure monitoring thresholds
  static const double _highPressureThreshold = 0.8; // 80% capacity
  static const double _mediumPressureThreshold = 0.6; // 60% capacity
  static const double _lowPressureThreshold = 0.3; // 30% capacity

  // Performance tracking
  int _totalCacheHits = 0;
  int _totalCacheMisses = 0;
  int _pressureCleanups = 0;
  DateTime? _lastPressureCleanup;

  MemoryManager.privateConstructor({this.cacheSizeLimit = 250}) {
    cache = LinkedHashMap<String, CacheItem>();
  }

  // Initialize memory monitoring system
  void _initializeMemoryMonitoring() {
    debugPrint('Memory Manager initialized with pressure monitoring');
    debugPrint('Cache limit: $cacheSizeLimit items');
    debugPrint(
        'High pressure threshold: ${(_highPressureThreshold * 100).toInt()}%');
    debugPrint(
        'Medium pressure threshold: ${(_mediumPressureThreshold * 100).toInt()}%');
  }

  // Start TTL cleanup timer
  void _startTTLCleanupTimer() {
    _ttlCleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupExpiredItems();
    });
  }

  // Clean up expired items
  void _cleanupExpiredItems() {
    final expiredKeys = <String>[];

    for (final entry in cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint('🕐 TTL cleanup: removed ${expiredKeys.length} expired items');
    }
  }

  // Enhanced add to cache with proactive memory pressure monitoring and TTL support
  void addToCache(String key, dynamic value, {Duration? ttl}) {
    // Clean up expired items first
    _cleanupExpiredItems();

    // Proactive memory pressure check BEFORE adding new items
    _handleMemoryPressure();

    // if the key exists, remove it first to update position in LRU
    if (cache.containsKey(key)) {
      cache.remove(key);
    }

    // add the new value with TTL, making it the most recently used
    cache[key] = CacheItem(value, ttl: ttl);

    // Final safety check - if still over limit after pressure management
    if (cache.length > cacheSizeLimit) {
      cache.remove(cache.keys.first);
      debugPrint('Emergency cleanup: Removed oldest item');
    }

    _logCacheStatus();
  }

  // Convenience method for adding items with default TTL
  void addToCacheWithDefaultTTL(String key, dynamic value,
      {Duration? customTTL}) {
    final ttl = customTTL ?? const Duration(hours: 1); // Default 1 hour TTL
    addToCache(key, value, ttl: ttl);
  }

  // Proactive memory pressure monitoring and cleanup
  void _handleMemoryPressure() {
    final currentPressure = cache.length / cacheSizeLimit;

    if (currentPressure >= _highPressureThreshold) {
      // High pressure: Clean 25% of cache
      final itemsToClean = (cacheSizeLimit * 0.25).round();
      _clearOldestItems(itemsToClean);
      _pressureCleanups++;
      _lastPressureCleanup = DateTime.now();
      debugPrint(
          '🔴 HIGH memory pressure detected (${(currentPressure * 100).toInt()}%)');
      debugPrint('   Cleaned $itemsToClean items proactively');
    } else if (currentPressure >= _mediumPressureThreshold) {
      // Medium pressure: Clean 10% of cache
      final itemsToClean = (cacheSizeLimit * 0.1).round();
      _clearOldestItems(itemsToClean);
      _pressureCleanups++;
      _lastPressureCleanup = DateTime.now();
      debugPrint(
          '🟡 MEDIUM memory pressure detected (${(currentPressure * 100).toInt()}%)');
      debugPrint('   Cleaned $itemsToClean items proactively');
    }
  }

  // Clear the oldest items from cache
  void _clearOldestItems(int count) {
    final itemsToRemove = count.clamp(0, cache.length);
    for (int i = 0; i < itemsToRemove; i++) {
      if (cache.isNotEmpty) {
        cache.remove(cache.keys.first);
      }
    }
  }

  // Log cache status for monitoring
  void _logCacheStatus() {
    final pressure = cache.length / cacheSizeLimit;
    String status;
    if (pressure >= _highPressureThreshold) {
      status = 'HIGH PRESSURE';
    } else if (pressure >= _mediumPressureThreshold) {
      status = 'MEDIUM PRESSURE';
    } else if (pressure >= _lowPressureThreshold) {
      status = 'LOW PRESSURE';
    } else {
      status = 'OPTIMAL';
    }
    debugPrint(
        'Cache: ${cache.length}/$cacheSizeLimit items | Status: $status (${(pressure * 100).toInt()}%)');
  }

  // Enhanced retrieval with performance tracking and TTL checking
  dynamic getFromCache(String key) {
    final cacheItem = cache.remove(key);
    if (cacheItem != null) {
      // Check if item is expired
      if (cacheItem.isExpired) {
        // Don't re-add expired item, treat as cache miss
        _totalCacheMisses++;
        debugPrint('🕐 Cache item expired: $key');
        return null;
      }

      // Move to end (most recently used) and track cache hit
      cache[key] = cacheItem;
      _totalCacheHits++;
      return cacheItem.value;
    } else {
      // Track cache miss
      _totalCacheMisses++;
      return null;
    }
  }

  // Get cache item age
  Duration? getCacheItemAge(String key) {
    final item = cache[key];
    if (item == null) return null;
    return DateTime.now().difference(item.createdAt);
  }

  // Check if cache item exists and is not expired
  bool isCacheItemValid(String key) {
    final item = cache[key];
    return item != null && !item.isExpired;
  }

  // clears the entire cache
  void clearCache() {
    cache.clear();
    debugPrint("Cache cleared");
  }

  // clear yung specific item duon sa cache
  void clearCacheItem(String key) {
    cache.remove(key);
    debugPrint("Item $key cleared");
  }

  // get the current size of the cache
  int get cacheSize => cache.length;

  // throttling and debouncing
  final Map<String, Timer> throttleTimers = {};
  final Map<String, Timer> debounceTimers = {};

  // throttles a function call to a maximum of one call per duration
  // subsequent calls within the duration are ignored
  void throttle(Function func, Duration duration, String key) {
    if (!throttleTimers.containsKey(key)) {
      func();
      throttleTimers[key] = Timer(duration, () {
        throttleTimers.remove(key);
      });
    }
  }

  void debounce(Function func, Duration duration, String key) {
    debounceTimers[key]?.cancel();
    debounceTimers[key] = Timer(duration, () {
      func();
      debounceTimers.remove(key);
    });
  }

  /// Get current memory pressure level (0.0 to 1.0)
  double get memoryPressureLevel => cache.length / cacheSizeLimit;

  /// Get human-readable memory status
  String get memoryStatus {
    final pressure = memoryPressureLevel;
    if (pressure >= _highPressureThreshold) return 'HIGH PRESSURE';
    if (pressure >= _mediumPressureThreshold) return 'MEDIUM PRESSURE';
    if (pressure >= _lowPressureThreshold) return 'LOW PRESSURE';
    return 'OPTIMAL';
  }

  /// Get cache hit ratio (0.0 to 1.0, higher is better)
  double get cacheHitRatio {
    final totalRequests = _totalCacheHits + _totalCacheMisses;
    return totalRequests > 0 ? _totalCacheHits / totalRequests : 0.0;
  }

  /// Get memory efficiency percentage
  int get memoryEfficiencyPercentage => (cacheHitRatio * 100).round();

  /// Get detailed memory statistics
  Map<String, dynamic> get memoryStats => {
        'cache_size': cache.length,
        'cache_limit': cacheSizeLimit,
        'memory_pressure_level': memoryPressureLevel,
        'memory_status': memoryStatus,
        'cache_hit_ratio': cacheHitRatio,
        'total_cache_hits': _totalCacheHits,
        'total_cache_misses': _totalCacheMisses,
        'pressure_cleanups': _pressureCleanups,
        'last_pressure_cleanup': _lastPressureCleanup?.toIso8601String(),
        'efficiency_percentage': memoryEfficiencyPercentage,
      };

  /// Print comprehensive memory health report
  void printMemoryHealthReport() {
    debugPrint('\n📊 MEMORY HEALTH REPORT 📊');
    debugPrint('===============================');
    debugPrint('Cache Status: $memoryStatus');
    debugPrint(
        'Memory Usage: ${cache.length}/$cacheSizeLimit (${(memoryPressureLevel * 100).toInt()}%)');
    debugPrint('Cache Efficiency: $memoryEfficiencyPercentage% hit ratio');
    debugPrint('Performance: $_totalCacheHits hits, $_totalCacheMisses misses');
    debugPrint('Pressure Cleanups: $_pressureCleanups times');
    if (_lastPressureCleanup != null) {
      final timeSinceLastCleanup =
          DateTime.now().difference(_lastPressureCleanup!);
      debugPrint(
          'Last Cleanup: ${timeSinceLastCleanup.inMinutes}m ${timeSinceLastCleanup.inSeconds % 60}s ago');
    }
    debugPrint('===============================\n');
  }

  /// Force a memory pressure check and cleanup if needed
  void forceMemoryPressureCheck() {
    debugPrint('🔍 Manual memory pressure check requested');
    _handleMemoryPressure();
  }

  // lifecycle methods

  // Enhanced dispose with memory health report
  void dispose() {
    // Print final memory health report
    printMemoryHealthReport();

    // Clean up TTL timer
    _ttlCleanupTimer?.cancel();

    // Clean up throttle/debounce timers
    for (var timer in throttleTimers.values) {
      timer.cancel();
    }
    throttleTimers.clear();
    for (var timer in debounceTimers.values) {
      timer.cancel();
    }
    debounceTimers.clear();

    // Clear cache
    clearCache();
    debugPrint(
        "Enhanced Memory Manager with TTL and pressure monitoring disposed");
  }
}
