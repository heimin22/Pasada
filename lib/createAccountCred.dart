import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pasada_passenger_app/homeScreen.dart';
import 'package:pasada_passenger_app/starttScreen.dart';

void main() => runApp(const CreateAccountCredPage());

class CreateAccountCredPage extends StatelessWidget {
  const CreateAccountCredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pasada',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const CredPage(title: 'Create Account'),
      routes: <String, WidgetBuilder>{
        'start': (BuildContext context) => const PasadaPassenger(),
        'home': (BuildContext context) => const HomeScreen(),
      },
    );
  }
}

class CredPage extends StatefulWidget {
  const CredPage({super.key, required this.title});

  final String title;

  @override
  State<CredPage> createState() => _CredPageState();
}

class _CredPageState extends State<CredPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // Positioned(
            //   top:
            // ),
          ],
        ),
      ),
    );
  }
}

