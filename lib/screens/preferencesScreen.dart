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
    // final screenHeight = MediaQuery.of(context).size.height;
    // final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: buildAppBar(),
      body: (),
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
          buildNotificationSection(screenSize.width),
          buildAppSettingsSection(screenSize.width),
        ],
      ),
    );
  }

  Widget buildNotificationSection(double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
    );
  }

  Widget buildAppSettingsSection(double screenWidth) {
    return Padding(

    );
  }
}
