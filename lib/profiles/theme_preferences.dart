import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences {
  static const key = 'is_dark_mode';

  static Future<bool> getDarkModeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> setDarkModeStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
