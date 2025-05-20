import 'package:flutter/material.dart';
import 'booking_details_container.dart';
import 'payment_details_container.dart';
import 'driver_details_container.dart';
import 'driver_loading_container.dart';
import '../location/selectedLocation.dart';

class BookingStatusManager extends StatelessWidget {
  final SelectedLocation? pickupLocation;
  final SelectedLocation? dropoffLocation;
  final String ETA;
  final String paymentMethod;
  final double fare;
  final VoidCallback onCancelBooking;
  final String driverName;
  final String plateNumber;
  final String vehicleModel;
  final String phoneNumber;
  final bool isDriverAssigned;
  final String bookingStatus;

  const BookingStatusManager({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.ETA,
    required this.paymentMethod,
    required this.fare,
    required this.onCancelBooking,
    required this.driverName,
    required this.plateNumber,
    required this.vehicleModel,
    required this.phoneNumber,
    required this.isDriverAssigned,
    this.bookingStatus = 'requested',
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (isDriverAssigned)
              DriverDetailsContainer(
                driverName: driverName,
                plateNumber: plateNumber,
                phoneNumber: phoneNumber,
              )
            else if (bookingStatus == 'requested')
              const DriverLoadingContainer(),
            BookingDetailsContainer(
              pickupLocation: pickupLocation,
              dropoffLocation: dropoffLocation,
              etaText: ETA,
            ),
            PaymentDetailsContainer(
              paymentMethod: paymentMethod,
              onCancelBooking: onCancelBooking,
              fare: fare,
            ),
          ],
        ),
      ),
    );
  }
}
