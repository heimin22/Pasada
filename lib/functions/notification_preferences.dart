import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreference {
  static const key = 'notification_enabled';

  static Future<bool> getNotificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? true;
  }

  static Future<void> setNotificationStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}