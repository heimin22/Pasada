import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:location/location.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/home/activityScreen.dart';
import 'package:pasada_passenger_app/home/settingsScreen.dart';
import 'package:pasada_passenger_app/home/homeScreen.dart';

class selectionScreen extends StatefulWidget {
  const selectionScreen({super.key});

  @override
  selectionState createState() => selectionState();
}

class selectionState extends State<selectionScreen> {
  int _currentIndex = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  final List<Widget> pages = const [
    HomeScreen(),
    ActivityScreen(),
    SettingsScreen(),
  ];

  void onTap (int newIndex) {
    setState(() {
      _currentIndex = newIndex;
    });
  }

  Widget buildCurvedNavItem(int index) {
    String selectedIcon, unselectedIcon;
    switch (index) {
      case 0:
        selectedIcon = 'homeSelectedIcon.svg';
        unselectedIcon = 'homeIcon.svg';
        break;
      case 1:
        selectedIcon = 'activitySelectedIcon.svg';
        unselectedIcon = 'activityIcon.svg';
        break;
      case 2:
        selectedIcon = 'profileSelectedIcon.svg';
        unselectedIcon = 'profileIcon.svg';
        break;
      default:
        selectedIcon = '';
        unselectedIcon = '';
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/svg/${_currentIndex == index ? selectedIcon : unselectedIcon}',
          colorFilter: _currentIndex == index
              ? ColorFilter.mode(Color(0xff067837), BlendMode.srcIn)
              : null,
          width: 24,
          height: 24,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        items: [
          buildCurvedNavItem(0),
          buildCurvedNavItem(1),
          buildCurvedNavItem(2),
        ],
        index: _currentIndex,
        color: const Color(0xFF00CC58),
        backgroundColor: Color(0xFFF5F5F5),
        buttonBackgroundColor: Color(0xFFF5F5F5),

        onTap: onTap,
        animationCurve: Curves.easeOutCubic,
        animationDuration: const Duration(milliseconds: 400),
        height: 75.0,
      ),
    );
  }
}
