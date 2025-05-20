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
            'ride_status': 'accepted',
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
      rideStatus: 'accepted', // initial status for new bookings
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

    try {
      await _localDbService.saveBookingDetails(bookingDetails);
      debugPrint('Successfully saved booking $bookingId to local database');
    } catch (e) {
      debugPrint('Error saving booking to local database: $e');
    }
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

  Future<bool> assignDriver(int bookingId,
      {required double fare, required String paymentMethod}) async {
    try {
      final apiService = ApiService();

      // First try to get booking from local database
      var booking = await getLocalBookingDetails(bookingId);

      // If not found locally, try to fetch from API
      if (booking == null) {
        debugPrint('Booking $bookingId not found locally, trying API...');
        final apiBooking = await getBookingDetails(bookingId);

        if (apiBooking == null) {
          debugPrint('Booking $bookingId not found in API either');
          return false;
        }

        // Create a BookingDetails object from API data
        booking = BookingDetails(
          bookingId: bookingId,
          passengerId: apiBooking['passenger_id'] ?? '',
          driverId: apiBooking['driver_id'] ?? 0,
          routeId: apiBooking['route_id'] ?? 0,
          rideStatus: apiBooking['ride_status'] ?? 'accepted',
          pickupAddress: apiBooking['pickup_address'] ?? '',
          pickupCoordinates: LatLng(
            apiBooking['pickup_lat'] ?? 0.0,
            apiBooking['pickup_lng'] ?? 0.0,
          ),
          dropoffAddress: apiBooking['dropoff_address'] ?? '',
          dropoffCoordinates: LatLng(
            apiBooking['dropoff_lat'] ?? 0.0,
            apiBooking['dropoff_lng'] ?? 0.0,
          ),
          startTime: TimeOfDay.now(),
          createdAt: DateTime.now(),
          fare: apiBooking['fare'] ?? 0.0,
          assignedAt: DateTime.now(),
          endTime: TimeOfDay.now(),
        );

        // Save to local database for future reference
        await _localDbService.saveBookingDetails(booking);
      }

      // Now we have the booking data, proceed with API call
      debugPrint('Attempting to assign driver for booking $bookingId');
      final response = await apiService.post<Map<String, dynamic>>(
        'bookings/assign-driver',
        body: {
          'booking_id': bookingId,
          'route_trip': booking.routeId,
          'origin_latitude': booking.pickupCoordinates.latitude,
          'origin_longitude': booking.pickupCoordinates.longitude,
          'destination_latitude': booking.dropoffCoordinates.latitude,
          'destination_longitude': booking.dropoffCoordinates.longitude,
          'pickup_address': booking.pickupAddress,
          'dropoff_address': booking.dropoffAddress,
          'fare': fare,
          'payment_method': paymentMethod,
        },
      );

      debugPrint('Driver assignment initiated: $response');
      return true;
    } catch (e) {
      debugPrint('Error requesting driver assignment: $e');
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

  bool isOnlinePaymentAllowed(double fare) {
    // Minimum payment for online methods is ₱20.00 (2000 centavos)
    return fare >= 20.0;
  }

  // Fetch booking details from the API
  Future<Map<String, dynamic>?> getBookingDetails(int bookingId) async {
    try {
      final apiService = ApiService();
      final response =
          await apiService.get<Map<String, dynamic>>('bookings/$bookingId');

      if (response != null) {
        debugPrint('Retrieved booking details from API: $response');
        return response;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching booking details from API: $e');
      return null;
    }
  }
}
