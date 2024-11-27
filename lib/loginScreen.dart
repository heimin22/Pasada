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
            Text(
              'Hi there!',
              style: TextStyle(
                fontSize: 40,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
              child: Text(
                'Welcome to Pasada',
                style: TextStyle(
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
