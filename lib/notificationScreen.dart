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
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Flexible(
              child: Container(
                // padding: ,
                child: Text(
                    'Notifications'
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}