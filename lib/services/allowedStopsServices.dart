import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/stop.dart';

class StopsService {
  final supabase = Supabase.instance.client;

  // Get all active stops for a specific route
  Future<List<Stop>> getStopsForRoute(int routeID) async {
    try {
      final response = await supabase
          .from('allowed_stops')
          .select("*")
          .eq('officialroute_id', routeID)
          .eq('is_active', true)
          .order('stop_order');

      return response.map<Stop>((data) => Stop.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error fetching stops: $e');
      return [];
    }
  }

  // Get all active stops across all routes
  Future<List<Stop>> getAllActiveStops() async {
    try {
      debugPrint('Attempting to fetch all active stops...');

      // First, check if we can access the table at all
      final countResponse = await supabase
          .from('allowed_stops')
          .select('*')
          .count(CountOption.exact);

      debugPrint('Total records in allowed_stops: ${countResponse.count}');

      if (countResponse.count == 0) {
        debugPrint(
            'No stops found in the database. Checking if table exists...');

        // Try to query the table structure to verify it exists
        try {
          final tableCheck = await supabase.rpc('check_table_exists',
              params: {'table_name': 'allowed_stops'});
          debugPrint('Table exists check: $tableCheck');
        } catch (e) {
          debugPrint('Error checking table: $e');
        }

        return [];
      }

      // Now try the actual query
      final response = await supabase
          .from('allowed_stops')
          .select('*')
          .eq('is_active', true);

      debugPrint('Raw response: $response');
      debugPrint('Response type: ${response.runtimeType}');
      debugPrint('Response length: ${response.length}');

      if (response.isEmpty) {
        debugPrint('No active stops found in the database');
        return [];
      }

      // Check the first record to see its structure
      if (response.isNotEmpty) {
        debugPrint('First record: ${response[0]}');
      }

      final stops = response.map<Stop>((data) {
        try {
          return Stop.fromJson(data);
        } catch (e) {
          debugPrint('Error parsing stop data: $e');
          debugPrint('Problematic data: $data');
          rethrow;
        }
      }).toList();

      debugPrint('Successfully parsed ${stops.length} stops');
      return stops;
    } catch (e) {
      debugPrint('Error fetching all stops: $e');
      return [];
    }
  }

  // Search for stops by name or address
  Future<List<Stop>> searchStops(String query) async {
    try {
      final response = await supabase
          .from('allowed_stops')
          .select('*, official_routes!inner(officialroute_id)')
          .eq('is_active', true)
          .or('stop_name.ilike.%$query%,stop_address.ilike.%$query%')
          .order('stop_name');

      return response.map<Stop>((data) => Stop.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error searching stops: $e');
      return [];
    }
  }

  // Search for stops within a specific route
  Future<List<Stop>> searchStopsInRoute(String query, int routeID) async {
    try {
      final response = await supabase
          .from('allowed_stops')
          .select("*")
          .eq('officialroute_id', routeID)
          .eq('is_active', true)
          .or('stop_name.ilike.%$query%,stop_address.ilike.%$query%')
          .order('stop_name');

      return response.map<Stop>((data) => Stop.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error searching stops in route: $e');
      return [];
    }
  }
}
