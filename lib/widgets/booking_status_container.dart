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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00CC58)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _statusMessages[_currentMessageIndex],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                color: isDarkMode
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFF121212),
              ),
            ),
          )
        ],
      ),
    );
  }
}
