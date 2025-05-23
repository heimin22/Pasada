import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key});

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'One passenger only allowed',
      icon: Icons.person,
      description: 'Pasada supports only one passenger to be booked for now.',
    ),
    OnboardingPage(
      title: 'Choose a route',
      icon: Icons.route,
      description: 'Choose a route first before picking locations.',
    ),
    OnboardingPage(
      title: 'Select your seating preferences',
      icon: Icons.event_seat,
      description: 'Choose if sitting or standing.',
    ),
    OnboardingPage(
      title: 'Select your preferred payment method',
      icon: Icons.payment,
      description: 'Choose if cash or cashless.',
    ),
    OnboardingPage(
      title: 'Then you\'re ready to go!',
      icon: Icons.check_circle,
      description: 'You can now book and enjoy!',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 300,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalPages,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], isDarkMode);
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _totalPages,
                (index) => _buildDotIndicator(index, isDarkMode),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text(
                      'Previous',
                      style: TextStyle(
                        color: const Color(0xFF00CC58),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 80),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _totalPages - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _markOnboardingComplete();
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00CC58),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    _currentPage < _totalPages - 1 ? 'Next' : 'Get Started',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, bool isDarkMode) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          page.icon,
          size: 80,
          color: const Color(0xFF00CC58),
        ),
        const SizedBox(height: 24),
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          page.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            color:
                isDarkMode ? const Color(0xFFDEDEDE) : const Color(0xFF1E1E1E),
          ),
        ),
      ],
    );
  }

  Widget _buildDotIndicator(int index, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index
            ? const Color(0xFF00CC58)
            : (isDarkMode ? const Color(0xFF3A3A3A) : const Color(0xFFD3D3D3)),
      ),
    );
  }

  Future<void> _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }
}

class OnboardingPage {
  final String title;
  final IconData icon;
  final String description;

  OnboardingPage({
    required this.title,
    required this.icon,
    required this.description,
  });
}

// Add a flag to prevent multiple dialogs
bool _isOnboardingDialogShowing = false;

// Function to show the onboarding dialog
Future<void> showOnboardingDialog(BuildContext context) async {
  // Check if dialog is already showing
  if (_isOnboardingDialogShowing) {
    debugPrint('Onboarding dialog already showing, ignoring duplicate call');
    return;
  }

  // Request location permissions first
  await _requestLocationPermissions();

  // Get shared preferences
  final prefs = await SharedPreferences.getInstance();

  // Check if user is new by looking for a specific flag
  final isNewUser = !(prefs.getBool('user_onboarded') ?? false);

  // Only show for new users and if not already shown
  if (isNewUser && await shouldShowOnboarding()) {
    if (context.mounted) {
      _isOnboardingDialogShowing = true;

      // Mark as shown immediately to prevent race conditions
      await prefs.setBool('user_onboarded', true);
      debugPrint('Showing onboarding dialog for new user');

      try {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const OnboardingDialog(),
        );

        // After dialog is closed, mark onboarding as complete
        await prefs.setBool('onboarding_complete', true);
      } finally {
        _isOnboardingDialogShowing = false;
      }
    }
  }
}

// Helper function to check if onboarding should be shown
Future<bool> shouldShowOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool('onboarding_complete') ?? false);
}

// Helper function to request location permissions
Future<void> _requestLocationPermissions() async {
  // Request location permissions
  await Permission.location.request();

  // For background location on Android, we need to request it separately
  if (await Permission.location.isGranted) {
    await Permission.locationAlways.request();
  }

  // Request notification permissions
  await Permission.notification.request();
}
