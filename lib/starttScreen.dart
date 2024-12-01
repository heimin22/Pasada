import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/createAccount.dart';
import 'package:pasada_passenger_app/loginAccount.dart';

void main() => runApp(const PasadaPassenger());

class PasadaPassenger extends StatelessWidget {
  const PasadaPassenger({super.key});

  // This widget is the root of your application.
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
      home: const PasadaHomePage(title: 'Pasada'),
      routes: <String, WidgetBuilder>{
        'start': (BuildContext context) => const PasadaPassenger(),
        'createAccount': (BuildContext context) => const CreateAccountPage(),
        'loginAccount': (BuildContext context) => const LoginAccountPage(),
      },
    );
  }
}

class PasadaHomePage extends StatefulWidget {
  const PasadaHomePage({super.key, required this.title});

  final String title;

  @override
  State<PasadaHomePage> createState() => PasadaHomePageState();
}

class PasadaHomePageState extends State<PasadaHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 130.0),
              height: 130,
              width: 130,
              child: SvgPicture.asset('assets/svg/Ellipse.svg'),
            ),
            Container(
              margin: const EdgeInsets.only(top: 70.0),
              child: const Text(
                'Hi there!',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(bottom: 30.0),
              child: Text(
                'Welcome to Pasada',
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 180.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, 'createAccount');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4AB00C),
                  minimumSize: const Size(380, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text(
                  'Create an account',
                  style: TextStyle(
                    color: Color(0xFFF2F2F2),
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, 'loginAccount');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF2F2F2),
                  minimumSize: const Size(380, 50),
                  side: const BorderSide(
                    color: Color(0xFF4AB00C),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text(
                  'Log-in',
                  style: TextStyle(
                    color: Color(0xFF121212),
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
