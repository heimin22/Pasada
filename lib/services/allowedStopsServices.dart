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

  // Add a new stop to the database
  Future<bool> addStop(int routeID, String name, String address,
      LatLng coordinates, int stopOrder) async {
    try {
      await supabase.from('allowed_stops').insert({
        'officialroute_id': routeID,
        'stop_name': name,
        'stop_address': address,
        'stop_lat': coordinates.latitude.toString(),
        'stop_lng': coordinates.longitude.toString(),
        'stop_order': stopOrder,
        'is_active': true
      });
      return true;
    } catch (e) {
      debugPrint('Error adding stop: $e');
      return false;
    }
  }

  // Update an existing stop
  Future<bool> updateStop(int stopID,
      {String? name,
      String? address,
      LatLng? coordinates,
      int? stopOrder,
      bool? isActive}) async {
    try {
      final Map<String, dynamic> updates = {};

      if (name != null) updates['stop_name'] = name;
      if (address != null) updates['stop_address'] = address;
      if (coordinates != null) {
        updates['stop_lat'] = coordinates.latitude.toString();
        updates['stop_lng'] = coordinates.longitude.toString();
      }
      if (stopOrder != null) updates['stop_order'] = stopOrder;
      if (isActive != null) updates['is_active'] = isActive;

      await supabase.from('allowed_stops').update(updates).eq('id', stopID);

      return true;
    } catch (e) {
      debugPrint('Error updating stop: $e');
      return false;
    }
  }

  // Delete a stop (or mark as inactive)
  Future<bool> deactivateStop(int stopID) async {
    try {
      await supabase
          .from('allowed_stops')
          .update({'is_active': false}).eq('id', stopID);

      return true;
    } catch (e) {
      debugPrint('Error deactivating stop: $e');
      return false;
    }
  }
}
