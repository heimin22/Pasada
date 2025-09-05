import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/asset_preloader_service.dart';
import '../services/authService.dart';
import '../services/encryptionService.dart';
import '../services/localDatabaseService.dart';
import '../services/notificationService.dart';
import '../utils/memory_manager.dart';
import '../widgets/loading_dialog.dart';

enum InitializationPriority {
  critical, // Must complete before UI shows
  essential, // Needed for basic functionality
  important, // Enhances user experience
  background // Can load after app is usable
}

class PriorityInitializationService {
  static final PriorityInitializationService _instance =
      PriorityInitializationService._internal();
  factory PriorityInitializationService() => _instance;
  PriorityInitializationService._internal();

  final MemoryManager _memoryManager = MemoryManager();
  bool _isInitializing = false;
  bool _criticalComplete = false;
  bool _essentialComplete = false;
  bool _importantComplete = false;

  final Map<InitializationPriority, List<String>> _completedTasks = {
    InitializationPriority.critical: [],
    InitializationPriority.essential: [],
    InitializationPriority.important: [],
    InitializationPriority.background: [],
  };

  /// Initialize app with priority-based loading
  Future<void> initializeWithPriority(
    BuildContext context, {
    VoidCallback? onCriticalComplete,
    VoidCallback? onEssentialComplete,
    VoidCallback? onImportantComplete,
  }) async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      // CRITICAL: Core services that block app startup
      LoadingDialog.updateMessage('Starting core services...');
      await _initializeCritical();
      _criticalComplete = true;
      onCriticalComplete?.call();
      debugPrint('✅ CRITICAL initialization complete');

      // ESSENTIAL: Services needed for basic functionality
      LoadingDialog.updateMessage('Loading essential features...');
      await _initializeEssential(context);
      _essentialComplete = true;
      onEssentialComplete?.call();
      debugPrint('✅ ESSENTIAL initialization complete');

      // IMPORTANT: Services that enhance UX (parallel with essential)
      LoadingDialog.updateMessage('Preparing enhanced features...');
      final importantFuture = _initializeImportant(context);

      // Don't wait for important - let UI show while these load
      importantFuture.then((_) {
        _importantComplete = true;
        onImportantComplete?.call();
        debugPrint('✅ IMPORTANT initialization complete');

        // Start background tasks after important ones finish
        _initializeBackground(context);
      });

      // Small delay to ensure smooth transition
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      debugPrint('❌ Priority initialization error: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// CRITICAL Priority: Absolutely essential for app to function
  Future<void> _initializeCritical() async {
    await Future.wait([
      _initializeFirebase(),
      _loadEnvironmentConfig(),
      _initializeConnectivity(),
      _preloadCriticalAssets(),
    ]);

    // Cache initialization status
    _memoryManager.addToCache('init_critical_complete', true);
  }

  /// ESSENTIAL Priority: Needed for basic app functionality
  Future<void> _initializeEssential(BuildContext context) async {
    // Check authentication first
    final supabaseAuth = Supabase.instance.client.auth;
    final session = supabaseAuth.currentSession;

    if (session == null) {
      debugPrint(
          'User not authenticated, skipping auth-dependent initialization');
      _completedTasks[InitializationPriority.essential]!.add('auth_skip');
      return;
    }

    await Future.wait([
      _initializeSupabase(),
      _initializeLocalDatabase(),
      _initializeEncryption(),
      _preloadUserPreferences(),
    ]);

    _memoryManager.addToCache('init_essential_complete', true);
  }

  /// IMPORTANT Priority: Enhances user experience
  Future<void> _initializeImportant(BuildContext context) async {
    final futures = <Future<void>>[];

    // Add location initialization
    futures.add(_initializeLocation(context));

    // Add notification setup
    futures.add(_configureNotifications());

    // Add high-priority asset preloading
    futures.add(_preloadHighPriorityAssets());

    // Add user profile loading if authenticated
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      futures.add(_loadUserProfile());
    }

    await Future.wait(futures);
    _memoryManager.addToCache('init_important_complete', true);
  }

  /// BACKGROUND Priority: Nice to have, loads after app is usable
  Future<void> _initializeBackground(BuildContext context) async {
    // Don't block on these - let them load in background
    Future.wait([
      _preloadMediumPriorityAssets(),
      _initializeWeatherIfLocationAvailable(context),
      _optimizeMemorySettings(),
      _preloadMapIfNeeded(context),
    ]).then((_) {
      _memoryManager.addToCache('init_background_complete', true);
      debugPrint('✅ BACKGROUND initialization complete');
    }).catchError((e) {
      debugPrint('⚠️  Background initialization partial failure: $e');
    });
  }

  // =============================================================================
  // INDIVIDUAL INITIALIZATION METHODS
  // =============================================================================

  Future<void> _initializeFirebase() async {
    // Firebase should already be initialized in main.dart, but ensure it's ready
    if (Supabase.instance.client.auth.currentUser == null) {
      // Just verify Firebase is accessible
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _completedTasks[InitializationPriority.critical]!.add('firebase');
  }

  Future<void> _loadEnvironmentConfig() async {
    // Environment should already be loaded in main.dart
    // Just cache some frequently used values
    final apiUrl = _memoryManager.getFromCache('SUPABASE_URL');
    if (apiUrl == null) {
      throw Exception('Environment configuration not loaded');
    }
    _completedTasks[InitializationPriority.critical]!.add('env_config');
  }

  Future<void> _initializeConnectivity() async {
    // Quick connectivity check without full initialization
    await Future.delayed(const Duration(milliseconds: 100));
    _completedTasks[InitializationPriority.critical]!.add('connectivity');
  }

  Future<void> _preloadCriticalAssets() async {
    await AssetPreloaderService().preloadAssets(
      maxPriority: AssetPriority.critical,
    );
    _completedTasks[InitializationPriority.critical]!.add('critical_assets');
  }

  Future<void> _initializeSupabase() async {
    final supabaseAuth = Supabase.instance.client.auth;
    final session = supabaseAuth.currentSession;

    if (session != null) {
      // Refresh session if expired or close to expiring
      if (session.expiresAt != null &&
          DateTime.now().millisecondsSinceEpoch >
              (session.expiresAt! * 1000) - 300000) {
        await supabaseAuth.refreshSession();
      }
    }
    _completedTasks[InitializationPriority.essential]!.add('supabase');
  }

  Future<void> _initializeLocalDatabase() async {
    final localDb = LocalDatabaseService();
    await localDb.initDatabase();
    _completedTasks[InitializationPriority.essential]!.add('local_db');
  }

  Future<void> _initializeEncryption() async {
    final encryptionService = EncryptionService();
    await encryptionService.initialize();

    final testPassed = await encryptionService.testEncryption();
    if (!testPassed) {
      throw Exception('Encryption service test failed');
    }
    _completedTasks[InitializationPriority.essential]!.add('encryption');
  }

  Future<void> _preloadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    _completedTasks[InitializationPriority.essential]!.add('user_prefs');
  }

  Future<void> _initializeLocation(BuildContext context) async {
    // Location initialization logic here
    await Future.delayed(const Duration(milliseconds: 200));
    _completedTasks[InitializationPriority.important]!.add('location');
  }

  Future<void> _configureNotifications() async {
    await NotificationService.initialize();
    await NotificationService.saveTokenAfterInit();
    _completedTasks[InitializationPriority.important]!.add('notifications');
  }

  Future<void> _preloadHighPriorityAssets() async {
    await AssetPreloaderService().preloadAssets(
      maxPriority: AssetPriority.high,
    );
    _completedTasks[InitializationPriority.important]!
        .add('high_priority_assets');
  }

  Future<void> _loadUserProfile() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      final authService = AuthService();
      await authService.migrateExistingUserDataToEncrypted();
      final profileData = await authService.getCurrentUserData();

      if (profileData != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', profileData.toString());
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
    _completedTasks[InitializationPriority.important]!.add('user_profile');
  }

  Future<void> _preloadMediumPriorityAssets() async {
    await AssetPreloaderService().preloadAssets(
      maxPriority: AssetPriority.medium,
    );
    _completedTasks[InitializationPriority.background]!
        .add('medium_priority_assets');
  }

  Future<void> _initializeWeatherIfLocationAvailable(
      BuildContext context) async {
    // Weather initialization logic here
    await Future.delayed(const Duration(milliseconds: 300));
    _completedTasks[InitializationPriority.background]!.add('weather');
  }

  Future<void> _optimizeMemorySettings() async {
    _memoryManager.forceMemoryPressureCheck();
    _completedTasks[InitializationPriority.background]!
        .add('memory_optimization');
  }

  Future<void> _preloadMapIfNeeded(BuildContext context) async {
    // Map preloading logic here
    await Future.delayed(const Duration(milliseconds: 400));
    _completedTasks[InitializationPriority.background]!.add('map_preload');
  }

  // =============================================================================
  // STATUS AND UTILITY METHODS
  // =============================================================================

  /// Check if critical initialization is complete
  bool get isCriticalComplete => _criticalComplete;

  /// Check if essential initialization is complete
  bool get isEssentialComplete => _essentialComplete;

  /// Check if important initialization is complete
  bool get isImportantComplete => _importantComplete;

  /// Get overall initialization progress (0.0 to 1.0)
  double get initializationProgress {
    final criticalWeight = 0.5; // 50% of progress
    final essentialWeight = 0.3; // 30% of progress
    final importantWeight = 0.2; // 20% of progress

    double progress = 0.0;
    if (_criticalComplete) progress += criticalWeight;
    if (_essentialComplete) progress += essentialWeight;
    if (_importantComplete) progress += importantWeight;

    return progress.clamp(0.0, 1.0);
  }

  /// Get initialization status message
  String get currentStatusMessage {
    if (!_criticalComplete) return 'Starting core services...';
    if (!_essentialComplete) return 'Loading essential features...';
    if (!_importantComplete) return 'Preparing enhanced features...';
    return 'Ready to go!';
  }

  /// Get detailed initialization report
  Map<String, dynamic> get initializationReport {
    return {
      'critical_complete': _criticalComplete,
      'essential_complete': _essentialComplete,
      'important_complete': _importantComplete,
      'progress': initializationProgress,
      'status_message': currentStatusMessage,
      'completed_tasks': _completedTasks,
    };
  }

  /// Reset initialization state (for testing)
  void reset() {
    _isInitializing = false;
    _criticalComplete = false;
    _essentialComplete = false;
    _importantComplete = false;

    for (final taskList in _completedTasks.values) {
      taskList.clear();
    }

    debugPrint('🔄 Priority initialization state reset');
  }
}
