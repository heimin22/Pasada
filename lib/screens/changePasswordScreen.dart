import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/main.dart';
import 'package:pasada_passenger_app/screens/authenticationCodePasswordScreen.dart';
import 'package:pasada_passenger_app/services/authService.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => ChangePasswordScreenState();
}

class ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthService authService = AuthService();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  PreferredSizeWidget buildAppBar(bool isDarkMode) {
    return AppBar(
      title: Text(
        'Change Password',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
        ),
      ),
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      foregroundColor:
          isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
      elevation: 1.0,
    );
  }

  Container buildPasswordField(
      String label, TextEditingController controller, bool isDarkMode) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: TextField(
              controller: controller,
              obscureText: !isPasswordVisible,
              style: TextStyle(
                color: isDarkMode
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFF121212),
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                fontSize: 14,
              ),
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  color: isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212),
                  onPressed: () {
                    setState(() => isPasswordVisible = !isPasswordVisible);
                  },
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDarkMode
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFE9E9E9),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: const Color(0xFF00CC58),
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container buildChangePasswordButton(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : handleChangePassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00CC58),
          minimumSize: const Size(360, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00CC58),
                ),
              )
            : Text(
                'Change Password',
                style: TextStyle(
                  color: Color(0xFFF5F5F5),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Future<void> handleChangePassword() async {
    if (currentPasswordController.text.isEmpty ||
        newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please fill in all fields',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(0xFFF5F5F5),
        textColor: Color(0xFF121212),
      );
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      Fluttertoast.showToast(
        msg: 'Passwords do not match',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(0xFFF5F5F5),
        textColor: Color(0xFF121212),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AuthenticationScreen(
                    email: user.email!,
                    newPassword: newPasswordController.text,
                  )),
        );
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to change password',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Color(0xFFF5F5F5),
          textColor: Color(0xFF121212),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor:
            isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: buildAppBar(isDarkMode),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildPasswordField('Current Password',
                      currentPasswordController, isDarkMode),
                  buildPasswordField(
                      'New Password', newPasswordController, isDarkMode),
                  buildPasswordField('Confirm New Password',
                      confirmPasswordController, isDarkMode),
                ],
              ),
              buildChangePasswordButton(isDarkMode),
            ],
          ),
        ),
      ),
    );
  }
}
