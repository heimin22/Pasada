import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CapacityService {
  final supabase = Supabase.instance.client;

  /// Gets the current vehicle capacity for a booking
  /// Returns a map with sitting_passenger and standing_passenger counts
  Future<Map<String, int>?> getVehicleCapacityForBooking(int bookingId) async {
    try {
      debugPrint(
          '[CapacityService] Fetching vehicle capacity for booking $bookingId');

      // Get the driver_id from the booking
      final bookingResponse = await supabase
          .from('bookings')
          .select('driver_id')
          .eq('booking_id', bookingId)
          .single();

      if (bookingResponse['driver_id'] == null) {
        debugPrint(
            '[CapacityService] No driver assigned to booking $bookingId');
        return null;
      }

      final driverId = bookingResponse['driver_id'];

      // Get the vehicle_id from the driver
      final driverResponse = await supabase
          .from('driverTable')
          .select('vehicle_id')
          .eq('driver_id', driverId)
          .single();

      if (driverResponse['vehicle_id'] == null) {
        debugPrint('[CapacityService] No vehicle assigned to driver $driverId');
        return null;
      }

      final vehicleId = driverResponse['vehicle_id'];

      // Get the vehicle capacity
      final vehicleResponse = await supabase
          .from('vehicleTable')
          .select('sitting_passenger, standing_passenger')
          .eq('vehicle_id', vehicleId)
          .single();

      final sittingPassengers =
          vehicleResponse['sitting_passenger'] as int? ?? 0;
      final standingPassengers =
          vehicleResponse['standing_passenger'] as int? ?? 0;

      debugPrint(
          '[CapacityService] Vehicle capacity - Sitting: $sittingPassengers, Standing: $standingPassengers');

      return {
        'sitting_passenger': sittingPassengers,
        'standing_passenger': standingPassengers,
      };
    } catch (e) {
      debugPrint('[CapacityService] Error fetching vehicle capacity: $e');
      return null;
    }
  }

  /// Updates the seating preference for a booking
  /// Returns true if successful, false otherwise
  Future<bool> updateSeatingPreference({
    required int bookingId,
    required String newSeatType,
  }) async {
    try {
      debugPrint(
          '[CapacityService] Updating seating preference for booking $bookingId to $newSeatType');

      final response =
          await supabase.rpc('update_booking_seating_preference', params: {
        'booking_id': bookingId,
        'new_seat_type': newSeatType,
      });

      if (response != null) {
        debugPrint('[CapacityService] Successfully updated seating preference');
        return true;
      } else {
        debugPrint(
            '[CapacityService] Failed to update seating preference - null response');
        return false;
      }
    } catch (e) {
      debugPrint('[CapacityService] Error updating seating preference: $e');
      return false;
    }
  }

  /// Checks if a booking is in a state where capacity changes are allowed
  /// Allows changes for 'assigned' and 'accepted' status, not 'ongoing' or 'completed'
  Future<bool> canChangeSeatingPreference(int bookingId) async {
    try {
      final response = await supabase
          .from('bookings')
          .select('ride_status')
          .eq('booking_id', bookingId)
          .single();

      final status = response['ride_status'] as String?;
      debugPrint('[CapacityService] Booking $bookingId status: $status');

      // Allow changes for 'assigned' and 'accepted' status, but not 'ongoing' or 'completed'
      return status == 'assigned' || status == 'accepted';
    } catch (e) {
      debugPrint('[CapacityService] Error checking booking status: $e');
      return false;
    }
  }

  /// Gets the current seating preference for a booking
  Future<String?> getCurrentSeatingPreference(int bookingId) async {
    try {
      final response = await supabase
          .from('bookings')
          .select('seat_type')
          .eq('booking_id', bookingId)
          .single();

      return response['seat_type'] as String?;
    } catch (e) {
      debugPrint(
          '[CapacityService] Error getting current seating preference: $e');
      return null;
    }
  }

  /// Resets booking status to 'requested' for driver reassignment
  /// Returns true if successful, false otherwise
  Future<bool> resetBookingForReassignment(int bookingId) async {
    try {
      debugPrint(
          '[CapacityService] Resetting booking $bookingId for reassignment');

      final response =
          await supabase.rpc('reset_booking_for_reassignment', params: {
        'booking_id': bookingId,
      });

      if (response != null) {
        debugPrint(
            '[CapacityService] Successfully reset booking for reassignment');
        return true;
      } else {
        debugPrint('[CapacityService] Failed to reset booking - null response');
        return false;
      }
    } catch (e) {
      debugPrint(
          '[CapacityService] Error resetting booking for reassignment: $e');
      return false;
    }
  }
}
