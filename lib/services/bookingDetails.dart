import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/utils/timezone_utils.dart';

class BookingDetails {
  final int bookingId;
  final String passengerId;
  final String driverId;
  final int routeId;
  final String rideStatus;
  final String pickupAddress;
  final LatLng pickupCoordinates;
  final String dropoffAddress;
  final LatLng dropoffCoordinates;
  final TimeOfDay startTime;
  final DateTime createdAt;
  final double fare;
  final String seatType;
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
    required this.seatType,
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
      'pickup_lat': pickupCoordinates.latitude,
      'pickup_lng': pickupCoordinates.longitude,
      'dropoff_address': dropoffAddress,
      'dropoff_lat': dropoffCoordinates.latitude,
      'dropoff_lng': dropoffCoordinates.longitude,
      'start_time': '${startTime.hour}:${startTime.minute}',
      'created_at': TimezoneUtils.toPhilippinesIso8601String(createdAt),
      'fare': fare,
      'seat_type': seatType,
      'assigned_at': TimezoneUtils.toPhilippinesIso8601String(assignedAt),
      'end_time': '${endTime.hour}:${endTime.minute}',
    };
  }

  factory BookingDetails.fromMap(Map<String, dynamic> map) {
    // helper to parse numbers from any type
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    // parse coordinates safely
    LatLng parseCoordinates(String latKey, String lngKey) {
      try {
        return LatLng(
          parseDouble(map[latKey]),
          parseDouble(map[lngKey]),
        );
      } catch (e) {
        debugPrint("Error parsing coordinates: $e");
        return const LatLng(0, 0);
      }
    }

    // parse time in 'HH:mm' format
    TimeOfDay parseTime(dynamic timeVal) {
      try {
        final timeStr = timeVal.toString();
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
        return TimeOfDay(hour: hour, minute: minute);
      } catch (e) {
        debugPrint("Error parsing time: $e");
        return const TimeOfDay(hour: 0, minute: 0);
      }
    }

    return BookingDetails(
      bookingId: map['booking_id'] as int,
      passengerId: map['passenger_id'] as String,
      driverId: map['driver_id']?.toString() ?? '',
      routeId: map['route_id'] as int,
      rideStatus: map['ride_status'] as String,
      pickupAddress: map['pickup_address'] as String,
      pickupCoordinates: parseCoordinates('pickup_lat', 'pickup_lng'),
      dropoffAddress: map['dropoff_address'] as String,
      dropoffCoordinates: parseCoordinates('dropoff_lat', 'dropoff_lng'),
      startTime: parseTime(map['start_time']),
      createdAt:
          TimezoneUtils.parseToPhilippinesTime(map['created_at'] as String),
      fare: (map['fare'] as num).toDouble(),
      seatType: map['seat_type'] as String,
      assignedAt:
          TimezoneUtils.parseToPhilippinesTime(map['assigned_at'] as String),
      endTime: parseTime(map['end_time']),
    );
  }
}
