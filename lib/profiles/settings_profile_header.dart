import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
        final userName = userData?['display_name'] ?? 'Guest user';

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
              buildProfileAvatar(avatarUrl),
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

  Widget buildProfileAvatar(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: screenWidth * 0.07,
        backgroundColor: Colors.transparent,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => buildDefaultAvatar(),
            fit: BoxFit.cover,
            width: screenWidth * 0.14,
            height: screenWidth * 0.14,
          ),
        ),
      );
    }
    return buildDefaultAvatar();
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
