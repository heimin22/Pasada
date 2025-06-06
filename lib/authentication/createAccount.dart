import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/screens/selectionScreen.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:pasada_passenger_app/main.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

bool isGoogleLoading = false;

class _CreateAccountPageState extends State<CreateAccountPage> {
  @override
  Widget build(BuildContext context) {
    return const CAPage(title: 'Pasada');
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
  final TextEditingController confirmPasswordController =
      TextEditingController();

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

  LinearGradient _getTimeBasedGradient() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      // Morning
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF236078), Color(0xFF439464)],
        transform: GradientRotation(21 * 3.14159 / 180),
      );
    } else if (hour >= 12 && hour < 18) {
      // Afternoon
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFCFA425), Color(0xFF26AB37)],
        transform: GradientRotation(21 * 3.14159 / 180),
      );
    } else if (hour >= 18 && hour < 22) {
      // Evening
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFB45F4F), Color(0xFF705776)],
        transform: GradientRotation(21 * 3.14159 / 180),
      );
    } else {
      // Night
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2E3B4E), Color(0xFF1C1F2E)],
        transform: GradientRotation(21 * 3.14159 / 180),
      );
    }
  }

  // sign up
  Future<void> SigningUp() async {
    // clear previous errors
    setState(() => errorMessage = '');

    // controllers
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Please fill in all fields.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Color(0xFFF5F5F5),
          textColor: Color(0xFF121212),
        );
        return;
      }
    }

    if (password != confirmPassword) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Passwords do not match.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Color(0xFFF5F5F5),
          textColor: Color(0xFF121212),
        );
        return;
      }
    }

    // attempt na masign-up
    try {
      setState(() => isLoading = true);
      debugPrint('Navigating to cred');
      Navigator.pushNamed(
        context,
        'cred',
        // pass success argument
        arguments: {'email': email, 'password': password},
      );
      debugPrint('Navigation completed');
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error: $e',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Color(0xFFF5F5F5),
          textColor: Color(0xFF121212),
        );
      }
      // pop the register page
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar to white icons
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: _getTimeBasedGradient(),
        ),
        child: Column(
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
                      buildConfirmPassText(),
                      buildConfirmPassInput(),
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
        icon: Icon(
          Icons.arrow_back,
          color: Color(0xFFF5F5F5),
        ),
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
          child: SvgPicture.asset('assets/svg/pasadaLogoWithoutText.svg'),
        ),

        /// Create your account text
        Container(
          margin:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
          child: const Text(
            'Create your account',
            style: TextStyle(
              color: Color(0xFFF5F5F5),
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
        ),
        const SizedBox(height: 3),

        /// Join the Pasada... text
        Container(
          padding:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.0025),
          child: Text(
            'Join the Pasada app and make your ride easier',
            style: TextStyle(color: Color(0xFFF5F5F5)),
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
            'Email or Phone Number',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                color: Color(0xFFF5F5F5)),
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
          style: const TextStyle(
            color: Color(0xFFF5F5F5),
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
            fontSize: 14,
          ),
          controller: emailController,
          cursorColor: Color(0xFF00CC58),
          decoration: InputDecoration(
            labelText: 'Enter your email',
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFFAAAAAA),
            ),
            floatingLabelStyle: const TextStyle(
              color: Color(0xFFF5F5F5),
            ),
            filled: true,
            fillColor: Colors.black12,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFFF5F5F5),
                width: 1.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFF00CC58),
              ),
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
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
            'Password',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                color: Color(0xFFF5F5F5)),
          ),
        ],
      ),
    );
  }

  Container buildPassengerPassInput() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.02),
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: TextField(
          style: const TextStyle(
            color: Color(0xFFF5F5F5),
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
            fontSize: 14,
          ),
          controller: passwordController,
          cursorColor: Color(0xFF00CC58),
          obscureText: !isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Enter your password',
            suffixIcon: IconButton(
              color: const Color(0xFFF5F5F5),
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
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFFAAAAAA),
            ),
            floatingLabelStyle: const TextStyle(
              color: Color(0xFFF5F5F5),
            ),
            filled: true,
            fillColor: Colors.black12,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFFF5F5F5),
                width: 1.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFF00CC58),
              ),
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            ),
          ),
        ),
      ),
    );
  }

  Container buildConfirmPassText() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
      child: const Row(
        children: [
          Text(
            'Confirm Password',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                color: Color(0xFFF5F5F5)),
          ),
        ],
      ),
    );
  }

  Container buildConfirmPassInput() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.02),
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: TextField(
          style: const TextStyle(
            color: Color(0xFFF5F5F5),
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
            fontSize: 14,
          ),
          controller: confirmPasswordController,
          cursorColor: Color(0xFF00CC58),
          obscureText: !isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Confirm your password',
            suffixIcon: IconButton(
              color: const Color(0xFFF5F5F5),
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
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFFAAAAAA),
            ),
            floatingLabelStyle: const TextStyle(
              color: Color(0xFFF5F5F5),
            ),
            filled: true,
            fillColor: Colors.black12,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFFF5F5F5),
                width: 1.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFF00CC58),
              ),
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
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
            backgroundColor: const Color(0xFFF5F5F5),
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
                    color: Color(0xFF00CC58),
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Continue',
                  style: TextStyle(
                    color: Color(0xFF00CC58),
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
          onPressed: isGoogleLoading
              ? null
              : () async {
                  setState(() => isGoogleLoading = true);
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
                    debugPrint('Google sign-in error: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => isGoogleLoading = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFFF5F5F5),
            minimumSize: const Size(360, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: const BorderSide(
                color: Color(0xFFF5F5F5),
                width: 2,
              ),
            ),
          ),
          child: isGoogleLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFFF5F5F5),
                    strokeWidth: 2,
                  ),
                )
              : Row(
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
                        color: Color(0xFFF5F5F5),
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
