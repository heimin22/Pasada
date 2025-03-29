import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/authenticationAccounts/authService.dart';

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
          final scaffoldMessenger = ScaffoldMessenger.of(context);
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