import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CapacityService {
  final supabase = Supabase.instance.client;

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
  /// Only allows changes for 'assigned' status, not 'ongoing'
  Future<bool> canChangeSeatingPreference(int bookingId) async {
    try {
      final response = await supabase
          .from('bookings')
          .select('ride_status')
          .eq('booking_id', bookingId)
          .single();

      final status = response['ride_status'] as String?;
      debugPrint('[CapacityService] Booking $bookingId status: $status');

      // Only allow changes for 'assigned' status
      return status == 'assigned';
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
}
