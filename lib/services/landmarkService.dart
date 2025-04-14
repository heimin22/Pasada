import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/utils/memory_manager.dart';
import 'dart:convert';
import '../network/networkUtilities.dart';

class LandmarkService {
  static String? _cachedApiKey;
  static final MemoryManager memoryManager = MemoryManager();

  static Future<String?> _getSecureApiKey() async {
    final cachedKey = memoryManager.getFromCache('api_key');
    if (cachedKey != null) return cachedKey as String;

    _cachedApiKey = dotenv.env['ANDROID_MAPS_API_KEY'];
    if (_cachedApiKey != null) memoryManager.addToCache('api_key', _cachedApiKey);
    // Implement secure storage retrieval
    return _cachedApiKey;
  }

  static Future<Map<String, dynamic>?> getNearestLandmark(
      LatLng position) async {
    final apiKey = await _getSecureApiKey();
    if (apiKey == null) {
      debugPrint("Failed to retrieve API key");
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

      return {
        'name': nearest['name'] ?? 'Unknown Landmark',
        'location': LatLng(
          (location['lat'] as num).toDouble(),
          (location['lng'] as num).toDouble(),
        ),
        'address': nearest['vicinity'] ?? 'Address not available'
      };
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
