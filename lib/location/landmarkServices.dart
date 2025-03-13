import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'networkUtilities.dart';

class LandmarkService {
  static Future<Map<String, dynamic>?> getNearestLandmark(LatLng position) async {
    final apiKey = dotenv.env['ANDROID_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint("API key is empty");
      return null;
    }

    final uri = Uri.https(
      "maps.googleapis.com",
      "maps/api/place/nearbysearch/json",
      {
        "location": "${position.latitude},${position.longitude}",
        "type": "point_of_interest|establishment",
        "rankby": "distance",
        "key": apiKey,
      },
    );

    try {
      final response = await NetworkUtility.fetchUrl(uri);
      if (response == null) return null;

      final data = json.decode(response);

      if (data['status'] != 'OK') return null;

      final results = data['results'] as List?;

      if (results == null || results.isEmpty) return null;

      final nearest = results.first;
      final geometry = nearest['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;

      if (location == null) return null;

      // if (response != null && data['results'].isNotEmpty) {
      //   final nearest = data['results'][0];
      //   final dist = calculateDistance(
      //     position.latitude,
      //     position.longitude,
      //     nearest['geometry']['location']['lat'],
      //     nearest['geometry']['location']['lng'],
      //   );

      return {
        'name': nearest['name'] ?? 'Unknown Landmark',
        'location': LatLng(
          (location['lat'] as num).toDouble(),
          (location['lng'] as num).toDouble(),
        ),
        'address': nearest['vicinity'] ?? 'Address not available'
      };
      // if (data['results'] != null && data['results'].isNotEmpty) {
      //   final nearest = data['result'][0];
      //   return {
      //     'name': nearest['name'],
      //     'location': LatLng(
      //       nearest['geometry']['location']['lat'],
      //       nearest['geometry']['location']['lng'],
      //     ),
      //     'address': nearest['vicinity'],
      //   };
      // }
    } catch (e) {
      debugPrint("Error in getNearestLandmark: $e");
      return null;
    }
  }

  static double calculateDistance(lat1, lon1, lat2, lon2) {
    // Haversine formula
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
