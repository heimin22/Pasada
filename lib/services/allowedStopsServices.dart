import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StopsService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getStopsForRoute(int routeID) async {
    try {
      final response = await supabase
          .from('allowed_stops')
          .select()
          .eq('officialroute_id', routeID)
          .eq('is_active', true)
          .order('stop_order');

      return response;
    } catch (e) {
      debugPrint('Error fetching stops: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getNearestStop(
      double lat, double lng, int routeID) async {
    try {
      final response = await supabase.rpc('find_nearest_stop', params: {
        'user_lat': lat,
        'user_lng': lng,
        'route_id_param': routeID,
      });

      if (response != null) {
        return response;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching nearest stop: $e');
      return null;
    }
  }
}
