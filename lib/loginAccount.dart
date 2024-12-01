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

        }
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
                onPressed: () {},
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
              padding: EdgeInsets.only(bottom: 10.0, right: 134.0),
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

                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}