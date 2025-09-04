import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/screens/changePasswordScreen.dart';
import 'package:pasada_passenger_app/screens/preferencesScreen.dart';
import 'package:pasada_passenger_app/screens/privacyPolicyScreen.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:pasada_passenger_app/widgets/settings_profile_header.dart';
import 'package:pasada_passenger_app/widgets/responsive_dialogs.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pasada_passenger_app/screens/offflineConnectionCheckService.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return const SettingsScreenStateful();
  }
}

class SettingsScreenStateful extends StatefulWidget {
  const SettingsScreenStateful({super.key});

  @override
  State<SettingsScreenStateful> createState() => SettingsScreenPageState();
}

class SettingsScreenPageState extends State<SettingsScreenStateful> {
  final AuthService authService = AuthService();
  final GlobalKey<SettingsProfileHeaderState> _profileHeaderKey = GlobalKey<SettingsProfileHeaderState>();
  bool isSynced = true;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final connectivityService = OfflineConnectionCheckService();

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            SettingsProfileHeader(
              key: _profileHeaderKey,
              authService: authService,
              screenHeight: screenSize.height,
              screenWidth: screenSize.width,
            ),
            // Not synced / offline indicator
            StreamBuilder<bool>(
              stream: connectivityService.connectionStream,
              initialData: connectivityService.isConnected,
              builder: (context, snapshot) {
                final online = snapshot.data ?? true;
                final showBanner = !online || !isSynced;
                if (!showBanner) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  color: const Color(0x33D7481D),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.sync_problem, color: Color(0xFFD7481D), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          online ? 'Profile may be out of date. Pull to refresh.' : 'Offline. Showing last known profile.',
                          style: TextStyle(
                            color: isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Divider(
              height: 0,
              thickness: 12,
              color: isDarkMode
                  ? const Color(0xFF1E1E1E)
                  : const Color(0xFFE9E9E9),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    isSynced = false;
                  });
                  try {
                    await _profileHeaderKey.currentState?.refreshUserData();
                    setState(() {
                      isSynced = true;
                    });
                  } catch (_) {
                    setState(() {
                      isSynced = false;
                    });
                  }
                },
                color: const Color(0xFF067837),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: buildSettingsSection(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // settings section widget
  Widget buildSettingsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
      child: Container(
        color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionHeader('My Account', screenWidth),
            buildSettingsListItem('Change your password', screenWidth, () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ChangePasswordScreen()));
            }),
            buildSettingsListItem("Log out", screenWidth, () {
              debugPrint('Log out tapped');
              showLogoutDialog();
            }, isDestructive: true),
            const SizedBox(height: 25),
            buildSectionHeader('Settings', screenWidth),
            buildSettingsListItem('Preferences', screenWidth, () {
              debugPrint('Preferences tapped');
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => PreferencesScreen()));
            }),
            buildSettingsListItem('Contact Support', screenWidth, () async {
              final String emailAddress = 'contact.pasada@gmail.com';
              final String subject = 'Support Request';
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: emailAddress,
                queryParameters: {
                  'subject': subject,
                },
              );
              // Attempt to launch the email client externally
              final bool launched = await launchUrl(
                emailLaunchUri,
                mode: LaunchMode.externalApplication,
              );
              if (!launched) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not launch email client.'),
                  ),
                );
              }
            }),
            buildSettingsListItem(
              'Privacy Policy',
              screenWidth,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // dito yung mga helper widgets my nigger

  // dito yung mga single tappable list items para sa settings ng sections
  Widget buildSettingsListItem(
    String title,
    double screenWidth,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.only(
              right: screenWidth * 0.05,
              left: screenWidth * 0.05,
              top: 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDestructive
                          ? const Color(0xFFD7481D)
                          : (isDarkMode
                              ? const Color(0xFFF5F5F5)
                              : const Color(0xFF121212)),
                      fontWeight:
                          isDestructive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212),
                  size: 22,
                )
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: const Divider(),
        ),
      ],
    );
  }

  // builds the header for a settings section
  Widget buildSectionHeader(String title, double screenWidth) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.03),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
        ),
      ),
    );
  }

  // logout dialog
  void showLogoutDialog() async {
    final AuthService authService = AuthService();
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Show confirmation dialog
    final confirmLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ResponsiveDialog(
        title: 'Log out?',
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to log out?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                color: isDarkMode
                    ? const Color(0xFFDEDEDE)
                    : const Color(0xFF1E1E1E),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: const Color(0xFF00CC58),
                  width: 3,
                ),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
              minimumSize: const Size(150, 40),
              backgroundColor: Colors.transparent,
              foregroundColor: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                fontSize: 15,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
              minimumSize: const Size(150, 40),
              backgroundColor: const Color(0xFFD7481D),
              foregroundColor: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );

    if (!(confirmLogout ?? false)) return;
    if (!context.mounted) return;

    // Show loading dialog using rootNavigator to ensure proper disposal
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (loadingDialogContext) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF067837),
          ),
        ),
      ),
    );

    // Perform logout and ensure the loading dialog is closed first
    try {
      await authService.logout();
      // Close loading dialog
      rootNavigator.pop();
      // Navigate back to the introduction screen via named route
      rootNavigator.pushNamedAndRemoveUntil(
        'introduction',
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      // Close loading dialog
      rootNavigator.pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }
}
