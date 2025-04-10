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
    return const Placeholder();
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
}
