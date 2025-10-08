import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/main.dart';
import 'package:pasada_passenger_app/screens/selectionScreen.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:pasada_passenger_app/utils/toast_utils.dart';

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

    // Input validation
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ToastUtils.showWarning('Please fill in all fields.');
      return;
    }

    if (!_isValidEmail(email)) {
      ToastUtils.showError('Please enter a valid email address.');
      return;
    }

    if (password.length < 8) {
      ToastUtils.showError('Password must be at least 8 characters long.');
      return;
    }

    if (password != confirmPassword) {
      ToastUtils.showError('Passwords do not match.');
      return;
    }

    // Check network connectivity
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      ToastUtils.showError(
          'No internet connection. Please check your network and try again.');
      return;
    }

    // Navigate to credentials screen
    try {
      setState(() => isLoading = true);
      debugPrint('Navigating to credentials screen');

      Navigator.pushNamed(
        context,
        'cred',
        arguments: {'email': email, 'password': password},
      );

      debugPrint('Navigation completed');
    } catch (e) {
      debugPrint('Error during navigation: $e');
      if (mounted) {
        ToastUtils.showError('Failed to proceed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: _getTimeBasedGradient(),
          ),
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              // Back button with its own padding
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.02,
                  left: MediaQuery.of(context).size.height * 0.01,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: buildBackButton(),
                ),
              ),
              // Expanded widget to fill remaining space with main content
              Expanded(
                child: SingleChildScrollView(
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// Logo
        Container(
          alignment: Alignment.center,
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.04,
          ),
          child: Image.asset(
            'assets/png/pasada_white_brand.png',
            height: 60,
            fit: BoxFit.contain,
          ),
        ),

        /// Create your account text
        Container(
          margin:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.05),
          child: const Text(
            'Create Account',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFF5F5F5),
              fontWeight: FontWeight.w800,
              fontSize: 32,
              letterSpacing: -0.5,
            ),
          ),
        ),

        /// Join the Pasada... text
        Container(
          margin:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
          child: const Text(
            'Yun o? Sign up ka na para makapagbook ka naman.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFE0E0E0),
              fontWeight: FontWeight.w400,
              fontSize: 16,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Container buildPassengerEmailNumberText() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.05),
      child: const Row(
        children: [
          Text(
            'Email Address',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              fontSize: 15,
              color: Color(0xFFF5F5F5),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Container buildPassengerEmailNumberInput() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.012),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: TextField(
          style: const TextStyle(
            color: Color(0xFFF5F5F5),
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            fontSize: 15,
          ),
          controller: emailController,
          cursorColor: Color(0xFF00CC58),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
              fontSize: 15,
              color: Color(0xFF999999),
            ),
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: Color(0xFFCCCCCC),
              size: 22,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.12),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.all(Radius.circular(14.0)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFF00CC58),
                width: 2.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(14.0)),
            ),
          ),
        ),
      ),
    );
  }

  Container buildPassengerPassText() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.025),
      child: const Row(
        children: [
          Text(
            'Password',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              fontSize: 15,
              color: Color(0xFFF5F5F5),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Container buildPassengerPassInput() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.012),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: TextField(
          style: const TextStyle(
            color: Color(0xFFF5F5F5),
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            fontSize: 15,
          ),
          controller: passwordController,
          cursorColor: Color(0xFF00CC58),
          obscureText: !isPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
              fontSize: 15,
              color: Color(0xFF999999),
            ),
            prefixIcon: const Icon(
              Icons.lock_outlined,
              color: Color(0xFFCCCCCC),
              size: 22,
            ),
            suffixIcon: IconButton(
              color: const Color(0xFFCCCCCC),
              onPressed: () {
                setState(() {
                  isPasswordVisible = !isPasswordVisible;
                });
              },
              icon: Icon(
                isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 22,
              ),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.12),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.all(Radius.circular(14.0)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFF00CC58),
                width: 2.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(14.0)),
            ),
          ),
        ),
      ),
    );
  }

  Container buildConfirmPassText() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.025),
      child: const Row(
        children: [
          Text(
            'Confirm Password',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              fontSize: 15,
              color: Color(0xFFF5F5F5),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Container buildConfirmPassInput() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.012),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: TextField(
          style: const TextStyle(
            color: Color(0xFFF5F5F5),
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            fontSize: 15,
          ),
          controller: confirmPasswordController,
          cursorColor: Color(0xFF00CC58),
          obscureText: !isPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Confirm your password',
            hintStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
              fontSize: 15,
              color: Color(0xFF999999),
            ),
            prefixIcon: const Icon(
              Icons.lock_outlined,
              color: Color(0xFFCCCCCC),
              size: 22,
            ),
            suffixIcon: IconButton(
              color: const Color(0xFFCCCCCC),
              onPressed: () {
                setState(() {
                  isPasswordVisible = !isPasswordVisible;
                });
              },
              icon: Icon(
                isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 22,
              ),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.12),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.all(Radius.circular(14.0)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFF00CC58),
                width: 2.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(14.0)),
            ),
          ),
        ),
      ),
    );
  }

  Container buildCreateAccountButton() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.04),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : SigningUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00CC58),
          foregroundColor: Colors.white,
          minimumSize: const Size(360, 56),
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Container buildOrDesign() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
      width: double.infinity,
      child: SvgPicture.asset('assets/svg/otherOptionsOptimized.svg'),
    );
  }

  Container buildSignUpGoogle() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.015),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isGoogleLoading
            ? null
            : () async {
                // Check network connectivity first
                final connectivityResult =
                    await connectivity.checkConnectivity();
                if (connectivityResult.contains(ConnectivityResult.none)) {
                  ToastUtils.showError(
                      'No internet connection. Please check your network and try again.');
                  return;
                }

                setState(() => isGoogleLoading = true);

                try {
                  ToastUtils.showInfo('Signing up with Google...');
                  final success = await authService.signInWithGoogle();

                  if (success && mounted) {
                    ToastUtils.showSuccess(
                        'Account created successfully! Welcome to Pasada!');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const selectionScreen()),
                    );
                  } else if (mounted) {
                    ToastUtils.showError(
                        'Google sign-up was cancelled or failed. Please try again.');
                  }
                } catch (e) {
                  debugPrint('Google sign-up error: $e');
                  if (mounted) {
                    String errorMessage =
                        ToastUtils.parseAuthError(e.toString());
                    if (errorMessage.contains('unexpected error')) {
                      errorMessage =
                          'Google sign-up failed. Please try again or use email/password.';
                    }
                    ToastUtils.showError(errorMessage);
                  }
                } finally {
                  if (mounted) setState(() => isGoogleLoading = false);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.12),
          foregroundColor: const Color(0xFFF5F5F5),
          minimumSize: const Size(360, 56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
        ),
        child: isGoogleLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Color(0xFFF5F5F5),
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/svg/googleIcon.svg',
                    height: 22,
                    width: 22,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: Color(0xFFF5F5F5),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
