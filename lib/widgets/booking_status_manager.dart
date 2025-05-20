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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scrollbar(
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (bookingStatus == 'accepted')
              DriverDetailsContainer(
                driverName: driverName,
                plateNumber: plateNumber,
                phoneNumber: phoneNumber,
              )
            else if (bookingStatus == 'requested')
              const DriverLoadingContainer()
            else if (bookingStatus == 'cancelled')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFF5F5F5),
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
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Your booking has been cancelled',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFF121212),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            BookingDetailsContainer(
              pickupLocation: pickupLocation,
              dropoffLocation: dropoffLocation,
              etaText: ETA,
            ),
            PaymentDetailsContainer(
              paymentMethod: paymentMethod,
              onCancelBooking: onCancelBooking,
              fare: fare,
              showCancelButton: bookingStatus == 'requested',
            )
          ],
        ),
      ),
    );
  }
}
