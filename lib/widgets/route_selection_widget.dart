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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: screenWidth * 0.03,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.route, color: Color(0xFF00CC58)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                routeName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Color(0xFFF5F5F5) : Color(0xFF1E1E1E),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode ? Color(0xFFF5F5F5) : Color(0xFF1E1E1E),
            ),
          ],
        ),
      ),
    );
  }
}
