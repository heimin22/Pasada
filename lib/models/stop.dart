import 'package:google_maps_flutter/google_maps_flutter.dart';

class Stop {
  final int id;
  final int officialrouteId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final int order;
  final bool isActive;
  final DateTime createdAt;
  final double? distance;

  Stop({
    required this.id,
    required this.officialrouteId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.order,
    required this.isActive,
    required this.createdAt,
    this.distance,
  });

  LatLng get coordinates => LatLng(lat, lng);

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'],
      officialrouteId: json['officialroute_id'],
      name: json['stop_name'],
      address: json['stop_address'],
      lat: double.parse(json['stop_lat']),
      lng: double.parse(json['stop_lng']),
      order: json['stop_order'],
      isActive: json['is_active'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      distance: json['distance']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'officialroute_id': officialrouteId,
      'stop_name': name,
      'stop_address': address,
      'stop_lat': lat.toString(),
      'stop_lng': lng.toString(),
      'stop_order': order,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      if (distance != null) 'distance': distance,
    };
  }
}
