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
        if (snapshot.hasError) {
          debugPrint('Error: ${snapshot.error}');
          return Text('Error loading profile');
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator();
        }
        final userData = snapshot.data;
        final userName = (userData?['first_name'] != null && userData?['last_name'] != null)
            ? '${snapshot.data!['first_name']} ${snapshot.data!['last_name']}'
            : 'Guest user';

        return Container(
          width: double.infinity,
          color: const Color(0xFFF5F5F5),
          height: screenHeight * 0.13,
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.03,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: screenWidth * 0.07,
                backgroundColor: const Color(0xFF00CC58),
                child: Icon(
                  Icons.person,
                  size: screenWidth * 0.1,
                  color: const Color(0xFFDEDEDE),
                ),
              ),
              SizedBox(width: screenWidth * 0.06),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.008),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF121212),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  buildEditProfile(context),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget buildEditProfile(BuildContext context) {
    return InkWell(
      // TODO: dapat may function na ito sa susunod may nigga ha
      onTap: () => debugPrint('Edit profile tapped'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Edit profile',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF121212),
            ),
          ),
          SizedBox(width: screenWidth * 0.01),
          const Icon(
            Icons.arrow_forward,
            size: 15,
            color: Color(0xFF121212),
          ),
        ],
      ),
    );
  }
}
