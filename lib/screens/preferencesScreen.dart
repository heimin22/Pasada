import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/widgets/theme_preferences.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:pasada_passenger_app/theme/theme_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:pasada_passenger_app/functions/notification_preferences.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => PreferencesScreenState();
}

class PreferencesScreenState extends State<PreferencesScreen> {
  bool notificationsEnabled = true;
  bool isDarkMode = false;
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    loadNotificationPreferences();
    loadThemePreferences();
  }

  Future<void> loadThemePreferences() async {
    final darkMode = await ThemePreferences.getDarkModeStatus();
    setState(() => isDarkMode = darkMode);
  }

  Future<void> loadNotificationPreferences() async {
    final enabled = await NotificationPreference.getNotificationStatus();
    setState(() => notificationsEnabled = enabled);
  }

  Future<void> toggleDarkMode(bool value) async {
    // Update UI immediately
    setState(() => isDarkMode = value);

    // Update theme preferences
    await ThemePreferences.setDarkModeStatus(value);

    // Update the theme immediately using ThemeController
    if (mounted) {
      final themeController = ThemeController();
      await themeController.toggleTheme(context);
    }
  }

  Future<void> toggleNotification(bool value) async {
    setState(() => notificationsEnabled = value);
    await NotificationPreference.setNotificationStatus(value);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: buildAppBar(isDarkMode),
      body: buildBody(screenSize, isDarkMode),
    );
  }

  PreferredSizeWidget buildAppBar(bool isDarkMode) {
    return AppBar(
      title: Text(
        'Preferences',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
        ),
      ),
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      foregroundColor:
          isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
      elevation: 1.0,
    );
  }

  Widget buildBody(Size screenSize, bool isDarkMode) {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: 12),
          buildNotificationSection(screenSize.width, isDarkMode),
          buildAppSettingsSection(
              screenSize.width, screenSize.height, isDarkMode),
        ],
      ),
    );
  }

  // settings section ng notification
  Widget buildNotificationSection(double screenWidth, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            buildSectionHeader('Notifications', screenWidth, isDarkMode),
            buildToggleListItem(
              'Push Notifications',
              'Enable/disable app notifications',
              notificationsEnabled,
              toggleNotification,
              screenWidth,
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  // additional application settings section
  Widget buildAppSettingsSection(
      double screenWidth, double screenHeight, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.02, horizontal: screenWidth * 0.03),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            buildSectionHeader('App Settings', screenWidth, isDarkMode),
            buildToggleListItem(
              'Dark Mode',
              'Switch screen appearance to dark mode',
              isDarkMode,
              toggleDarkMode,
              screenWidth,
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

// section header helper
  Widget buildSectionHeader(String title, double screenWidth, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.03),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
          ),
        ],
      ),
    );
  }

// Toggle List Item Helper
  Widget buildToggleListItem(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    double screenWidth,
    bool isDarkMode,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.03,
            vertical: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFF121212),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? const Color(0xFFAAAAAA)
                          : const Color(0xFF515151),
                    ),
                  ),
                ],
              ),
              Transform.scale(
                scale: 0.8,
                child: CupertinoSwitch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: const Color(0xFF00CC58),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
          child: Divider(
            height: 1,
            color:
                isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          ),
        ),
      ],
    );
  }

// regular settings list item helper my niggers
  Widget buildSettingsListItem(
    String title,
    String subtitle,
    double screenWidth,
    VoidCallback onTap,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.03),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF121212),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF121212),
                  size: 22,
                )
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
          child: const Divider(height: 1),
        ),
      ],
    );
  }
}
