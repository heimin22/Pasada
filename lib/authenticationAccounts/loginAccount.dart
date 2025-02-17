import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/home/selectionScreen.dart';
import 'package:pasada_passenger_app/home/main.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/home/homeScreen.dart';
import 'package:pasada_passenger_app/authenticationAccounts/authService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        'home': (BuildContext context) => const HomeScreen(),
        'selection': (BuildContext context) => const selectionScreen(),
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
  // text controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // get auth service
  final AuthService _authService = AuthService();

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
    connectivitySubscription = connectivity.onConnectivityChanged.listen(updateConnectionStatus);
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
      await _authService.supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        // successful login
        Navigator.pushReplacementNamed(context, 'selection');
      }
    }
    on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    catch (err) {
      setState(() => errorMessage = 'An unexpected error occurred');
    }
    finally {
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
      body: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // buildbackButton(),
              buildHeader(),
              buildPassengerEmailNumberText(),
              buildPassengerEmailNumberInput(),
              buildPassengerPassText(),
              buildPassengerPassInput(),
              buildLogInButton(),
              // buildLoginWithGoogleButton(),
              // Container(
              //   // Viber Button
              //   margin: EdgeInsets.only(bottom: 20.0),
              //   child: Center(
              //     child: ConstrainedBox(
              //       constraints: BoxConstraints(
              //         maxWidth: 360,
              //       ),
              //       child: ElevatedButton(
              //         onPressed: () {},
              //         style: ElevatedButton.styleFrom(
              //           backgroundColor: const Color(0xFF5f3fc4),
              //           minimumSize: const Size(360, 50),
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(10.0),
              //           ),
              //         ),
              //         child: Row(
              //           mainAxisAlignment: MainAxisAlignment.center,
              //           children: [
              //             SvgPicture.asset(
              //               'assets/svg/viberIcon.svg',
              //               height: 30,
              //               width: 30,
              //             ),
              //             const SizedBox(width: 25),
              //             const Text(
              //               'Continue with Viber',
              //               style: TextStyle(
              //                 color: Color(0xFFF2F2F2),
              //                 fontSize: 20,
              //                 fontWeight: FontWeight.w600,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Container buildPassengerPassInput() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
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
              color: Color(0XFF5f3fc4),
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
    );
  }

  Container buildPassengerEmailNumberInput() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
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

  Container buildPassengerEmailNumberText() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.1),
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

  Flexible buildLogInButton() {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.only(top: 120),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : login,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5f3fc4),
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

  Column buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () {
              Navigator.pushNamed(context, 'start');
            },
            icon: Icon(Icons.arrow_back),
          ),
        ),
        Container(
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.only(top: 50),
          // margin: EdgeInsets.only(top:80.0, bottom: 30.0, right:300.0),
          height: 80,
          width: 80,
          child: SvgPicture.asset('assets/svg/Ellipse.svg'),
        ),
        Container(
          margin: const EdgeInsets.only(top: 30),
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