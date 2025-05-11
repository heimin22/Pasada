import 'package:pasada_passenger_app/services/apiService.dart';

class TripService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> requestTrip({
    required double originLatitude,
    required double originLongitude,
    required String originAddress,
    required double destinationLatitude,
    required double destinationLongitude,
    required String destinationAddress,
    required String routeTrip,
    required double fare,
    required String paymentMethod,
  }) async {
    return await _api.post<Map<String, dynamic>>(
          'trips/request',
          body: {
            'origin_latitude': originLatitude,
            'origin_longitude': originLongitude,
            'origin_address': originAddress,
            'destination_latitude': destinationLatitude,
            'destination_longitude': destinationLongitude,
            'destination_address': destinationAddress,
            'route_trip': routeTrip,
            'fare': fare,
            'payment_method': paymentMethod,
          },
        ) ??
        {};
  }

  Future<Map<String, dynamic>> getCurrentTrip() async {
    return await _api.get<Map<String, dynamic>>('trips/current') ?? {};
  }

  Future<void> acceptTrip(String tripId) async {
    await _api.post<Map<String, dynamic>>('trips/$tripId/accept');
  }

  Future<void> cancelTrip(String tripId, String reason) async {
    await _api.post<Map<String, dynamic>>(
      'trips/$tripId/cancel',
      body: {'reason': reason},
    );
  }
}
