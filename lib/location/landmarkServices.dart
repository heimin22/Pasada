import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'networkUtilities.dart';

class LandmarkService {
  static Future<Map<String, dynamic>?> getNearestLandmark(
      LatLng position) async {
    final apiKey = dotenv.env['ANDROID_MAPS_API_KEY'] ?? '';
    final uri = Uri.https(
      "maps.googleapis.com",
      "maps/api/place/nearbysearch/json",
      {
        "location": "${position.latitude},${position.longitude}",
        "radius": "50",
        "type": "point_of_interest|establishment",
        "rankby": "prominence",
        "key": apiKey,
      },
    );

    try {
      final response = await NetworkUtility.fetchUrl(uri);
      if (response == null) return null;

      final data = json.decode(response);
      if (data['results'] != null && data['results'].isNotEmpty) {
        final nearest = data['result'][0];
        return {
          'name': nearest['name'],
          'location': LatLng(
            nearest['geometry']['location']['lat'],
            nearest['geometry']['location']['lng'],
          ),
          'address': nearest['vicinity'],
        };
      }
    } catch (e) {
      debugPrint("Error in getNearestLandmark: $e");
    }
    return null;
  }
}
