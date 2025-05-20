import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/apiService.dart';

class DriverAssignmentService {
  final ApiService _apiService = ApiService();
  Timer? _pollingTimer;

  // Poll the backend for driver assignment status
  void pollForDriverAssignment(
      int bookingId, Function(Map<String, dynamic>) onDriverAssigned,
      {Function? onError, Function(String)? onStatusChange}) {
    // Cancel any existing polling before starting
    stopPolling();

    debugPrint('Starting to poll for driver assignment on booking: $bookingId');

    // Poll every 5 seconds using the bookings endpoint
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final response =
            await _apiService.get<Map<String, dynamic>>('bookings/$bookingId');

        debugPrint('Booking status update from bookings endpoint: $response');

        // Notify about status changes if callback provided
        if (response != null &&
            response['ride_status'] != null &&
            onStatusChange != null) {
          onStatusChange(response['ride_status']);
        }

        // Check if a driver has been assigned
        if (response != null &&
            response['ride_status'] == 'accepted' &&
            response['driver_id'] != null) {
          // Stop polling once we have a driver
          stopPolling();

          // Fetch driver details
          final driverDetails =
              await _fetchDriverDetails(response['driver_id']);

          if (driverDetails != null) {
            // Call the callback with driver data
            onDriverAssigned({
              'booking': response,
              'driver': driverDetails,
            });
          }
        }
      } catch (e) {
        debugPrint('Error polling for driver assignment: $e');
        if (onError != null) {
          onError();
        }
      }
    });
  }

  Future<Map<String, dynamic>?> _fetchDriverDetails(String driverId) async {
    try {
      // Use the new endpoint
      return await _apiService.get<Map<String, dynamic>>('drivers/$driverId');
    } catch (e) {
      debugPrint('Error fetching driver details: $e');
      return null;
    }
  }

  // Add a new method to fetch booking details
  Future<Map<String, dynamic>?> fetchBookingDetails(int bookingId) async {
    try {
      return await _apiService.get<Map<String, dynamic>>('bookings/$bookingId');
    } catch (e) {
      debugPrint('Error fetching booking details: $e');
      return null;
    }
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('Stopped polling for driver assignment');
  }
}
