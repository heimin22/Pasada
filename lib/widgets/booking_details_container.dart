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

    return Container();
  }
}
