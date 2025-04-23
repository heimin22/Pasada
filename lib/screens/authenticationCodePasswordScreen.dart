import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/screens/changeForgottenPasswordScreen.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthenticationScreen extends StatefulWidget {
  final String email;
  final String newPassword;

  const AuthenticationScreen(
      {super.key, required this.email, required this.newPassword});

  @override
  State<AuthenticationScreen> createState() => AuthenticationScreenState();
}

class AuthenticationScreenState extends State<AuthenticationScreen> {
  final TextEditingController codeController = TextEditingController();
  final AuthService authService = AuthService();
  bool isLoading = false;
  bool canResend = false;
  int remainingTime = 120;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    sendAuthenticationCode();
    startTimer();
  }

  @override
  void dispose() {
    codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (count) {
      if (remainingTime > 0) {
        setState(() => remainingTime--);
      } else {
        setState(() => canResend = true);
        _timer?.cancel();
      }
    });
  }

  Future<void> sendAuthenticationCode() async {
    try {
      setState(() {
        isLoading = true;
        canResend = false;
      });

      await authService.sendPasswordResetEmail(widget.email);

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Authentication code sent',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Color(0xFFF5F5F5),
          textColor: Color(0xFF121212),
        );
      }
    } catch (e) {
      debugPrint(
          'Error sending authentication code: $e'); // Add this for debugging
      if (mounted) {
        // Only show error toast if there's actually an error
        String errorMessage = 'Failed to send authentication code';
        if (e.toString().contains('rate_limit')) {
          errorMessage = 'Please wait before requesting another code';
        }
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Color(0xFFF5F5F5),
          textColor: Color(0xFF121212),
        );
      }
      rethrow; // Add this to propagate the error if needed
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> verifyCodeAndChangedPassword() async {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter the authentication code',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(0xFFF5F5F5),
        textColor: Color(0xFF121212),
      );
      return;
    }

    if (code.length != 6) {
      Fluttertoast.showToast(
        msg: 'Please enter a valid 6-digit code',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(0xFFF5F5F5),
        textColor: Color(0xFF121212),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // First verify the OTP
      final response = await authService.supabase.auth.verifyOTP(
        email: widget.email,
        token: code,
        type: OtpType.recovery,
      );

      if (response.session != null) {
        if (widget.newPassword.isNotEmpty) {
          // For normal password change flow
          await authService.supabase.auth.updateUser(
            UserAttributes(password: widget.newPassword),
          );

          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Password changed successfully',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Color(0xFFF5F5F5),
              textColor: Color(0xFF121212),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else {
          // For forgotten password flow
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeForgottenPasswordScreen(
                  email: widget.email,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Verification error: $e');
      if (mounted) {
        String errorMessage = 'Invalid verification code';
        if (e.toString().contains('rate_limit')) {
          errorMessage = 'Please wait before trying again';
        }
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Color(0xFFF5F5F5),
          textColor: Color(0xFF121212),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Verify Authentication Code',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the authentication code sent to:',
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFFF5F5F5)
                        : const Color(0xFF121212),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.email,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? const Color(0xFFF5F5F5)
                        : const Color(0xFF121212),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: 'Authentication Code',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF2F2F2),
                    helperText: 'Enter the 6-digit code sent to your email',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFFF5F5F5)
                        : const Color(0xFF121212),
                    letterSpacing: 8.0,
                  ),
                ),
                const SizedBox(height: 16),
                if (!canResend)
                  Text(
                    'Resend code in ${remainingTime}s',
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFF121212),
                    ),
                  ),
                if (canResend)
                  TextButton(
                    onPressed: () {
                      sendAuthenticationCode();
                      setState(() {
                        remainingTime = 120;
                        canResend = false;
                      });
                      startTimer();
                    },
                    child: const Text('Resend Code'),
                  ),
              ],
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              child: ElevatedButton(
                onPressed: isLoading ? null : verifyCodeAndChangedPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00CC58),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Verify Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF5F5F5),
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
