import 'package:flutter/material.dart';

/// Service to optimize asset loading and identify unused assets
class AssetOptimizerService {
  static final AssetOptimizerService _instance =
      AssetOptimizerService._internal();
  factory AssetOptimizerService() => _instance;
  AssetOptimizerService._internal();

  // Assets that are actually used in the codebase
  static const Set<String> _usedAssets = {
    // Critical navigation assets
    'assets/svg/pasadaLogoWithoutText.svg',
    'assets/svg/homeIcon.svg',
    'assets/svg/homeSelectedIcon.svg',
    'assets/svg/activityIcon.svg',
    'assets/svg/activitySelectedIcon.svg',
    'assets/svg/notificationIcon.svg',
    'assets/svg/notificationSelectedIcon.svg',
    'assets/svg/profileIcon.svg',
    'assets/svg/profileSelectedIcon.svg',

    // Map and location assets
    'assets/svg/locationPin.svg',
    'assets/svg/navigation.svg',
    'assets/svg/pickupPin.svg',
    'assets/svg/pindropoff.svg',
    'assets/svg/pinpickup.svg',

    // Bus and transportation assets
    'assets/svg/bus.svg',
    'assets/png/bus.png',
    'assets/png/bus_h.png',
    'assets/png/pin_pickup.png',
    'assets/png/pin_dropoff.png',

    // Branding and social assets
    'assets/svg/googleIcon.svg',
    'assets/svg/viberIcon.svg',
    'assets/svg/phFlag.svg',

    // App icons
    'assets/png/pasada_main_app_icon.png',
    'assets/png/pasada_app_icon_text_colored.png',
    'assets/png/pasada_app_icon_text_white.png',

    // User profile assets
    'assets/svg/default_user_profile.svg',
    'assets/png/default_user_profile.png',

    // Settings and other options
    'assets/svg/settingsIcon.svg',
    'assets/svg/settingsSelectedIcon.svg',
    'assets/svg/accountSelectedIcon.svg',

    // Content assets
    'assets/md/privacy_policy.md',
    '.env',
  };

  // Assets that can be removed (unused or redundant)
  static const Set<String> _unusedAssets = {
    // All unused assets have been removed during optimization
  };

  /// Check if an asset is actually used in the app
  bool isAssetUsed(String assetPath) {
    return _usedAssets.contains(assetPath);
  }

  /// Get list of unused assets that can be safely removed
  Set<String> getUnusedAssets() {
    return _unusedAssets;
  }

  /// Get list of used assets
  Set<String> getUsedAssets() {
    return _usedAssets;
  }

  /// Generate optimized pubspec.yaml assets section
  String generateOptimizedAssetsSection() {
    final sortedAssets = _usedAssets.toList()..sort();

    final buffer = StringBuffer();
    buffer.writeln('  assets:');

    for (final asset in sortedAssets) {
      buffer.writeln('    - $asset');
    }

    return buffer.toString();
  }

  /// Get asset usage statistics
  Map<String, dynamic> getAssetStats() {
    return {
      'total_used_assets': _usedAssets.length,
      'total_unused_assets': _unusedAssets.length,
      'optimization_potential':
          '${((_unusedAssets.length / (_usedAssets.length + _unusedAssets.length)) * 100).toStringAsFixed(1)}%',
      'used_assets': _usedAssets.toList()..sort(),
      'unused_assets': _unusedAssets.toList()..sort(),
    };
  }

  /// Print asset optimization report
  void printAssetOptimizationReport() {
    final stats = getAssetStats();

    debugPrint('\n📊 ASSET OPTIMIZATION REPORT 📊');
    debugPrint('===============================');
    debugPrint('Used Assets: ${stats['total_used_assets']}');
    debugPrint('Unused Assets: ${stats['total_unused_assets']}');
    debugPrint('Optimization Potential: ${stats['optimization_potential']}');
    debugPrint('\nUnused Assets (can be removed):');
    for (final asset in stats['unused_assets'] as List<String>) {
      debugPrint('  ❌ $asset');
    }
    debugPrint('\nUsed Assets (keep these):');
    for (final asset in stats['used_assets'] as List<String>) {
      debugPrint('  ✅ $asset');
    }
    debugPrint('===============================\n');
  }

  /// Validate asset usage in pubspec.yaml
  bool validatePubspecAssets(List<String> pubspecAssets) {
    final unusedInPubspec = <String>[];
    final missingInPubspec = <String>[];

    // Check for unused assets in pubspec
    for (final asset in pubspecAssets) {
      if (!_usedAssets.contains(asset) && !_unusedAssets.contains(asset)) {
        // Asset in pubspec but not in our tracking - might be newly added
        debugPrint('⚠️  Asset not tracked: $asset');
      }
    }

    // Check for missing used assets
    for (final asset in _usedAssets) {
      if (!pubspecAssets.contains(asset)) {
        missingInPubspec.add(asset);
      }
    }

    if (unusedInPubspec.isNotEmpty) {
      debugPrint('❌ Unused assets in pubspec.yaml:');
      for (final asset in unusedInPubspec) {
        debugPrint('  - $asset');
      }
    }

    if (missingInPubspec.isNotEmpty) {
      debugPrint('❌ Missing used assets in pubspec.yaml:');
      for (final asset in missingInPubspec) {
        debugPrint('  - $asset');
      }
    }

    return unusedInPubspec.isEmpty && missingInPubspec.isEmpty;
  }
}

/// Extension to make asset optimization easier
extension AssetOptimizationExtension on String {
  /// Check if this asset path is used
  bool get isAssetUsed => AssetOptimizerService().isAssetUsed(this);

  /// Check if this asset path is unused
  bool get isAssetUnused =>
      AssetOptimizerService().getUnusedAssets().contains(this);
}
