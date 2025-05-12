import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/apiService.dart';

class DriverAssignmentService {
  final ApiService _apiService = ApiService();
  Timer? _pollingTimer;
  int _failedAttempts = 0;
  static const int _maxFailedAttempts = 3;

  // Poll the backend for driver assignment status
  void pollForDriverAssignment(
      int bookingId, Function(Map<String, dynamic>) onDriverAssigned,
      {Function? onError}) {
    // Cancel any existing polling
    stopPolling();

    debugPrint('Starting to poll for driver assignment on booking: $bookingId');

    // Poll every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final response = await _apiService
            .get<Map<String, dynamic>>('trips/$bookingId/status');

        // Reset failed attempts on success
        _failedAttempts = 0;

        if (response != null) {
          debugPrint('Booking status update: $response');

          // Check if a driver has been assigned
          if (response['status'] == 'accepted' &&
              response['driver_id'] != null) {
            // Fetch driver details
            final driverDetails =
                await _fetchDriverDetails(response['driver_id']);

            if (driverDetails != null) {
              // Stop polling once we have a driver
              stopPolling();

              // Call the callback with driver data
              onDriverAssigned({
                'booking': response,
                'driver': driverDetails,
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error polling for driver assignment: $e');
        _failedAttempts++;

        // If we've failed too many times, stop polling and notify
        if (_failedAttempts >= _maxFailedAttempts) {
          stopPolling();
          if (onError != null) {
            onError();
          }
        }
      }
    });
  }

  Future<Map<String, dynamic>?> _fetchDriverDetails(String driverId) async {
    try {
      return await _apiService
          .get<Map<String, dynamic>>('trips/drivers/$driverId');
    } catch (e) {
      debugPrint('Error fetching driver details: $e');
      return null;
    }
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _failedAttempts = 0;
    debugPrint('Stopped polling for driver assignment');
  }
}
