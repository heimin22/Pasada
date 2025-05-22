import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pasada_passenger_app/services/notificationService.dart';
import 'package:pasada_passenger_app/services/localDatabaseService.dart';

class LoadingDialog extends StatelessWidget {
  final String message;

  const LoadingDialog({super.key, this.message = 'Loading resources...'});

  static Future<void> show(BuildContext context,
      {String message = 'Loading resources...'}) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(message: message),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
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
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00CC58)),
            ),
            const SizedBox(height: 24),
            Text(
              message,
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
      // Initialize shared resources concurrently for efficiency
      await Future.wait([
        _initializeSupabase(),
        _preloadUserPreferences(),
        _initializeLocalDatabase(),
        _configureNotifications(),
      ]);

      // Load user profile data if authenticated
      await _loadUserProfile();

      // Add a slight delay to ensure smooth transition
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('Initialization error: $e');
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

  static Future<void> _loadUserProfile() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      // Fetch user profile data
      final profileData = await Supabase.instance.client
          .from('passenger')
          .select('*')
          .eq('id', currentUser.id)
          .single();

      // Cache profile data in shared preferences for faster access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile', profileData.toString());
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }
}
