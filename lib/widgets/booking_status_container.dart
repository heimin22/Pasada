import 'package:flutter/material.dart';

class BookingStatusContainer extends StatefulWidget {
  const BookingStatusContainer({super.key});

  @override
  State<BookingStatusContainer> createState() => BookingStatusContainerState();
}

class BookingStatusContainerState extends State<BookingStatusContainer> {
  final List<String> _statusMessages = [
    'Naghahanap na po ng driver...',
    'Wait lang, boss...',
    'Mabilisan lang \'to promise...',
    '\'Wag mo munang cancel hehe...',
  ];
  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _startMessageRotation();
  }

  void _startMessageRotation() {
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _statusMessages.length;
        });
        _startMessageRotation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
