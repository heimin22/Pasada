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

    _tripChannel = supabase.channel('public:bookings').onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          callback: (payload) {
            if (payload.newRecord['id'] == currentTrip?.id) {
              currentTrip =
                  Trip.fromJson(Map<String, dynamic>.from(payload.newRecord));
              notifyListeners();
            }
          },
        );

    _tripChannel?.subscribe();
  }

  @override
  void dispose() {
    supabase.removeAllChannels();
    super.dispose();
  }
}
