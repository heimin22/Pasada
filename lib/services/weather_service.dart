import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class Weather {
  final String condition;
  final String iconUrl;
  final double precipitation;

  Weather({
    required this.condition,
    required this.iconUrl,
    required this.precipitation,
  });

  bool get isRaining => condition.toLowerCase().contains('heavy rain');

  factory Weather.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final condition = current['condition']['text'] as String;
    final icon = current['condition']['icon'] as String;
    final precipitation = (current['precip_mm'] as num).toDouble();
    return Weather(
      condition: condition,
      iconUrl: 'https:$icon',
      precipitation: precipitation,
    );
  }
}

class WeatherService {
  final String _apiKey = dotenv.env['WEATHERAPI'] ?? '';
  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxRetries = 3;
  static const Duration _baseDelay = Duration(milliseconds: 500);

  /// Fetches weather data with timeout, retry logic, and connection checking
  Future<Weather> fetchWeather(double lat, double lon) async {
    // Check internet connectivity first
    final connectivity = Connectivity();
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      throw Exception('No internet connection available');
    }

    return _fetchWeatherWithRetry(lat, lon, 0);
  }

  Future<Weather> _fetchWeatherWithRetry(double lat, double lon, int attempt) async {
    try {
      final url = Uri.parse(
        'https://api.weatherapi.com/v1/current.json?key=$_apiKey&q=$lat,$lon',
      );
      
      final response = await http.get(url).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Weather.fromJson(data);
      } else if (response.statusCode >= 500 && attempt < _maxRetries) {
        // Server error - retry with exponential backoff
        final delay = _baseDelay * (1 << attempt); // Exponential backoff
        await Future.delayed(delay);
        return _fetchWeatherWithRetry(lat, lon, attempt + 1);
      } else {
        throw Exception(
          'Failed to load weather: ${response.statusCode} ${response.body}');
      }
    } on SocketException {
      if (attempt < _maxRetries) {
        final delay = _baseDelay * (1 << attempt);
        await Future.delayed(delay);
        return _fetchWeatherWithRetry(lat, lon, attempt + 1);
      }
      throw Exception('Network connection failed');
    } on HttpException {
      if (attempt < _maxRetries) {
        final delay = _baseDelay * (1 << attempt);
        await Future.delayed(delay);
        return _fetchWeatherWithRetry(lat, lon, attempt + 1);
      }
      throw Exception('HTTP request failed');
    } catch (e) {
      if (e.toString().contains('timeout') && attempt < _maxRetries) {
        final delay = _baseDelay * (1 << attempt);
        await Future.delayed(delay);
        return _fetchWeatherWithRetry(lat, lon, attempt + 1);
      }
      rethrow;
    }
  }
}
