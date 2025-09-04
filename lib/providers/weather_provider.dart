import 'package:flutter/foundation.dart';
import 'package:pasada_passenger_app/services/weather_service.dart';
import 'package:location/location.dart';
import 'package:pasada_passenger_app/services/location_permission_manager.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _service = WeatherService();
  // Reduced cache duration for better responsiveness
  static const Duration _cacheDuration = Duration(minutes: 3);
  DateTime? _lastFetchTime;
  double? _lastLat;
  double? _lastLon;

  Weather? _weather;
  bool _isLoading = false;
  String? _error;
  int _retryCount = 0;
  static const int _maxUserRetries = 3;

  Weather? get weather => _weather;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isRaining => _weather?.isRaining ?? false;
  bool get hasError => _error != null;
  bool get canRetry => _retryCount < _maxUserRetries && !_isLoading;
  
  /// Check if cache is still valid
  bool get isCacheValid {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  /// Fetch weather with optional force refresh
  Future<void> fetchWeather(double lat, double lon, {bool forceRefresh = false}) async {
    final now = DateTime.now();
    
    // Check if we can use cached data
    if (!forceRefresh && 
        _lastFetchTime != null &&
        _lastLat == lat &&
        _lastLon == lon &&
        now.difference(_lastFetchTime!) < _cacheDuration &&
        _weather != null &&
        _error == null) {
      return;
    }

    _lastLat = lat;
    _lastLon = lon;
    _lastFetchTime = now;
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final w = await _service.fetchWeather(lat, lon);
      _weather = w;
      _error = null;
      _retryCount = 0; // Reset retry count on success
    } catch (e) {
      _error = _formatError(e.toString());
      _retryCount++;
      // Don't clear existing weather data on error unless it's the first fetch
      if (_weather == null) {
        _weather = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force refresh weather data
  Future<void> refreshWeather() async {
    if (_lastLat != null && _lastLon != null) {
      await fetchWeather(_lastLat!, _lastLon!, forceRefresh: true);
    }
  }

  /// Retry fetching weather with the last known coordinates
  Future<void> retryFetch() async {
    if (_lastLat != null && _lastLon != null && canRetry) {
      await fetchWeather(_lastLat!, _lastLon!, forceRefresh: true);
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _weather = null;
    _error = null;
    _isLoading = false;
    _lastFetchTime = null;
    _lastLat = null;
    _lastLon = null;
    _retryCount = 0;
    notifyListeners();
  }

  /// Initialize weather with location services (used during app startup)
  Future<bool> initializeWeatherService() async {
    try {
      final locationManager = LocationPermissionManager.instance;
      final locationReady = await locationManager.ensureLocationReady();
      if (!locationReady) {
        debugPrint('Cannot initialize weather - location not ready');
        return false;
      }

      final location = Location();
      final locationData = await location.getLocation().timeout(
        const Duration(seconds: 5),
      );

      if (locationData.latitude != null && locationData.longitude != null) {
        await fetchWeather(locationData.latitude!, locationData.longitude!, forceRefresh: true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error initializing weather service: $e');
      return false;
    }
  }

  /// Format error messages for better user experience
  String _formatError(String error) {
    final lowerError = error.toLowerCase();
    
    if (lowerError.contains('no internet connection')) {
      return 'No internet connection. Please check your network.';
    } else if (lowerError.contains('timeout')) {
      return 'Weather request timed out. Please try again.';
    } else if (lowerError.contains('network connection failed')) {
      return 'Unable to connect to weather service.';
    } else if (lowerError.contains('failed to load weather')) {
      return 'Weather service is temporarily unavailable.';
    } else {
      return 'Unable to load weather data.';
    }
  }
}
