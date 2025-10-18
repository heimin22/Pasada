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

    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // Calculate responsive values
    final isSmallScreen = screenHeight < 600 || screenWidth < 400;
    final horizontalPadding =
        isSmallScreen ? screenWidth * 0.05 : screenHeight * 0.035;
    final topPadding =
        isSmallScreen ? screenHeight * 0.005 : screenHeight * 0.01;
    final bottomPadding =
        isSmallScreen ? screenHeight * 0.02 : screenHeight * 0.035;

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
                      top: topPadding,
                      left: horizontalPadding,
                      right: horizontalPadding,
                      bottom: bottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildHeader(isSmallScreen),
                        buildPassengerEmailNumberText(isSmallScreen),
                        buildPassengerEmailNumberInput(isSmallScreen),
                        buildPassengerPassText(isSmallScreen),
                        buildPassengerPassInput(isSmallScreen),
                        buildConfirmPassText(isSmallScreen),
                        buildConfirmPassInput(isSmallScreen),
                        buildCreateAccountButton(isSmallScreen),
                        buildOrDesign(isSmallScreen),
                        buildSignUpGoogle(isSmallScreen),
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

  Column buildHeader(bool isSmallScreen) {
    final logoHeight = isSmallScreen ? 50.0 : 60.0;
    final titleFontSize = isSmallScreen ? 28.0 : 32.0;
    final subtitleFontSize = isSmallScreen ? 14.0 : 16.0;
    final logoMargin = isSmallScreen ? 0.03 : 0.04;
    final titleMargin = isSmallScreen ? 0.04 : 0.05;
    final subtitleMargin = isSmallScreen ? 0.008 : 0.01;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// Logo
        Container(
          alignment: Alignment.center,
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * logoMargin,
          ),
          child: Image.asset(
            'assets/png/pasada_white_brand.png',
            height: logoHeight,
            fit: BoxFit.contain,
          ),
        ),

        /// Create your account text
        Container(
          margin: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * titleMargin),
          child: Text(
            'Create Account',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFF5F5F5),
              fontWeight: FontWeight.w800,
              fontSize: titleFontSize,
              letterSpacing: -0.5,
            ),
          ),
        ),

        /// Join the Pasada... text
        Container(
          margin: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * subtitleMargin),
          child: Text(
            'Yun o? Sign up ka na para makapagbook ka naman.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFE0E0E0),
              fontWeight: FontWeight.w400,
              fontSize: subtitleFontSize,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Container buildPassengerEmailNumberText(bool isSmallScreen) {
    final margin = isSmallScreen ? 0.04 : 0.05;
    final fontSize = isSmallScreen ? 14.0 : 15.0;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * margin),
      child: Row(
        children: [
          Text(
            'Email Address',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              fontSize: fontSize,
              color: const Color(0xFFF5F5F5),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Container buildPassengerEmailNumberInput(bool isSmallScreen) {
    final margin = isSmallScreen ? 0.01 : 0.012;
    final height = isSmallScreen ? 50.0 : 56.0;
    final fontSize = isSmallScreen ? 14.0 : 15.0;
    final iconSize = isSmallScreen ? 20.0 : 22.0;
    final horizontalPadding = isSmallScreen ? 16.0 : 20.0;
    final verticalPadding = isSmallScreen ? 14.0 : 18.0;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * margin),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: TextField(
          style: TextStyle(
            color: const Color(0xFFF5F5F5),
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            fontSize: fontSize,
          ),
          controller: emailController,
          cursorColor: const Color(0xFF00CC58),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: TextStyle(
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
              fontSize: fontSize,
              color: const Color(0xFF999999),
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: const Color(0xFFCCCCCC),
              size: iconSize,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.12),
            contentPadding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: verticalPadding),
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

  Container buildPassengerPassText(bool isSmallScreen) {
    final margin = isSmallScreen ? 0.02 : 0.025;
    final fontSize = isSmallScreen ? 14.0 : 15.0;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * margin),
      child: Row(
        children: [
          Text(
            'Password',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              fontSize: fontSize,
              color: const Color(0xFFF5F5F5),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Container buildPassengerPassInput(bool isSmallScreen) {
    final margin = isSmallScreen ? 0.01 : 0.012;
    final height = isSmallScreen ? 50.0 : 56.0;
    final fontSize = isSmallScreen ? 14.0 : 15.0;
    final iconSize = isSmallScreen ? 20.0 : 22.0;
    final horizontalPadding = isSmallScreen ? 16.0 : 20.0;
    final verticalPadding = isSmallScreen ? 14.0 : 18.0;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * margin),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: TextField(
          style: TextStyle(
            color: const Color(0xFFF5F5F5),
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            fontSize: fontSize,
          ),
          controller: passwordController,
          cursorColor: const Color(0xFF00CC58),
          obscureText: !isPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: TextStyle(
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
              fontSize: fontSize,
              color: const Color(0xFF999999),
            ),
            prefixIcon: Icon(
              Icons.lock_outlined,
              color: const Color(0xFFCCCCCC),
              size: iconSize,
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
                size: iconSize,
              ),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.12),
            contentPadding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: verticalPadding),
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

  Container buildConfirmPassText(bool isSmallScreen) {
    final margin = isSmallScreen ? 0.02 : 0.025;
    final fontSize = isSmallScreen ? 14.0 : 15.0;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * margin),
      child: Row(
        children: [
          Text(
            'Confirm Password',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              fontSize: fontSize,
              color: const Color(0xFFF5F5F5),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Container buildConfirmPassInput(bool isSmallScreen) {
    final margin = isSmallScreen ? 0.01 : 0.012;
    final height = isSmallScreen ? 50.0 : 56.0;
    final fontSize = isSmallScreen ? 14.0 : 15.0;
    final iconSize = isSmallScreen ? 20.0 : 22.0;
    final horizontalPadding = isSmallScreen ? 16.0 : 20.0;
    final verticalPadding = isSmallScreen ? 14.0 : 18.0;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * margin),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: TextField(
          style: TextStyle(
            color: const Color(0xFFF5F5F5),
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            fontSize: fontSize,
          ),
          controller: confirmPasswordController,
          cursorColor: const Color(0xFF00CC58),
          obscureText: !isPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Confirm your password',
            hintStyle: TextStyle(
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
              fontSize: fontSize,
              color: const Color(0xFF999999),
            ),
            prefixIcon: Icon(
              Icons.lock_outlined,
              color: const Color(0xFFCCCCCC),
              size: iconSize,
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
                size: iconSize,
              ),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.12),
            contentPadding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: verticalPadding),
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

  Container buildCreateAccountButton(bool isSmallScreen) {
    final margin = isSmallScreen ? 0.03 : 0.04;
    final buttonHeight = isSmallScreen ? 50.0 : 56.0;
    final fontSize = isSmallScreen ? 15.0 : 17.0;
    final minWidth = isSmallScreen ? 320.0 : 360.0;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * margin),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : SigningUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00CC58),
          foregroundColor: Colors.white,
          minimumSize: Size(minWidth, buttonHeight),
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: isSmallScreen ? 20 : 22,
                height: isSmallScreen ? 20 : 22,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: fontSize,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Container buildOrDesign(bool isSmallScreen) {
    final margin = isSmallScreen ? 0.025 : 0.03;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * margin),
      width: double.infinity,
      child: SvgPicture.asset('assets/svg/otherOptionsOptimized.svg'),
    );
  }

  Container buildSignUpGoogle(bool isSmallScreen) {
    final margin = isSmallScreen ? 0.012 : 0.015;
    final buttonHeight = isSmallScreen ? 50.0 : 56.0;
    final fontSize = isSmallScreen ? 14.0 : 16.0;
    final minWidth = isSmallScreen ? 320.0 : 360.0;
    final iconSize = isSmallScreen ? 20.0 : 22.0;
    final spacing = isSmallScreen ? 10.0 : 12.0;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * margin),
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
          minimumSize: Size(minWidth, buttonHeight),
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
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: const CircularProgressIndicator(
                  color: Color(0xFFF5F5F5),
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/svg/googleIcon.svg',
                    height: iconSize,
                    width: iconSize,
                  ),
                  SizedBox(width: spacing),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: const Color(0xFFF5F5F5),
                      fontSize: fontSize,
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
