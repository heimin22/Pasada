import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pasada_passenger_app/services/id_image_upload_service.dart';
import 'package:pasada_passenger_app/utils/app_logger.dart';
import 'package:pasada_passenger_app/utils/timezone_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'apiService.dart';
import 'bookingDetails.dart';
import 'driverAssignmentService.dart';
import 'encryptionService.dart';
import 'localDatabaseService.dart';

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

  Future<void> startLocationTracking(String passengerID) async {
    stopLocationTracking();

    final location = Location();

    // Use balanced accuracy and shorter interval for faster, battery-friendly updates
    location.changeSettings(
      accuracy: LocationAccuracy.balanced,
      interval: 5000,
    );
    // Keep updates alive when app goes to background (requires proper permissions)
    try {
      await location.enableBackgroundMode(enable: true);
    } catch (_) {}

    _locationSubscription = location.onLocationChanged.listen((locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        _updatePassengerLocation(
          passengerID,
          locationData.latitude!,
          locationData.longitude!,
        );
      }
    });

    AppLogger.info('Location tracking started for passenger $passengerID',
        tag: 'BookingService', throttle: true);
  }

  void stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    AppLogger.info('Location tracking stopped', tag: 'BookingService');
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

      AppLogger.debug('Passenger location updated: $latitude, $longitude',
          tag: 'BookingService', throttle: true);
    } catch (e) {
      AppLogger.warn('Error updating passenger location: $e',
          tag: 'BookingService');
    }
  }

  // Check how many bookings a user has made today
  Future<int> getTodayBookingCount(String passengerId) async {
    try {
      final now = TimezoneUtils.nowInPhilippines();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Query bookings and count them
      final response = await supabase
          .from('bookings')
          .select('booking_id')
          .eq('passenger_id', passengerId)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      // Count the number of bookings
      final count = response.length;

      AppLogger.debug('Today booking count for $passengerId: $count',
          tag: 'BookingService');
      return count;
    } catch (e) {
      AppLogger.error('Error getting today booking count: $e',
          tag: 'BookingService');
      // On error, return 0 to allow booking (fail open)
      return 0;
    }
  }

  // Check if user can make a booking (rate limit: 5 per day)
  Future<bool> canBookToday(String passengerId,
      {int maxBookingsPerDay = 5}) async {
    final count = await getTodayBookingCount(passengerId);
    return count < maxBookingsPerDay;
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
    String? passengerType, // Student, Senior Citizen, PWD, or null
    String? idImageUrl, // URL of uploaded ID image from Supabase Storage
    Function(BookingDetails)? onDriverAssigned,
    Function(String)? onStatusChange,
    Function? onTimeout,
  }) async {
    try {
      final apiService = ApiService();

      // No need to encrypt the ID image URL - it's already securely stored in Supabase
      // The URL contains signed tokens for access control
      AppLogger.debug('ID image provided: ${idImageUrl != null}',
          tag: 'BookingService');

      // Prepare encrypted path if an ID image URL is provided
      String? encryptedIdImagePath;
      if (idImageUrl != null) {
        try {
          final filePath =
              IdImageUploadService.extractFilePathFromUrl(idImageUrl);
          if (filePath != null && filePath.isNotEmpty) {
            final encryptionService = EncryptionService();
            await encryptionService.initialize();
            encryptedIdImagePath =
                await encryptionService.encryptUserData(filePath);
          }
        } catch (e) {
          debugPrint('Error encrypting ID image path: $e');
        }
      }

      // Build and log the request body to ensure seat_type is included
      final requestBody = {
        'route_trip': routeId,
        'origin_latitude': pickupCoordinates.latitude,
        'origin_longitude': pickupCoordinates.longitude,
        'pickup_address': pickupAddress,
        'destination_latitude': dropoffCoordinates.latitude,
        'destination_longitude': dropoffCoordinates.longitude,
        'dropoff_address': dropoffAddress,
        'fare': fare,
        'payment_method': paymentMethod,
        'seat_type': seatingPreference,
        'passenger_type': passengerType, // Add passenger type for discount
        'passenger_id_image_url': idImageUrl, // No need to encrypt the URL
        // Also send the encrypted storage path so backend can persist to bookings.passenger_id_image_path
        if (encryptedIdImagePath != null)
          'passenger_id_image_path': encryptedIdImagePath,
      };
      AppLogger.debug('createBooking body: $requestBody',
          tag: 'BookingService');
      final response = await apiService.post<Map<String, dynamic>>(
        'bookings/assign-driver',
        body: requestBody,
      );

      if (response != null && response.containsKey('booking')) {
        final bookingData = response['booking'] as Map<String, dynamic>;

        // Extract data from backend response
        final bookingId = bookingData['booking_id'] as int;
        final backendPassengerId = bookingData['passenger_id'] as String? ??
            passengerId; // Prefer backend's if available
        final driverId = bookingData['driver_id'] as String? ?? '';
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
        final backendSeatType =
            (bookingData['seat_type'] as String?) ?? seatingPreference;
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
          driverId: driverId,
          routeId: backendRouteId,
          rideStatus: rideStatus,
          pickupAddress: backendPickupAddress,
          pickupCoordinates: LatLng(backendPickupLat, backendPickupLng),
          dropoffAddress: backendDropoffAddress,
          dropoffCoordinates: LatLng(backendDropoffLat, backendDropoffLng),
          seatType: backendSeatType,
          startTime: TimeOfDay.fromDateTime(
              createdAtDateTime), // Using createdAt for startTime
          createdAt: createdAtDateTime,
          fare: backendFare,
          assignedAt: assignedAtDateTime,
          endTime: TimeOfDay.fromDateTime(
              createdAtDateTime), // Placeholder, can be updated later
        );

        await _localDbService.saveBookingDetails(bookingDetails);
        AppLogger.info(
            'Booking created: $bookingId, status: $rideStatus (saved locally)',
            tag: 'BookingService');

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
                  driverId: driverData['driver']['driver_id']?.toString() ?? '',
                  routeId: bookingDetails.routeId,
                  rideStatus: 'accepted',
                  pickupAddress: bookingDetails.pickupAddress,
                  pickupCoordinates: bookingDetails.pickupCoordinates,
                  dropoffAddress: bookingDetails.dropoffAddress,
                  dropoffCoordinates: bookingDetails.dropoffCoordinates,
                  startTime: bookingDetails.startTime,
                  createdAt: bookingDetails.createdAt,
                  fare: bookingDetails.fare,
                  seatType: bookingDetails.seatType,
                  assignedAt: TimezoneUtils.nowInPhilippines(),
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
        AppLogger.warn(errorMessage, tag: 'BookingService');
        return BookingResult(errorMessage: errorMessage);
      }
    } catch (e) {
      // Catches ApiExceptions from apiService.post and other errors
      AppLogger.error('createBooking error: $e', tag: 'BookingService');

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

  // Update booking status both in Supabase and locally
  Future<void> updateBookingStatus(int bookingId, String newStatus) async {
    try {
      // Update in Supabase
      await supabase.from('bookings').update({
        'ride_status': newStatus,
      }).eq('booking_id', bookingId);

      // Update locally
      await _localDbService.updateLocalBookingStatus(bookingId, newStatus);
    } catch (e) {
      throw Exception('Error updating booking status: $e');
    }
  }

  Future<int> assignDriver(
    int bookingId, {
    required double fare,
    required String paymentMethod,
    String? excludeDriverId,
    String? seatType,
  }) async {
    try {
      final apiService = ApiService();

      // First try to get booking from local database
      var booking = await getLocalBookingDetails(bookingId);

      // If not found locally, try to fetch from API
      if (booking == null) {
        AppLogger.info('Booking $bookingId not found locally, trying API...',
            tag: 'BookingService');
        final apiBooking = await getBookingDetails(bookingId);

        if (apiBooking == null) {
          AppLogger.warn('Booking $bookingId not found in API',
              tag: 'BookingService');
          return bookingId; // Return original booking ID if booking not found
        }

        // Create a BookingDetails object from API data
        booking = BookingDetails(
          bookingId: bookingId,
          passengerId: apiBooking['passenger_id'] ?? '',
          driverId: apiBooking['driver_id']?.toString() ?? '',
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
          startTime: TimeOfDay.fromDateTime(TimezoneUtils.nowInPhilippines()),
          createdAt: TimezoneUtils.nowInPhilippines(),
          fare: (apiBooking['fare'] as num? ?? 0.0).toDouble(),
          seatType: apiBooking['seat_type'] ?? 'Any',
          assignedAt: TimezoneUtils.nowInPhilippines(),
          endTime: TimeOfDay.fromDateTime(TimezoneUtils.nowInPhilippines()),
        );

        // Save to local database for future reference
        await _localDbService.saveBookingDetails(booking);
      }

      // Now we have the booking data, proceed with API call
      AppLogger.info('Assigning driver for booking $bookingId',
          tag: 'BookingService');
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
          if (excludeDriverId != null) 'exclude_driver_id': excludeDriverId,
          if (seatType != null) 'seat_type': seatType,
        },
      );

      AppLogger.debug('Driver assignment initiated: $response',
          tag: 'BookingService');

      // Check if backend returned a new booking (new booking_id)
      // This happens when reassignment creates a new booking
      if (response != null && response.containsKey('booking')) {
        final bookingData = response['booking'] as Map<String, dynamic>;
        final newBookingId = bookingData['booking_id'] as int?;

        if (newBookingId != null && newBookingId != bookingId) {
          AppLogger.info(
              'New booking created during reassignment: $newBookingId (was $bookingId)',
              tag: 'BookingService');
          return newBookingId; // Return new booking ID
        }
      }

      return bookingId; // Return same booking ID if no new booking created
    } catch (e) {
      throw Exception('Error requesting driver assignment: $e');
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

  // Fetch booking details from the API
  Future<Map<String, dynamic>?> getBookingDetails(int bookingId) async {
    try {
      final apiService = ApiService();
      final response =
          await apiService.get<Map<String, dynamic>>('bookings/$bookingId');
      if (response == null) {
        AppLogger.warn('getBookingDetails: null response for $bookingId',
            tag: 'BookingService');
        return null;
      }

      Map<String, dynamic> bookingData;
      // If wrapped under 'trip', unwrap
      if (response.containsKey('trip') &&
          response['trip'] is Map<String, dynamic>) {
        if (AppLogger.verbose) {
          AppLogger.debug('getBookingDetails: unwrapped trip for $bookingId',
              tag: 'BookingService');
        }
        bookingData = response['trip'] as Map<String, dynamic>;
      }
      // If response directly has ride_status, return it
      else if (response.containsKey('ride_status')) {
        if (AppLogger.verbose) {
          AppLogger.debug('getBookingDetails: direct response for $bookingId',
              tag: 'BookingService');
        }
        bookingData = response;
      }
      // Fallback: return the entire response
      else {
        if (AppLogger.verbose) {
          AppLogger.debug('getBookingDetails: fallback response for $bookingId',
              tag: 'BookingService');
        }
        bookingData = response;
      }

      // Handle ID image URL (no decryption needed for Supabase URLs)
      if (bookingData.containsKey('passenger_id_image_url') &&
          bookingData['passenger_id_image_url'] != null) {
        final imageUrl = bookingData['passenger_id_image_url'].toString();
        if (imageUrl.isNotEmpty) {
          // Check if URL is expired and refresh if needed
          try {
            // Extract file path from URL to generate new signed URL if needed
            final filePath =
                IdImageUploadService.extractFilePathFromUrl(imageUrl);
            if (filePath != null) {
              // Generate a fresh signed URL for better security
              final refreshedUrl = await IdImageUploadService.getSignedUrl(
                imagePath: filePath,
                expiryInSeconds: 24 * 60 * 60, // 24 hours
              );
              if (refreshedUrl != null) {
                bookingData['passenger_id_image_url'] = refreshedUrl;
                AppLogger.debug('ID image URL refreshed for $bookingId',
                    tag: 'BookingService');
              }
            }
          } catch (e) {
            AppLogger.warn('Error refreshing ID image URL for $bookingId: $e',
                tag: 'BookingService');
            // Keep the original URL if refresh fails
          }
        }
      }

      // Legacy support: Handle old encrypted paths and convert to URLs if possible
      if (bookingData.containsKey('passenger_id_image_path') &&
          bookingData['passenger_id_image_path'] != null &&
          !bookingData.containsKey('passenger_id_image_url')) {
        try {
          final encryptionService = EncryptionService();
          await encryptionService.initialize();
          final encryptedPath =
              bookingData['passenger_id_image_path'].toString();
          if (encryptedPath.isNotEmpty &&
              encryptionService.isEncrypted(encryptedPath)) {
            final decryptedPath =
                await encryptionService.decryptUserData(encryptedPath);
            bookingData['passenger_id_image_path'] = decryptedPath;
            AppLogger.debug('Legacy ID image path decrypted for $bookingId',
                tag: 'BookingService');
            // Note: This is legacy data, new bookings should use passenger_id_image_url
          }
        } catch (e) {
          AppLogger.warn(
              'Error decrypting legacy ID image path for $bookingId: $e',
              tag: 'BookingService');
        }
      }

      return bookingData;
    } catch (e) {
      // If completed and backend returns 404, treat as no active booking
      if (e is ApiException && e.statusCode == 404) {
        AppLogger.info('Booking $bookingId not found (404) - likely completed',
            tag: 'BookingService');
        return null;
      }
      AppLogger.warn('Error fetching booking details from API: $e',
          tag: 'BookingService');
      return null;
    }
  }
}
