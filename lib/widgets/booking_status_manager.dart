import 'package:flutter/material.dart';
import 'booking_details_container.dart';
import 'payment_details_container.dart';
import 'driver_details_container.dart';
import 'driver_loading_container.dart';
import '../location/selectedLocation.dart';
import 'dart:async';

class BookingStatusManager extends StatefulWidget {
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
  State<BookingStatusManager> createState() => _BookingStatusManagerState();
}

class _BookingStatusManagerState extends State<BookingStatusManager> {
  bool _showLoading = false;
  Timer? _debounceTimer;
  final Duration _debounceDuration = const Duration(seconds: 1);

  @override
  void didUpdateWidget(covariant BookingStatusManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldShowLoading = widget.bookingStatus == 'requested' ||
        (widget.isDriverAssigned &&
            (widget.driverName.isEmpty ||
                widget.driverName == 'Driver' ||
                widget.driverName == 'Not Available'));
    if (shouldShowLoading && !_showLoading) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(_debounceDuration, () {
        if (mounted) setState(() => _showLoading = true);
      });
    } else if (!shouldShowLoading) {
      _debounceTimer?.cancel();
      if (_showLoading) setState(() => _showLoading = false);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Log the current status and driver details for debugging
    debugPrint(
        'BookingStatusManager - Status: ${widget.bookingStatus}, Driver assigned: ${widget.isDriverAssigned}');
    if (widget.bookingStatus == 'accepted' || widget.isDriverAssigned) {
      debugPrint(
          'Driver details - Name: ${widget.driverName}, Plate: ${widget.plateNumber}, Phone: ${widget.phoneNumber}');
    }

    return Scrollbar(
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (widget.bookingStatus == 'accepted')
              DriverDetailsContainer(
                driverName: widget.driverName,
                plateNumber: widget.plateNumber,
                phoneNumber: widget.phoneNumber,
              )
            else if (_showLoading)
              const DriverLoadingContainer()
            else if (widget.bookingStatus == 'cancelled')
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
              pickupLocation: widget.pickupLocation,
              dropoffLocation: widget.dropoffLocation,
              etaText: widget.ETA,
            ),
            PaymentDetailsContainer(
              paymentMethod: widget.paymentMethod,
              onCancelBooking: widget.onCancelBooking,
              fare: widget.fare,
              showCancelButton: widget.bookingStatus == 'requested',
            )
          ],
        ),
      ),
    );
  }
}
