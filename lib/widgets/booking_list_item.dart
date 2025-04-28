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
    );
  }
}
