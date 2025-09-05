import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pasada_passenger_app/services/notificationService.dart';
import 'package:pasada_passenger_app/services/localDatabaseService.dart';
import 'package:pasada_passenger_app/services/encryptionService.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:pasada_passenger_app/screens/offflineConnectionCheckService.dart';
import 'package:pasada_passenger_app/widgets/offline_bottom_sheet.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:pasada_passenger_app/providers/weather_provider.dart';
import 'package:pasada_passenger_app/services/location_weather_service.dart';
import 'package:location/location.dart';
import 'package:pasada_passenger_app/services/location_permission_manager.dart';

class LoadingDialog extends StatefulWidget {
  final String message;

  const LoadingDialog({super.key, this.message = 'Loading resources...'});

  static OverlayEntry? _overlayEntry;
  static final ValueNotifier<String> _messageNotifier =
      ValueNotifier('Loading resources...');

  static Future<void> show(BuildContext context,
      {String message = 'Loading resources...'}) async {
    if (_overlayEntry != null) return;

    _messageNotifier.value = message;
    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: ValueListenableBuilder<String>(
            valueListenable: _messageNotifier,
            builder: (context, currentMessage, _) =>
                LoadingDialog(message: currentMessage),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  static void updateMessage(String message) {
    _messageNotifier.value = message;
  }

  static void hide(BuildContext context) {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  State<LoadingDialog> createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<LoadingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _controller,
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00CC58)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class InitializationService {
  static Future<void> initialize(BuildContext context) async {
    try {
      // Initialize and check connectivity first
      LoadingDialog.updateMessage('Checking connectivity...');
      await _initializeConnectivity(context);

      // Check if user is authenticated before initializing resources
      final supabaseAuth = Supabase.instance.client.auth;
      final session = supabaseAuth.currentSession;

      if (session == null) {
        debugPrint('User not authenticated, skipping resource initialization');
        return;
      }

      // Initialize shared resources concurrently for efficiency
      LoadingDialog.updateMessage('Loading core resources...');
      await Future.wait([
        _initializeSupabase(),
        _preloadUserPreferences(),
        _initializeLocalDatabase(),
        _configureNotifications(),
        _initializeEncryption(), // Add encryption initialization
        _preloadGoogleMap(context),
      ]);

      // Load user profile data if authenticated
      LoadingDialog.updateMessage('Loading user profile...');
      await _loadUserProfile();

      // Initialize location services first (required for weather)
      LoadingDialog.updateMessage('Setting up location services...');
      final locationReady = await _initializeLocation(context);

      // Initialize weather data only if location is available
      if (locationReady) {
        LoadingDialog.updateMessage('Loading weather data...');
        await _initializeWeather(context);
      } else {
        debugPrint('Skipping weather initialization - location not available');
      }

      LoadingDialog.updateMessage('Finalizing setup...');
      // Add a slight delay to ensure smooth transition
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('Initialization error: $e');
      rethrow; // Re-throw to handle in calling code
    }
  }

  /// Initialize connectivity service and check internet connection
  static Future<void> _initializeConnectivity(BuildContext context) async {
    // Initialize the connectivity service
    await OfflineConnectionCheckService().initialize();

    // Check initial connectivity
    final isConnected =
        await OfflineConnectionCheckService().checkConnectivity();

    if (!isConnected) {
      debugPrint('No internet connection detected during initialization');

      // Show offline bottom sheet and wait for connection
      await _handleOfflineState(context);
    }
  }

  /// Handle offline state by showing bottom sheet until connection is restored
  static Future<void> _handleOfflineState(BuildContext context) async {
    final connectivityService = OfflineConnectionCheckService();

    // Only show the bottom sheet if it's not already shown
    if (!connectivityService.isOfflineBottomSheetShown) {
      connectivityService.setOfflineBottomSheetShown(true);

      final completer = Completer<void>();

      // Show the offline bottom sheet
      await OfflineBottomSheet.show(
        context,
        onConnectionRestored: () async {
          debugPrint('Connection restored, continuing initialization');
          connectivityService.setOfflineBottomSheetShown(false);
          completer.complete();
        },
        isPersistent: true,
      );

      // Wait until connection is restored
      await completer.future;
    } else {
      debugPrint(
          'Offline bottom sheet already shown, waiting for connection silently');

      // Wait for connection without showing another bottom sheet
      final completer = Completer<void>();
      late StreamSubscription<bool> subscription;

      subscription = connectivityService.connectionStream.listen((isConnected) {
        if (isConnected) {
          debugPrint('Connection restored silently');
          subscription.cancel();
          completer.complete();
        }
      });

      // Check if already connected
      if (connectivityService.isConnected) {
        subscription.cancel();
        completer.complete();
      }

      await completer.future;
    }
  }

  static Future<void> _initializeSupabase() async {
    final supabaseAuth = Supabase.instance.client.auth;

    // Check if user session exists and refresh if needed
    final session = supabaseAuth.currentSession;
    if (session != null) {
      // Refresh session if expired or close to expiring (within 5 minutes)
      if (session.expiresAt != null &&
          DateTime.now().millisecondsSinceEpoch >
              (session.expiresAt! * 1000) - 300000) {
        await supabaseAuth.refreshSession();
      }
    }
  }

  static Future<void> _preloadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Preload commonly used preferences for faster access
    await prefs.reload(); // Ensure we have the latest values
  }

  static Future<void> _initializeLocalDatabase() async {
    // Initialize the local database
    final localDb = LocalDatabaseService();
    await localDb.initDatabase();

    // No need for maintenance tasks since it's not implemented
    // Just add a debug print for info
    debugPrint('Local database initialized');
  }

  static Future<void> _configureNotifications() async {
    // Initialize notification services
    await NotificationService.initialize();

    // Use the existing method in NotificationService
    await NotificationService.saveTokenAfterInit();
  }

  static Future<void> _initializeEncryption() async {
    // Initialize encryption service for secure user data handling
    final encryptionService = EncryptionService();
    await encryptionService.initialize();

    // Test encryption to ensure it's working properly
    final testPassed = await encryptionService.testEncryption();
    if (!testPassed) {
      throw Exception('Encryption service test failed');
    }

    debugPrint('Encryption service initialized and tested successfully');
  }

  static Future<void> _loadUserProfile() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      // Initialize AuthService to handle migration
      final authService = AuthService();

      // Migrate existing user data to encrypted format if needed
      await authService.migrateExistingUserDataToEncrypted();

      // Fetch user profile data (now decrypted automatically)
      final profileData = await authService.getCurrentUserData();

      if (profileData != null) {
        // Cache profile data in shared preferences for faster access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', profileData.toString());
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  // Preload a hidden GoogleMap to warm up the map rendering engine
  static Future<void> _preloadGoogleMap(BuildContext context) async {
    final completer = Completer<GoogleMapController>();
    final overlay = Overlay.of(context);
    // Use 1x1 pixel to fully initialize the map engine
    final entry = OverlayEntry(
        builder: (_) => SizedBox(
              width: 1,
              height: 1,
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(0, 0),
                  zoom: 1,
                ),
                onMapCreated: (controller) {
                  completer.complete(controller);
                },
              ),
            ));
    overlay.insert(entry);
    try {
      await completer.future.timeout(const Duration(seconds: 5));
    } catch (_) {
      // ignore timeout or errors
    }
    entry.remove();
  }

  /// Initialize location services and permissions
  static Future<bool> _initializeLocation(BuildContext context) async {
    try {
      final locationManager = LocationPermissionManager.instance;

      // Ensure location permissions are granted with reasonable timeout
      final locationReady = await locationManager.ensureLocationReady().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Location permission setup timed out');
          return false;
        },
      );

      if (!locationReady) {
        debugPrint(
            'Location not ready - permissions not granted or service unavailable');
        return false;
      }

      // Test if we can actually get location data
      try {
        final location = Location();
        final locationData = await location.getLocation().timeout(
              const Duration(seconds: 8),
              onTimeout: () => throw TimeoutException(
                  'Location fetch timeout', const Duration(seconds: 8)),
            );

        if (locationData.latitude != null && locationData.longitude != null) {
          debugPrint('Location services initialized successfully');
          return true;
        } else {
          debugPrint('Location data is invalid');
          return false;
        }
      } catch (e) {
        debugPrint('Error getting initial location: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Error initializing location services: $e');
      return false;
    }
  }

  /// Initialize weather data during resource loading (assumes location is ready)
  static Future<void> _initializeWeather(BuildContext context) async {
    try {
      final weatherProvider = context.read<WeatherProvider>();

      // Since location is already confirmed to be ready, use a shorter timeout
      final weatherInitialized = await LocationWeatherService.fetchAndSubscribe(
        weatherProvider,
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('Weather initialization timed out');
          return false;
        },
      );

      if (!weatherInitialized) {
        debugPrint(
            'Weather initialization failed despite location being ready');
      } else {
        debugPrint('Weather initialized successfully');
      }
    } catch (e) {
      debugPrint('Error initializing weather: $e');
      // Don't throw error, weather loading failure shouldn't block app initialization
    }
  }
}
