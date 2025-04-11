import 'package:flutter/material.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  Widget build(BuildContext context) {
    return const ActivityScreenStateful();
  }
}

class ActivityScreenStateful extends StatefulWidget {
  const ActivityScreenStateful({super.key});

  @override
  State<ActivityScreenStateful> createState() => ActivityScreenPageState();
}

class ActivityScreenPageState extends State<ActivityScreenStateful> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            activityTitle(),
          ],
        ),
      ),
    );
  }

  Positioned activityTitle() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Positioned(
      top: screenHeight * 0.03,
      left: screenWidth * 0.05,
      right: screenWidth * 0.18,
      child: Text(
        'Activity',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF121212),
        ),
      ),
    );
  }
}
