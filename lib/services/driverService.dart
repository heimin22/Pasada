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

  // Fetch driver details from the API
  Future<Map<String, dynamic>?> getDriverDetails(String driverId) async {
    try {
      final response =
          await _api.get<Map<String, dynamic>>('drivers/$driverId');

      if (response != null) {
        debugPrint('Retrieved driver details from API: $response');
        return response;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching driver details from API: $e');
      return null;
    }
  }
}
