import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/apiService.dart';

class Driverassignmentservice {
  final ApiService _apiService = ApiService();
  Timer? _pollingTimer;

  void pollForDriverAssignment(
      int bookingId, Function(Map<String, dynamic>?) onDriverAssigned) {
    stopPolling();

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final response = await _apiService
            .get<Map<String, dynamic>>('bookings/$bookingId/driver-assignment');

        if (response != null) {
          debugPrint('Driver assignment response: $response');
          if (response['driver_id'] != null) {
            final driverDetails =
                await _fetchDriverDetails(response['driver_id']);

            if (driverDetails != null) {
              onDriverAssigned({'booking': response, 'driver': driverDetails});
              stopPolling();
            }
          }
        }
      } catch (e) {
        debugPrint('Error polling for driver assignment: $e');
      }
    });
  }

  Future<Map<String, dynamic>?> _fetchDriverDetails(int driverId) async {
    try {
      return await _apiService
          .get<Map<String, dynamic>>('driverTable/$driverId');
    } catch (e) {
      debugPrint('Error fetching driver details: $e');
      return null;
    }
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('Driver assignment polling stopped');
  }
}
