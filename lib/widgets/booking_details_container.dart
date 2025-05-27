import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
import '../location/selectedLocation.dart';

class BookingDetailsContainer extends StatelessWidget {
  final SelectedLocation? pickupLocation;
  final SelectedLocation? dropoffLocation;

  const BookingDetailsContainer({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
  });

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
          _buildLocationRow(
            context,
            'Pick-up',
            pickupLocation?.address ?? 'Unknown location',
            Icons.location_on_outlined,
            isDarkMode,
          ),
          const SizedBox(height: 16),
          _buildLocationRow(
            context,
            'Drop-off',
            dropoffLocation?.address ?? 'Unknown location',
            Icons.location_on,
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(BuildContext context, String title, String value,
      IconData icon, bool isDarkMode) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: const Color(0xFF00CC58),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode
                      ? const Color(0xFFAAAAAA)
                      : const Color(0xFF515151),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String title, String value,
      IconData icon, bool isDarkMode) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: const Color(0xFF00CC58),
        ),
        const SizedBox(width: 12),
        Text(
          '$title: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF00CC58),
          ),
        ),
      ],
    );
  }
}
