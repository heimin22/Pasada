import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal();

  bool _isDarkMode = true; // Default to dark mode
  bool get isDarkMode => _isDarkMode;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? true; // Default to dark mode
    notifyListeners();
  }

  Future<void> toggleTheme(BuildContext context) async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();

    Fluttertoast.showToast(
      msg: 'Please restart the app to fully apply theme changes',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Color(0xFF121212),
      textColor: Color(0xFFF5F5F5),
    );
  }
}
