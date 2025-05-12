import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'localDatabaseService.dart';
import 'bookingDetails.dart';
import 'package:location/location.dart';
import 'apiService.dart';

class BookingService {
  final LocalDatabaseService _localDbService = LocalDatabaseService();
  final supabase = Supabase.instance.client;
  StreamSubscription<LocationData>? _locationSubscription;

  void startLocationTracking(String passengerID) {
    stopLocationTracking();

    final location = Location();

    location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 10000,
    );

    _locationSubscription = location.onLocationChanged.listen((locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        _updatePassengerLocation(
          passengerID,
          locationData.latitude!,
          locationData.longitude!,
        );
      }
    });

    debugPrint('Location tracking started for passenger $passengerID');
  }

  void stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    debugPrint('Location tracking stopped');
  }

  Future<void> _updatePassengerLocation(
    String passengerID,
    double latitude,
    double longitude,
  ) async {
    try {
      await supabase.rpc('update_passenger_location', params: {
        'passenger_id': passengerID,
        'latitude': latitude,
        'longitude': longitude,
      });

      debugPrint('Passenger location updated: $latitude, $longitude');
    } catch (e) {
      debugPrint('Error updating passenger location: $e');
    }
  }

  // Create a new booking and save it locally
  Future<int?> createBooking({
    required String passengerId,
    required int routeId,
    required String pickupAddress,
    required LatLng pickupCoordinates,
    required String dropoffAddress,
    required LatLng dropoffCoordinates,
    required String paymentMethod,
    required String seatingPreference,
    required double fare,
  }) async {
    try {
      // First, create the booking in Supabase
      final response = await supabase
          .from('bookings')
          .insert({
            'passenger_id': passengerId,
            'route_id': routeId,
            'ride_status': 'requested',
            'pickup_address': pickupAddress,
            'pickup_lat': pickupCoordinates.latitude,
            'pickup_lng': pickupCoordinates.longitude,
            'dropoff_address': dropoffAddress,
            'dropoff_lat': dropoffCoordinates.latitude,
            'dropoff_lng': dropoffCoordinates.longitude,
            'payment_method': paymentMethod,
            'seat_type': seatingPreference,
            'fare': fare,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('booking_id')
          .single();

      final bookingId = response['booking_id'] as int;

      // Then save the booking locally
      await _saveBookingLocally(
        bookingId: bookingId,
        passengerId: passengerId,
        routeId: routeId,
        pickupAddress: pickupAddress,
        pickupCoordinates: pickupCoordinates,
        dropoffAddress: dropoffAddress,
        dropoffCoordinates: dropoffCoordinates,
        fare: fare,
      );

      debugPrint('Booking created with ID: $bookingId');
      return bookingId;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      return null;
    }
  }

  // Save booking to local SQLite database
  Future<void> _saveBookingLocally({
    required int bookingId,
    required String passengerId,
    required int routeId,
    required String pickupAddress,
    required LatLng pickupCoordinates,
    required String dropoffAddress,
    required LatLng dropoffCoordinates,
    required double fare,
  }) async {
    final now = DateTime.now();

    final bookingDetails = BookingDetails(
      bookingId: bookingId,
      passengerId: passengerId,
      driverId: 0, // Will be updated when a driver is assigned
      routeId: routeId,
      rideStatus: 'requested',
      pickupAddress: pickupAddress,
      pickupCoordinates: pickupCoordinates,
      dropoffAddress: dropoffAddress,
      dropoffCoordinates: dropoffCoordinates,
      startTime: TimeOfDay.now(),
      createdAt: now,
      fare: fare,
      assignedAt: now,
      endTime: TimeOfDay.now(),
    );

    await _localDbService.saveBookingDetails(bookingDetails);
  }

  // Update booking status both in Supabase and locally
  Future<void> updateBookingStatus(int bookingId, String newStatus) async {
    try {
      // Update in Supabase
      await supabase.from('bookings').update({
        'ride_status': newStatus,
      }).eq('booking_id', bookingId);

      // Update locally
      await _localDbService.updateLocalBookingStatus(bookingId, newStatus);

      debugPrint('Booking $bookingId status updated to $newStatus');
    } catch (e) {
      debugPrint('Error updating booking status: $e');
    }
  }

  Future<bool> assignDriver(int bookingId) async {
    try {
      final apiService = ApiService();

      // Call the external backend API to find a driver
      final response = await apiService.post<Map<String, dynamic>>(
        'bookings/assign-driver',
        body: {'booking_id': bookingId},
      );

      debugPrint('Driver assignment initiated: $response');
      return true;
    } catch (e) {
      debugPrint('Error requesting driver assignment: $e');
      // Return false instead of throwing to handle the error gracefully
      return false;
    }
  }

  // Get booking details from local database
  Future<BookingDetails?> getLocalBookingDetails(int bookingId) async {
    return await _localDbService.getBookingDetails(bookingId);
  }

  // Delete booking from local database
  Future<void> deleteLocalBooking(int bookingId) async {
    await _localDbService.deleteBookingDetails(bookingId);
  }
}
