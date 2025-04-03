import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/network/networkUtilities.dart';

class RoutingService {
  final String apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;
  final NetworkUtility networkUtility = NetworkUtility();

  // calculates the estimated travel duration between two points
  // returns duration in seconds, or null if teh calculation fails
  Future<int?> calculateEtaSeconds(LatLng origin, LatLng destination) async {
    final uri = Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');
    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      // request only yung duration field para maminimize yung response size
      'X-Goog-FieldMask': 'routes.legs.duration', // adjusted field mask
    };
    final body = jsonEncode({
      'origin': {
        'location': {
          'latLng': {'latitude': origin.latitude, 'longitude': origin.longitude}
        },
      },
      'destination': {
        'location': {
          'latlng': {'latitude': destination.latitude, 'longitude': destination.longitude},
        },
      },
      'travelMode': 'DRIVE',
      // optimize para sa traffic, critical para sa ETA
      'routingPreference': 'TRAFFIC_AWARE',
      // don't compute polylines or alternatives routes here
      'computeAlternativeRoutes': false,
      // specify yung language
      'languageCode': 'en-US',
      // specify kung anong units
      'units': 'METRIC',
    });

    try {
      final responseString = await NetworkUtility.postUrl(uri, headers: headers, body: body);
      if (responseString == null) {
        debugPrint('No response from Routing API');
        return null;
      }

      final data = json.decode(responseString) as Map<String, dynamic>;
      debugPrint('Routing API Response for ETA: $data');

      // early exit para sa mga empty/missing routes
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        debugPrint("No routes found in API response");
        return null;
      }

      // early exit for empty/missing legs
      final legs = routes[0]['legs'] as List<dynamic>?;
      if (legs == null || legs.isEmpty) {
        debugPrint('Legs data missing or empty in route');
        return null;
      }

      // early exit for missing duration
      final durationString = legs[0]['duration'] as String?;
      if (durationString == null) {
        debugPrint("Duration field missing in leg data");
        return null;
      }

      // parse duration
      final secondString = durationString.replaceAll('s', '');
      final durationSeconds = int.tryParse(secondString);
      if (durationSeconds == null) {
        debugPrint('Could not parse duration string: $durationString');
        return null;
      }

      debugPrint('Calculated ETA: $durationSeconds seconds');
      return durationSeconds;

    } catch (e) {
      debugPrint('Error calculating ETA: $e');
      return null;
    }
  }
}