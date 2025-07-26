import 'package:flutter/material.dart';

class DriverLoadingContainer extends StatefulWidget {
  const DriverLoadingContainer({super.key});

  @override
  State<DriverLoadingContainer> createState() => _DriverLoadingContainerState();
}

class _DriverLoadingContainerState extends State<DriverLoadingContainer> {
  final List<String> _loadingMessages = [
    'Saglit lang boss...',
    'Parating na si driver...',
    'Kaunting kembot na lang...',
    '\'Wag mo na pong i-cancel please hehehe...',
  ];
  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _startMessageRotation();
  }

  void _startMessageRotation() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessages.length;
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
      child: Column(
        children: [
          Row(
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
                  _loadingMessages[_currentMessageIndex],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? const Color(0xFFF5F5F5)
                        : const Color(0xFF121212),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
