import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/screens/authenticationCodePasswordScreen.dart';

class ChangeForgottenPassword extends StatefulWidget {
  const ChangeForgottenPassword({super.key});

  @override
  State<ChangeForgottenPassword> createState() =>
      ChangeForgottenPasswordState();
}

class ChangeForgottenPasswordState extends State<ChangeForgottenPassword> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please enter your email",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Color(0xFFF5F5F5),
        textColor: Color(0xFF121212),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.supabase
          .from('passenger')
          .select()
          .eq('email', email)
          .single();

      if (response == null) {
        Fluttertoast.showToast(
          msg: "User not found",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Color(0xFFF5F5F5),
          textColor: Color(0xFF121212),
        );
        return;
      }

      await _authService.sendPasswordResetEmail(email);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AuthenticationScreen(
              email: email,
              newPassword: '',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        debugPrint("Error in handleForgotPassword: $e");

        String errorMessage = "An error occurred";

        if (e.toString().contains('not found')) {
          errorMessage = "No account found with this email";
        } else if (e.toString().contains('network')) {
          errorMessage = "Network error. Please check your connection";
        }

        Fluttertoast.showToast(
          msg: "An error occurred",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF121212)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Forgot Password",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF121212),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Enter your email to reset your password",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF121212),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF121212),
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
              decoration: const InputDecoration(
                hintText: "Email",
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF121212),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF121212)),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF121212)),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : handleForgotPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00CC58),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFF5F5F5)),
                        ),
                      )
                    : Text(
                        'Reset Password',
                        style: TextStyle(
                          color: const Color(0xFFF5F5F5),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
