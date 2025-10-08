import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/authentication/otpVerificationScreen.dart';
import 'package:pasada_passenger_app/screens/privacyPolicyScreen.dart';
import 'package:pasada_passenger_app/services/phoneValidationService.dart';
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
                      top: MediaQuery.of(context).size.height * 0.06,
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// Logo
        Container(
          alignment: Alignment.center,
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.02,
          ),
          child: Image.asset(
            'assets/png/pasada_app_icon_text_white.png',
            height: 60,
            fit: BoxFit.contain,
          ),
        ),

        /// Create your account text
        Container(
          margin:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.04),
          child: const Text(
            'Almost There!',
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
            'Kaunti na lang, bossing. Hehehe.',
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

  Container buildPassengerDisplayNameText() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.04),
      child: const Text(
        'Full Name',
        style: TextStyle(
          color: Color(0xFFF5F5F5),
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Container buildPassengerDisplayNameInput() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.012),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: TextField(
          controller: firstNameController,
          cursorColor: Color(0xFF00CC58),
          style: const TextStyle(
            color: Color(0xFFF5F5F5),
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            hintStyle: const TextStyle(
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              color: Color(0xFF999999),
            ),
            prefixIcon: const Icon(
              Icons.person_outline,
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

  Container buildPassengerContactNumberText() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.025),
      child: const Text(
        'Contact Number',
        style: TextStyle(
          color: Color(0xFFF5F5F5),
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
          fontSize: 15,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Container buildPassengerContactNumberInput() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.012),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: TextField(
          controller: contactController,
          cursorColor: Color(0xFF00CC58),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          style: const TextStyle(
            color: Color(0xFFF5F5F5),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/svg/phFlag.svg',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '+63',
                    style: TextStyle(
                      color: Color(0xFFF5F5F5),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                      fontSize: 15,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 1,
                    height: 24,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
            hintText: '9123456789',
            hintStyle: const TextStyle(
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              color: Color(0xFF999999),
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

  Container buildTermsCheckbox() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 1.15,
            child: Checkbox(
              value: isChecked,
              checkColor: Colors.white,
              activeColor: Color(0xFF00CC58),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (newBool) {
                setState(() {
                  isChecked = newBool ?? false;
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFE0E0E0),
                    fontFamily: 'Inter',
                  ),
                  children: [
                    const TextSpan(
                      text: "I agree to Pasada's ",
                    ),
                    const TextSpan(
                      text: 'Terms and Conditions',
                      style: TextStyle(
                        color: Color(0xFF00CC58),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF00CC58),
                      ),
                    ),
                    const TextSpan(
                      text: ' and ',
                    ),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        color: Color(0xFF00CC58),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF00CC58),
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
                'Create Account',
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

  Future<void> handleSignUp() async {
    // Check terms and conditions acceptance
    if (!isChecked) {
      ToastUtils.showWarning(
          'Please accept the terms and conditions to continue.');
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
      ToastUtils.showError(
          'Phone number must be exactly 10 digits (without country code).');
      return;
    }

    if (!_isValidPhoneNumber(contactDigits)) {
      ToastUtils.showError(
          'Please enter a valid Philippine mobile number (starting with 9).');
      return;
    }

    // Check network connectivity
    final connectivity = Connectivity();
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      ToastUtils.showError(
          'No internet connection. Please check your network and try again.');
      return;
    }

    setState(() => isLoading = true);

    try {
      // Check if phone number is already registered before sending OTP
      final isPhoneAvailable =
          await PhoneValidationService.isPhoneNumberAvailable(contactNumber);

      if (!isPhoneAvailable) {
        if (mounted) {
          ToastUtils.showError(
              'This phone number is already registered. Please use a different number or try logging in.');
        }
        return;
      }

      // Navigate to OTP verification only after phone number validation
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
        ToastUtils.showError(
            'Failed to proceed with account creation. Please try again.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool _isValidPhoneNumber(String phoneDigits) {
    // Philippine mobile numbers start with 9 and are 10 digits long
    return phoneDigits.startsWith('9') &&
        phoneDigits.length == 10 &&
        RegExp(r'^\d{10}$').hasMatch(phoneDigits);
  }
}
