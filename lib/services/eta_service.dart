import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ETAService {
  // Google Routes API key
  final String apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;

  /// Compute ETA (duration) via Google Routes API for given origin/destination
  Future<Map<String, dynamic>> getETAWithGemini(
      Map<String, dynamic> features) async {
    // features must contain 'origin' and 'destination' maps with 'lat' and 'lng'
    final origin = features['origin'] as Map<String, dynamic>;
    final destination = features['destination'] as Map<String, dynamic>;
    final uri =
        Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');
    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask': 'routes.legs.duration.seconds',
    };
    final body = jsonEncode({
      'origin': {
        'location': {
          'latLng': {
            'latitude': origin['lat'],
            'longitude': origin['lng'],
          }
        }
      },
      'destination': {
        'location': {
          'latLng': {
            'latitude': destination['lat'],
            'longitude': destination['lng'],
          }
        }
      },
      'travelMode': 'DRIVE',
      'computeAlternativeRoutes': false,
      'routingPreference': 'TRAFFIC_AWARE',
    });
    final response = await http.post(uri, headers: headers, body: body);
    if (response.statusCode != 200) {
      throw Exception('Failed to get ETA: \\$response.statusCode');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['routes'] == null || (data['routes'] as List).isEmpty) {
      throw Exception('No routes found');
    }
    final legs = data['routes'][0]['legs'];
    if (legs is! List || legs.isEmpty) {
      throw Exception('No legs in route');
    }
    final duration = legs[0]['duration'];
    if (duration == null || duration['seconds'] == null) {
      throw Exception('Duration missing');
    }
    final secondsVal = duration['seconds'];
    final int seconds =
        secondsVal is int ? secondsVal : int.parse(secondsVal.toString());
    return {'eta_seconds': seconds};
  }
}
