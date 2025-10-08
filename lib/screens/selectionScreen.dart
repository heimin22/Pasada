import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/screens/activityScreen.dart';
import 'package:pasada_passenger_app/screens/homeScreen.dart';
import 'package:pasada_passenger_app/screens/settingsScreen.dart';
import 'package:pasada_passenger_app/services/slow_internet_warning_service.dart';
import 'package:pasada_passenger_app/widgets/slow_internet_warning_banner.dart';

class selectionScreen extends StatefulWidget {
  const selectionScreen({super.key});

  @override
  selectionState createState() => selectionState();
}

class PersistentHomeScreen extends StatefulWidget {
  const PersistentHomeScreen({super.key});

  @override
  State<PersistentHomeScreen> createState() => PersistentHomeScreenState();
}

class PersistentHomeScreenState extends State<PersistentHomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const HomeScreen(key: PageStorageKey('Home'));
  }
}

class PersistentActivityScreen extends StatefulWidget {
  const PersistentActivityScreen({super.key});

  @override
  State<PersistentActivityScreen> createState() =>
      _PersistentActivityScreenState();
}

class _PersistentActivityScreenState extends State<PersistentActivityScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const ActivityScreen(key: PageStorageKey('Activity'));
  }
}

class PersistentProfileScreen extends StatefulWidget {
  const PersistentProfileScreen({super.key});

  @override
  State<PersistentProfileScreen> createState() =>
      _PersistentProfileScreenState();
}

class _PersistentProfileScreenState extends State<PersistentProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const SettingsScreen(key: PageStorageKey('Settings'));
  }
}

class selectionState extends State<selectionScreen> {
  int currentIndex = 0;
  int previousIndex = 0;
  final PageStorageBucket bucket = PageStorageBucket();
  final GlobalKey<CurvedNavigationBarState> bottomNavigationKey = GlobalKey();
  final SlowInternetWarningService _warningService =
      SlowInternetWarningService();

  late final List<Widget> pages = [
    PersistentHomeScreen(),
    PersistentActivityScreen(),
    PersistentProfileScreen(),
  ];

  Color getNavBarColor() {
    switch (currentIndex) {
      case 0:
        return const Color(0xFF00CC58);
      case 1:
        return const Color(0xFFFFCE21);
      case 2:
        return const Color(0xFFD7481D);
      default:
        return const Color(0xFF00CC58);
    }
  }

  Color getIconColor() {
    switch (currentIndex) {
      case 0:
        return const Color(0xFF067837);
      case 1:
        return const Color(0xFFFFCE21);
      case 2:
        return const Color(0xFFD7481D);
      default:
        return const Color(0xFF067837);
    }
  }

  void onTap(int newIndex) {
    setState(() {
      previousIndex = currentIndex;
      currentIndex = newIndex;

      // If we're navigating away from the home screen, reset its initialization state
      // This will ensure resources are reinitialized when returning to home
      if (previousIndex == 0 && currentIndex != 0) {
        final homeScreenState =
            (pages[0] as PersistentHomeScreen).key as PageStorageKey<String>?;

        if (homeScreenState != null) {
          // This is a hint to reinitialize when returning to home
          PageStorage.of(context).writeState(
            context,
            false,
            identifier: const ValueKey('homeInitialized'),
          );
        }
      }
    });
  }

  Widget buildCurvedNavItem(int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
              ? ColorFilter.mode(getIconColor(), BlendMode.srcIn)
              : isDarkMode
                  ? const ColorFilter.mode(Color(0xFFF5F5F5), BlendMode.srcIn)
                  : null,
          width: 24,
          height: 24,
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _warningService.initialize();
  }

  @override
  void dispose() {
    _warningService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PageStorage(
      bucket: bucket,
      child: SlowInternetWarningBanner(
        child: Scaffold(
          backgroundColor: Color(0xFFF5F5F5),
          body: IndexedStack(
            index: currentIndex,
            children: pages,
          ),
          bottomNavigationBar: CurvedNavigationBar(
            key: bottomNavigationKey,
            items: [
              buildCurvedNavItem(0),
              buildCurvedNavItem(1),
              buildCurvedNavItem(2),
            ],
            index: currentIndex,
            color:
                isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
            backgroundColor: getNavBarColor(),
            buttonBackgroundColor: Color(0xFFF5F5F5),
            onTap: (newIndex) {
              setState(() {
                previousIndex = currentIndex;
                currentIndex = newIndex;
              });
            },
            animationCurve: Curves.fastOutSlowIn,
            animationDuration: const Duration(milliseconds: 400),
            height: 75.0,
          ),
        ),
        onRetry: () {
          _warningService.testConnection();
        },
        onDismiss: () {
          // Banner will be dismissed automatically
        },
      ),
    );
  }
}
