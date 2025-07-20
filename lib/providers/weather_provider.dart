import 'package:flutter/foundation.dart';
import 'package:pasada_passenger_app/services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _service = WeatherService();
  // Cache duration to limit API calls
  static const Duration _cacheDuration = Duration(minutes: 7);
  DateTime? _lastFetchTime;

  Weather? _weather;
  bool _isLoading = false;
  String? _error;

  Weather? get weather => _weather;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isRaining => _weather?.isRaining ?? false;

  Future<void> fetchWeather(double lat, double lon) async {
    final now = DateTime.now();
    // Skip fetching if within cache duration
    if (_lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _cacheDuration) {
      return;
    }
    _lastFetchTime = now;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final w = await _service.fetchWeather(lat, lon);
      _weather = w;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
