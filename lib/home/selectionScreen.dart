import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:pasada_passenger_app/home/activityScreen.dart';
import 'package:pasada_passenger_app/home/settingsScreen.dart';
import 'package:pasada_passenger_app/home/homeScreen.dart';

class selectionScreen extends StatefulWidget {
  const selectionScreen({super.key});

  @override
  selectionState createState() => selectionState();
}

class selectionState extends State<selectionScreen> {
  int currentIndex = 0;
  int previousIndex = 0;
  final GlobalKey<CurvedNavigationBarState> bottomNavigationKey = GlobalKey();

  final List<Widget> pages = const [
    HomeScreen(key: ValueKey('Home')),
    ActivityScreen(key: ValueKey('Activity')),
    SettingsScreen(key: ValueKey('Settings')),
  ];

  void onTap (int newIndex) {
    setState(() {
      previousIndex = currentIndex;
      currentIndex = newIndex;
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
          'assets/svg/${currentIndex == index ? selectedIcon : unselectedIcon}',
          colorFilter: currentIndex == index
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400), // matched dapat yung animation duration so bottom nav bar
        transitionBuilder: (Widget child, Animation<double> animation) {
          // slide animation
          final bool isForward = currentIndex > previousIndex;
          final Offset begin = isForward
              ? const Offset(1.0, 0.0) // enter from right para sa forward navigation
              : const Offset(-1.0, 0.0); // enter from left para sa backward navigation

            return SlideTransition(
              position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.fastOutSlowIn,
                ),
              ),
              child: child,
            );
          },
        child: pages[currentIndex],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: bottomNavigationKey,
        items: [
          buildCurvedNavItem(0),
          buildCurvedNavItem(1),
          buildCurvedNavItem(2),
        ],
        index: currentIndex,
        color: const Color(0xFFF5F5F5),
        backgroundColor: Color(0xFF00CC58),
        buttonBackgroundColor: Color(0xFFF5F5F5),

        onTap: onTap,
        animationCurve: Curves.fastOutSlowIn,
        animationDuration: const Duration(milliseconds: 400),
        height: 75.0,
      ),
    );
  }
}
