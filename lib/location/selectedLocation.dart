import 'package:google_maps_flutter/google_maps_flutter.dart';

class SelectedLocation {
  final String address;
  final LatLng coordinates;

  SelectedLocation(this.address, this.coordinates);

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

