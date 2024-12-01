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
   int _currentIndex = 0;
  // final List<Widget> pages = [
  //   HomeScreen(),
  //   // ActivityScreen(),
  //   // NotificationScreen(),
  //   // ProfileScreen(),
  //   // SettingsScreen(),
  // ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF2F2F2)
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (int newIndex) {
            setState(() {
              _currentIndex = newIndex;
            });
          },
          showSelectedLabels: true,
          showUnselectedLabels: false,
          selectedLabelStyle: TextStyle(
            color: const Color(0xFF121212),
            fontFamily: 'Inter',
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
          ),
          backgroundColor: Color(0xFFF2F2F2),
          selectedItemColor: Color(0xFF4AB00C),
          items: [
            BottomNavigationBarItem(
              label: 'Home',
              icon: _currentIndex == 0
                  ? SvgPicture.asset(
                      'assets/svg/homeSelectedIcon.svg',
                      width: 24,
                      height: 24,
                    )
                  : SvgPicture.asset(
                      'assets/svg/homeIcon.svg',
                      width: 24,
                      height: 24,
                    ),
            ),
            BottomNavigationBarItem(
              label: 'Activity',
              icon: _currentIndex == 1
                  ? SvgPicture.asset(
                      'assets/svg/activitySelectedIcon.svg',
                      width: 24,
                      height: 24,
                    )
                  : SvgPicture.asset(
                      'assets/svg/activityIcon.svg',
                      width: 24,
                      height: 24,
                    ),
            ),
            BottomNavigationBarItem(
              label: 'Notifications',
              icon: _currentIndex == 2
                  ? SvgPicture.asset(
                      'assets/svg/notificationSelectedIcon.svg',
                      width: 24,
                      height: 24,
                    )
                  : SvgPicture.asset(
                      'assets/svg/notificationIcon.svg',
                      width: 24,
                      height: 24,
                    ),
            ),
            BottomNavigationBarItem(
              label: 'Profile',
              icon: _currentIndex == 3
                  ? SvgPicture.asset(
                      'assets/svg/accountSelectedIcon.svg',
                      width: 24,
                      height: 24,
                    )
                  : SvgPicture.asset(
                      'assets/svg/profileIcon.svg',
                      width: 24,
                      height: 24,
                    ),
            ),
            BottomNavigationBarItem(
              label: 'Settings',
              icon: _currentIndex == 4
                  ? SvgPicture.asset(
                      'assets/svg/settingsSelectedIcon.svg',
                      width: 24,
                      height: 24,
                    )
                  : SvgPicture.asset(
                      'assets/svg/settingsIcon.svg',
                      width: 24,
                      height: 24,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}