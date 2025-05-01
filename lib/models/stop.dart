import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Stop {
  final int id;
  final int routeId;
  final String name;
  final String address;
  final LatLng coordinates;
  final int stopOrder;
  final bool isActive;

  Stop({
    required this.id,
    required this.routeId,
    required this.name,
    required this.address,
    required this.coordinates,
    required this.stopOrder,
    required this.isActive,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('Parsing stop data: $json');

      // Check if required fields exist
      if (json['allowedstop_id'] == null) {
        debugPrint('Missing allowedstop_id in data');
      }
      if (json['officialroute_id'] == null) {
        debugPrint('Missing officialroute_id in data');
      }
      if (json['stop_name'] == null) {
        debugPrint('Missing stop_name in data');
      }
      if (json['stop_address'] == null) {
        debugPrint('Missing stop_address in data');
      }
      if (json['stop_lat'] == null) {
        debugPrint('Missing stop_lat in data');
      }
      if (json['stop_lng'] == null) {
        debugPrint('Missing stop_lng in data');
      }

      return Stop(
        id: json['allowedstop_id'],
        routeId: json['officialroute_id'],
        name: json['stop_name'] ?? 'Unknown Stop',
        address: json['stop_address'] ?? 'No address',
        coordinates: LatLng(
          double.parse(json['stop_lat'] ?? '0'),
          double.parse(json['stop_lng'] ?? '0'),
        ),
        stopOrder: json['stop_order'] ?? 0,
        isActive: json['is_active'] ?? true,
      );
    } catch (e) {
      debugPrint('Error in Stop.fromJson: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'allowedstop_id': id, // Updated to match your schema
      'officialroute_id': routeId,
      'stop_name': name,
      'stop_address': address,
      'stop_lat': coordinates.latitude.toString(),
      'stop_lng': coordinates.longitude.toString(),
      'stop_order': stopOrder,
      'is_active': isActive,
    };
  }
}
