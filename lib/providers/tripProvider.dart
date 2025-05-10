import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pasada_passenger_app/models/trip.dart';
import 'package:pasada_passenger_app/services/apiService.dart';
import 'package:pasada_passenger_app/services/tripService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TripProvider extends ChangeNotifier {
  final TripService _tripService = TripService();
  Trip? currentTrip;
  bool isLoading = false;
  String? error;
  final supabase = Supabase.instance.client;
  RealtimeChannel? _tripChannel;

  Future<void> requestNewTrip({
    required double originLatitude,
    required double originLongitude,
    required String originAddress,
    required double destinationLatitude,
    required double destinationLongitude,
    required String destinationAddress,
    required double fare,
    required String paymentMethod,
  }) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final response = await _tripService.requestTrip(
        originLatitude: originLatitude,
        originLongitude: originLongitude,
        originAddress: originAddress,
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
        destinationAddress: destinationAddress,
        routeTrip: 'direct',
        fare: fare,
        paymentMethod: paymentMethod,
      );

      currentTrip = Trip.fromJson(response['booking']);
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCurrentTrip() async {
    try {
      final response = await _tripService.getCurrentTrip();
      currentTrip = Trip.fromJson(response);
      notifyListeners();
      debugPrint('Current trip: ${currentTrip?.id}');
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
    }
  }

  void setupRealtimeSubscription() {
    _tripChannel?.unsubscribe();

    if (currentTrip == null || currentTrip?.id == null) {
      debugPrint('Cannot set up realtime subscription: No valid trip ID');
      return;
    }

    try {
      _tripChannel = supabase.channel('bookings').onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'bookings',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'booking_id',
              value: int.tryParse(currentTrip!.id) ?? currentTrip!.id,
            ),
            callback: (payload) {
              try {
                if (payload.newRecord['booking_id'].toString() ==
                    currentTrip?.id.toString()) {
                  // Create a safe copy of the payload data
                  final Map<String, dynamic> safeRecord =
                      Map<String, dynamic>.from(payload.newRecord);

                  final List<String> coordinateFields = [
                    'pickup_lat',
                    'pickup_lng',
                    'dropoff_lat',
                    'dropoff_lng'
                  ];

                  // Remove coordinate fields if they are null or 'null'
                  for (final field in coordinateFields) {
                    if (safeRecord.containsKey(field) &&
                        (safeRecord[field] == null ||
                            safeRecord[field] == 'null')) {
                      safeRecord.remove(field);
                    }
                  }
                  // Update the trip with the safe data
                  currentTrip = Trip.fromJson(safeRecord);
                  notifyListeners();
                  debugPrint('Trip updated via realtime: ${currentTrip?.id}');
                }
              } catch (e) {
                debugPrint('Error processing realtime payload: $e');
                // Continue subscription despite error in a single update
              }
            },
          );

      _tripChannel?.subscribe();
      debugPrint(
          'Realtime subscription setup for booking ID: ${currentTrip?.id}');
    } catch (e) {
      debugPrint('Error setting up realtime subscription: $e');
      // You might want to implement a retry mechanism here
    }
  }

  @override
  void dispose() {
    supabase.removeAllChannels();
    super.dispose();
  }
}
