import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/authService.dart';

class SettingsProfileHeader extends StatelessWidget {
  final AuthService authService;
  final double screenHeight;
  final double screenWidth;

  const SettingsProfileHeader({
    super.key,
    required this.authService,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: authService.getCurrentUserData(),
      builder: (context, snapshot) {
        final userName = snapshot.data?['first_name'] != null && snapshot.data?['last_name']
            ? '${snapshot.data!['first_name']} ${snapshot.data!['last_name']}'
            : 'Guest user';

      },
    );
  }
}
