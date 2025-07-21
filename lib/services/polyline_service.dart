import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pasada_passenger_app/utils/map_utils.dart';
import 'package:pasada_passenger_app/network/networkUtilities.dart';
import 'package:pasada_passenger_app/utils/memory_manager.dart';

class PolylineService {
  final _points = PolylinePoints();
  final _apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;

  Future<List<LatLng>> generateBetween(LatLng start, LatLng end) async {
    final key = 'polyline_${start.latitude}_${start.longitude}'
        '_${end.latitude}_${end.longitude}';
    final cached = MemoryManager.instance.getFromCache(key);
    if (cached is List<LatLng>) return cached;

    final uri = Uri.parse(
      'https://routes.googleapis.com/directions/v2:computeRoutes',
    );
    final body = jsonEncode({
      'origin': {
        'location': {
          'latLng': {'latitude': start.latitude, 'longitude': start.longitude}
        }
      },
      'destination': {
        'location': {
          'latLng': {'latitude': end.latitude, 'longitude': end.longitude}
        }
      },
      'travelMode': 'DRIVE',
      'polylineEncoding': 'ENCODED_POLYLINE',
      'computeAlternativeRoutes': false,
      'routingPreference': 'TRAFFIC_AWARE',
    });
    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _apiKey,
      'X-Goog-FieldMask':
          'routes.polyline.encodedPolyline,routes.legs.duration.seconds',
    };

    final resp =
        await NetworkUtility.postUrl(uri, headers: headers, body: body);
    if (resp == null) return [];

    final data = json.decode(resp);
    final poly = data['routes']?[0]?['polyline']?['encodedPolyline'] as String?;
    if (poly == null) return [];

    final decoded = _points.decodePolyline(poly);
    final coords = decoded.map((p) => LatLng(p.latitude, p.longitude)).toList();
    MemoryManager.instance.addToCache(key, coords);
    return coords;
  }

  /// Calculates the total distance in kilometers along the generated polyline
  Future<double> calculateRouteDistanceKm(LatLng start, LatLng end) async {
    final coords = await generateBetween(start, end);
    if (coords.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < coords.length - 1; i++) {
      total += calculateDistanceKm(coords[i], coords[i + 1]);
    }
    return total;
  }
}
