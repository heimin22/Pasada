import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SelectedLocation {
  final String address;
  final LatLng coordinates;

  SelectedLocation(this.address, this.coordinates);

  double distanceFrom(LatLng other) {
    const double earthRadius = 6371.0; // Earth's radius in kilometers

    final double lat1 = coordinates.latitude * math.pi / 180;
    final double lat2 = other.latitude * math.pi / 180;
    final double dLat = (other.latitude - coordinates.latitude) * math.pi / 180;
    final double dLon =
        (other.longitude - coordinates.longitude) * math.pi / 180;

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'lat': coordinates.latitude,
        'lng': coordinates.longitude,
      };

  factory SelectedLocation.fromJson(Map<String, dynamic> json) {
    return SelectedLocation(
      json['address'],
      LatLng(json['lat'], json['lng']),
    );
  }
}
