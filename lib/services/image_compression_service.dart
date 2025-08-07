import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../utils/memory_manager.dart';

/// Different compression levels for various use cases
enum CompressionLevel {
  /// High quality for profile pictures (85% quality, max 1024px)
  profile,

  /// Medium quality for content images (75% quality, max 800px)
  content,

  /// Low quality for thumbnails (60% quality, max 300px)
  thumbnail,

  /// Maximum compression for network-constrained scenarios (45% quality, max 500px)
  minimal,
}

/// Comprehensive image compression service with memory optimization
/// Automatically compresses images based on usage context and device capabilities
class ImageCompressionService {
  static final ImageCompressionService _instance =
      ImageCompressionService._internal();
  factory ImageCompressionService() => _instance;
  ImageCompressionService._internal();

  final MemoryManager _memoryManager = MemoryManager();

  // Performance tracking
  int _totalCompressions = 0;
  int _totalBytesSaved = 0;
  final Map<CompressionLevel, int> _compressionStats = {};

  /// Compression settings for each level
  static final Map<CompressionLevel, Map<String, dynamic>>
      _compressionSettings = {
    CompressionLevel.profile: {
      'quality': 85,
      'maxWidth': 1024,
      'maxHeight': 1024,
      'format': CompressFormat.jpeg,
    },
    CompressionLevel.content: {
      'quality': 75,
      'maxWidth': 800,
      'maxHeight': 800,
      'format': CompressFormat.jpeg,
    },
    CompressionLevel.thumbnail: {
      'quality': 60,
      'maxWidth': 300,
      'maxHeight': 300,
      'format': CompressFormat.jpeg,
    },
    CompressionLevel.minimal: {
      'quality': 45,
      'maxWidth': 500,
      'maxHeight': 500,
      'format': CompressFormat.jpeg,
    },
  };

  /// Compress a file with automatic level detection based on size
  Future<File?> compressImage(
    File imageFile, {
    CompressionLevel? level,
    String? customPath,
  }) async {
    try {
      final startTime = DateTime.now();
      final originalSize = await imageFile.length();

      // Auto-detect compression level if not provided
      level ??= _autoDetectCompressionLevel(originalSize);

      final settings = _compressionSettings[level]!;

      // Generate cache key for this compression
      final cacheKey = await _generateCacheKey(imageFile.path, level);

      // Check if already compressed and cached
      final cachedPath = _memoryManager.getFromCache(cacheKey);
      if (cachedPath != null && await File(cachedPath).exists()) {
        debugPrint('📸 Image compression: Using cached compressed image');
        return File(cachedPath);
      }

      // Create output path
      final outputPath =
          customPath ?? await _generateOutputPath(imageFile.path, level);

      debugPrint('📸 Starting image compression:');
      debugPrint('   Level: ${level.name}');
      debugPrint('   Original size: ${_formatBytes(originalSize)}');
      debugPrint('   Quality: ${settings['quality']}%');
      debugPrint(
          '   Max dimensions: ${settings['maxWidth']}x${settings['maxHeight']}');

      // Perform compression
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        outputPath,
        quality: settings['quality'],
        minWidth: 100,
        minHeight: 100,
        format: settings['format'] as CompressFormat,
        keepExif: false, // Remove metadata to save space
      );

      if (compressedFile == null) {
        debugPrint('❌ Image compression failed');
        return null;
      }

      final compressedSize = await compressedFile.length();
      final compressionRatio =
          ((originalSize - compressedSize) / originalSize * 100);
      final compressionTime =
          DateTime.now().difference(startTime).inMilliseconds;

      // Update statistics
      _updateCompressionStats(level, originalSize, compressedSize);

      // Cache the compressed file path
      _memoryManager.addToCache(cacheKey, compressedFile.path);

      debugPrint('✅ Image compression completed:');
      debugPrint('   Compressed size: ${_formatBytes(compressedSize)}');
      debugPrint(
          '   Space saved: ${_formatBytes(originalSize - compressedSize)} (${compressionRatio.toStringAsFixed(1)}%)');
      debugPrint('   Compression time: ${compressionTime}ms');

      return File(compressedFile.path);
    } catch (e) {
      debugPrint('❌ Image compression error: $e');
      return null;
    }
  }

  /// Compress multiple images in batch with progress callback
  Future<List<File?>> compressMultipleImages(
    List<File> imageFiles, {
    CompressionLevel level = CompressionLevel.content,
    Function(int completed, int total)? onProgress,
  }) async {
    final results = <File?>[];

    debugPrint('📸 Starting batch compression of ${imageFiles.length} images');
    final batchStartTime = DateTime.now();

    for (int i = 0; i < imageFiles.length; i++) {
      final compressed = await compressImage(imageFiles[i], level: level);
      results.add(compressed);

      onProgress?.call(i + 1, imageFiles.length);

      // Allow UI to update between compressions
      await Future.delayed(const Duration(milliseconds: 10));
    }

    final batchTime = DateTime.now().difference(batchStartTime).inSeconds;
    debugPrint('✅ Batch compression completed in ${batchTime}s');

    return results;
  }

  /// Compress image data in memory (useful for network images)
  Future<Uint8List?> compressImageData(
    Uint8List imageData, {
    CompressionLevel level = CompressionLevel.content,
  }) async {
    try {
      final settings = _compressionSettings[level]!;

      final compressed = await FlutterImageCompress.compressWithList(
        imageData,
        quality: settings['quality'],
        format: settings['format'] as CompressFormat,
        keepExif: false,
      );

      final originalSize = imageData.length;
      final compressedSize = compressed.length;
      final ratio = ((originalSize - compressedSize) / originalSize * 100);

      debugPrint(
          '📸 Memory compression: ${_formatBytes(originalSize)} → ${_formatBytes(compressedSize)} (${ratio.toStringAsFixed(1)}% saved)');

      return compressed;
    } catch (e) {
      debugPrint('❌ Memory compression error: $e');
      return null;
    }
  }

  /// Auto-detect optimal compression level based on file size
  CompressionLevel _autoDetectCompressionLevel(int fileSizeBytes) {
    const mbSize = 1024 * 1024;

    if (fileSizeBytes > 5 * mbSize) {
      return CompressionLevel.minimal; // >5MB: aggressive compression
    } else if (fileSizeBytes > 2 * mbSize) {
      return CompressionLevel.content; // 2-5MB: standard compression
    } else if (fileSizeBytes > 500 * 1024) {
      return CompressionLevel.profile; // 500KB-2MB: light compression
    } else {
      return CompressionLevel.thumbnail; // <500KB: minimal compression
    }
  }

  /// Generate cache key for compression result
  Future<String> _generateCacheKey(
      String imagePath, CompressionLevel level) async {
    final file = File(imagePath);
    final stats = await file.stat();
    final content =
        '${imagePath}_${level.name}_${stats.size}_${stats.modified.millisecondsSinceEpoch}';
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return 'compressed_${digest.toString().substring(0, 16)}';
  }

  /// Generate output path for compressed image
  Future<String> _generateOutputPath(
      String originalPath, CompressionLevel level) async {
    final directory = await getTemporaryDirectory();
    final originalName = path.basenameWithoutExtension(originalPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return path.join(directory.path,
        'compressed_${originalName}_${level.name}_$timestamp.jpg');
  }

  /// Update compression statistics
  void _updateCompressionStats(
      CompressionLevel level, int originalSize, int compressedSize) {
    _totalCompressions++;
    _totalBytesSaved += (originalSize - compressedSize);
    _compressionStats[level] = (_compressionStats[level] ?? 0) + 1;
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Get compression statistics
  Map<String, dynamic> getCompressionStats() {
    return {
      'total_compressions': _totalCompressions,
      'total_bytes_saved': _totalBytesSaved,
      'total_mb_saved': (_totalBytesSaved / (1024 * 1024)).toStringAsFixed(2),
      'compressions_by_level': Map.fromEntries(
        _compressionStats.entries.map((e) => MapEntry(e.key.name, e.value)),
      ),
      'memory_cache_size': _memoryManager.cacheSize,
      'memory_status': _memoryManager.memoryStatus,
    };
  }

  /// Print comprehensive compression report
  void printCompressionReport() {
    debugPrint('\n📊 IMAGE COMPRESSION REPORT 📊');
    debugPrint('===============================');
    debugPrint('Total Compressions: $_totalCompressions');
    debugPrint('Total Space Saved: ${_formatBytes(_totalBytesSaved)}');
    debugPrint(
        'Average Savings per Image: ${_totalCompressions > 0 ? _formatBytes(_totalBytesSaved ~/ _totalCompressions) : "0B"}');
    debugPrint('\nCompressions by Level:');
    for (final entry in _compressionStats.entries) {
      debugPrint('  ${entry.key.name}: ${entry.value} images');
    }
    debugPrint('\nMemory Cache Status:');
    debugPrint('  Cache Size: ${_memoryManager.cacheSize} items');
    debugPrint('  Memory Status: ${_memoryManager.memoryStatus}');
    debugPrint(
        '  Cache Efficiency: ${_memoryManager.memoryEfficiencyPercentage}%');
    debugPrint('===============================\n');
  }

  /// Clear compression cache
  Future<void> clearCompressionCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFiles = tempDir.listSync();

      int deletedCount = 0;
      for (final file in tempFiles) {
        if (file.path.contains('compressed_') && file.path.endsWith('.jpg')) {
          await file.delete();
          deletedCount++;
        }
      }

      _memoryManager.clearCache();
      debugPrint('🧹 Cleared compression cache: $deletedCount files deleted');
    } catch (e) {
      debugPrint('❌ Error clearing compression cache: $e');
    }
  }

  /// Optimize storage by removing old compressed files
  Future<void> optimizeStorage({int maxAgeHours = 24}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final now = DateTime.now();
      final cutoffTime = now.subtract(Duration(hours: maxAgeHours));

      final tempFiles = tempDir.listSync();
      int deletedCount = 0;
      int freedBytes = 0;

      for (final file in tempFiles) {
        if (file.path.contains('compressed_') && file.path.endsWith('.jpg')) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffTime)) {
            freedBytes += stat.size;
            await file.delete();
            deletedCount++;
          }
        }
      }

      debugPrint(
          '🗑️ Storage optimization: Deleted $deletedCount old files, freed ${_formatBytes(freedBytes)}');
    } catch (e) {
      debugPrint('❌ Storage optimization error: $e');
    }
  }

  /// Force memory pressure cleanup for image cache
  void forceImageCacheCleanup() {
    _memoryManager.forceMemoryPressureCheck();
    debugPrint('🧹 Forced image cache cleanup completed');
  }
}

/// Convenient extension methods for easy integration
extension ImageCompressionExtensions on File {
  /// Quick compression with auto-detection
  Future<File?> compress({CompressionLevel? level}) {
    return ImageCompressionService().compressImage(this, level: level);
  }

  /// Compress specifically for profile use
  Future<File?> compressForProfile() {
    return ImageCompressionService()
        .compressImage(this, level: CompressionLevel.profile);
  }

  /// Compress for thumbnail
  Future<File?> compressForThumbnail() {
    return ImageCompressionService()
        .compressImage(this, level: CompressionLevel.thumbnail);
  }
}
