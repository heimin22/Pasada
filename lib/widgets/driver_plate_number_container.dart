import 'package:flutter/material.dart';

class DriverPlateNumberContainer extends StatelessWidget {
  final String plateNumber;

  const DriverPlateNumberContainer({super.key, required this.plateNumber});

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
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 0),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.directions_car,
            size: 24,
            color: const Color(0xFF00CC58),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plate Number',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode
                      ? const Color(0xFFAAAAAA)
                      : const Color(0xFF515151),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plateNumber,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
