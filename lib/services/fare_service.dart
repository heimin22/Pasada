import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/utils/map_utils.dart';

/// Service to calculate fare based on distance in kilometers
class FareService {
  static const double baseFare = 15.0;
  static const double ratePerKm = 2.2;

  /// Calculates fare for the given distance (in km)
  static double calculateFare(double distanceInKm) {
    if (distanceInKm <= 4.0) {
      return baseFare;
    }
    return baseFare + (distanceInKm - 4.0) * ratePerKm;
  }

  /// Calculates fare between two coordinates by computing distance (in km) via map_utils
  static double calculateFareBetween(LatLng start, LatLng end) {
    final distance = calculateDistanceKm(start, end);
    return calculateFare(distance);
  }

  /// Calculates fare for a full polyline by summing segment distances
  static double calculateFareForPolyline(List<LatLng> polyline) {
    double totalDistance = 0.0;
    for (int i = 0; i < polyline.length - 1; i++) {
      totalDistance += calculateDistanceKm(polyline[i], polyline[i + 1]);
    }
    return calculateFare(totalDistance);
  }
}
