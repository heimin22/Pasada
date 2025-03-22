import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/authenticationAccounts/authService.dart';
import 'package:pasada_passenger_app/authenticationAccounts/loginAccount.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import 'package:pasada_passenger_app/main.dart';
import 'package:pasada_passenger_app/authenticationAccounts/createAccountCred.dart';

void main() => runApp(const CreateAccountPage());

class CreateAccountPage extends StatelessWidget {
  const CreateAccountPage({super.key});

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
      home: const CAPage(title: 'Create Account'),
      routes: <String, WidgetBuilder>{
        'start': (BuildContext context) => const PasadaPassenger(),
        'cred': (BuildContext context) => const CreateAccountCredPage(),
        'login': (BuildContext context) => const LoginAccountPage(),
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
  // text controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // get auth service
  final AuthService authService = AuthService();

  // session
  final session = supabase.auth.currentSession;

  // password visibility
  bool isPasswordVisible = false;

  // error message
  String errorMessage = ' ';

  // loading
  bool isLoading = false;

  // internet connection
  final Connectivity connectivity = Connectivity();

  // sign up
  Future<void> SigningUp() async {
    // preprepare na yung data
    final email = emailController.text;
    final password = passwordController.text;

    // attempt na masign-up
    try {
      await authService.signUp(email,password);
      // kapag successful yung pagregister ng account
      Navigator.pushNamedAndRemoveUntil(
        context,
        'start',
        (route) => false,
        arguments: {'accountCreated': true}, // pass success argument
      );
    }
    catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }

      // pop the register page
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // Back button with its own padding
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.07,
              left: MediaQuery.of(context).size.height * 0.01,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: buildBackButton(),
            ),
          ),
          // Expanded widget to fill remaining space with main content
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.01,
                  left: MediaQuery.of(context).size.height * 0.035,
                  right: MediaQuery.of(context).size.height * 0.035,
                  bottom: MediaQuery.of(context).size.height * 0.035,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildHeader(),
                    buildPassengerEmailNumberText(),
                    buildPassengerEmailNumberInput(),
                    buildPassengerPassText(),
                    buildPassengerPassInput(),
                    buildCreateAccountButton(),
                    buildOrDesign(),
                    buildSignUpGoogle(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container buildBackButton() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
      child: IconButton(
        onPressed: () {
          Navigator.pushNamed(context, 'start');
        },
        icon: Icon(Icons.arrow_back),
      ),
    );
  }

  Column buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.01,
          ),
          alignment: Alignment.centerLeft,
        ),
        /// Logo
        Container(
          alignment: Alignment.centerLeft,
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.01,
          ),
          // margin: EdgeInsets.only(top:80.0, bottom: 30.0, right:300.0),
          height: 80,
          width: 80,
          child: SvgPicture.asset('assets/svg/Ellipse.svg'),
        ),
        /// Create your account text
        Container(
          margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
          child: const Text(
            'Create your account',
            style: TextStyle(
              color: Color(0xFF121212),
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
        ),
        const SizedBox(height: 3),
        /// Join the Pasada... text
        Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.0025),
          child: Text(
            'Join the Pasada app and make your ride easier',
            style: TextStyle(color: Color(0xFF121212)),
          ),
        ),
      ],
    );
  }

  Container buildPassengerEmailNumberText() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
      child: const Row(
        children: [
          Text(
            'Enter your ',
            style: TextStyle(color: Color(0xFF121212)),
          ),
          Text(
            'email or phone number',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            ' to continue',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Container buildPassengerEmailNumberInput() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.02),
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: TextField(
          controller: emailController,
          style: const TextStyle(
            color: Color(0xFF121212),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            labelText: 'Enter your email or phone number',
            labelStyle: const TextStyle(
              fontSize: 12,
            ),
            errorText: errorMessage.isNotEmpty ? errorMessage : null,
            floatingLabelStyle: const TextStyle(
              color: Color(0xFF121212),
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
                color: Color(0xFF121212),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Container buildPassengerPassText() {
    return Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
        child: const Row(
          children: [
            Text(
              'Enter your ',
              style: TextStyle(
                color: Color(0xFF121212),
              ),
            ),
            Text(
              'password.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            )
          ],
        )
    );
  }

  Container buildPassengerPassInput() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.02),
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: TextField(
          controller: passwordController,
          obscureText: !isPasswordVisible,
          style: const TextStyle(
            color: Color(0xFF121212),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            labelText: 'Enter your password',
            errorText: errorMessage.isNotEmpty ? errorMessage : null,
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
              color: Color(0XFF121212),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFF121212),
                width: 1.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFF121212),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Flexible buildCreateAccountButton() {
    return Flexible(
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : SigningUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF121212),
            minimumSize: const Size(360, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFFF5F5F5),
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Continue',
                  style: TextStyle(
                    color: Color(0xFFF2F2F2),
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
        ),
      ),
    );
  }

  Flexible buildOrDesign() {
    return Flexible(
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
        width: double.infinity,
        child: SvgPicture.asset('assets/svg/otherOptionsOptimized.svg'),
      ),
    );
  }

  Flexible buildSignUpGoogle() {
    return Flexible(
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF121212),
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
    );
  }
}
