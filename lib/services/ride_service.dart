import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/services/polyline_service.dart';

/// Service to generate driver route polylines for pickups or dropoffs
class RideService {
  final PolylineService _polylineService = PolylineService();

  /// Returns a list of LatLng representing the route from [start] to [end].
  /// If [end] is null, returns an empty list.
  Future<List<LatLng>> getRoute(LatLng start, LatLng? end) async {
    if (end == null) return [];
    return _polylineService.generateBetween(start, end);
  }
}
