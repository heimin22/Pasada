import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  PreferredSizeWidget buildAppBar(bool isDarkMode) {
    return AppBar(
      title: Text(
        'Change Password',
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

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
