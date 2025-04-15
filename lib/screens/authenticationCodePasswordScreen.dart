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

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
