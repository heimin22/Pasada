import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/notificationScreen.dart';
import 'package:pasada_passenger_app/activityScreen.dart';
import 'package:pasada_passenger_app/profileSettingsScreen.dart';
import 'package:pasada_passenger_app/settingsScreen.dart';

void main() => runApp(const HomeScreen());

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Screen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const HomeScreenStateful(title: 'Home Screen'),
      routes: <String, WidgetBuilder>{

      },
    );
  }
}

class HomeScreenStateful extends StatefulWidget {
  const HomeScreenStateful({super.key, required this.title});

  final String title;

  @override
  State<HomeScreenStateful> createState() => HomeScreenPageState();
}

class HomeScreenPageState extends State<HomeScreenStateful> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(
            icon: SvgPicture.asset(
              'assets/svg/homeIcon.svg',
              width: 24,
              height: 24,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: SvgPicture.asset(
              'assets/svg/activityIcon.svg',
              width: 24,
              height: 24,
            ),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: SvgPicture.asset(
              'assets/svg/notificationIcon.svg',
              width: 24,
              height: 24,
            ),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: SvgPicture.asset(
              'assets/svg/profileIcon.svg',
              width: 24,
              height: 24,
            ),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: SvgPicture.asset(
              'assets/svg/settingsIcon.svg',
              width: 24,
              height: 24,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}