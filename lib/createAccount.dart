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
    final TextEditingController inputController = TextEditingController();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 30.0, right: 300.0),
              height: 80,
              width: 80,
              child: SvgPicture.asset('assets/svg/Ellipse.svg'),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 10.0, right: 134.0),
              child: const Text(
                'Create your account',
                style: const TextStyle(
                  color: Color(0xFF121212),
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              margin: const EdgeInsets.only(bottom: 28.0, right: 60.0),
              child: const Text(
                'Join the Pasada app and make your ride easier',
                style: TextStyle(
                  color: Color(0xFF121212)
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 36.0, right: 39.0, bottom: 380.0),
              height: 50,
              child: TextField(
                controller: inputController,
                style: const TextStyle(
                  color: Color(0xFF121212),
                ),
                decoration: const InputDecoration(
                  labelText: 'Enter your email or phone number',
                  labelStyle: TextStyle(
                    fontSize: 14,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: Color(0xFF4AB00C)
                  ),
                  hintText: 'Email or phone number',
                  hintStyle: TextStyle(
                    fontSize: 4,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFFC7C7C6),
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF4AB00C),
                    ),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 36.0, right: 39.0),
              height: 50,
              child: const TextField(
                style: TextStyle(
                  color: Color(0xFF121212),
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: TextStyle(
                    fontSize: 4,
                  ),
                  labelText: 'Enter your password'
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // bool validateEmailOrPhone(String input) {
  //   final emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
  //   if (emailRegex.hasMatch(input)) {
  //     return true;
  //   }
  //
  //   final phoneRegex = RegExp(r"^\d{10,}$");
  //   if (phoneRegex.hasMatch(input)) {
  //     return true;
  //   }
  //
  //   return false;
  // }
}
