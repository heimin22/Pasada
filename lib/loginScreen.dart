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
            const Text(
              'Hi there!',
              style: TextStyle(
                fontSize: 40,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
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

            ),
            ElevatedButton(
              onPressed: (){},
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4ab00c),
                minimumSize: Size(260, 50),
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
          ]
        ),
      ),
    );
  }
}
