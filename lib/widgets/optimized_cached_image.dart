import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/image_compression_service.dart';
import '../utils/adaptive_memory_manager.dart';

/// Enhanced cached network image with automatic compression and memory optimization
/// Integrates with our custom memory manager and image compression service
class OptimizedCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final CompressionLevel compressionLevel;
  final bool enableMemoryCache;
  final Duration? fadeInDuration;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;

  const OptimizedCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.compressionLevel = CompressionLevel.content,
    this.enableMemoryCache = true,
    this.fadeInDuration,
    this.memCacheWidth,
    this.memCacheHeight,
    this.borderRadius,
  });

  /// Factory constructor for profile images with optimal settings
  factory OptimizedCachedImage.profile({
    required String imageUrl,
    double? size,
    Widget? placeholder,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) {
    return OptimizedCachedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      compressionLevel: CompressionLevel.profile,
      fit: BoxFit.cover,
      placeholder: placeholder,
      errorWidget: errorWidget,
      borderRadius: borderRadius,
      memCacheWidth: size?.toInt(),
      memCacheHeight: size?.toInt(),
      fadeInDuration: const Duration(milliseconds: 300),
    );
  }

  /// Factory constructor for thumbnails with aggressive compression
  factory OptimizedCachedImage.thumbnail({
    required String imageUrl,
    double? size,
    Widget? placeholder,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) {
    return OptimizedCachedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      compressionLevel: CompressionLevel.thumbnail,
      fit: BoxFit.cover,
      placeholder: placeholder,
      errorWidget: errorWidget,
      borderRadius: borderRadius,
      memCacheWidth: size?.toInt(),
      memCacheHeight: size?.toInt(),
      fadeInDuration: const Duration(milliseconds: 200),
    );
  }

  /// Factory constructor for content images with balanced compression
  factory OptimizedCachedImage.content({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) {
    return OptimizedCachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      compressionLevel: CompressionLevel.content,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
      borderRadius: borderRadius,
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      fadeInDuration: const Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check memory pressure and adjust cache behavior
    final memoryManager = AdaptiveMemoryManager();
    final isHighMemoryPressure = memoryManager.memoryPressureLevel > 0.8;

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder != null
          ? (context, url) => placeholder!
          : (context, url) => _buildDefaultPlaceholder(),
      errorWidget: errorWidget != null
          ? (context, url, error) => errorWidget!
          : (context, url, error) => _buildDefaultErrorWidget(),
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 300),

      // Memory optimization based on compression level and memory pressure
      memCacheWidth: isHighMemoryPressure
          ? _getReducedCacheSize(memCacheWidth)
          : memCacheWidth,
      memCacheHeight: isHighMemoryPressure
          ? _getReducedCacheSize(memCacheHeight)
          : memCacheHeight,

      // Cache configuration optimized for memory pressure
      maxWidthDiskCache: _getMaxDiskCacheSize(),
      maxHeightDiskCache: _getMaxDiskCacheSize(),
    );

    // Apply border radius if provided
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Build default placeholder with compression level awareness
  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius,
      ),
      child: _getPlaceholderIcon(),
    );
  }

  /// Get placeholder icon based on compression level
  Widget _getPlaceholderIcon() {
    final iconSize = _getIconSize();

    switch (compressionLevel) {
      case CompressionLevel.profile:
        return Icon(Icons.person, size: iconSize, color: Colors.grey[600]);
      case CompressionLevel.thumbnail:
        return Icon(Icons.image_outlined,
            size: iconSize, color: Colors.grey[600]);
      case CompressionLevel.content:
        return Icon(Icons.photo, size: iconSize, color: Colors.grey[600]);
      case CompressionLevel.minimal:
        return Icon(Icons.image_not_supported_outlined,
            size: iconSize, color: Colors.grey[600]);
    }
  }

  /// Build default error widget
  Widget _buildDefaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.error_outline,
        size: _getIconSize(),
        color: Colors.red[400],
      ),
    );
  }

  /// Get appropriate icon size based on widget dimensions
  double _getIconSize() {
    if (width != null && height != null) {
      return (width! + height!) / 8;
    } else if (width != null) {
      return width! / 4;
    } else if (height != null) {
      return height! / 4;
    }
    return 24.0;
  }

  /// Get max disk cache size based on compression level
  int _getMaxDiskCacheSize() {
    switch (compressionLevel) {
      case CompressionLevel.profile:
        return 1024;
      case CompressionLevel.content:
        return 800;
      case CompressionLevel.thumbnail:
        return 300;
      case CompressionLevel.minimal:
        return 500;
    }
  }

  /// Reduce cache size during high memory pressure
  int? _getReducedCacheSize(int? originalSize) {
    if (originalSize == null) return null;
    return (originalSize * 0.7).round(); // Reduce by 30% during pressure
  }
}

/// Extension to provide memory-aware caching for existing CachedNetworkImage widgets
extension CachedNetworkImageMemoryOptimization on CachedNetworkImage {
  /// Create a memory-optimized version of this image
  Widget optimizeForMemory() {
    final memoryManager = AdaptiveMemoryManager();
    final isHighPressure = memoryManager.memoryPressureLevel > 0.8;

    if (!isHighPressure) {
      return this; // Return original if memory is fine
    }

    // Create optimized version during high memory pressure
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
      fadeInDuration: fadeInDuration,

      // Reduced memory cache during pressure
      memCacheWidth:
          memCacheWidth != null ? (memCacheWidth! * 0.6).round() : null,
      memCacheHeight:
          memCacheHeight != null ? (memCacheHeight! * 0.6).round() : null,

      // Smaller disk cache
      maxWidthDiskCache: 400,
      maxHeightDiskCache: 400,
    );
  }
}

/// Widget that automatically handles image optimization based on current memory state
class AdaptiveImageWidget extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final CompressionLevel compressionLevel;

  const AdaptiveImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.compressionLevel = CompressionLevel.content,
  });

  @override
  State<AdaptiveImageWidget> createState() => _AdaptiveImageWidgetState();
}

class _AdaptiveImageWidgetState extends State<AdaptiveImageWidget> {
  final AdaptiveMemoryManager _memoryManager = AdaptiveMemoryManager();
  late bool _useOptimizedVersion;

  @override
  void initState() {
    super.initState();
    _updateOptimizationState();

    // Listen for memory pressure changes
    _startMemoryMonitoring();
  }

  void _updateOptimizationState() {
    _useOptimizedVersion = _memoryManager.memoryPressureLevel > 0.6;
  }

  void _startMemoryMonitoring() {
    // Check memory state periodically
    _memoryManager.throttle(() {
      final shouldOptimize = _memoryManager.memoryPressureLevel > 0.6;
      if (shouldOptimize != _useOptimizedVersion) {
        setState(() {
          _useOptimizedVersion = shouldOptimize;
        });
      }
    }, const Duration(seconds: 5), 'adaptive_image_monitor');
  }

  @override
  Widget build(BuildContext context) {
    if (_useOptimizedVersion) {
      // Use heavily optimized version during memory pressure
      return OptimizedCachedImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        compressionLevel: CompressionLevel.minimal,
        memCacheWidth:
            widget.width != null ? (widget.width! * 0.5).round() : null,
        memCacheHeight:
            widget.height != null ? (widget.height! * 0.5).round() : null,
      );
    } else {
      // Use normal optimized version
      return OptimizedCachedImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        compressionLevel: widget.compressionLevel,
      );
    }
  }

  @override
  void dispose() {
    // No specific cleanup needed as MemoryManager handles its own lifecycle
    super.dispose();
  }
}
