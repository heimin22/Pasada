import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';

class BookingDetails {
  final int bookingId;
  final String passengerId;
  final int driverId;
  final int routeId;
  final String rideStatus;
  final String pickupAddress;
  final LatLng pickupCoordinates;
  final String dropoffAddress;
  final LatLng dropoffCoordinates;
  final TimeOfDay startTime;
  final DateTime createdAt;
  final double fare;
  final DateTime assignedAt;
  final TimeOfDay endTime;

  BookingDetails({
    required this.bookingId,
    required this.passengerId,
    required this.driverId,
    required this.routeId,
    required this.rideStatus,
    required this.pickupAddress,
    required this.pickupCoordinates,
    required this.dropoffAddress,
    required this.dropoffCoordinates,
    required this.startTime,
    required this.createdAt,
    required this.fare,
    required this.assignedAt,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'booking_id': bookingId,
      'passenger_id': passengerId,
      'driver_id': driverId,
      'route_id': routeId,
      'ride_status': rideStatus,
      'pickup_address': pickupAddress,
      'pickup_lat': pickupCoordinates.latitude.toString(),
      'pickup_lng': pickupCoordinates.longitude.toString(),
      'dropoff_address': dropoffAddress,
      'dropoff_lat': dropoffCoordinates.latitude.toString(),
      'dropoff_lng': dropoffCoordinates.longitude.toString(),
      'start_time': '${startTime.hour}:${startTime.minute}',
      'created_at': createdAt.toIso8601String(),
      'fare': fare,
      'assigned_at': assignedAt.toIso8601String(),
      'end_time': '${startTime.hour}:${startTime.minute}',
    };
  }

  factory BookingDetails.fromMap(Map<String, dynamic> map) {
    // coordinate parsing para sa error handling
    LatLng parseCoordinates(String latKey, String lngKey) {
      try {
        return LatLng(
          double.parse(map[latKey] as String),
          double.parse(map[lngKey] as String),
        );
      } catch (e) {
        debugPrint("Error parsing coordinates: $e");
        return const LatLng(0, 0);
      }
    }

    return BookingDetails(
      bookingId: map['booking_id'] as int,
      passengerId: map['passenger_id'] as String,
      driverId: map['driver_id'] as int,
      routeId: map['route_id'] as int,
      rideStatus: map['ride_status'] as String,
      pickupAddress: map['pickup_address'] as String,
      pickupCoordinates: parseCoordinates('pickup_lat', 'pickup_lng'),
      dropoffAddress: map['dropoff_address'] as String,
      dropoffCoordinates: parseCoordinates('dropoff_lat', 'dropoff_lng'),
      startTime: TimeOfDay.fromDateTime(DateTime.parse(map['start_time'])),
      createdAt: DateTime.parse(map['created_at'] as String),
      fare: (map['fare'] as num).toDouble(),
      assignedAt: DateTime.parse(map['assigned_at'] as String),
      endTime: TimeOfDay.fromDateTime(DateTime.parse(map['end_time'])),
    );
  }
}