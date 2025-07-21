import 'package:flutter/material.dart';

class WeatherAlertDialogContent extends StatelessWidget {
  const WeatherAlertDialogContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.water_drop,
            size: 80,
            color: const Color(0xFF00CC58),
          ),
          const SizedBox(height: 24),
          Text(
            'Heavy Rain Alert',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Malakas ang ulan ha, mahirap magcommute ngayon.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
          ),
          // Action button moved to sequence dialog
        ],
      ),
    );
  }
}
