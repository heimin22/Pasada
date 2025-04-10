import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pasada_passenger_app/services/authService.dart';
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
      setState(() {
        nameController.text = userData['display_name'] ?? '';
        emailController.text = userData['passenger_email'] ?? '';
        mobileNumberController.text = userData['contact_number'] ?? '';
        profileImageUrl = userData['avatar_url'];
        isGoogleLinked = userData['is_google_linked'] ?? false;
      });
    }
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> saveProfile() async {
    try {
      // upload yung image if selected
      String? newAvatarUrl;
      if (_imageFile != null) {
        newAvatarUrl = await authService.uploadProfileImage(_imageFile!);
      }

      await authService.updateProfile(
        displayName: nameController.text,
        email: emailController.text,
        mobileNumber: mobileNumberController.text,
        avatarUrl: newAvatarUrl ?? profileImageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF121212),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(screenSize.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: screenSize.width * 0.15,
                        backgroundColor: const Color(0xFF00CC58),
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!) as ImageProvider
                            : (profileImageUrl != null
                                ? NetworkImage(profileImageUrl!)
                                : null),
                        child: (_imageFile == null && profileImageUrl == null)
                            ? Icon(
                                Icons.person,
                                size: screenSize.width * 0.15,
                                color: const Color(0xFFF5F5F5),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFF00CC58),
                          radius: screenSize.width * 0.05,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt,
                                color: Colors.white),
                            onPressed: pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                buildInputField('Name', nameController),
                buildPhoneNumberField(),
                buildInputField('Email Address', emailController),
                const SizedBox(height: 24),
                buildLinkedAccountsSection(screenSize.width),
                const SizedBox(height: 48),
                SizedBox(
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF121212),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildPhoneNumberField() {
    return Column(
      children: [
        const Text(
          'Mobile Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF121212),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: const Text(
                    '+63',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF121212),
                    ),
                  )),
              Container(
                width: 1,
                height: 20,
                color: Color(0xFF515151),
              ),
              Expanded(
                child: TextField(
                  controller: mobileNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildLinkedAccountsSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Linked Accounts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF121212),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/svg/googleIcon.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Google',
                style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF121212),
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: isGoogleLinked,
            onChanged: null,
            activeTrackColor: const Color(0xFF00CC58),
          ),
        ),
      ],
    );
  }
}
