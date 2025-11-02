import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/stop.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StopsService {
  final supabase = Supabase.instance.client;

  // Get all active stops for a specific route
  Future<List<Stop>> getStopsForRoute(int routeID) async {
    try {
      debugPrint('Fetching stops for route ID: $routeID');

      // Check if there are any stops for this route
      final countResponse = await supabase
          .from('allowed_stops')
          .select('*')
          .eq('officialroute_id', routeID)
          .count(CountOption.exact);

      debugPrint('Found ${countResponse.count} stops for route $routeID');

      // If we have stops, return them
      if (countResponse.count > 0) {
        final response = await supabase
            .from('allowed_stops')
            .select("*")
            .eq('officialroute_id', routeID)
            .eq('is_active', true)
            .order('stop_order');

        return response.map<Stop>((data) => Stop.fromJson(data)).toList();
      }

      // If no stops found, return an empty list
      // We'll handle the fallback to Google Places in the UI
      return [];
    } catch (e) {
      debugPrint('Error fetching stops for route $routeID: $e');
      return [];
    }
  }

  // Get paginated stops for a specific route
  Future<List<Stop>> getStopsForRoutePaginated(
    int routeID, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await supabase
          .from('allowed_stops')
          .select("*")
          .eq('officialroute_id', routeID)
          .eq('is_active', true)
          .order('stop_order')
          .range(offset, offset + limit - 1);

      return response.map<Stop>((data) => Stop.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error fetching paginated stops for route $routeID: $e');
      return [];
    }
  }

  // Get total count of stops for a route
  Future<int> getStopsCountForRoute(int routeID) async {
    try {
      final countResponse = await supabase
          .from('allowed_stops')
          .select('*')
          .eq('officialroute_id', routeID)
          .eq('is_active', true)
          .count(CountOption.exact);

      return countResponse.count;
    } catch (e) {
      debugPrint('Error getting stops count for route $routeID: $e');
      return 0;
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
        debugPrint('No stops found in the database.');
        // Insert test data if table is empty
        await insertTestStopsIfEmpty();

        // Try fetching again after inserting test data
        final retryResponse = await supabase
            .from('allowed_stops')
            .select('*')
            .eq('is_active', true);

        if (retryResponse.isNotEmpty) {
          return retryResponse
              .map<Stop>((data) => Stop.fromJson(data))
              .toList();
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

  // Get paginated active stops across all routes
  Future<List<Stop>> getAllActiveStopsPaginated({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await supabase
          .from('allowed_stops')
          .select('*')
          .eq('is_active', true)
          .range(offset, offset + limit - 1);

      return response.map<Stop>((data) {
        try {
          return Stop.fromJson(data);
        } catch (e) {
          debugPrint('Error parsing stop data: $e');
          rethrow;
        }
      }).toList();
    } catch (e) {
      debugPrint('Error fetching paginated stops: $e');
      return [];
    }
  }

  // Get total count of all active stops
  Future<int> getAllActiveStopsCount() async {
    try {
      final countResponse = await supabase
          .from('allowed_stops')
          .select('*')
          .eq('is_active', true)
          .count(CountOption.exact);

      return countResponse.count;
    } catch (e) {
      debugPrint('Error getting total stops count: $e');
      return 0;
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

  // Insert test data if the table is empty
  Future<void> insertTestStopsIfEmpty() async {
    try {
      // Check if table is empty
      final countResponse = await supabase
          .from('allowed_stops')
          .select('*')
          .count(CountOption.exact);

      if (countResponse.count == 0) {
        debugPrint('No stops found in the database. Inserting test data...');

        // Get a route ID to use for the test data
        try {
          final routeResponse = await supabase
              .from('official_routes')
              .select('officialroute_id')
              .limit(1);

          int routeId;
          if (routeResponse.isEmpty) {
            debugPrint('No routes found. Creating a test route first...');
            // Create a test route if none exists
            final newRoute = await supabase
                .from('official_routes')
                .insert({
                  'route_name': 'Test Route',
                  'description': 'Test route for development',
                  'status': 'active'
                })
                .select('officialroute_id')
                .single();

            routeId = newRoute['officialroute_id'];
          } else {
            routeId = routeResponse[0]['officialroute_id'];
          }

          // Insert test stops
          await supabase.from('allowed_stops').insert([
            {
              'officialroute_id': routeId,
              'stop_name': 'Test Stop 1',
              'stop_address': 'Test Address 1',
              'stop_lat': '14.721957951314671',
              'stop_lng': '121.03660698876655',
              'stop_order': 1,
              'is_active': true
            },
            {
              'officialroute_id': routeId,
              'stop_name': 'Test Stop 2',
              'stop_address': 'Test Address 2',
              'stop_lat': '14.693028415325333',
              'stop_lng': '120.96837623290318',
              'stop_order': 2,
              'is_active': true
            }
          ]);

          debugPrint('Test stops inserted successfully.');
        } catch (e) {
          debugPrint('Error creating test route or stops: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in insertTestStopsIfEmpty: $e');
    }
  }

  // Check the structure of the allowed_stops table
  Future<void> checkTableStructure() async {
    try {
      // This is a PostgreSQL-specific query to get column information
      final response = await supabase
          .rpc('get_table_columns', params: {'table_name': 'allowed_stops'});

      debugPrint('Table structure: $response');
    } catch (e) {
      // If the RPC doesn't exist, try a different approach
      debugPrint('Error checking table structure: $e');

      try {
        // Try to get at least one row to see the structure
        final response =
            await supabase.from('allowed_stops').select('*').limit(1);

        if (response.isNotEmpty) {
          debugPrint('Sample row structure: ${response[0].keys}');
        } else {
          debugPrint('No rows to check structure');
        }
      } catch (e) {
        debugPrint('Error getting sample row: $e');
      }
    }
  }

  // Add a new method to create test stops for a specific route
  Future<void> insertTestStopsForRoute(int routeID) async {
    try {
      debugPrint('Creating test stops for route ID: $routeID');

      // Get route details to create meaningful test stops
      final routeDetails = await supabase
          .from('official_routes')
          .select(
              'route_name, origin_lat, origin_lng, destination_lat, destination_lng')
          .eq('officialroute_id', routeID)
          .single();

      if (routeDetails.isEmpty) {
        debugPrint('Could not find route details for ID: $routeID');
        return;
      }

      // Create test stops based on route origin and destination
      double originLat =
          double.tryParse(routeDetails['origin_lat']?.toString() ?? '0') ??
              14.6;
      double originLng =
          double.tryParse(routeDetails['origin_lng']?.toString() ?? '0') ??
              121.0;
      double destLat =
          double.tryParse(routeDetails['destination_lat']?.toString() ?? '0') ??
              14.7;
      double destLng =
          double.tryParse(routeDetails['destination_lng']?.toString() ?? '0') ??
              121.1;

      // Calculate midpoint for an intermediate stop
      double midLat = (originLat + destLat) / 2;
      double midLng = (originLng + destLng) / 2;

      // Insert test stops for this route
      await supabase.from('allowed_stops').insert([
        {
          'officialroute_id': routeID,
          'stop_name': 'Origin Stop - ${routeDetails['route_name']}',
          'stop_address': 'Starting point of ${routeDetails['route_name']}',
          'stop_lat': originLat.toString(),
          'stop_lng': originLng.toString(),
          'stop_order': 1,
          'is_active': true
        },
        {
          'officialroute_id': routeID,
          'stop_name': 'Midpoint Stop - ${routeDetails['route_name']}',
          'stop_address': 'Middle point of ${routeDetails['route_name']}',
          'stop_lat': midLat.toString(),
          'stop_lng': midLng.toString(),
          'stop_order': 2,
          'is_active': true
        },
        {
          'officialroute_id': routeID,
          'stop_name': 'Destination Stop - ${routeDetails['route_name']}',
          'stop_address': 'End point of ${routeDetails['route_name']}',
          'stop_lat': destLat.toString(),
          'stop_lng': destLng.toString(),
          'stop_order': 3,
          'is_active': true
        }
      ]);

      debugPrint('Successfully created test stops for route $routeID');
    } catch (e) {
      debugPrint('Error creating test stops for route $routeID: $e');
    }
  }

  Future<Stop?> findClosestStop(LatLng coordinates, int routeID) async {
    try {
      final stops = await getStopsInOrder(routeID);
      if (stops.isEmpty) return null;

      double minDistance = double.infinity;
      Stop? closestStop;

      for (var stop in stops) {
        final double distance = _calculatedDistance(
          coordinates.latitude,
          coordinates.longitude,
          stop.coordinates.latitude,
          stop.coordinates.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          closestStop = stop;
        }
      }

      return minDistance < 0.5 ? closestStop : null;
    } catch (e) {
      debugPrint('Error finding closest stop: $e');
      return null;
    }
  }

  double _calculatedDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371.0;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Get stops in order for a route
  Future<List<Stop>> getStopsInOrder(int routeID) async {
    try {
      final response = await supabase
          .from('allowed_stops')
          .select("*")
          .eq('officialroute_id', routeID)
          .eq('is_active', true)
          .order('stop_order');

      return response.map<Stop>((data) => Stop.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error getting stops in order for route $routeID: $e');
      return [];
    }
  }
}
