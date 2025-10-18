import 'package:flutter/material.dart';

class RushHourDialogContent extends StatelessWidget {
  const RushHourDialogContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    // Calculate responsive values
    final iconSize = screenSize.width * 0.2; // 20% of screen width
    final titleFontSize = screenSize.width * 0.06; // 6% of screen width
    final descriptionFontSize = screenSize.width * 0.04; // 4% of screen width
    final padding = screenSize.width * 0.06; // 6% of screen width
    final spacing = screenSize.height * 0.02; // 2% of screen height

    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: iconSize,
            color: const Color(0xFF00CC58),
          ),
          SizedBox(height: spacing),
          Text(
            'Heavy Traffic Alert',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
          ),
          SizedBox(height: spacing * 0.8),
          Text(
            'Heavy traffic on your route, please expect delays!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: descriptionFontSize,
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
