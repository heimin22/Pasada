import 'package:flutter/material.dart';

class DriverDetailsContainer extends StatelessWidget {
  final String driverName;
  final String plateNumber;
  final String phoneNumber;

  const DriverDetailsContainer({
    super.key,
    required this.driverName,
    required this.plateNumber,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Debug output to see what values are being passed to this widget
    debugPrint(
        'DriverDetailsContainer - driverName: "$driverName", plateNumber: "$plateNumber", phoneNumber: "$phoneNumber"');

    // Check if we have meaningful driver data
    final bool hasDriverData = driverName != 'Driver' && driverName.isNotEmpty;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Driver Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                  color: isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212),
                ),
              ),
              // Show debug indicator if driver data is missing
              if (!hasDriverData)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Missing Data',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    hasDriverData ? const Color(0xFF00CC58) : Colors.grey,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        color: isDarkMode
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF121212),
                      ),
                    ),
                    if (plateNumber.isNotEmpty && plateNumber != 'Unknown')
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Vehicle: $plateNumber',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                            color: isDarkMode
                                ? const Color(0xFFBBBBBB)
                                : const Color(0xFF515151),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
