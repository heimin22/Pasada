import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../utils/adaptive_memory_manager.dart';

/// Enhanced asset compression service specifically for app assets
class EnhancedAssetCompressionService {
  static final EnhancedAssetCompressionService _instance =
      EnhancedAssetCompressionService._internal();
  factory EnhancedAssetCompressionService() => _instance;
  EnhancedAssetCompressionService._internal();

  final AdaptiveMemoryManager _memoryManager = AdaptiveMemoryManager();

  // Asset-specific compression settings
  static const Map<String, Map<String, dynamic>> _assetCompressionSettings = {
    // App icons - high quality, larger size
    'pasada_app_icon': {
      'quality': 95,
      'maxWidth': 512,
      'maxHeight': 512,
      'format': CompressFormat.png,
    },
    // Bus images - medium quality, optimized for UI
    'bus': {
      'quality': 85,
      'maxWidth': 256,
      'maxHeight': 256,
      'format': CompressFormat.jpeg,
    },
    // Pin images - small size, high quality for clarity
    'pin': {
      'quality': 90,
      'maxWidth': 128,
      'maxHeight': 128,
      'format': CompressFormat.png,
    },
    // Profile images - balanced quality
    'profile': {
      'quality': 80,
      'maxWidth': 200,
      'maxHeight': 200,
      'format': CompressFormat.jpeg,
    },
  };

  // Performance tracking
  int _totalAssetCompressions = 0;
  int _totalBytesSaved = 0;
  final Map<String, int> _compressionStats = {};

  /// Compress all app assets during build time or first run
  Future<void> compressAllAssets() async {
    debugPrint('Starting comprehensive asset compression...');

    final assetsToCompress = [
      'assets/png/pasada_app_icon_text_colored.png',
      'assets/png/pasada_app_icon_text_white.png',
      'assets/png/pasada_main_app_icon.png',
      'assets/png/bus.png',
      'assets/png/bus_h.png',
      'assets/png/pin_pickup.png',
      'assets/png/pin_dropoff.png',
      'assets/png/default_user_profile.png',
    ];

    int successCount = 0;
    int totalBytesSaved = 0;

    for (final assetPath in assetsToCompress) {
      try {
        final originalFile = File(assetPath);
        if (!await originalFile.exists()) {
          debugPrint(' Asset not found: $assetPath');
          continue;
        }

        final originalSize = await originalFile.length();
        final compressedFile = await _compressAsset(assetPath);

        if (compressedFile != null) {
          final compressedSize = await compressedFile.length();
          final bytesSaved = originalSize - compressedSize;
          totalBytesSaved += bytesSaved;
          successCount++;

          debugPrint('Compressed: ${path.basename(assetPath)}');
          debugPrint(
              '   ${_formatBytes(originalSize)} → ${_formatBytes(compressedSize)} (${_formatBytes(bytesSaved)} saved)');
        }
      } catch (e) {
        debugPrint('Failed to compress $assetPath: $e');
      }
    }

    debugPrint('Asset compression completed:');
    debugPrint(
        '   Successfully compressed: $successCount/${assetsToCompress.length} assets');
    debugPrint('   Total space saved: ${_formatBytes(totalBytesSaved)}');
  }

  /// Compress a specific asset with appropriate settings
  Future<File?> _compressAsset(String assetPath) async {
    try {
      final originalFile = File(assetPath);
      final assetName = path.basenameWithoutExtension(assetPath);

      // Determine compression settings based on asset type
      final settings = _getCompressionSettingsForAsset(assetName);

      // Generate cache key
      final cacheKey = await _generateAssetCacheKey(assetPath, settings);

      // Check if already compressed and cached
      final cachedPath = _memoryManager.getFromCache(cacheKey);
      if (cachedPath != null && await File(cachedPath).exists()) {
        return File(cachedPath);
      }

      // Create output path
      final outputPath = await _generateAssetOutputPath(assetPath, settings);

      // Perform compression
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        outputPath,
        quality: settings['quality'],
        minWidth: 50,
        minHeight: 50,
        format: settings['format'] as CompressFormat,
        keepExif: false,
      );

      if (compressedFile != null) {
        // Cache the compressed file path
        _memoryManager.addToCache(cacheKey, compressedFile.path);

        // Update statistics
        final originalSize = await originalFile.length();
        final compressedSize = await compressedFile.length();
        _updateCompressionStats(assetName, originalSize, compressedSize);

        return File(compressedFile.path);
      }

      return null;
    } catch (e) {
      debugPrint('Asset compression error for $assetPath: $e');
      return null;
    }
  }

  /// Get compression settings for a specific asset
  Map<String, dynamic> _getCompressionSettingsForAsset(String assetName) {
    // Check for specific asset patterns
    if (assetName.contains('pasada_app_icon')) {
      return _assetCompressionSettings['pasada_app_icon']!;
    } else if (assetName.contains('bus')) {
      return _assetCompressionSettings['bus']!;
    } else if (assetName.contains('pin')) {
      return _assetCompressionSettings['pin']!;
    } else if (assetName.contains('profile')) {
      return _assetCompressionSettings['profile']!;
    } else {
      // Default settings for unknown assets
      return {
        'quality': 80,
        'maxWidth': 256,
        'maxHeight': 256,
        'format': CompressFormat.jpeg,
      };
    }
  }

  /// Generate cache key for asset compression
  Future<String> _generateAssetCacheKey(
      String assetPath, Map<String, dynamic> settings) async {
    final file = File(assetPath);
    final stats = await file.stat();
    final content =
        '${assetPath}_${settings['quality']}_${settings['maxWidth']}_${settings['maxHeight']}_${stats.size}_${stats.modified.millisecondsSinceEpoch}';
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return 'compressed_asset_${digest.toString().substring(0, 16)}';
  }

  /// Generate output path for compressed asset
  Future<String> _generateAssetOutputPath(
      String originalPath, Map<String, dynamic> settings) async {
    final directory = await getTemporaryDirectory();
    final originalName = path.basenameWithoutExtension(originalPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = settings['format'] == CompressFormat.png ? 'png' : 'jpg';
    return path.join(
        directory.path, 'compressed_${originalName}_$timestamp.$extension');
  }

  /// Update compression statistics
  void _updateCompressionStats(
      String assetName, int originalSize, int compressedSize) {
    _totalAssetCompressions++;
    _totalBytesSaved += (originalSize - compressedSize);
    _compressionStats[assetName] = (_compressionStats[assetName] ?? 0) + 1;
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Get asset compression statistics
  Map<String, dynamic> getAssetCompressionStats() {
    return {
      'total_asset_compressions': _totalAssetCompressions,
      'total_bytes_saved': _totalBytesSaved,
      'total_mb_saved': (_totalBytesSaved / (1024 * 1024)).toStringAsFixed(2),
      'compressions_by_asset': Map.from(_compressionStats),
      'memory_cache_size': _memoryManager.cacheSize,
      'memory_status': _memoryManager.memoryStatus,
    };
  }

  /// Print comprehensive asset compression report
  void printAssetCompressionReport() {
    final stats = getAssetCompressionStats();

    debugPrint('\nASSET COMPRESSION REPORT');
    debugPrint('===============================');
    debugPrint(
        'Total Asset Compressions: ${stats['total_asset_compressions']}');
    debugPrint('Total Space Saved: ${_formatBytes(_totalBytesSaved)}');
    debugPrint(
        'Average Savings per Asset: ${_totalAssetCompressions > 0 ? _formatBytes(_totalBytesSaved ~/ _totalAssetCompressions) : "0B"}');
    debugPrint('\nCompressions by Asset:');
    for (final entry in _compressionStats.entries) {
      debugPrint('  ${entry.key}: ${entry.value} compressions');
    }
    debugPrint('\nMemory Cache Status:');
    debugPrint('  Cache Size: ${_memoryManager.cacheSize} items');
    debugPrint('  Memory Status: ${_memoryManager.memoryStatus}');
    debugPrint(
        '  Cache Efficiency: ${_memoryManager.memoryEfficiencyPercentage}%');
    debugPrint('===============================\n');
  }

  /// Clear asset compression cache
  Future<void> clearAssetCompressionCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFiles = tempDir.listSync();

      int deletedCount = 0;
      for (final file in tempFiles) {
        if (file.path.contains('compressed_') &&
            (file.path.endsWith('.jpg') || file.path.endsWith('.png'))) {
          await file.delete();
          deletedCount++;
        }
      }

      _memoryManager.clearCache();
      debugPrint(
          'Cleared asset compression cache: $deletedCount files deleted');
    } catch (e) {
      debugPrint('Error clearing asset compression cache: $e');
    }
  }

  /// Optimize asset storage by removing old compressed files
  Future<void> optimizeAssetStorage({int maxAgeHours = 24}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final now = DateTime.now();
      final cutoffTime = now.subtract(Duration(hours: maxAgeHours));

      final tempFiles = tempDir.listSync();
      int deletedCount = 0;
      int freedBytes = 0;

      for (final file in tempFiles) {
        if (file.path.contains('compressed_') &&
            (file.path.endsWith('.jpg') || file.path.endsWith('.png'))) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffTime)) {
            freedBytes += stat.size;
            await file.delete();
            deletedCount++;
          }
        }
      }

      debugPrint(
          'Asset storage optimization: Deleted $deletedCount old files, freed ${_formatBytes(freedBytes)}');
    } catch (e) {
      debugPrint('Asset storage optimization error: $e');
    }
  }

  /// Pre-compress assets for faster app startup
  Future<void> preCompressCriticalAssets() async {
    debugPrint('Pre-compressing critical assets for faster startup...');

    final criticalAssets = [
      'assets/png/pasada_main_app_icon.png',
      'assets/png/bus.png',
      'assets/png/pin_pickup.png',
      'assets/png/pin_dropoff.png',
    ];

    for (final assetPath in criticalAssets) {
      try {
        await _compressAsset(assetPath);
        debugPrint('Pre-compressed: ${path.basename(assetPath)}');
      } catch (e) {
        debugPrint('Failed to pre-compress $assetPath: $e');
      }
    }

    debugPrint('Critical asset pre-compression completed');
  }
}
