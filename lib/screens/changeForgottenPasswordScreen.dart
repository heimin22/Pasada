import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/screens/selectionScreen.dart';

class ChangeForgottenPasswordScreen extends StatefulWidget {
  const ChangeForgottenPasswordScreen({super.key});

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

  Future<void> handleForgotPassword() async {}

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
