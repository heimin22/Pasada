import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:pasada_passenger_app/theme/theme_controller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';

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
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to send authentication code',
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

  Future<void> verifyCodeAndChangedPassword() async {
    if (codeController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter the authentication code',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(0xFFF5F5F5),
        textColor: Color(0xFF121212),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await authService.verifyPasswordResetCode(
        widget.email,
        codeController.text,
        widget.newPassword,
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

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Verify Authentication Code'),
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
                    fillColor:
                        isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  ),
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFFF5F5F5)
                        : const Color(0xFF121212),
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
                onPressed: isLoading ? null : verifyCodeAndChangePassword,
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
