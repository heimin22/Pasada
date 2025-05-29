import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/screens/editProfileScreen.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';

class SettingsProfileHeader extends StatefulWidget {
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
  SettingsProfileHeaderState createState() => SettingsProfileHeaderState();
}

class SettingsProfileHeaderState extends State<SettingsProfileHeader> {
  late Future<Map<String, dynamic>?> _userFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _userFuture = widget.authService.getCurrentUserData();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    String sanitizeUserName(String? name) {
      if (name == null || name.isEmpty) return 'Guest user';
      // Remove any potentially harmful characters
      return name.replaceAll(RegExp(r'[<>&"/]'), '');
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error: ${snapshot.error}');
          return Text('Error loading profile');
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator();
        }
        final userData = snapshot.data;
        final userName = sanitizeUserName(userData?['display_name']);
        final avatarUrl = userData?['avatar_url'];

        return Container(
          width: double.infinity,
          color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
          padding: EdgeInsets.symmetric(
            horizontal: widget.screenWidth * 0.06,
            vertical: widget.screenHeight * 0.06,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              buildProfileAvatar(avatarUrl),
              SizedBox(width: widget.screenWidth * 0.08),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: widget.screenHeight * 0.008),
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFF121212),
                    ),
                  ),
                  SizedBox(height: widget.screenHeight * 0.005),
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
    // calculate dynamic avatar size based on screen dimensions
    final double avatarDiameter =
        min(widget.screenWidth, widget.screenHeight) * 0.23;
    final double avatarRadius = avatarDiameter / 2;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: avatarRadius,
        backgroundColor: Colors.transparent,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => buildDefaultAvatar(),
            fit: BoxFit.cover,
            width: avatarDiameter,
            height: avatarDiameter,
          ),
        ),
      );
    }
    return buildDefaultAvatar();
  }

  Widget buildDefaultAvatar() {
    // default avatar with same dynamic sizing
    final double avatarDiameter =
        min(widget.screenWidth, widget.screenHeight) * 0.23;
    final double avatarRadius = avatarDiameter / 2;
    return CircleAvatar(
      radius: avatarRadius,
      backgroundColor: const Color(0xFF00CC58),
      child: Icon(
        Icons.person,
        size: avatarDiameter * 0.5,
        color: const Color(0xFFF5F5F5),
      ),
    );
  }

  Widget buildEditProfile(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TextButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EditProfileScreen(),
          ),
        );
        setState(() {
          _loadUserData();
        });
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Edit profile',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
          ),
          SizedBox(width: widget.screenWidth * 0.01),
          Icon(
            Icons.arrow_forward,
            size: 16,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ],
      ),
    );
  }
}
