import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/main.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/selectionScreen.dart';

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
        icon: Icon(Icons.arrow_back, color: Color(0xFF121212)),
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
          margin:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
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
          padding:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.0025),
          child: Text(
            'Join the Pasada app and make your ride easier',
            style: TextStyle(color: Color(0xFF121212)),
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
        style: TextStyle(color: Color(0xFF121212), fontWeight: FontWeight.w700),
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
          style: const TextStyle(
            color: Color(0xFF121212),
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
            fontSize: 14,
          ),
          decoration: InputDecoration(
            labelText: 'Enter your name',
            labelStyle: const TextStyle(
              fontSize: 12,
            ),
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

  Container buildPassengerContactNumberText() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
      child: Text(
        'Contact Number',
        style: TextStyle(
          color: Color(0xFF121212),
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
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          style: TextStyle(
              color: Color(0xFF121212),
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
                      color: Color(0xFF121212),
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
            ),
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
              child: Text(
                'By signing up, I have read and agree to Pasada’s Terms and Conditions and Privacy Policy',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff121212),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Flexible buildCreateAccountButton() {
    return Flexible(
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : () => handleSignUp(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF121212),
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
                    color: Color(0xFFF2F2F2),
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> handleSignUp() async {
    if (!isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final displayName = firstNameController.text.trim();
    final contactDigits = contactController.text.trim();
    final email = widget.email;
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final password = args['password'];
    final contactNumber = '+63$contactDigits';

    // Basic validation
    if (displayName.isEmpty || contactDigits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (contactDigits.length != 10) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Phone number must be 10 digits',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Color(0xFFF5F5F5),
          textColor: Color(0xFF121212),
        );
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      // Check if email exists
      final existingEmailData = await supabase
          .from('passenger')
          .select()
          .eq('passenger_email', email);

      if (existingEmailData.isNotEmpty) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'This email is already registered',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Color(0xFFF5F5F5),
            textColor: Color(0xFF121212),
          );
          setState(() => isLoading = false);
        }
        return;
      }

      // Check if phone number exists
      final existingPhoneData = await supabase
          .from('passenger')
          .select()
          .eq('contact_number', contactNumber);

      if (existingPhoneData.isNotEmpty) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'This phone number is already registered',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Color(0xFFF5F5F5),
            textColor: Color(0xFF121212),
          );
          setState(() => isLoading = false);
        }
        return;
      }

      final authService = AuthService();
      const defaultAvatarUrl = 'assets/svg/default_user_profile.svg';

      // Create auth user
      final authResponse = await authService.signUpAuth(
        email,
        password,
        data: {
          'display_name': displayName,
          'contact_number': contactNumber,
          'avatar_url': defaultAvatarUrl,
        },
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create account');
      }

      // Insert into passenger table
      await supabase.from('passenger').insert({
        'id': authResponse.user!.id,
        'passenger_email': email,
        'display_name': displayName,
        'contact_number': contactNumber,
        'avatar_url': defaultAvatarUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const selectionScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        late String userMessage;

        // Handle specific error cases
        if (e is PostgrestException && e.code == '23505') {
          // Only show duplicate entry message if it's actually a duplicate
          final errorMessage = e.message.toLowerCase();
          if (errorMessage.contains('email') ||
              errorMessage.contains('contact_number')) {
            userMessage = 'This account information is already in use';
          } else {
            // If it's some other database error, proceed with sign in
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const selectionScreen()),
                (route) => false,
              );
              return;
            }
          }
        } else if (e.toString().contains('invalid_email')) {
          userMessage = 'Please enter a valid email address';
        } else if (e.toString().contains('weak_password')) {
          userMessage = 'Please use a stronger password';
        }

        Fluttertoast.showToast(
          msg: userMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Color(0xFFF5F5F5),
          textColor: Color(0xFF121212),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}
