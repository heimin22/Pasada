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
  final String startTime;
  final DateTime createdAt;
  final double fare;
  final DateTime assignedAt;
  final String endTime;

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
      'start_time': startTime,
      'created_at': createdAt.toIso8601String(),
      'fare': fare,
      'assigned_at': assignedAt.toIso8601String(),
      'end_time': endTime,
    };
  }

}