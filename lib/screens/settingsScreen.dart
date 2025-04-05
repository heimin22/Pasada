import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:pasada_passenger_app/profiles/settings_profile_header.dart';
import '../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pasada',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const SettingsScreenStateful(title:  'Pasada'),
      routes: <String, WidgetBuilder>{
        'start': (BuildContext context) => const PasadaPassenger(),
      },
    );
  }
}

class SettingsScreenStateful extends StatefulWidget {
  const SettingsScreenStateful({super.key, required this.title});
  final String title;

  @override
  State<SettingsScreenStateful> createState() => SettingsScreenPageState();
}

class SettingsScreenPageState extends State<SettingsScreenStateful> {
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SettingsProfileHeader(
              authService: authService,
              screenHeight: screenSize.height,
              screenWidth: screenSize.width,
            ),
            const Divider(
              height: 0,
              thickness: 12,
              color: Color(0xFFE9E9E9),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
      child: Container(
        color: Color(0xFFF5F5F5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionHeader('My Account', screenWidth),
            buildSettingsListItem('Change your password', screenWidth, () {
              debugPrint('Change Password tapped');
              // TODO: dapat may function na ito sa susunod my nigger
            }),
            buildSettingsListItem('Delete my account', screenWidth, () {
              debugPrint('Delete Account tapped');
              // TODO: dapat may function na ito sa susunod my nigger
            }),
            buildSettingsListItem("Log out", screenWidth, () {
              debugPrint('Log out tapped');
              showLogoutDialog();
            }, isDestructive: true),

            const SizedBox(height: 25),

            buildSectionHeader('Settings', screenWidth),
            buildSettingsListItem('Preferences', screenWidth, (){
              debugPrint('Preferences tapped');
              // TODO: dapat may function na ito sa susunod my nigger
            }),
            buildSettingsListItem('Contact Support', screenWidth, (){
              debugPrint('Contact support tapped');
              // TODO: dapat may function na ito sa susunod my nigger
            }),
          ],
        ),
      ),
    );
  }

  // dito yung mga helper widgets my nigger

  // dito yung mga single tappable list items para sa settings ng sections
  Widget buildSettingsListItem(String title, double screenWidth, VoidCallback onTap, {bool isDestructive = false}) {
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
                      color: isDestructive ? Color(0xFFD7481D) : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: isDestructive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Color(0xFF121212),
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
    return Padding (
      padding: EdgeInsets.only(
        left: screenWidth * 0.05,
        right: screenWidth * 0.05,
        top: 10,
        bottom: 15,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF121212),
        ),
      ),
    );
  }

  // logout dialog
  void showLogoutDialog() async {
    final AuthService authService = AuthService();
    final navigator = Navigator.of(context);
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
        rootNavigator.pop();
        rootNavigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => PasadaPassenger()),
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