import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/screens/forgotPasswordScreen.dart';
import 'package:pasada_passenger_app/screens/selectionScreen.dart';
import 'package:pasada_passenger_app/main.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

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

  @override
  void initState() {
    super.initState();
    checkInitialConnectivity();
    connectivitySubscription =
        connectivity.onConnectivityChanged.listen(updateConnectionStatus);
  }

  Future<void> checkInitialConnectivity() async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      showNoInternetToast();
    }
  }

  void updateConnectionStatus(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.none)) showNoInternetToast();
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
    if (connectivityResult.contains(ConnectivityResult.none)) {
      showNoInternetToast();
    }

    try {
      await authService.supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (mounted) {
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
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.03,
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
        icon: Icon(Icons.arrow_back, color: Color(0xFFF5F5F5)),
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

  Container buildPassengerEmailNumberInput() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: TextField(
          controller: emailController,
          style: const TextStyle(
            color: Color(0xFFF5F5F5),
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
            fontSize: 14,
          ),
          cursorColor: Color(0xFF00CC58),
          decoration: InputDecoration(
            labelText: 'Enter your email',
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              fontFamily: 'Inter',
              color: Color(0xFFAAAAAA),
            ),
            errorText: errorMessage.isNotEmpty ? errorMessage : null,
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

  Container buildPassengerEmailNumberText() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.05),
      child: const Row(
        children: [
          Text(
            'Email',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              color: Color(0xFFF5F5F5),
            ),
          ),
        ],
      ),
    );
  }

  Container buildLogInButton() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : login,
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
                'Log-in',
                style: TextStyle(
                  color: Color(0xFF00CC58),
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
      ),
    );
  }

  Widget buildOrDesign() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
      width: double.infinity,
      child: SvgPicture.asset('assets/svg/otherOptionsOptimized.svg'),
    );
  }

  Widget buildLoginGoogle() {
    return Container(
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
                    Navigator.push(
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
                color: Color(0xFFF5F5F5),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ChangeForgottenPassword()),
            );
          },
          child: Text(
            "Forgot Password?",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF5F5F5),
            ),
          ),
        ));
  }

  Column buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.centerLeft,
          margin:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
          child: SvgPicture.asset('assets/svg/pasadaLogoWithoutText.svg'),
        ),
        Container(
          margin:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
          child: const Text(
            'Log-in to your account',
            style: TextStyle(
              color: Color(0xFFF5F5F5),
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
        ),
      ],
    );
  }

  // Add the time-based gradient method
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
}
