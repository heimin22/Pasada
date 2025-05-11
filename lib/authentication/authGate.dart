/*

Authentication gate - this will continuously listen for auth changes

unauthenticated - login page
authenticated - main page

*/

import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/main.dart';
import 'package:pasada_passenger_app/screens/introductionScreen.dart';
import 'package:pasada_passenger_app/screens/selectionScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _hasSeenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      // listen to auth state changes
      stream: Supabase.instance.client.auth.onAuthStateChange,

      // build appropriate page based on auth state
      builder: (context, snapshot) {
        // loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        if (session != null) {
          // User is logged in
          return const selectionScreen();
        } else {
          // User is not logged in
          if (_hasSeenOnboarding) {
            // User has seen onboarding, show introduction screen
            return const IntroductionScreen();
          } else {
            // User has not seen onboarding, show onboarding
            return const PasadaHomePage();
          }
        }
      },
    );
  }
}
