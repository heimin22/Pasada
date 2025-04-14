import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RecentSearch {
  final String address;
  final LatLng coordinates;
  final DateTime timestamp;

  RecentSearch(this.address, this.coordinates, this.timestamp);

  Map<String, dynamic> toJson() => {
        'address': address,
        'lat': coordinates.latitude,
        'lng': coordinates.longitude,
        'timestamp': timestamp.toIso8601String(),
      };

  factory RecentSearch.fromJson(Map<String, dynamic> json) {
    return RecentSearch(
      json['address'],
      LatLng(json['lat'], json['lng']),
      DateTime.parse(json['timestamp']),
    );
  }
}
