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
}
