import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pasada_passenger_app/functions/notification_preferences.dart';
import 'package:pasada_passenger_app/screens/selectionScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:bcrypt/bcrypt.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _requestPermissions();

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked with payload: ${response.payload}');
        _handleNotificationTap();
      },
    );

    // Set up FCM handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Get FCM token and save it - but only if Supabase is initialized
    try {
      final String? fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        debugPrint('FCM Token: $fcmToken');
        // Only save token if Supabase is initialized
        await saveTokenToDatabase(fcmToken);
      }

      // Set up token refresh listener
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed');
        // We'll try to save the token, but it will only work if Supabase is initialized
        saveTokenToDatabase(newToken);
      });
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  // This method can be called after Supabase is fully initialized
  static Future<void> saveTokenAfterInit() async {
    try {
      final String? fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        await saveTokenToDatabase(fcmToken);
      }
    } catch (e) {
      debugPrint('Error saving token after init: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message received: ${message.data}');

    if (message.notification != null) {
      await showNotification(
        title: message.notification?.title ?? 'Pasada',
        body: message.notification?.body ?? 'You have a new notification',
      );
    }
  }

  static Future<void> _handleBackgroundMessageTap(RemoteMessage message) async {
    debugPrint('Background message tapped: ${message.data}');
    _handleNotificationTap();
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final bool notificationsEnabled =
          await NotificationPreference.getNotificationStatus();
      if (!notificationsEnabled) return;

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'pasada_notifications',
        'Pasada Notifications',
        channelDescription: 'Notifications for Pasada',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.service,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  static void _handleNotificationTap() {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const selectionScreen()),
        (route) => false,
      );
    }
  }

  // Send booking availability notification via FCM
  static Future<void> showAvailabilityNotification() async {
    try {
      // Check if notifications are enabled before showing
      final bool notificationsEnabled =
          await NotificationPreference.getNotificationStatus();
      if (!notificationsEnabled) return;

      // Get current user
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('No user logged in, showing generic notification');
        await showNotification(
          title: 'Pasada',
          body: 'You can now book a ride!',
        );
        return;
      }

      try {
        // Get user's display name
        final userData = await Supabase.instance.client
            .from('passenger')
            .select('display_name')
            .eq('id', user.id)
            .single();

        final String userName = userData['display_name'] ?? 'user';

        // For local notification fallback
        await showNotification(
          title: 'Pasada',
          body: 'Hello $userName, pwedeng-pwede ka na magbook, boss!',
        );

        // The actual FCM notification will be sent from the server
        // This is just a local fallback
      } catch (e) {
        debugPrint('Error getting user data: $e');
        await showNotification(
          title: 'Pasada',
          body: 'You can now book a ride!',
        );
      }
    } catch (e) {
      debugPrint('Error showing availability notification: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  static Future<bool> checkPermissions() async {
    final bool? permissionGranted = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();

    return permissionGranted ?? false;
  }

  static Future<void> _requestPermissions() async {
    try {
      // Request permission for FCM
      final NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCM permission status: ${settings.authorizationStatus}');

      // Request permission for local notifications
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  // Save FCM token to your backend (Supabase in this case)
  static Future<void> saveTokenToDatabase(String token) async {
    try {
      bool isSupabaseInitialized = false;
      try {
        final _ = Supabase.instance.client;
        isSupabaseInitialized = true;
      } catch (e) {
        isSupabaseInitialized = false;
      }

      if (!isSupabaseInitialized) {
        debugPrint('Supabase not initialized, skipping token save');
        return;
      }

      // Get current user ID from Supabase
      final user = Supabase.instance.client.auth.currentUser;

      // Get device info and encrypt it
      final rawDeviceInfo =
          '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
      final deviceInfo = BCrypt.hashpw(rawDeviceInfo, BCrypt.gensalt());

      if (user != null) {
        try {
          await Supabase.instance.client.rpc(
            'save_fcm_token',
            params: {
              'p_token': token,
              'p_device_info': deviceInfo,
            },
          );
          debugPrint('FCM token saved to database');
        } catch (e) {
          if (e.toString().contains('auth') ||
              e.toString().contains('Not initialized')) {
            debugPrint('User not authenticated, skipping FCM token save');
            return;
          }
          debugPrint('Error saving FCM token: $e');
        }
      } else {
        debugPrint('No user logged in, cannot save token');
      }
    } catch (e) {
      debugPrint('Error in saveTokenToDatabase: $e');
    }
  }
}
