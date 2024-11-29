import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
        home: const CAPage(title: 'Create Account'));
  }
}

class CAPage extends StatefulWidget {
  const CAPage({super.key, required this.title});

  final String title;

  @override
  State<CAPage> createState() => CreateAccountScreen();
}

class CreateAccountScreen extends State<CAPage> {
  final TextEditingController inputController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  String errorMessage = ' ';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 40.0, bottom: 30.0, right: 300.0),
              height: 80,
              width: 80,
              child: SvgPicture.asset('assets/svg/Ellipse.svg')
                  .animate()
                  .fadeIn(duration: 650.ms, delay: 500.ms)
                  .slide(),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 10.0, right: 134.0),
              child: Text(
                'Create your account',
                style: TextStyle(
                  color: Color(0xFF121212),
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slide(),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: EdgeInsets.only(bottom: 25.0, right: 60.0),
              child: Text(
                'Join the Pasada app and make your ride easier',
                style: TextStyle(color: Color(0xFF121212)),
              ).animate().fadeIn(duration: 500.ms, delay: 500.ms).slide(),
            ),
            Container(
              margin:
                  const EdgeInsets.only(left: 35.0, right: 39.0, bottom: 25.0),
              height: 50,
              child: TextField(
                controller: inputController,
                style: const TextStyle(
                  color: Color(0xFF121212),
                ),
                decoration: const InputDecoration(
                  labelText: 'Enter your email or phone number',
                  labelStyle: TextStyle(
                    fontSize: 12,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: Color(0xFF4AB00C),
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
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 15.0, right: 307.0),
              child: const Text(
                'Password',
                style: TextStyle(
                  color: Color(0xFF121212),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              margin:
                  const EdgeInsets.only(left: 35.0, right: 39.0, bottom: 50.0),
              height: 50,
              child: TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                style: const TextStyle(
                  color: Color(0xFF121212),
                ),
                decoration: InputDecoration(
                  labelText: 'Enter your password',
                  suffixIcon: IconButton(
                    color: const Color(0xFF121212),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                  ),
                  floatingLabelStyle: const TextStyle(
                    color: Color(0xFF4AB00C),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFFC7C7C6),
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF4AB00C),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4AB00C),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    color: Color(0xFFF2F2F2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(bottom: 5.0, top: 80.0),
              child: SvgPicture.asset('assets/svg/otherOptionsOptimized.svg'),
            ),
            Container(
              margin: EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4AB00C),
                  minimumSize: const Size(400, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: Color(0xFFF2F2F2),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(bottom: 100.0),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4AB00C),
                  minimumSize: const Size(400, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text(
                  'Continue with Viber',
                  style: TextStyle(
                    color: Color(0xFFF2F2F2),
                    fontSize: 20,
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
