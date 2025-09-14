import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/asset_preloader_service.dart' as preloader;
import '../utils/adaptive_memory_manager.dart';

/// Optimized SVG widget that uses preloaded assets when available
class OptimizedSvgWidget extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? placeholderWidget;

  const OptimizedSvgWidget(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.placeholderWidget,
  });

  @override
  Widget build(BuildContext context) {
    final preloaderService = preloader.AssetPreloaderService();
    final memoryManager = AdaptiveMemoryManager();

    // Check if SVG is preloaded
    final preloadedSvgData = preloaderService.getPreloadedSvg(assetPath);

    if (preloadedSvgData != null) {
      // Use preloaded SVG data for faster rendering
      return SvgPicture.string(
        preloadedSvgData,
        width: width,
        height: height,
        colorFilter:
            color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
        fit: fit,
        alignment: alignment,
        placeholderBuilder:
            placeholderWidget != null ? (_) => placeholderWidget! : null,
      );
    }

    // Check memory pressure to decide rendering approach
    final isHighMemoryPressure = memoryManager.memoryPressureLevel > 0.7;

    if (isHighMemoryPressure) {
      // Use memory-optimized approach during high pressure
      return SvgPicture.asset(
        assetPath,
        width: width,
        height: height,
        colorFilter:
            color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
        fit: fit,
        alignment: alignment,
        placeholderBuilder: placeholderWidget != null
            ? (_) => placeholderWidget!
            : (_) => _buildDefaultPlaceholder(),
      );
    }

    // Normal rendering with full caching
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      colorFilter:
          color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      fit: fit,
      alignment: alignment,
      placeholderBuilder:
          placeholderWidget != null ? (_) => placeholderWidget! : null,
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.image,
        size: (width != null && height != null)
            ? (width! < height! ? width! : height!) * 0.5
            : 24,
        color: Colors.grey[500],
      ),
    );
  }
}

/// Optimized SVG icon widget for navigation and UI icons
class OptimizedSvgIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color? color;
  final String? semanticLabel;

  const OptimizedSvgIcon(
    this.assetPath, {
    super.key,
    this.size = 24.0,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: OptimizedSvgWidget(
        assetPath,
        width: size,
        height: size,
        color: color,
        fit: BoxFit.contain,
        placeholderWidget: _buildIconPlaceholder(),
      ),
    );
  }

  Widget _buildIconPlaceholder() {
    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        Icons.image,
        size: size * 0.7,
        color: Colors.grey[400],
      ),
    );
  }
}

/// Batch SVG preloader for specific asset groups
class SvgAssetBatcher {
  static final SvgAssetBatcher _instance = SvgAssetBatcher._internal();
  factory SvgAssetBatcher() => _instance;
  SvgAssetBatcher._internal();

  final Map<String, List<String>> _assetGroups = {
    'navigation': [
      'assets/svg/homeIcon.svg',
      'assets/svg/homeSelectedIcon.svg',
      'assets/svg/activityIcon.svg',
      'assets/svg/activitySelectedIcon.svg',
      'assets/svg/notificationIcon.svg',
      'assets/svg/notificationSelectedIcon.svg',
      'assets/svg/profileIcon.svg',
      'assets/svg/profileSelectedIcon.svg',
    ],
    'map': [
      'assets/svg/locationPin.svg',
      'assets/svg/navigation.svg',
      'assets/svg/pickupPin.svg',
      'assets/svg/pindropoff.svg',
    ],
    'branding': [
      'assets/svg/pasadaLogoWithoutText.svg',
      'assets/svg/googleIcon.svg',
    ],
  };

  /// Preload a specific group of SVG assets
  Future<void> preloadGroup(String groupName) async {
    final assets = _assetGroups[groupName];
    if (assets == null) return;

    final preloaderService = preloader.AssetPreloaderService();

    // Create a custom batch with only these assets
    await Future.wait(
      assets.map((asset) async {
        try {
          await preloaderService.preloadAssets(
              maxPriority: AssetPriority.critical);
          debugPrint('Preloaded SVG asset: $asset');
        } catch (e) {
          debugPrint('Failed to preload SVG asset: $asset - $e');
        }
      }),
    );

    debugPrint('Preloaded SVG group: $groupName (${assets.length} assets)');
  }

  /// Get all assets in a group
  List<String>? getGroupAssets(String groupName) => _assetGroups[groupName];

  /// Add custom asset group
  void addAssetGroup(String groupName, List<String> assets) {
    _assetGroups[groupName] = assets;
  }
}

/// Extension to make SVG usage more convenient
extension OptimizedSvgExtension on String {
  /// Convert string path to optimized SVG widget
  OptimizedSvgWidget toOptimizedSvg({
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    return OptimizedSvgWidget(
      this,
      width: width,
      height: height,
      color: color,
      fit: fit,
    );
  }

  /// Convert string path to optimized SVG icon
  OptimizedSvgIcon toOptimizedSvgIcon({
    double size = 24.0,
    Color? color,
    String? semanticLabel,
  }) {
    return OptimizedSvgIcon(
      this,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
  }
}
