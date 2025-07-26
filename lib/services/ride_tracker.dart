import 'dart:async';
import 'package:flutter/services.dart';
import 'eta_service.dart';

class RideTracker {
  static final RideTracker _instance = RideTracker._internal();
  factory RideTracker() => _instance;
  RideTracker._internal();

  static const MethodChannel _channel = MethodChannel('ride_channel');
  final ETAService _etaService = ETAService();

  Timer? _timer;
  int? _initialSeconds;
  String? _destinationName;

  Future<void> startTracking({
    required Map<String, dynamic> origin,
    required Map<String, dynamic> destination,
    required String destinationName,
    Duration updateInterval = const Duration(seconds: 30),
  }) async {
    await _channel.invokeMethod('startRide');

    final data = await _etaService.getETA({
      'origin': origin,
      'destination': destination,
    });
    _initialSeconds = data['eta_seconds'] as int;
    _destinationName = destinationName;

    _timer?.cancel();
    _timer = Timer.periodic(updateInterval, (timer) async {
      final updateData = await _etaService.getETA({
        'origin': origin,
        'destination': destination,
      });
      final remaining = updateData['eta_seconds'] as int;
      final initial = _initialSeconds ?? remaining;
      final progressed =
          ((initial - remaining) / initial * 100).clamp(0, 100).toInt();

      final formattedEta = _formatEta(remaining);
      await _channel.invokeMethod('updateRide', {
        'eta': formattedEta,
        'destination': _destinationName,
        'progress': progressed,
      });
    });
  }

  void stopTracking() {
    _timer?.cancel();
  }

  String _formatEta(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '\${hours}h \\${minutes}m';
    } else {
      return '\\${minutes}m';
    }
  }
}
