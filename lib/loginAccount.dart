import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/starttScreen.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      home: const LoginPage(title: 'Log-in to your account'),
      routes: <String, WidgetBuilder>{
        'start': (BuildContext context) => const PasadaPassenger(),
      },
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
  final TextEditingController inputController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  String errorMessage = '';

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
            Container (
              margin: EdgeInsets.only(top:80.0, bottom: 30.0, right:300.0),
              height: 80,
              width: 80,
              child: SvgPicture.asset('assets/svg/Ellipse.svg'),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 25.0, right: 63.0),
              child: Text(
                'Enter your email or mobile number to continue',
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
                  )
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
              margin: const EdgeInsets.only(left: 35.0, right: 39.0, bottom: 50.0),
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
                      isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                  ),
                  floatingLabelStyle: const TextStyle(
                    color: Color(0XFF4AB00C),
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
                    )
                  )
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
                      backgroundColor: const Color(0xFF4AB00C),
                      minimumSize: const Size(360, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      )
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

          ],
        ),
      ),
    );
  }
}