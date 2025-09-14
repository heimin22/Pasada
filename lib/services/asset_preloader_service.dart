import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/adaptive_memory_manager.dart';

class AssetPreloaderService {
  static final AssetPreloaderService _instance =
      AssetPreloaderService._internal();
  factory AssetPreloaderService() => _instance;
  AssetPreloaderService._internal();

  final AdaptiveMemoryManager _memoryManager = AdaptiveMemoryManager();
  bool _isPreloading = false;
  bool _criticalAssetsLoaded = false;
  bool _highPriorityAssetsLoaded = false;

  // Critical assets - needed immediately on app start
  static const List<String> _criticalAssets = [
    'assets/svg/pasadaLogoWithoutText.svg',
    'assets/png/pasada_main_app_icon.png',
    'assets/svg/homeIcon.svg',
    'assets/svg/homeSelectedIcon.svg',
    'assets/svg/navigation.svg',
  ];

  // High priority assets - needed for primary navigation
  static const List<String> _highPriorityAssets = [
    'assets/svg/activityIcon.svg',
    'assets/svg/activitySelectedIcon.svg',
    'assets/svg/notificationIcon.svg',
    'assets/svg/notificationSelectedIcon.svg',
    'assets/svg/profileIcon.svg',
    'assets/svg/profileSelectedIcon.svg',
    'assets/svg/locationPin.svg',
    'assets/svg/pickupPin.svg',
    'assets/svg/pindropoff.svg',
  ];

  // Medium priority assets - secondary features
  static const List<String> _mediumPriorityAssets = [
    'assets/svg/bus.svg',
    'assets/png/bus.png',
    'assets/svg/googleIcon.svg',
  ];

  // Low priority assets - rarely used or decorative
  static const List<String> _lowPriorityAssets = [
    'assets/svg/Ellipse.svg',
    'assets/svg/lines.svg',
    'assets/svg/otherOptions.svg',
    'assets/svg/viberIcon.svg',
    'assets/svg/phFlag.svg',
    'assets/svg/default_user_profile.svg',
    'assets/png/default_user_profile.png',
  ];

  /// Preload assets based on priority
  Future<void> preloadAssets({
    AssetPriority maxPriority = AssetPriority.high,
    VoidCallback? onCriticalComplete,
    VoidCallback? onHighPriorityComplete,
  }) async {
    if (_isPreloading) return;
    _isPreloading = true;

    try {
      // Always load critical assets first
      await _preloadAssetBatch(_criticalAssets, AssetPriority.critical);
      _criticalAssetsLoaded = true;
      onCriticalComplete?.call();
      debugPrint('Critical assets preloaded (${_criticalAssets.length} items)');

      // Load high priority if requested
      if (maxPriority.index >= AssetPriority.high.index) {
        await _preloadAssetBatch(_highPriorityAssets, AssetPriority.high);
        _highPriorityAssetsLoaded = true;
        onHighPriorityComplete?.call();
        debugPrint(
            'High priority assets preloaded (${_highPriorityAssets.length} items)');
      }

      // Load medium priority if requested
      if (maxPriority.index >= AssetPriority.medium.index) {
        await _preloadAssetBatch(_mediumPriorityAssets, AssetPriority.medium);
        debugPrint(
            'Medium priority assets preloaded (${_mediumPriorityAssets.length} items)');
      }

      // Load low priority if requested (background loading)
      if (maxPriority.index >= AssetPriority.low.index) {
        // Load low priority assets in background without blocking
        _preloadAssetBatch(_lowPriorityAssets, AssetPriority.low).then((_) {
          debugPrint(
              'Low priority assets preloaded (${_lowPriorityAssets.length} items)');
        });
      }
    } catch (e) {
      debugPrint('Asset preloading error: $e');
    } finally {
      _isPreloading = false;
    }
  }

  /// Preload specific asset batch with concurrency control
  Future<void> _preloadAssetBatch(
      List<String> assets, AssetPriority priority) async {
    // Adjust concurrency based on priority
    final concurrency = _getConcurrencyLimit(priority);
    final batches = <List<String>>[];

    // Split assets into concurrent batches
    for (int i = 0; i < assets.length; i += concurrency) {
      batches.add(assets.skip(i).take(concurrency).toList());
    }

    // Process batches sequentially, items within batch in parallel
    for (final batch in batches) {
      await Future.wait(
        batch.map((asset) => _preloadSingleAsset(asset, priority)),
      );
    }
  }

  /// Get concurrency limit based on priority using adaptive memory manager
  int _getConcurrencyLimit(AssetPriority priority) {
    return _memoryManager.getConcurrencyLimit(priority);
  }

  /// Preload single asset and cache it
  Future<void> _preloadSingleAsset(
      String assetPath, AssetPriority priority) async {
    try {
      // Check if already cached
      final cacheKey = 'preloaded_$assetPath';
      if (_memoryManager.getFromCache(cacheKey) != null) {
        return; // Already cached
      }

      if (assetPath.endsWith('.svg')) {
        // Preload SVG by loading the asset data
        final svgData = await rootBundle.loadString(assetPath);
        _memoryManager.addToCache(cacheKey, svgData);
      } else if (assetPath.endsWith('.png') || assetPath.endsWith('.jpg')) {
        // Preload image
        final imageStream =
            AssetImage(assetPath).resolve(const ImageConfiguration());
        final completer = Completer<void>();

        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (image, _) {
            _memoryManager.addToCache(cacheKey, image.image);
            imageStream.removeListener(listener);
            completer.complete();
          },
          onError: (error, stack) {
            imageStream.removeListener(listener);
            completer.completeError(error);
          },
        );

        imageStream.addListener(listener);
        await completer.future;
      }

      debugPrint('Preloaded ${priority.name}: $assetPath');
    } catch (e) {
      debugPrint('Failed to preload $assetPath: $e');
    }
  }

  /// Get preloaded SVG data from cache
  String? getPreloadedSvg(String assetPath) {
    return _memoryManager.getFromCache('preloaded_$assetPath') as String?;
  }

  /// Get preloaded image from cache
  ui.Image? getPreloadedImage(String assetPath) {
    return _memoryManager.getFromCache('preloaded_$assetPath') as ui.Image?;
  }

  /// Check if critical assets are loaded
  bool get criticalAssetsLoaded => _criticalAssetsLoaded;

  /// Check if high priority assets are loaded
  bool get highPriorityAssetsLoaded => _highPriorityAssetsLoaded;

  /// Get loading progress (0.0 to 1.0)
  double get loadingProgress {
    final totalCritical = _criticalAssets.length;
    final totalHigh = _highPriorityAssets.length;
    final totalMedium = _mediumPriorityAssets.length;
    final totalAssets = totalCritical + totalHigh + totalMedium;

    int loadedCount = 0;

    if (_criticalAssetsLoaded) loadedCount += totalCritical;
    if (_highPriorityAssetsLoaded) loadedCount += totalHigh;

    return loadedCount / totalAssets;
  }

  /// Preload assets in background (fire and forget)
  void preloadAssetsInBackground() {
    Future.delayed(const Duration(milliseconds: 500), () {
      preloadAssets(maxPriority: AssetPriority.low);
    });
  }

  /// Clear preloaded assets to free memory
  void clearPreloadedAssets() {
    final allAssets = [
      ..._criticalAssets,
      ..._highPriorityAssets,
      ..._mediumPriorityAssets,
      ..._lowPriorityAssets,
    ];

    for (final asset in allAssets) {
      _memoryManager.clearCacheItem('preloaded_$asset');
    }

    _criticalAssetsLoaded = false;
    _highPriorityAssetsLoaded = false;
    debugPrint('Preloaded assets cache cleared');
  }
}
