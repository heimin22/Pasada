import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/services/polyline_service.dart';

/// Service to fetch route polyline for rides (driver to pickup/dropoff)
class RideService {
  static Future<List<LatLng>> getDriverRoute(
    LatLng start,
    LatLng end,
  ) async {
    final service = PolylineService();
    return await service.generateBetween(start, end);
  }
}
