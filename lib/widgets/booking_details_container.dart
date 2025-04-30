import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../location/selectedLocation.dart';

class BookingDetailsContainer extends StatelessWidget {
  final SelectedLocation? pickupLocation;
  final SelectedLocation? dropoffLocation;
  final String ETA;

  const BookingDetailsContainer({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.ETA,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final formattedTime = DateFormat('h:mm a').format(now);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Text(
            'Booking Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
