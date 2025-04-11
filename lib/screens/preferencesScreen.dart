import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:pasada_passenger_app/functions/notification_preferences.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => PreferencesScreenState();
}

class PreferencesScreenState extends State<PreferencesScreen> {
  bool notificationsEnabled = true;
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    loadNotificationPreferences();
  }

  Future<void> loadNotificationPreferences() async {
    final enabled = await NotificationPreference.getNotificationStatus();
    setState(() => notificationsEnabled = enabled);
  }

  Future<void> toggleNotification(bool value) async {
    await NotificationPreference.setNotificationStatus(value);
    setState(() => notificationsEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: buildAppBar(),
      body: buildBody(screenSize),
    );
  }

  PreferredSizeWidget buildAppBar() {
    return AppBar(
      title: const Text(
        'Preferences',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF121212),
        ),
      ),
      backgroundColor: Color(0xFFF5F5F5),
      foregroundColor: Color(0xFF121212),
      elevation: 1.0,
    );
  }

  Widget buildBody(Size screenSize) {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: 12),
          buildNotificationSection(screenSize.width),
          buildAppSettingsSection(screenSize.width, screenSize.height),
        ],
      ),
    );
  }

  // settings section ng notification
  Widget buildNotificationSection(double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            buildSectionHeader('Notifications', screenWidth),
            buildToggleListItem(
              'Push Notifications',
              'Enable/disable app notifications',
              notificationsEnabled,
              toggleNotification,
              screenWidth,
            ),
          ],
        ),
      ),
    );
  }

  // additional application settings section
  Widget buildAppSettingsSection(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.02, horizontal: screenWidth * 0.03),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            buildSectionHeader('App Settings', screenWidth),
            buildSettingsListItem('Dark Mode',
                'Switch screen appearance to dark mode', screenWidth, () {
              debugPrint('Appearance tapped');
            }),
          ],
        ),
      ),
    );
  }

// section header helper
  Widget buildSectionHeader(String title, double screenWidth) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.03),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF121212),
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
                      color: Color(0xFF515151),
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
          child: const Divider(height: 1),
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
