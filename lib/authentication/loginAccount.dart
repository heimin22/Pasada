import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/screens/selectionScreen.dart';
import 'package:pasada_passenger_app/main.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginAccountPage extends StatefulWidget {
  const LoginAccountPage({super.key});

  @override
  State<LoginAccountPage> createState() => _LoginAccountPageState();
}

class _LoginAccountPageState extends State<LoginAccountPage> {
  @override
  Widget build(BuildContext context) {
    return const LoginPage(title: 'Pasada');
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});

  final String title;

  @override
  State<LoginPage> createState() => LoginScreen();
}

class LoginScreen extends State<LoginPage> {
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
  String errorMessage = '';

  // loading
  bool isLoading = false;

  // internet connection
  final Connectivity connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> connectivitySubscription;

  void initState() {
    super.initState();
    checkInitialConnectivity();
    connectivitySubscription =
        connectivity.onConnectivityChanged.listen(updateConnectionStatus);
  }

  Future<void> checkInitialConnectivity() async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) showNoInternetToast();
  }

  void updateConnectionStatus(List<ConnectivityResult> result) {
    if (result == ConnectivityResult.none) showNoInternetToast();
  }

  void showNoInternetToast() {
    Fluttertoast.showToast(
      msg: 'No internet connection detected',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Color(0xFFF2F2F2),
      textColor: Color(0xFF121212),
      fontSize: 16.0,
    );
  }

  Future<void> login() async {
    final email = emailController.text;
    final password = passwordController.text;
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) showNoInternetToast();

    try {
      await authService.supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        // successful login
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => selectionScreen()));
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } catch (err) {
      setState(() => errorMessage = 'An unexpected error occurred');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF5F5F5), // Force light mode
      body: Column(
        children: [
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
                    buildForgotPassword(),
                    SizedBox(height: 48),
                    buildLogInButton(),
                    buildOrDesign(),
                    buildLoginGoogle(),
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
          Navigator.pop(context);
        },
        icon: Icon(Icons.arrow_back),
      ),
    );
  }

  Container buildPassengerPassInput() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: TextField(
          controller: passwordController,
          obscureText: !isPasswordVisible,
          style: const TextStyle(
            color: Color(0xFF121212),
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
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
              color: Color(0XFF00CC58),
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
                color: Color(0xFF00CC58),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Container buildPassengerEmailNumberInput() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: TextField(
          controller: emailController,
          style: const TextStyle(
            color: Color(0xFF121212),
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
            fontSize: 14,
          ),
          decoration: InputDecoration(
            labelText: 'Enter your email or phone number',
            labelStyle: const TextStyle(
              fontSize: 12,
            ),
            errorText: errorMessage.isNotEmpty ? errorMessage : null,
            floatingLabelStyle: const TextStyle(
              color: Color(0xFF00CC58),
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
                color: Color(0xFF00CC58),
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
        ));
  }

  Container buildPassengerEmailNumberText() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.05),
      child: const Row(
        children: [
          Text(
            'Enter your ',
            style: TextStyle(color: Color(0xFF121212)),
          ),
          Text(
            'email',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            ' to continue',
            style: TextStyle(color: Color(0xFF121212)),
          ),
        ],
      ),
    );
  }

  Flexible buildLogInButton() {
    return Flexible(
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : login,
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
                  'Log-in',
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

  Widget buildOrDesign() {
    return Flexible(
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
        width: double.infinity,
        child: SvgPicture.asset('assets/svg/otherOptionsOptimized.svg'),
      ),
    );
  }

  Widget buildLoginGoogle() {
    return Flexible(
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  setState(() => isLoading = true);
                  try {
                    final success = await authService.signInWithGoogle();
                    if (success && mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const selectionScreen()),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Failed to sign in with Google')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => isLoading = false);
                  }
                },
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
                'Log-in with Google',
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

  Container buildForgotPassword() {
    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).size.height * 0.02,
        left: MediaQuery.of(context).size.height * 0.003,
      ),
      child: Text(
        "Forgot Password?",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF121212),
        ),
      ),
    );
  }

  Column buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.centerLeft,
          margin:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
          height: 80,
          width: 80,
          child: SvgPicture.asset('assets/svg/Ellipse.svg'),
        ),
        Container(
          margin:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
          child: const Text(
            'Log-in to your account',
            style: TextStyle(
              color: Color(0xFF121212),
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
        ),
      ],
    );
  }
}
