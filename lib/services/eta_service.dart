import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class ETAService {
  // Google Routes API key
  final String apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;

  /// Compute ETA (duration) via Google Routes API for given origin/destination
  Future<Map<String, dynamic>> getETA(Map<String, dynamic> features) async {
    // features must contain 'origin' and 'destination' maps with 'lat' and 'lng'
    final origin = features['origin'] as Map<String, dynamic>;
    final destination = features['destination'] as Map<String, dynamic>;
    // Use Maps Directions API endpoint
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/directions/json',
      {
        'origin': '${origin['lat']},${origin['lng']}',
        'destination': '${destination['lat']},${destination['lng']}',
        'key': apiKey,
      },
    );
    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask': 'routes.legs.duration.seconds'
    };
    final body = jsonEncode({
      'origin': {
        'location': {
          'latLng': {'latitude': origin['lat'], 'longitude': origin['lng']}
        }
      },
      'destination': {
        'location': {
          'latLng': {
            'latitude': destination['lat'],
            'longitude': destination['lng']
          }
        }
      },
      'travelMode': 'DRIVE'
    });
    final resp = await http.post(uri, headers: headers, body: body);
    if (resp.statusCode != 200) {
      throw Exception('Failed to get ETA: ${resp.statusCode}');
    }
    final data = json.decode(resp.body) as Map<String, dynamic>;
    debugPrint('ETAService.getETA: raw response data = $data');
    // Check Directions API status
    final routes = data['routes'] as List<dynamic>;
    final legs = (routes[0] as Map)['legs'] as List<dynamic>;
    final raw = (legs[0] as Map)['duration'];

    int seconds;
    if (raw is String) {
      seconds = int.parse(raw.replaceAll('s', ''));
    } else if (raw is Map && raw['seconds'] != null) {
      final v = raw['seconds'];
      seconds = v is int ? v : int.parse(v.toString());
    } else {
      throw Exception('Unrecognized duration format: $raw');
    }

    return {'eta_seconds': seconds};
  }
}
