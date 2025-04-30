import 'package:flutter/material.dart';
import 'booking_status_container.dart';
import 'booking_details_container.dart';
import 'payment_details_container.dart';
import '../location/selectedLocation.dart';

class BookingStatusManager extends StatelessWidget {
  final SelectedLocation? pickupLocation;
  final SelectedLocation? dropoffLocation;
  final String ETA;
  final String paymentMethod;
  final VoidCallback onCancelBooking;

  const BookingStatusManager(
      {super.key,
      required this.pickupLocation,
      required this.dropoffLocation,
      required this.ETA,
      required this.paymentMethod,
      required this.onCancelBooking});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const BookingStatusContainer(),
          BookingDetailsContainer(
            pickupLocation: pickupLocation,
            dropoffLocation: dropoffLocation,
            ETA: ETA,
          ),
          PaymentDetailsContainer(
            paymentMethod: paymentMethod,
            onCancelBooking: onCancelBooking,
          ),
        ],
      ),
    );
  }
}
