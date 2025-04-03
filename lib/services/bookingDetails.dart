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


}