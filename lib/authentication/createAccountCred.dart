import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/gestures.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pasada_passenger_app/screens/privacyPolicyScreen.dart';
import 'package:pasada_passenger_app/authentication/otpVerificationScreen.dart';
import 'package:pasada_passenger_app/utils/toast_utils.dart';

class CreateAccountCredPage extends StatefulWidget {
  final String email;
  final String title;

  const CreateAccountCredPage(
      {super.key, required this.title, required this.email});

  @override
  State<CreateAccountCredPage> createState() => _CreateAccountCredPageState();
}

class _CreateAccountCredPageState extends State<CreateAccountCredPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final contactController = TextEditingController();
  bool isChecked = false;
  bool isLoading = false;

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
                      top: MediaQuery.of(context).size.height * 0.10,
                      left: MediaQuery.of(context).size.height * 0.035,
                      right: MediaQuery.of(context).size.height * 0.035,
                      bottom: MediaQuery.of(context).size.height * 0.035,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        buildHeader(),
                        buildPassengerDisplayNameText(),
                        buildPassengerDisplayNameInput(),
                        buildPassengerContactNumberText(),
                        buildPassengerContactNumberInput(),
                        buildTermsCheckbox(),
                        buildCreateAccountButton(),
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
          // navigate back to the previous screen
          Navigator.pop(context);
        },
        icon: Icon(Icons.arrow_back, color: Color(0xFFF5F5F5)),
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
          child: SvgPicture.asset(
            'assets/svg/pasadaLogoWithoutText.svg',
          ),
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

  Container buildPassengerDisplayNameText() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
      child: Text(
        'Name',
        style: TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.w700),
      ),
    );
  }

  Container buildPassengerDisplayNameInput() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.02),
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: TextField(
          controller: firstNameController,
          cursorColor: Color(0xFF00CC58),
          style: const TextStyle(
            color: Color(0xFFF5F5F5),
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
            fontSize: 14,
          ),
          decoration: InputDecoration(
            labelText: 'Enter your name',
            labelStyle: const TextStyle(
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

  Container buildPassengerContactNumberText() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
      child: Text(
        'Contact Number',
        style: TextStyle(
          color: Color(0xFFF5F5F5),
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Container buildPassengerContactNumberInput() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.02),
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: TextField(
          controller: contactController,
          cursorColor: Color(0xFF00CC58),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          style: TextStyle(
              color: Color(0xFFF5F5F5),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter'),
          decoration: InputDecoration(
            prefix: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/svg/phFlag.svg',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '+63 |',
                    style: TextStyle(
                      color: Color(0xFFF5F5F5),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            labelText: 'Enter your contact number (e.g., 9123456789)',
            labelStyle: const TextStyle(
              fontSize: 12,
              fontFamily: 'Inter',
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

  Container buildTermsCheckbox() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(top: 10, left: 0),
            child: Checkbox(
              value: isChecked,
              checkColor: Color(0xFFF5F5F5),
              activeColor: Color(0xFF00CC58),
              onChanged: (newBool) {
                setState(() {
                  isChecked = newBool ?? false;
                });
              },
            ),
          ),
          Expanded(
            // Ensures text wraps and doesn't push Checkbox
            child: Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.02),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFF5F5F5),
                  ),
                  children: [
                    const TextSpan(
                      text:
                          "By signing up, I have read and agree to Pasada's Terms and Conditions and ",
                    ),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        color: Color(0xFFF5F5F5),
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container buildCreateAccountButton() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : () => handleSignUp(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF5F5F5),
          minimumSize: const Size(360, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Sign-up',
                style: TextStyle(
                  color: Color(0xFF00CC58),
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
      ),
    );
  }

  Future<void> handleSignUp() async {
    // Check terms and conditions acceptance
    if (!isChecked) {
      ToastUtils.showWarning('Please accept the terms and conditions to continue.');
      return;
    }

    final displayName = firstNameController.text.trim();
    final contactDigits = contactController.text.trim();
    final email = widget.email;
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final password = args['password'];
    final contactNumber = '+63$contactDigits';

    // Input validation
    if (displayName.isEmpty || contactDigits.isEmpty) {
      ToastUtils.showWarning('Please fill in all required fields.');
      return;
    }

    if (displayName.length < 2) {
      ToastUtils.showError('Name must be at least 2 characters long.');
      return;
    }

    if (contactDigits.length != 10) {
      ToastUtils.showError('Phone number must be exactly 10 digits (without country code).');
      return;
    }

    if (!_isValidPhoneNumber(contactDigits)) {
      ToastUtils.showError('Please enter a valid Philippine mobile number (starting with 9).');
      return;
    }

    // Check network connectivity
    final connectivity = Connectivity();
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      ToastUtils.showError('No internet connection. Please check your network and try again.');
      return;
    }

    setState(() => isLoading = true);

    try {
      // Navigate to OTP verification instead of creating account directly
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              phoneNumber: contactNumber,
              email: email,
              password: password,
              displayName: displayName,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error during sign-up process: $e');
      if (mounted) {
        ToastUtils.showError('Failed to proceed with account creation. Please try again.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool _isValidPhoneNumber(String phoneDigits) {
    // Philippine mobile numbers start with 9 and are 10 digits long
    return phoneDigits.startsWith('9') && phoneDigits.length == 10 && 
           RegExp(r'^\d{10}$').hasMatch(phoneDigits);
  }
}
