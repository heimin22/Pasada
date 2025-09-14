import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/apiService.dart';
import 'package:pasada_passenger_app/services/driverService.dart';

class DriverAssignmentService {
  final ApiService _apiService = ApiService();
  final DriverService _driverService = DriverService();
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

    // Poll every 2 seconds for faster driver assignment detection
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        // Fetch booking details and unwrap if wrapped under 'trip'
        final raw =
            await _apiService.get<Map<String, dynamic>>('bookings/$bookingId');
        if (raw == null) {
          debugPrint('No response from API (raw) for booking $bookingId');
          if (onError != null) onError();
          return;
        }
        // Unwrap 'trip' key if present
        Map<String, dynamic> response;
        if (raw.containsKey('trip') && raw['trip'] is Map<String, dynamic>) {
          response = raw['trip'] as Map<String, dynamic>;
          debugPrint(
              'Unwrapped booking response from raw[\'trip\']: $response');
        } else {
          response = raw;
          debugPrint('Booking status update from bookings endpoint: $response');
        }

        // Notify about status changes if callback provided
        if (response['ride_status'] != null && onStatusChange != null) {
          onStatusChange(response['ride_status'] as String);
        }

        // When booking status is accepted, fetch driver details using parallel approach
        if (response['ride_status'] == 'accepted') {
          // Polling continues to allow updates (do not stopPolling here)

          // Use parallel fetching for faster driver details retrieval
          _fetchDriverDetailsParallel(bookingId, response, onDriverAssigned);
        }
      } catch (e) {
        debugPrint('Error polling for driver assignment: $e');
        if (onError != null) {
          onError();
        }
      }
    });
  }

  /// Faster parallel driver details fetching
  Future<void> _fetchDriverDetailsParallel(
      int bookingId,
      Map<String, dynamic> bookingResponse,
      Function(Map<String, dynamic>) onDriverAssigned) async {
    try {
      // Try multiple methods in parallel for fastest response
      final futures = <Future>[];

      // Method 1: RPC call (usually fastest)
      final rpcFuture = _driverService.getDriverDetailsByBooking(bookingId);
      futures.add(rpcFuture);

      // Method 2: Direct driver query if we have driver_id
      if (bookingResponse.containsKey('driver_id') &&
          bookingResponse['driver_id'] != null) {
        final directFuture = _driverService
            .getDriverDetails(bookingResponse['driver_id'].toString());
        futures.add(directFuture);
      }

      // Wait for first successful response
      for (final future in futures) {
        try {
          final result = await future;
          if (result != null) {
            // Call the callback with driver data immediately
            onDriverAssigned({'booking': bookingResponse, 'driver': result});
            return; // Exit after first successful result
          }
        } catch (e) {
          debugPrint('Driver details fetch method failed: $e');
          continue; // Try next method
        }
      }

      debugPrint(
          'All parallel driver fetch methods failed for booking $bookingId');
    } catch (e) {
      debugPrint('Error in parallel driver details fetch: $e');
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
