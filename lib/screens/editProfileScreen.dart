import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:pasada_passenger_app/services/image_compression_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService authService = AuthService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();
  String? profileImageUrl;
  File? _imageFile;
  bool isGoogleLinked = false;

  @override
  void initState() {
    super.initState();
    // Fetch user data and initialize controllers
    loadUserData();
  }

  Future<void> loadUserData() async {
    final userData = await authService.getCurrentUserData();
    if (userData != null) {
      final isGoogleProvider = authService.isGoogleLinkedAccount();

      setState(() {
        nameController.text = userData['display_name'] ?? '';
        emailController.text = userData['passenger_email'] ?? '';
        mobileNumberController.text = userData['contact_number'] ?? '';
        profileImageUrl = userData['avatar_url'];
        isGoogleLinked = isGoogleProvider;
      });

      // Auto-sync Google profile data when loading
      if (isGoogleProvider) {
        await authService.syncGoogleProfile();
        // Reload data after sync
        final updatedUserData = await authService.getCurrentUserData();
        if (updatedUserData != null) {
          setState(() {
            nameController.text = updatedUserData['display_name'] ?? '';
            emailController.text = updatedUserData['email'] ?? '';
            profileImageUrl = updatedUserData['avatar_url'];
          });
        }
      }
    }
  }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // Show compression progress
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🖼️ Optimizing image...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Compress the image for profile use
        final originalFile = File(image.path);
        final compressedFile = await originalFile.compressForProfile();

        if (compressedFile != null) {
          setState(() {
            _imageFile = compressedFile;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Image optimized successfully!'),
                duration: Duration(seconds: 1),
              ),
            );
          }

          // Log compression stats
          ImageCompressionService().printCompressionReport();
        } else {
          // Fallback to original file if compression fails
          setState(() {
            _imageFile = originalFile;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Using original image (compression failed)'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking/compressing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error selecting image'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> saveProfile() async {
    try {
      // upload yung image if selected
      String? newAvatarUrl;
      if (_imageFile != null) {
        newAvatarUrl = await authService.uploadNewProfileImage(_imageFile!);
      }

      // Use the enhanced update method that handles Google account constraints
      await authService.updateProfileEnhanced(
        displayName: nameController.text,
        email: emailController.text,
        mobileNumber: mobileNumberController.text,
        avatarUrl: newAvatarUrl ?? profileImageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isGoogleLinked
                ? 'Profile updated successfully (Google profile synced)'
                : 'Profile updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          selectionHandleColor: const Color(0xFF067837),
          cursorColor: const Color(0xFF067837),
          selectionColor: const Color(0xFF067837),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
          ),
          title: Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
          ),
          backgroundColor:
              isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
          elevation: 1.0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDarkMode ? Brightness.light : Brightness.dark,
            statusBarBrightness:
                isDarkMode ? Brightness.dark : Brightness.light,
          ),
        ),
        backgroundColor:
            isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(screenSize.width * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: screenSize.width * 0.12,
                                backgroundColor: const Color(0xFF00CC58),
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!) as ImageProvider
                                    : (profileImageUrl != null
                                        ? NetworkImage(profileImageUrl!)
                                        : null),
                                child: (_imageFile == null &&
                                        profileImageUrl == null)
                                    ? Icon(
                                        Icons.person,
                                        size: screenSize.width * 0.12,
                                        color: const Color(0xFFF5F5F5),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  backgroundColor: const Color(0xFF00CC58),
                                  radius: screenSize.width * 0.04,
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt,
                                        color: Colors.white),
                                    onPressed: pickImage,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                        buildInputField('Name', nameController, isDarkMode),
                        buildPhoneNumberField(isDarkMode),
                        buildEmailField(isDarkMode),
                        const SizedBox(height: 24),
                        buildLinkedAccountsSection(
                            screenSize.width, isDarkMode),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(screenSize.width * 0.04),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00CC58),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInputField(
      String label, TextEditingController controller, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          cursorColor:
              isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor:
                isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 14,
            ),
          ),
        ),
        const SizedBox(height: 45),
      ],
    );
  }

  Widget buildPhoneNumberField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobile Number',
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color:
                isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/svg/phFlag.svg',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '+63',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF121212),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 20,
                color: isDarkMode
                    ? const Color(0xFF515151)
                    : const Color(0xFF515151),
              ),
              Expanded(
                child: TextField(
                  controller: mobileNumberController,
                  cursorColor: isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212),
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? const Color(0xFFF5F5F5)
                        : const Color(0xFF121212),
                    fontFamily: 'Inter',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 45),
      ],
    );
  }

  Widget buildEmailField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Email Address',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFF121212),
              ),
            ),
            if (isGoogleLinked) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00CC58),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Google',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: emailController,
          enabled: !isGoogleLinked, // Disable for Google accounts
          cursorColor:
              isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isGoogleLinked
                ? (isDarkMode
                    ? const Color(0xFF888888)
                    : const Color(0xFF666666))
                : (isDarkMode
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFF121212)),
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isGoogleLinked
                ? (isDarkMode
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE0E0E0))
                : (isDarkMode
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFF5F5F5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 14,
            ),
            suffixIcon: isGoogleLinked
                ? const Icon(Icons.lock_outline,
                    color: Color(0xFF888888), size: 20)
                : null,
          ),
        ),
        if (isGoogleLinked) ...[
          const SizedBox(height: 4),
          Text(
            'Email is managed by Google and cannot be changed here',
            style: TextStyle(
              fontSize: 11,
              color: isDarkMode
                  ? const Color(0xFF888888)
                  : const Color(0xFF666666),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 45),
      ],
    );
  }

  Widget buildLinkedAccountsSection(double screenWidth, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Linked Accounts',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Google Icon and Text
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/svg/googleIcon.svg',
                    width: 24,
                    height: 24,
                    // Removing any color override to keep original Google colors
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Google',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFF121212),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (isGoogleLinked) ...[
                // Sync button for Google accounts
                GestureDetector(
                  onTap: () async {
                    try {
                      final success = await authService.syncGoogleProfile();
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('✅ Google profile synced successfully'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        // Reload user data after sync
                        await loadUserData();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('❌ Failed to sync Google profile'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00CC58),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Sync',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Transform.scale(
                scale: 0.8,
                child: CupertinoSwitch(
                  value: isGoogleLinked,
                  onChanged: null,
                  activeTrackColor: const Color(0xFF00CC58),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
