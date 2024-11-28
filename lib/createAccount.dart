import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/starttScreen.dart';

void main() => runApp(const CreateAccountPage());

class CreateAccountPage extends StatelessWidget {
  const CreateAccountPage({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Create Account',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const CAPage(title: 'Create Account')
    );
  }
}

class CAPage extends StatefulWidget {
  const CAPage({super.key, required this.title});
  final String title;
  @override
  State<CAPage> createState() => CreateAccountScreen();
}

class CreateAccountScreen extends State<CAPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 200.0),
              child: const Text(
                'Create your account',
                style: const TextStyle(
                  color: Color(0xFF121212),
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
