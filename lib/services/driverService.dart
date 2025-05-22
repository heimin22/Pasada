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
        debugPrint('Retrieved driver details from API: $response');

        // Ensure we're returning the driver data in the expected format
        if (response.containsKey('driver')) {
          // If the API response already includes a 'driver' object, return as is
          return response;
        } else {
          // If the API returns just the driver data directly, wrap it
          return {'driver': response};
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching driver details from API: $e');
      return null;
    }
  }

  // Fetch driver details by booking ID using get_driver_details_by_booking function
  Future<Map<String, dynamic>?> getDriverDetailsByBooking(int bookingId) async {
    try {
      debugPrint('Fetching driver details for booking ID: $bookingId');

      // The database function you shared is get_driver_details_by_booking
      // Let's try endpoints that might map to this function

      // Try direct call to a dedicated endpoint for driver details by booking
      try {
        final response =
            await _api.get<Map<String, dynamic>>('bookings/$bookingId/driver');

        if (response != null) {
          debugPrint('Response from bookings/$bookingId/driver: SUCCESS');
          return _processDriverResponse(response);
        }
      } catch (e) {
        debugPrint('Error calling bookings/$bookingId/driver: $e');
      }

      // Try a general booking endpoint that might include driver details
      try {
        final response =
            await _api.get<Map<String, dynamic>>('bookings/$bookingId');

        if (response != null) {
          debugPrint('Response from bookings/$bookingId: SUCCESS');

          // Check if we can find driver details in the response
          if (response.containsKey('driver')) {
            return _processDriverResponse({'driver': response['driver']});
          }

          // Try using driver_id to fetch driver details
          if (response.containsKey('driver_id') &&
              response['driver_id'] != null) {
            final driverId = response['driver_id'];
            debugPrint('Found driver_id in booking: $driverId');

            // Fetch driver details with driver ID
            final driverResponse = await getDriverDetails(driverId.toString());
            if (driverResponse != null) {
              return driverResponse;
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching booking details: $e');
      }

      // Try a direct RPC call (may not work depending on your backend setup)
      try {
        final response = await _api.post<Map<String, dynamic>>(
            'rpc/get_driver_details_by_booking',
            body: {'p_booking_id': bookingId, 'p_user_id': await _getUserId()});

        if (response != null) {
          debugPrint('Response from RPC call: SUCCESS');
          return _processDriverResponse({'driver': response});
        }
      } catch (e) {
        debugPrint('Error calling RPC directly: $e');
      }

      debugPrint('All attempts to fetch driver details failed');
      return null;
    } catch (e) {
      debugPrint('Error in getDriverDetailsByBooking: $e');
      return null;
    }
  }

  // Helper to get current user ID
  Future<String?> _getUserId() async {
    final user = _api.supabase.auth.currentUser;
    return user?.id;
  }

  // Helper method to process driver response
  Map<String, dynamic> _processDriverResponse(Map<String, dynamic> response) {
    debugPrint('Processing driver response: $response');

    // Try to find the driver data in the response
    dynamic driverData;

    // Check common response structures
    if (response.containsKey('driver')) {
      driverData = response['driver'];
    } else if (response.containsKey('data')) {
      driverData = response['data'];
    } else {
      // Look for specific fields that would indicate this is the driver data itself
      List<String> driverFields = [
        'full_name',
        'driver_number',
        'plate_number',
        'driver_id'
      ];
      bool looksLikeDriverData =
          driverFields.any((field) => response.containsKey(field));

      if (looksLikeDriverData) {
        driverData = response;
      }
    }

    // Handle case where driver data is null
    if (driverData == null) {
      debugPrint('Could not locate driver data in response');
      // If we couldn't find driver data, just wrap the whole response
      return {'driver': response};
    }

    // Handle case where driver data is an array (from RPC)
    if (driverData is List) {
      debugPrint('Driver data is a List with ${driverData.length} items');

      if (driverData.isEmpty) {
        debugPrint('Driver data list is empty');
        return {'driver': []};
      }

      // Return the first item from the list directly - this is key for RPC functions
      return {'driver': driverData};
    }

    // Return the processed driver data
    return {'driver': driverData};
  }
}
