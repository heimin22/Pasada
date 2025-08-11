import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pasada_passenger_app/utils/map_utils.dart';
import 'package:pasada_passenger_app/network/networkUtilities.dart';
import 'package:pasada_passenger_app/utils/memory_manager.dart';

class PolylineService {
  final _apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;

  Future<List<LatLng>> generateBetween(LatLng start, LatLng end) async {
    // Use rounded coordinates for better cache hit rate (approx 11m precision)
    final roundedStartLat = (start.latitude * 10000).round() / 10000;
    final roundedStartLng = (start.longitude * 10000).round() / 10000;
    final roundedEndLat = (end.latitude * 10000).round() / 10000;
    final roundedEndLng = (end.longitude * 10000).round() / 10000;

    final key = 'polyline_${roundedStartLat}_$roundedStartLng'
        '_${roundedEndLat}_$roundedEndLng';
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
    if (resp == null) return <LatLng>[];
    final data = json.decode(resp);
    // Robustly handle routes as List or Map
    dynamic routesData = data['routes'];
    List<dynamic> routesList;
    if (routesData is List) {
      routesList = routesData;
    } else if (routesData is Map) {
      routesList = routesData.values.toList();
    } else {
      return <LatLng>[];
    }
    if (routesList.isEmpty) return <LatLng>[];
    final firstRoute = routesList.first;
    // Extract encodedPolyline safely
    dynamic polylineData = firstRoute['polyline'];
    String? poly;
    if (polylineData is Map && polylineData['encodedPolyline'] != null) {
      poly = polylineData['encodedPolyline'] as String;
    } else {
      return <LatLng>[];
    }
    final decoded = PolylinePoints.decodePolyline(poly);
    final coords = decoded.map((p) => LatLng(p.latitude, p.longitude)).toList();
    // Cache with the rounded key for consistency
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

  /// Finds nearest point on [routePolyline] to the given point [p].
  LatLng findNearestPointOnRoute(LatLng p, List<LatLng> routePolyline) {
    if (routePolyline.isEmpty) return p;
    double minDist = double.infinity;
    LatLng nearest = routePolyline.first;
    for (int i = 0; i < routePolyline.length - 1; i++) {
      final s = routePolyline[i];
      final e = routePolyline[i + 1];
      final candidate = findNearestPointOnSegment(p, s, e);
      final dist = calculateDistanceKm(p, candidate);
      if (dist < minDist) {
        minDist = dist;
        nearest = candidate;
      }
    }
    return nearest;
  }

  /// Generates a contiguous segment of [routePolyline] between [start] and [end].
  /// Returns a list beginning with [start], the intermediate route points, and [end].
  List<LatLng> generateAlongRoute(
      LatLng start, LatLng end, List<LatLng> routePolyline) {
    if (routePolyline.isEmpty) {
      return [start, end];
    }
    final startOnRoute = findNearestPointOnRoute(start, routePolyline);
    final endOnRoute = findNearestPointOnRoute(end, routePolyline);
    int startIdx = 0, endIdx = routePolyline.length - 1;
    double minStartDist = double.infinity, minEndDist = double.infinity;
    for (int i = 0; i < routePolyline.length; i++) {
      final point = routePolyline[i];
      final sd = calculateDistanceKm(startOnRoute, point);
      if (sd < minStartDist) {
        minStartDist = sd;
        startIdx = i;
      }
      final ed = calculateDistanceKm(endOnRoute, point);
      if (ed < minEndDist) {
        minEndDist = ed;
        endIdx = i;
      }
    }
    if (startIdx > endIdx) {
      final tmp = startIdx;
      startIdx = endIdx;
      endIdx = tmp;
    }
    final segment = <LatLng>[];
    segment.add(start);
    if (endIdx > startIdx + 1) {
      segment.addAll(routePolyline.sublist(startIdx + 1, endIdx));
    }
    segment.add(end);
    return segment;
  }
}
