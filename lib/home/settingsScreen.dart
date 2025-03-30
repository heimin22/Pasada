import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/authenticationAccounts/authService.dart';
import 'package:postgres/postgres.dart';

import '../main.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:pasada_passenger_app/home/homeScreen.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:location/location.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:pasada_passenger_app/home/notificationScreen.dart';
// import 'package:pasada_passenger_app/home/activityScreen.dart';
// import 'package:pasada_passenger_app/home/profileSettingsScreen.dart';
// import 'package:pasada_passenger_app/home/settingsScreen.dart';
// import 'package:pasada_passenger_app/home/homeScreen.dart';

// void main() => runApp(const SettingsScreen());

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
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            settingsTitle(),
            logoutButton(),
          ],
        ),
      ),
    );
  }

  // settings title header
  Positioned settingsTitle() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Positioned(
      top: screenHeight * 0.03,
      left: screenWidth * 0.05,
      right: screenWidth * 0.18,
      child: Text(
        'Settings',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF121212),
        ),
      ),
    );
  }

  // profile section widget
  Widget buildPassengerProfile() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Container (
      width: double.infinity,
      color: Color(0xFFF5F5F5),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.03,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: screenWidth * 0.08,
            backgroundColor: const Color(0xFF00CC58),
            child: Icon(
              Icons.person,
              size: screenWidth * 0.1,
              color: const Color(0xFFDEDEDE),
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fyke Tonel',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF121212)
                ),
              ),
              SizedBox(height: screenHeight * 0.005),
              InkWell(
                onTap: () {
                  debugPrint('Edit profile tapped');
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Edit profile',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF121212),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Icon(
                      Icons.arrow_forward,
                      size: 15,
                      color: Color(0xFF121212),
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
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

            buildSectionHeader('General', screenWidth),
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
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: 14,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDestructive ? Color(0xFFD7481D) : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w400,
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
        top: 15,
        bottom: 8,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
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
        navigator.pop();
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

  Positioned logoutButton() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Positioned(
      top: screenHeight * 0.08,
      left: screenWidth * 0.05,
      child: GestureDetector(
        onTap: () async {
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
              navigator.pop();
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
        },
        child: Text(
          'Log out',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFD7481D),
          ),
        ),
      ),
    );
  }
}