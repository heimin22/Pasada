import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:location/location.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/home/notificationScreen.dart';
import 'package:pasada_passenger_app/home/activityScreen.dart';
import 'package:pasada_passenger_app/home/profileSettingsScreen.dart';
import 'package:pasada_passenger_app/home/settingsScreen.dart';
import 'package:pasada_passenger_app/home/homeScreen.dart';

class selectionScreen extends StatefulWidget {
  const selectionScreen({super.key});

  @override
  selectionState createState() => selectionState();
}

class selectionState extends State<selectionScreen> {
  int _currentIndex = 0;

  final List<Widget> pages = const [
    HomeScreen(),
    ActivityScreen(),
    NotificationScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  void onTap (int newIndex) {
    setState(() {
      _currentIndex = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: IndexedStack( // Use IndexedStack to preserve state
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFFF2F2F2),
      currentIndex: _currentIndex,
      onTap: onTap,
      showSelectedLabels: true,
      showUnselectedLabels: false,
      selectedLabelStyle: const TextStyle(
        color: Color(0xFF121212),
        fontFamily: 'Inter',
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
      ),
      selectedItemColor: const Color(0xFF5f3fc4),
      type: BottomNavigationBarType.fixed,
      items: [
        _buildNavItem(0, 'Home', 'homeSelectedIcon.svg', 'homeIcon.svg'),
        _buildNavItem(1, 'Activity', 'activitySelectedIcon.svg', 'activityIcon.svg'),
        _buildNavItem(2, 'Notifications', 'notificationSelectedIcon.svg', 'notificationIcon.svg'),
        _buildNavItem(3, 'Profile', 'accountSelectedIcon.svg', 'profileIcon.svg'),
        _buildNavItem(4, 'Settings', 'settingsSelectedIcon.svg', 'settingsIcon.svg'),
      ],
    );
  }

  BottomNavigationBarItem _buildNavItem(
      int index,
      String label,
      String selectedIcon,
      String unselectedIcon
      ) {
    return BottomNavigationBarItem(
      label: label,
      icon: _currentIndex == index
          ? SvgPicture.asset(
        'assets/svg/$selectedIcon',
        width: 24,
        height: 24,
      )
          : SvgPicture.asset(
        'assets/svg/$unselectedIcon',
        width: 24,
        height: 24,
      ),
      // backgroundColor: Color(0xFFF2F2F2),
      // body: pages[_currentIndex],
      // bottomNavigationBar: BottomNavigationBar(
      //   backgroundColor: Color(0xFFF2F2F2),
      //   currentIndex: _currentIndex,
      //   onTap: onTap,
      //   showSelectedLabels: true,
      //   showUnselectedLabels: false,
      //   selectedLabelStyle: TextStyle(
      //     color: const Color(0xFF121212),
      //     fontFamily: 'Inter',
      //     fontSize: 12,
      //   ),
      //   unselectedLabelStyle: TextStyle(
      //     fontFamily: 'Inter',
      //     fontSize: 12,
      //   ),
      //   selectedItemColor: Color(0xFF5f3fc4),
      //   items: [
      //     BottomNavigationBarItem(
      //       label: 'Home',
      //       icon: _currentIndex == 0
      //           ? SvgPicture.asset(
      //         'assets/svg/homeSelectedIcon.svg',
      //         width: 24,
      //         height: 24,
      //       )
      //           : SvgPicture.asset(
      //         'assets/svg/homeIcon.svg',
      //         width: 24,
      //         height: 24,
      //       ),
      //     ),
      //     BottomNavigationBarItem(
      //       label: 'Activity',
      //       icon: _currentIndex == 1
      //           ? SvgPicture.asset(
      //         'assets/svg/activitySelectedIcon.svg',
      //         width: 24,
      //         height: 24,
      //       )
      //           : SvgPicture.asset(
      //         'assets/svg/activityIcon.svg',
      //         width: 24,
      //         height: 24,
      //       ),
      //     ),
      //     BottomNavigationBarItem(
      //       label: 'Notifications',
      //       icon: _currentIndex == 2
      //           ? SvgPicture.asset(
      //         'assets/svg/notificationSelectedIcon.svg',
      //         width: 24,
      //         height: 24,
      //       )
      //           : SvgPicture.asset(
      //         'assets/svg/notificationIcon.svg',
      //         width: 24,
      //         height: 24,
      //       ),
      //     ),
      //     BottomNavigationBarItem(
      //       label: 'Profile',
      //       icon: _currentIndex == 3
      //           ? SvgPicture.asset(
      //         'assets/svg/accountSelectedIcon.svg',
      //         width: 24,
      //         height: 24,
      //       )
      //           : SvgPicture.asset(
      //         'assets/svg/profileIcon.svg',
      //         width: 24,
      //         height: 24,
      //       ),
      //     ),
      //     BottomNavigationBarItem(
      //       label: 'Settings',
      //       icon: _currentIndex == 4
      //           ? SvgPicture.asset(
      //         'assets/svg/settingsSelectedIcon.svg',
      //         width: 24,
      //         height: 24,
      //       )
      //           : SvgPicture.asset(
      //         'assets/svg/settingsIcon.svg',
      //         width: 24,
      //         height: 24,
      //       ),
      //     ),
      //   ],
      // ),
    );
  }
}
