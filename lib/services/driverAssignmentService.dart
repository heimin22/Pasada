import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/apiService.dart';
import 'package:pasada_passenger_app/services/driverService.dart';
import 'package:pasada_passenger_app/utils/app_logger.dart';

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

    AppLogger.info('Start polling driver assignment: $bookingId',
        tag: 'DriverAssign');

    // Set a 1-minute timeout to cancel if no driver is found
    _timeoutTimer = Timer(const Duration(minutes: 1), () async {
      AppLogger.warn('Driver assignment timeout: $bookingId',
          tag: 'DriverAssign');
      stopPolling(); // Stop the polling

      // Cancel the booking
      try {
        await _apiService.put<Map<String, dynamic>>(
          'bookings/$bookingId',
          body: {'ride_status': 'cancelled'},
        );

        AppLogger.info('Auto-cancelled booking $bookingId (timeout)',
            tag: 'DriverAssign');

        // Notify the caller about the timeout
        if (onTimeout != null) {
          onTimeout();
        }

        // Also notify about status change if callback provided
        if (onStatusChange != null) {
          onStatusChange('cancelled');
        }
      } catch (e) {
        AppLogger.error('Cancel on timeout failed: $e', tag: 'DriverAssign');
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
          AppLogger.warn('No API response for booking $bookingId',
              tag: 'DriverAssign');
          if (onError != null) onError();
          return;
        }
        // Unwrap 'trip' key if present
        Map<String, dynamic> response;
        if (raw.containsKey('trip') && raw['trip'] is Map<String, dynamic>) {
          response = raw['trip'] as Map<String, dynamic>;
          if (AppLogger.verbose) {
            AppLogger.debug('Unwrapped trip: $response', tag: 'DriverAssign');
          }
        } else {
          response = raw;
          if (AppLogger.verbose) {
            AppLogger.debug('Booking status update: $response',
                tag: 'DriverAssign');
          }
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
        // Treat 404 as terminal: booking no longer exists (likely completed)
        if (e is ApiException && e.statusCode == 404) {
          AppLogger.info('Stopping polling: booking $bookingId not found (404)',
              tag: 'DriverAssign');
          stopPolling();
          if (onStatusChange != null) {
            onStatusChange('completed');
          }
          return;
        }
        AppLogger.error('Polling error: $e', tag: 'DriverAssign');
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
          AppLogger.debug('Driver details fetch method failed: $e',
              tag: 'DriverAssign');
          continue; // Try next method
        }
      }

      AppLogger.warn('All parallel driver fetch methods failed for $bookingId',
          tag: 'DriverAssign');
    } catch (e) {
      AppLogger.error('Parallel driver details fetch error: $e',
          tag: 'DriverAssign');
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
    AppLogger.info('Stopped polling', tag: 'DriverAssign');
  }
}
