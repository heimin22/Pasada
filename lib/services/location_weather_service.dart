import 'package:location/location.dart';
import 'package:pasada_passenger_app/providers/weather_provider.dart';

/// Service that automatically fetches weather based on device location
class LocationWeatherService {
  static final Location _location = Location();

  /// Initializes location permissions, fetches current weather, and subscribes to updates
  static Future<void> fetchAndSubscribe(WeatherProvider provider) async {
    // Ensure service enabled
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    // Ensure permission granted
    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted != PermissionStatus.granted) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    try {
      // Initial weather fetch
      final locData = await _location.getLocation();
      if (locData.latitude != null && locData.longitude != null) {
        await provider.fetchWeather(locData.latitude!, locData.longitude!);
      }
    } catch (_) {
      // ignore initial fetch errors
    }

    // Subscribe to location changes
    _location.onLocationChanged.listen((data) {
      if (data.latitude != null && data.longitude != null) {
        provider.fetchWeather(data.latitude!, data.longitude!);
      }
    });
  }
}
