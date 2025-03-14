import 'package:flutter/material.dart';
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

void main() => runApp(const ProfileScreen());

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
      home: const ProfileScreenStateful(title: 'Pasada'),
      routes: <String, WidgetBuilder>{

      },
    );
  }
}

class ProfileScreenStateful extends StatefulWidget {
  const ProfileScreenStateful({super.key, required this.title});

  final String title;

  @override
  State<ProfileScreenStateful> createState() => ProfileScreenPageState();
}

class ProfileScreenPageState extends State<ProfileScreenStateful> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            profilesTitle(),
          ],
        ),
      ),
    );
  }

  Positioned profilesTitle() {
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
}