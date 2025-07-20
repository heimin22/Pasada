import 'package:flutter/foundation.dart';
import 'package:pasada_passenger_app/services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _service = WeatherService();

  Weather? _weather;
  bool _isLoading = false;
  String? _error;

  Weather? get weather => _weather;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isRaining => _weather?.isRaining ?? false;

  Future<void> fetchWeather(double lat, double lon) async {
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
