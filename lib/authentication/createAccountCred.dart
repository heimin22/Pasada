import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/services/authService.dart';

import '../screens/selectionScreen.dart';

class CreateAccountCredPage extends StatefulWidget {
  final String email;
  final String title;

  const CreateAccountCredPage({super.key, required this.title, required this.email});

  @override
  State<CreateAccountCredPage> createState() => _CreateAccountCredPageState();
}

class _CreateAccountCredPageState extends State<CreateAccountCredPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final contactController = TextEditingController();
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    // final screenHeight = MediaQuery.of(context).size.height;
    // final screenWidth = MediaQuery.of(context).size.width;
    try {
      debugPrint('Building CredPage with email: ${widget.email}');
      return Scaffold(
        resizeToAvoidBottomInset: false,
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
                      buildPassengerFirstNameText(),
                      buildPassengerFirstNameInput(),
                      buildPassengerLastNameText(),
                      buildPassengerLastNameInput(),
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
    } catch (e) {
      debugPrint('Error building CreateAccountCredPage: $e');
      return Scaffold(body: Center(child: Text('Error: $e')));
    }
  }

  Container buildBackButton() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
      child: IconButton(
        onPressed: () {
          // navigate back to the previous screen
          Navigator.pop(context);
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

  Container buildPassengerFirstNameText() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
      child: Text(
        'First Name',
        style: TextStyle(color: Color(0xFF121212), fontWeight: FontWeight.w700),
      ),
    );
  }

  Container buildPassengerFirstNameInput() {
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
            labelText: 'Enter your first name',
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

  Container buildPassengerLastNameText() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
      child: Text(
        'Last Name',
        style: TextStyle(color: Color(0xFF121212), fontWeight: FontWeight.w700),
      ),
    );
  }

  Container buildPassengerLastNameInput() {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.02),
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: TextField(
          controller: lastNameController,
          style: const TextStyle(
            color: Color(0xFF121212),
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
            fontSize: 14,
          ),
          decoration: InputDecoration(
            labelText: 'Enter your last name',
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
              fontFamily: 'Inter'
          ),
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
              padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.02),
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
          // onPressed: isLoading ? null : SigningUp,
          onPressed: () async{
            if (!isChecked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please accept the terms and conditions.'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            // validate required fields
            final firstName = firstNameController.text.trim();
            final lastName = lastNameController.text.trim();
            final contactDigits = contactController.text.trim();
            final email = widget.email;
            // retrieve natin ung password na pinasa duon sa previous page
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            final password = args['password'];

            if (firstName.isEmpty || lastName.isEmpty || contactDigits.isEmpty) {
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
            }

            try {
              final authService = AuthService();
              final contactNumber = '+63$contactDigits';

              final authResponse = await authService.signUpAuth(
                email,
                password,
                data: {
                  'first_name': firstName,
                  'last_name': lastName,
                  'contact_number': contactNumber,
                },
              );
              if (authResponse.user != null) {
                debugPrint('User signed up: ${authResponse.user!.email}');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const selectionScreen())
                );
              }
            } catch (e) {
              if (mounted) {
                Fluttertoast.showToast(
                  msg: 'Error saving details: $e',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Color(0xFFF5F5F5),
                  textColor: Color(0xFF121212),
                );
                debugPrint('Error saving details: $e');
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF121212),
            minimumSize: const Size(360, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: const Text(
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
}

