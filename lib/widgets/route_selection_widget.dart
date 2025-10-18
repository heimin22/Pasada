import 'package:flutter/material.dart';

class RouteSelectionWidget extends StatelessWidget {
  final String routeName;
  final VoidCallback onTap;

  const RouteSelectionWidget({
    super.key,
    required this.routeName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 6 : 8),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 20,
          vertical: isSmallScreen ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius:
                  isSmallScreen ? screenWidth * 0.02 : screenWidth * 0.03,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.route,
              color: Color(0xFF00CC58),
              size: isSmallScreen ? 18 : 20,
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
            Expanded(
              child: Text(
                routeName,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Color(0xFFF5F5F5) : Color(0xFF1E1E1E),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: isSmallScreen ? 14 : 16,
              color: isDarkMode ? Color(0xFFF5F5F5) : Color(0xFF1E1E1E),
            ),
          ],
        ),
      ),
    );
  }
}
