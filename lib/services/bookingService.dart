import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'localDatabaseService.dart';
import 'bookingDetails.dart';
import 'package:location/location.dart';
import 'apiService.dart';
import 'driverAssignmentService.dart';

// Object to return from createBooking with additional error information
class BookingResult {
  final BookingDetails? booking;
  final String? errorMessage;
  final int? statusCode;

  BookingResult({this.booking, this.errorMessage, this.statusCode});

  bool get success => booking != null;
  bool get isNoDriversError => statusCode == 404;
}

class BookingService {
  final LocalDatabaseService _localDbService = LocalDatabaseService();
  final DriverAssignmentService _driverAssignmentService =
      DriverAssignmentService();
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

  // Create a new booking by calling the backend API and save it locally
  Future<BookingResult> createBooking({
    required String
        passengerId, // Used for local save, backend derives from auth
    required int routeId,
    required String pickupAddress,
    required LatLng pickupCoordinates,
    required String dropoffAddress,
    required LatLng dropoffCoordinates,
    required String paymentMethod,
    required String
        seatingPreference, // Note: Not used by backend 'requestTrip' or BookingDetails model
    required double fare,
    Function(BookingDetails)? onDriverAssigned,
    Function(String)? onStatusChange,
    Function? onTimeout,
  }) async {
    try {
      final apiService = ApiService();

      // Call the backend endpoint that maps to requestTrip
      // This endpoint will create the booking and attempt to assign a driver.
      final response = await apiService.post<Map<String, dynamic>>(
        'bookings/assign-driver', // Assuming this is the endpoint for requestTrip
        body: {
          // Parameters expected by requestTrip backend function
          'route_trip': routeId,
          'origin_latitude': pickupCoordinates.latitude,
          'origin_longitude': pickupCoordinates.longitude,
          'pickup_address': pickupAddress,
          'destination_latitude': dropoffCoordinates.latitude,
          'destination_longitude': dropoffCoordinates.longitude,
          'dropoff_address': dropoffAddress,
          'fare': fare,
          'payment_method': paymentMethod,
        },
      );

      if (response != null && response.containsKey('booking')) {
        final bookingData = response['booking'] as Map<String, dynamic>;

        // Extract data from backend response
        final bookingId = bookingData['booking_id'] as int;
        final backendPassengerId = bookingData['passenger_id'] as String? ??
            passengerId; // Prefer backend's if available
        final driverId = bookingData['driver_id'] as int?;
        final rideStatus = bookingData['ride_status'] as String;
        final backendRouteId = bookingData['route_id'] as int;
        final backendPickupAddress = bookingData['pickup_address'] as String;
        final backendPickupLat = (bookingData['pickup_lat'] as num).toDouble();
        final backendPickupLng = (bookingData['pickup_lng'] as num).toDouble();
        final backendDropoffAddress = bookingData['dropoff_address'] as String;
        final backendDropoffLat =
            (bookingData['dropoff_lat'] as num).toDouble();
        final backendDropoffLng =
            (bookingData['dropoff_lng'] as num).toDouble();
        final backendFare = (bookingData['fare'] as num).toDouble();
        final createdAtString = bookingData['created_at'] as String;
        final assignedAtString = bookingData['assigned_at'] as String?;

        final createdAtDateTime = DateTime.parse(createdAtString);
        final assignedAtDateTime = assignedAtString != null
            ? DateTime.parse(assignedAtString)
            : createdAtDateTime; // Default to createdAt if not assigned

        // Construct BookingDetails for local storage
        final bookingDetails = BookingDetails(
          bookingId: bookingId,
          passengerId: backendPassengerId,
          driverId: driverId ?? 0,
          routeId: backendRouteId,
          rideStatus: rideStatus,
          pickupAddress: backendPickupAddress,
          pickupCoordinates: LatLng(backendPickupLat, backendPickupLng),
          dropoffAddress: backendDropoffAddress,
          dropoffCoordinates: LatLng(backendDropoffLat, backendDropoffLng),
          startTime: TimeOfDay.fromDateTime(
              createdAtDateTime), // Using createdAt for startTime
          createdAt: createdAtDateTime,
          fare: backendFare,
          assignedAt: assignedAtDateTime,
          endTime: TimeOfDay.fromDateTime(
              createdAtDateTime), // Placeholder, can be updated later
        );

        await _localDbService.saveBookingDetails(bookingDetails);
        debugPrint(
            'Booking created via backend, ID: $bookingId, Status: $rideStatus. Saved locally.');

        // Start polling for driver assignment with 1-minute timeout
        if (onDriverAssigned != null ||
            onStatusChange != null ||
            onTimeout != null) {
          _driverAssignmentService.pollForDriverAssignment(
            bookingId,
            (driverData) {
              if (onDriverAssigned != null) {
                // Create a new BookingDetails object with updated driver info
                final updatedBookingDetails = BookingDetails(
                  bookingId: bookingDetails.bookingId,
                  passengerId: bookingDetails.passengerId,
                  driverId: driverData['driver']['driver_id'] ?? 0,
                  routeId: bookingDetails.routeId,
                  rideStatus: 'accepted',
                  pickupAddress: bookingDetails.pickupAddress,
                  pickupCoordinates: bookingDetails.pickupCoordinates,
                  dropoffAddress: bookingDetails.dropoffAddress,
                  dropoffCoordinates: bookingDetails.dropoffCoordinates,
                  startTime: bookingDetails.startTime,
                  createdAt: bookingDetails.createdAt,
                  fare: bookingDetails.fare,
                  assignedAt: DateTime.now(),
                  endTime: bookingDetails.endTime,
                );

                // Save updated booking details to local DB
                _localDbService.saveBookingDetails(updatedBookingDetails);

                // Notify caller with updated booking details
                onDriverAssigned(updatedBookingDetails);
              }
            },
            onStatusChange: (newStatus) {
              if (onStatusChange != null) {
                onStatusChange(newStatus);
              }

              // Update local booking status
              _localDbService.updateLocalBookingStatus(bookingId, newStatus);
            },
            onTimeout: onTimeout,
          );
        }

        return BookingResult(booking: bookingDetails);
      } else {
        // Handle cases where backend might not return booking (e.g., no drivers found, error)
        // apiService.post would typically throw ApiException for non-2xx, caught below.
        // This 'else' handles cases where post returns null or response doesn't have 'booking'.
        String errorMessage =
            'Failed to create booking via backend: No booking data in response.';
        if (response != null && response.containsKey('error')) {
          errorMessage += ' Backend error: ${response['error']}';
          if (response.containsKey('reason')) {
            errorMessage += ', Reason: ${response['reason']}';
          }
        }
        debugPrint(errorMessage);
        return BookingResult(errorMessage: errorMessage);
      }
    } catch (e) {
      // Catches ApiExceptions from apiService.post and other errors
      debugPrint('Error in createBooking: $e');

      // Check if it's an ApiException with a 404 status code (no drivers)
      if (e is ApiException && e.statusCode == 404) {
        return BookingResult(
            errorMessage: "No drivers available in your area", statusCode: 404);
      }

      // Other API exceptions
      if (e is ApiException) {
        return BookingResult(errorMessage: e.message, statusCode: e.statusCode);
      }

      // Generic errors
      return BookingResult(errorMessage: "Error creating booking: $e");
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
      rideStatus: 'requested', // initial status for new bookings
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
          rideStatus: apiBooking['ride_status'] ?? 'requested',
          pickupAddress: apiBooking['pickup_address'] ?? '',
          pickupCoordinates: LatLng(
            (apiBooking['pickup_lat'] as num? ?? 0.0).toDouble(),
            (apiBooking['pickup_lng'] as num? ?? 0.0).toDouble(),
          ),
          dropoffAddress: apiBooking['dropoff_address'] ?? '',
          dropoffCoordinates: LatLng(
            (apiBooking['dropoff_lat'] as num? ?? 0.0).toDouble(),
            (apiBooking['dropoff_lng'] as num? ?? 0.0).toDouble(),
          ),
          startTime: TimeOfDay.now(),
          createdAt: DateTime.now(),
          fare: (apiBooking['fare'] as num? ?? 0.0).toDouble(),
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

      if (response != null && response.containsKey('trip')) {
        debugPrint('Retrieved booking details from API: ${response['trip']}');
        return response['trip'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching booking details from API: $e');
      return null;
    }
  }
}
