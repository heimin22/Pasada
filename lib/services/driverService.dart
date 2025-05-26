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
    try {
      debugPrint(
          'DriverService: Fetching driver details for booking ID: $bookingId');

      final userId = await _getUserId();
      if (userId == null) {
        debugPrint('DriverService: No authenticated user found');
        return null;
      }

      // Use the database function directly via Supabase RPC
      final response =
          await _api.supabase.rpc('get_driver_details_by_booking', params: {
        'p_booking_id': bookingId,
        'p_user_id': userId,
      });

      if (response != null) {
        debugPrint('DriverService: RPC response: $response');

        if (response is List && response.isNotEmpty) {
          // The function returns a table, so we get the first row
          final driverData = response[0];
          debugPrint(
              'DriverService: Processing driver data from RPC: $driverData');

          // Convert to the expected format
          return {
            'driver': {
              'driver_id': driverData['driver_id'],
              'full_name': driverData['full_name'] ?? 'Not Available',
              'driver_number': driverData['driver_number'] ?? 'Not Available',
              'plate_number': driverData['plate_number'] ?? 'Not Available',
              'driving_status': driverData['driving_status'],
              'passenger_capacity': driverData['passenger_capacity'],
              'sitting_passenger': driverData['sitting_passenger'],
              'standing_passenger': driverData['standing_passenger'],
              'vehicle_location': driverData['vehicle_location'],
              'current_location': driverData['current_location'],
              'last_online': driverData['last_online'],
            }
          };
        } else {
          debugPrint(
              'DriverService: RPC returned empty result for booking $bookingId');
          return null;
        }
      }

      debugPrint('DriverService: RPC call failed for booking $bookingId');
      return null;
    } catch (e) {
      debugPrint('DriverService: Error in getDriverDetailsByBooking: $e');
      return null;
    }
  }

  // Helper to get current user ID
  Future<String?> _getUserId() async {
    final user = _api.supabase.auth.currentUser;
    return user?.id;
  }
}
