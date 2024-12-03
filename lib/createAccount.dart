import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pasada_passenger_app/starttScreen.dart';
import 'package:pasada_passenger_app/createAccountCred.dart';

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
      home: const CAPage(title: 'Create Account'),
      routes: <String, WidgetBuilder>{
        'start': (BuildContext context) => const PasadaPassenger(),
        'cred': (BuildContext context) => const CreateAccountCredPage(),
      },
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
              margin: const EdgeInsets.only(top: 35.0, right: 360.0),
              child: IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, 'start');
                  },
                  icon: Icon(Icons.arrow_back),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 80.0, bottom: 30.0, right: 300.0),
              height: 80,
              width: 80,
              child: SvgPicture.asset('assets/svg/Ellipse.svg'),
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
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: EdgeInsets.only(bottom: 25.0, right: 60.0),
              child: Text(
                'Join the Pasada app and make your ride easier',
                style: TextStyle(color: Color(0xFF121212)),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 35.0, right: 39.0, bottom: 25.0),
              height: 50,
              child: TextField(
                controller: inputController,
                style: const TextStyle(
                  color: Color(0xFF121212),
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  labelText: 'Enter your email or phone number',
                  labelStyle: TextStyle(
                    fontSize: 12,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: Color(0xFF5f3fc4),
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
                      color: Color(0xFF5f3fc4),
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
                  fontSize: 14,
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
                    color: Color(0xFF5f3fc4),
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
                      color: Color(0xFF5f3fc4),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, 'cred');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5f3fc4),
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
              margin: EdgeInsets.only(bottom: 5.0, top: 75.0),
              child: SvgPicture.asset('assets/svg/otherOptionsOptimized.svg'),
            ),
            Container(
              // Google Button
              margin: EdgeInsets.only(bottom: 20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 360,
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5f3fc4),
                      minimumSize: const Size(360, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/googleIcon.svg',
                          height: 24,
                          width: 24,
                        ),
                        const SizedBox(width: 25),
                        const Text(
                          'Sign-up with Google',
                          style: TextStyle(
                            color: Color(0xFFF2F2F2),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              // Viber Button
              margin: EdgeInsets.only(bottom: 20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 360,
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5f3fc4),
                      minimumSize: const Size(360, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/viberIcon.svg',
                          height: 30,
                          width: 30,
                        ),
                        const SizedBox(width: 25),
                        const Text(
                          'Sign-up with Viber',
                          style: TextStyle(
                            color: Color(0xFFF2F2F2),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
