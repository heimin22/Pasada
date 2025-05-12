import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/screens/changePasswordScreen.dart';
import 'package:pasada_passenger_app/screens/preferencesScreen.dart';
import 'package:pasada_passenger_app/screens/privacyPolicyScreen.dart';
import 'package:pasada_passenger_app/screens/introductionScreen.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:pasada_passenger_app/widgets/settings_profile_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return const SettingsScreenStateful();
  }
}

class SettingsScreenStateful extends StatefulWidget {
  const SettingsScreenStateful({super.key});

  @override
  State<SettingsScreenStateful> createState() => SettingsScreenPageState();
}

class SettingsScreenPageState extends State<SettingsScreenStateful> {
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            SettingsProfileHeader(
              authService: authService,
              screenHeight: screenSize.height,
              screenWidth: screenSize.width,
            ),
            Divider(
              height: 0,
              thickness: 12,
              color: isDarkMode
                  ? const Color(0xFF1E1E1E)
                  : const Color(0xFFE9E9E9),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: buildSettingsSection(),
            ),
          ],
        ),
      ),
    );
  }

  // settings section widget
  Widget buildSettingsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
      child: Container(
        color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionHeader('My Account', screenWidth),
            buildSettingsListItem('Change your password', screenWidth, () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ChangePasswordScreen()));
            }),
            buildSettingsListItem("Log out", screenWidth, () {
              debugPrint('Log out tapped');
              showLogoutDialog();
            }, isDestructive: true),
            const SizedBox(height: 25),
            buildSectionHeader('Settings', screenWidth),
            buildSettingsListItem('Preferences', screenWidth, () {
              debugPrint('Preferences tapped');
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => PreferencesScreen()));
            }),
            buildSettingsListItem('Contact Support', screenWidth, () {
              debugPrint('Contact support tapped');
            }),
            buildSettingsListItem(
              'Privacy Policy',
              screenWidth,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // dito yung mga helper widgets my nigger

  // dito yung mga single tappable list items para sa settings ng sections
  Widget buildSettingsListItem(
    String title,
    double screenWidth,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.only(
              right: screenWidth * 0.05,
              left: screenWidth * 0.05,
              top: 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDestructive
                          ? const Color(0xFFD7481D)
                          : (isDarkMode
                              ? const Color(0xFFF5F5F5)
                              : const Color(0xFF121212)),
                      fontWeight:
                          isDestructive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212),
                  size: 22,
                )
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: const Divider(),
        ),
      ],
    );
  }

  // builds the header for a settings section
  Widget buildSectionHeader(String title, double screenWidth) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.03),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
        ),
      ),
    );
  }

  // logout dialog
  void showLogoutDialog() async {
    final AuthService authService = AuthService();
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    try {
      final confirmLogout = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Log out?'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Logout'),
            )
          ],
        ),
      );
      if (confirmLogout ?? false) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (loadingDialogContext) => const PopScope(
            canPop: false,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF067837),
              ),
            ),
          ),
        );
        await authService.logout();
        if (!context.mounted) return;
        rootNavigator.pop(); // Close loading dialog

        // Navigate directly to IntroductionScreen instead of PasadaPassenger
        rootNavigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const IntroductionScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }
}
