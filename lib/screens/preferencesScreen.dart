import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pasada_passenger_app/functions/notification_preferences.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => PreferencesScreenState();
}

class PreferencesScreenState extends State<PreferencesScreen> {
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      ),
    );
  }
}
