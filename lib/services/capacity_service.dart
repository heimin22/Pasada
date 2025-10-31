// Removed unused foundation import
import 'package:pasada_passenger_app/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CapacityService {
  final supabase = Supabase.instance.client;

  /// Gets the current vehicle capacity for a booking
  /// Returns a map with sitting_passenger and standing_passenger counts
  Future<Map<String, int>?> getVehicleCapacityForBooking(int bookingId) async {
    try {
      AppLogger.debug('Fetching vehicle capacity for $bookingId',
          tag: 'Capacity');

      // Get the driver_id from the booking
      final bookingResponse = await supabase
          .from('bookings')
          .select('driver_id')
          .eq('booking_id', bookingId)
          .single();

      if (bookingResponse['driver_id'] == null) {
        AppLogger.debug('No driver assigned to booking $bookingId',
            tag: 'Capacity');
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
        AppLogger.debug('No vehicle for driver $driverId', tag: 'Capacity');
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

      AppLogger.debug(
          'Vehicle capacity sit:$sittingPassengers stand:$standingPassengers',
          tag: 'Capacity',
          throttle: true);

      return {
        'sitting_passenger': sittingPassengers,
        'standing_passenger': standingPassengers,
      };
    } catch (e) {
      AppLogger.warn('Error fetching vehicle capacity: $e', tag: 'Capacity');
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
      AppLogger.info('Update seat pref booking:$bookingId -> $newSeatType',
          tag: 'Capacity');

      final response =
          await supabase.rpc('update_booking_seating_preference', params: {
        'booking_id': bookingId,
        'new_seat_type': newSeatType,
      });

      if (response != null) {
        AppLogger.debug('Seat pref updated', tag: 'Capacity');
        return true;
      } else {
        AppLogger.warn('Seat pref update failed - null response',
            tag: 'Capacity');
        return false;
      }
    } catch (e) {
      AppLogger.warn('Error updating seating preference: $e', tag: 'Capacity');
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
      AppLogger.debug('Booking $bookingId status: $status', tag: 'Capacity');

      // Allow changes for 'assigned' and 'accepted' status, but not 'ongoing' or 'completed'
      return status == 'assigned' || status == 'accepted';
    } catch (e) {
      AppLogger.warn('Error checking booking status: $e', tag: 'Capacity');
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
      AppLogger.warn('Error getting current seat preference: $e',
          tag: 'Capacity');
      return null;
    }
  }

  /// Resets booking status to 'requested' for driver reassignment
  /// Returns true if successful, false otherwise
  Future<bool> resetBookingForReassignment(int bookingId) async {
    try {
      AppLogger.info('Reset booking $bookingId for reassignment',
          tag: 'Capacity');

      final response =
          await supabase.rpc('reset_booking_for_reassignment', params: {
        'booking_id': bookingId,
      });

      if (response != null) {
        AppLogger.debug('Reset booking for reassignment success',
            tag: 'Capacity');
        return true;
      } else {
        AppLogger.warn('Reset booking failed - null response', tag: 'Capacity');
        return false;
      }
    } catch (e) {
      AppLogger.warn('Error resetting booking for reassignment: $e',
          tag: 'Capacity');
      return false;
    }
  }

  /// Cancels a booking and unassigns its driver (driver_id = NULL)
  /// Uses RPC: cancel_and_unassign_driver
  Future<bool> cancelAndUnassignDriver(int bookingId) async {
    try {
      AppLogger.info('Cancel and unassign booking $bookingId', tag: 'Capacity');
      final result = await supabase.rpc('cancel_and_unassign_driver',
          params: {'p_booking_id': bookingId});
      if (result != null) {
        AppLogger.debug('Cancel and unassign successful', tag: 'Capacity');
        return true;
      }
      AppLogger.warn('Cancel and unassign failed - null result',
          tag: 'Capacity');
      return false;
    } catch (e) {
      AppLogger.warn('Error on cancel_and_unassign_driver: $e',
          tag: 'Capacity');
      return false;
    }
  }
}
