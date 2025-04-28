import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingListItem extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingListItem({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final createdAt = DateTime.parse(booking['created_at']);
    final formattedDate = DateFormat('MMM d, yyyy').format(createdAt);
    final formattedTime = DateFormat('h:mm a').format(createdAt);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00CC58),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.directions_car_outlined,
              color: const Color(0xFF00CC58),
              size: 24,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${booking['pickup_address']} to ${booking['dropoff_address']}',
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
                SizedBox(height: 4),
                Text(
                  '$formattedDate, $formattedTime',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? const Color(0xFFAAAAAA)
                        : const Color(0xFF515151),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 15),
          Text(
            '₱${booking['fare'].toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
          ),
        ],
      ),
    );
  }
}
