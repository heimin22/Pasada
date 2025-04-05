import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:pasada_passenger_app/screens/homeScreen.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:location/location.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:pasada_passenger_app/screens/notificationScreen.dart';
// import 'package:pasada_passenger_app/screens/activityScreen.dart';
// import 'package:pasada_passenger_app/screens/profileSettingsScreen.dart';
// import 'package:pasada_passenger_app/screens/settingsScreen.dart';
// import 'package:pasada_passenger_app/screens/homeScreen.dart';

void main() => runApp(const NotificationScreen());

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pasada',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0XFFF2F2F2),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const NotifScreenStateful(title: 'Pasada'),
      routes: <String, WidgetBuilder>{

      },
    );
  }
}

class NotifScreenStateful extends StatefulWidget {
  const NotifScreenStateful({super.key, required this.title});

  final String title;

  @override
  State<NotifScreenStateful> createState() => NotifScreenPageState();
}

class NotifScreenPageState extends State<NotifScreenStateful> {

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: screenHeight * 0.03,
              left: screenWidth * 0.05,
              right: screenWidth * 0.18,
              child: Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF121212),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}