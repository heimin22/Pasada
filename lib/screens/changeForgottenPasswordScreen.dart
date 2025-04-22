import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/screens/selectionScreen.dart';

class ChangeForgottenPasswordScreen extends StatefulWidget {
  final String email;

  const ChangeForgottenPasswordScreen({super.key, required this.email});

  @override
  State<ChangeForgottenPasswordScreen> createState() =>
      ChangeForgottenPasswordScreenState();
}

class ChangeForgottenPasswordScreenState
    extends State<ChangeForgottenPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> handleForgotPassword() async {
    if (_newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please fill in all fields",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(0xFFF5F5F5),
        textColor: Color(0xFF121212),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.login(widget.email, _newPasswordController.text);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => selectionScreen()),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
