import 'dart:async';

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
  bool _canResend = true;
  int _remainingTime = 60;
  Timer? _timer;

  @override
  void dispose() {
    _emailController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _canResend = false;
      _remainingTime = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        setState(() => _canResend = true);
        _timer?.cancel();
      }
    });
  }

  Future<void> handleForgotPassword() async {
    final email = _emailController.text.trim().toLowerCase();

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

    if (!_canResend) {
      Fluttertoast.showToast(
        msg: "Please wait $_remainingTime seconds before requesting again",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(0xFFF5F5F5),
        textColor: Color(0xFF121212),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bool canProceed =
          await _authService.checkResetPasswordRateLimit(email);

      if (!canProceed) {
        throw Exception('rate_limit');
      }

      // First, try to send the password reset email
      await _authService.supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: null,
      );

      _startTimer(); // Start the cooldown timer

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
      debugPrint("Detailed error in handleForgotPassword: $e");
      if (mounted) {
        String errorMessage;
        if (e.toString().contains('rate_limit')) {
          errorMessage = "Please wait before requesting another reset email";
        } else if (e.toString().contains('network')) {
          errorMessage = "Network error. Please check your connection";
        } else if (e.toString().contains('not found') ||
            e.toString().contains('Invalid login credentials')) {
          errorMessage = "No account found with this email";
        } else {
          errorMessage = "An error occurred while resetting password";
        }

        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Color(0xFF121212),
          textColor: Color(0xFFF5F5F5),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget timerWidget = _canResend
        ? const SizedBox.shrink()
        : Text(
            'Resend in $_remainingTime seconds',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          );

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
            timerWidget,
          ],
        ),
      ),
    );
  }
}
