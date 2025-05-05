import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pasada_passenger_app/functions/notification_preferences.dart';
import 'package:pasada_passenger_app/screens/selectionScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.initialize();
  await NotificationService.showNotification(
    title: message.notification?.title ?? 'Default Title',
    body: message.notification?.body ?? 'Default Body',
  );
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _requestPermissions();

    final String? fcmToken = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $fcmToken');

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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

    await _requestPermissions();
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Got a message whilst in the background.');
    debugPrint('Foreground message received: ${message.data}');

    if (message.notification != null) {
      debugPrint('Foreground message title: ${message.notification}');
    }
  }

  static Future<void> _handleBackgroundMessageTap(RemoteMessage message) async {
    debugPrint('Background message received: ${message.data}');
    _handleNotificationTap();
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
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
  }

  static void _handleNotificationTap() {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const selectionScreen()),
        (route) => false,
      );
    }
  }

  static Future<void> showAvailabilityNotification() async {
    // Check if notifications are enabled before showing
    final bool notificationsEnabled =
        await NotificationPreference.getNotificationStatus();
    if (!notificationsEnabled) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pasada_availability',
      'Booking Availability',
      channelDescription: 'Hello! Magbook ka na, sige na.',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      category: AndroidNotificationCategory.service,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      1,
      'Booking Availability',
      'Hello! Magbook ka na, sige na.',
      platformChannelSpecifics,
    );
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
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  // Save FCM token to your backend (Supabase in this case)
  static Future<void> saveTokenToDatabase(String token) async {
    // Get current user ID from Supabase
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('user_fcm_tokens').upsert(
          {
            'user_id': user.id,
            'fcm_token': token,
            'updated_at': DateTime.now().toIso8601String(),
            'device_info':
                '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'
          },
          onConflict: 'user_id',
        );
        debugPrint('FCM token saved to database');
      } catch (e) {
        debugPrint('Error saving FCM token: $e');
      }
    }
  }
}
