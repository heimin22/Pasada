import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pasada_passenger_app/homeScreen.dart';
import 'package:pasada_passenger_app/starttScreen.dart';

void main() => runApp(const CreateAccountCredPage());

class CreateAccountCredPage extends StatelessWidget {
  const CreateAccountCredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pasada',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const CredPage(title: 'Create Account'),
      routes: <String, WidgetBuilder>{
        'start': (BuildContext context) => const PasadaPassenger(),
        'home': (BuildContext context) => const HomeScreen(),
      },
    );
  }
}

class CredPage extends StatefulWidget {
  const CredPage({super.key, required this.title});

  final String title;

  @override
  State<CredPage> createState() => _CredPageState();
}

class _CredPageState extends State<CredPage> {
  @override
  Widget build(BuildContext context) {
    bool? isChecked = false;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,

            //CONTENTS
            children: [
              //HEADER
              Container(
                alignment: Alignment.centerLeft,
                // margin: const EdgeInsets.only(top: 60),
                width: 80,
                height: 80,
                child: SvgPicture.asset('assets/svg/Ellipse.svg'),
              ),
              Container(
                margin: const EdgeInsets.only(top: 30),
                child: const Text(
                  'Create your account',
                  style: TextStyle(
                    fontSize: 25,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 15),
                child: const Text(
                  'Join the Pasada app and make your ride easier',
                  style: TextStyle(color: Color(0xFF121212)),
                ),
              ),

              //DRIVER ID PART
              Container(
                margin: const EdgeInsets.only(top: 35),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Text(
                          'First Name',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    //INPUT
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: TextField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7.0),
                            ),
                            labelText: 'Enter your first name here',
                            labelStyle: const TextStyle(
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            contentPadding:
                            const EdgeInsets.fromLTRB(15, 0, 115, 0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              //PASSWORD PART
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Text(
                          'Last Name',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    //INPUT
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7.0),
                            ),
                            labelText: 'Enter your last name here',
                            labelStyle: const TextStyle(
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            contentPadding:
                            const EdgeInsets.fromLTRB(15, 0, 115, 0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.only(top: 20),
                alignment: Alignment.centerLeft,
                child: Checkbox(
                  value: isChecked,
                  activeColor: Color(0xFF5F3FC4),
                  onChanged: (newBool) {
                    setState(() {
                      isChecked = newBool!;
                    });
                  },
                ),
              ),

              //LOG IN BUTTON
              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(top: 120),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F3FC4),
                      minimumSize: const Size(240, 45),
                      shadowColor: Colors.black,
                    ),
                    child: const Text(
                      'Log in',
                      style: TextStyle(
                        color: Color(0xFFF2F2F2),
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        fontFamily: 'Inter',
                      ),
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
}

