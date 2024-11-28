import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/starttScreen.dart';
import 'package:pasada_passenger_app/loginAccount.dart';

void main() => runApp(const LoginAccountPage());

class LoginAccountPage extends StatelessWidget {
  const LoginAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Log-in',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const LoginPage(title: 'Log-in to your account')
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});

  final String title;

  @override
  State<LoginPage> createState() => LoginScreen();
}

class LoginScreen extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    );
  }
}