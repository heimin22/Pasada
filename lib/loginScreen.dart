import 'package:flutter/material.dart';

void main() => runApp(const PassengerPassengerApp());

class PassengerPassengerApp extends StatelessWidget {
  const PassengerPassengerApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.only(top: 250.0),
              child: Text(
                'Hi there!',
                style: TextStyle(
                  fontSize: 40,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(bottom: 30.0),
              child: Text(
                'Welcome to Pasada',
                style: TextStyle(
                  fontFamily: 'Inter',
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 240.0),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4AB00C),
                  minimumSize: Size(260, 60),
                ),
                child: const Text(
                  'Create an account',
                  style: TextStyle(
                    color: Color(0xFFF2F2F2),
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 20.0),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF2F2F2),
                  minimumSize: Size(260, 60),
                  side: BorderSide(
                    color: Color(0xFF4AB00C),
                    width: 2,
                  ),
                ),
                child: const Text(
                    'Log-in',
                  style: TextStyle(
                    color: Color(0xFF121212),
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    fontFamily: 'Inter',
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
