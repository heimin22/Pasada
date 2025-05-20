import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/apiService.dart';

class DriverAssignmentService {
  final ApiService _apiService = ApiService();
  Timer? _pollingTimer;
  Timer? _timeoutTimer;

  // Poll the backend for driver assignment status
  void pollForDriverAssignment(
      int bookingId, Function(Map<String, dynamic>) onDriverAssigned,
      {Function? onError,
      Function(String)? onStatusChange,
      Function? onTimeout}) {
    // Cancel any existing polling before starting
    stopPolling();

    debugPrint('Starting to poll for driver assignment on booking: $bookingId');

    // Set a 1-minute timeout to cancel if no driver is found
    _timeoutTimer = Timer(const Duration(minutes: 1), () async {
      debugPrint('Driver assignment timeout for booking: $bookingId');
      stopPolling(); // Stop the polling

      // Cancel the booking
      try {
        await _apiService.put<Map<String, dynamic>>(
          'bookings/$bookingId',
          body: {'ride_status': 'cancelled'},
        );

        debugPrint(
            'Booking $bookingId automatically cancelled due to no driver found');

        // Notify the caller about the timeout
        if (onTimeout != null) {
          onTimeout();
        }

        // Also notify about status change if callback provided
        if (onStatusChange != null) {
          onStatusChange('cancelled');
        }
      } catch (e) {
        debugPrint('Error cancelling booking after timeout: $e');
        if (onError != null) {
          onError();
        }
      }
    });

    // Poll every 5 seconds using the bookings endpoint
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final response =
            await _apiService.get<Map<String, dynamic>>('bookings/$bookingId');

        if (response == null) {
          debugPrint('No response from API for booking $bookingId');
          if (onError != null) onError();
          return;
        }

        debugPrint('Booking status update from bookings endpoint: $response');

        // Notify about status changes if callback provided
        if (response['ride_status'] != null && onStatusChange != null) {
          onStatusChange(response['ride_status']);
        }

        // Check if a driver has been assigned
        if (response['ride_status'] == 'accepted' &&
            response['driver_id'] != null) {
          // Stop polling and cancel timeout once we have a driver
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

  // Add a method to directly fetch booking details from API
  Future<Map<String, dynamic>?> fetchBookingFromAPI(int bookingId) async {
    try {
      return await _apiService.get<Map<String, dynamic>>('bookings/$bookingId');
    } catch (e) {
      debugPrint('Error fetching booking from API: $e');
      return null;
    }
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    debugPrint('Stopped polling for driver assignment');
  }
}
