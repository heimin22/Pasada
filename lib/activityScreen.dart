import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/homeScreen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/notificationScreen.dart';
import 'package:pasada_passenger_app/activityScreen.dart';
import 'package:pasada_passenger_app/profileSettingsScreen.dart';
import 'package:pasada_passenger_app/settingsScreen.dart';
import 'package:pasada_passenger_app/homeScreen.dart';

void main() => runApp(const ActivityScreen());

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

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
      home: const ActivityScreenStateful(title: 'Pasada'),
      routes: <String, WidgetBuilder>{

      },
    );
  }
}

class ActivityScreenStateful extends StatefulWidget {
  const ActivityScreenStateful({super.key, required this.title});

  final String title;

  @override
  State<ActivityScreenStateful> createState() => ActivityScreenPageState();
}

class ActivityScreenPageState extends State<ActivityScreenStateful> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Flexible(
              child: Container(
                // padding: ,
                child: Text(
                    'Activity'
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}