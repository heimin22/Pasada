import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/apiService.dart';

class DriverService {
  final ApiService _api = ApiService();

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    await _api.put<Map<String, dynamic>>(
      'drivers/me/location',
      body: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  Future<void> updateAvailablity(bool isAvailable) async {
    await _api.put<Map<String, dynamic>>('drivers/update_availability', body: {
      'is_available': isAvailable,
    });
  }

  // Fetch driver details from the API by driver ID
  Future<Map<String, dynamic>?> getDriverDetails(String driverId) async {
    try {
      final response =
          await _api.get<Map<String, dynamic>>('drivers/$driverId');

      if (response != null) {
        debugPrint(
            'DriverService: Retrieved driver details from API for $driverId: $response');

        if (response.containsKey('driver')) {
          debugPrint(
              'DriverService: API response for $driverId already contains "driver" key. Returning as is.');
          return response;
        } else if (response.entries.isNotEmpty) {
          debugPrint(
              'DriverService: API response for $driverId is a flat map (keys: ${response.keys}), wrapping it with "driver" key.');
          return {'driver': response};
        } else {
          debugPrint(
              'DriverService: API response for $driverId is null, empty, or not a map with entries. Raw: $response. Returning null.');
          return null;
        }
      }
      debugPrint(
          'DriverService: API response for $driverId was null (after _api.get). Returning null.');
      return null;
    } catch (e) {
      debugPrint(
          'DriverService: Error fetching driver details for $driverId from API: $e');
      return null;
    }
  }

  // Fetch driver details by booking ID using get_driver_details_by_booking function
  Future<Map<String, dynamic>?> getDriverDetailsByBooking(int bookingId) async {
    final userId = await _getUserId();
    if (userId == null) {
      debugPrint('Cannot get driver details: user ID is null');
      return null;
    }
    try {
      final driverData = await _api.supabase
          .rpc<Map<String, dynamic>>('get_driver_details_by_booking', params: {
        'p_booking_id': bookingId,
        'p_user_id': userId,
      }).single();
      return {'driver': driverData};
    } catch (e) {
      debugPrint(
          'DriverService: Error calling get_driver_details_by_booking RPC: $e');
      return null;
    }
  }

  // Helper to get current user ID
  Future<String?> _getUserId() async {
    final user = _api.supabase.auth.currentUser;
    return user?.id;
  }

  // Helper method to process driver response
}
