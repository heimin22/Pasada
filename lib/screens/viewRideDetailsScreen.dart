import 'package:flutter/material.dart';

class ViewRideDetailsScreen extends StatelessWidget {
  const ViewRideDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Receipt'),
      ),
      body: const Center(
        child: Text('Ride details go here'),
      ),
    );
  }
}
