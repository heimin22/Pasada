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
      } catch (e) {
        debugPrint('Error polling for driver assignment: $e');
      }
    });
  }

  void stopPolling() {}
}
