import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Weather {
  final String condition;
  final String iconUrl;
  final double precipitation;

  Weather({
    required this.condition,
    required this.iconUrl,
    required this.precipitation,
  });

  bool get isRaining =>
      condition.toLowerCase().contains('rain') || precipitation > 0;

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

  Future<Weather> fetchWeather(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.weatherapi.com/v1/current.json?key=$_apiKey&q=$lat,$lon',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Weather.fromJson(data);
    } else {
      throw Exception(
          'Failed to load weather: ${response.statusCode} ${response.body}');
    }
  }
}
