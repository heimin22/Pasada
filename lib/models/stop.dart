import 'package:google_maps_flutter/google_maps_flutter.dart';

class Stop {
  final int id;
  final int routeId;
  final String name;
  final String address;
  final LatLng coordinates;
  final int order;
  final bool isActive;

  Stop({
    required this.id,
    required this.routeId,
    required this.name,
    required this.address,
    required this.coordinates,
    required this.order,
    required this.isActive,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    // Safely parse numeric values from dynamic JSON
    final id = int.tryParse(
            json['id']?.toString() ?? json['stop_id']?.toString() ?? '') ??
        0;
    final routeId =
        int.tryParse(json['officialroute_id']?.toString() ?? '') ?? 0;
    final name = json['stop_name']?.toString() ?? '';
    final address = json['stop_address']?.toString() ?? '';
    final lat = double.tryParse(json['stop_lat']?.toString() ?? '') ?? 0.0;
    final lng = double.tryParse(json['stop_lng']?.toString() ?? '') ?? 0.0;
    final order = int.tryParse(json['stop_order']?.toString() ?? '') ?? 0;
    final isActive = json['is_active'] is bool
        ? json['is_active'] as bool
        : (json['is_active']?.toString().toLowerCase() == 'true');
    return Stop(
      id: id,
      routeId: routeId,
      name: name,
      address: address,
      coordinates: LatLng(lat, lng),
      order: order,
      isActive: isActive,
    );
  }

  // Create a method to generate test stops for a route
  static List<Stop> generateTestStopsForRoute(
      int routeId, Map<String, dynamic> routeDetails) {
    // Extract route coordinates
    double originLat =
        double.tryParse(routeDetails['origin_lat']?.toString() ?? '0') ?? 14.6;
    double originLng =
        double.tryParse(routeDetails['origin_lng']?.toString() ?? '0') ?? 121.0;
    double destLat =
        double.tryParse(routeDetails['destination_lat']?.toString() ?? '0') ??
            14.7;
    double destLng =
        double.tryParse(routeDetails['destination_lng']?.toString() ?? '0') ??
            121.1;

    // Calculate midpoint
    double midLat = (originLat + destLat) / 2;
    double midLng = (originLng + destLng) / 2;

    String routeName = routeDetails['route_name'] ?? 'Unknown Route';

    return [
      Stop(
        id: -1, // Use negative IDs for local test data
        routeId: routeId,
        name: 'Origin - $routeName',
        address: 'Starting point of $routeName',
        coordinates: LatLng(originLat, originLng),
        order: 1,
        isActive: true,
      ),
      Stop(
        id: -2,
        routeId: routeId,
        name: 'Midpoint - $routeName',
        address: 'Middle point of $routeName',
        coordinates: LatLng(midLat, midLng),
        order: 2,
        isActive: true,
      ),
      Stop(
        id: -3,
        routeId: routeId,
        name: 'Destination - $routeName',
        address: 'End point of $routeName',
        coordinates: LatLng(destLat, destLng),
        order: 3,
        isActive: true,
      ),
    ];
  }
}
