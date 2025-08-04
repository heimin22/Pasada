import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:pasada_passenger_app/network/networkUtilities.dart';
import 'package:pasada_passenger_app/services/traffic_service.dart';
import 'package:pasada_passenger_app/services/route_service.dart';
import 'package:pasada_passenger_app/widgets/route_selection_widget.dart';
import 'package:pasada_passenger_app/widgets/rush_hour_dialog.dart';
import 'package:pasada_passenger_app/widgets/alert_sequence_dialog.dart';

class RouteSelection extends StatefulWidget {
  const RouteSelection({super.key});

  @override
  State<RouteSelection> createState() => _RouteSelectionState();
}

class _RouteSelectionState extends State<RouteSelection> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _filteredRoutes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    _searchController.addListener(_filterRoutes);
  }

  void _filterRoutes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRoutes = _routes.where((route) {
        final routeName = route['route_name'].toString().toLowerCase();
        final description = route['description'].toString().toLowerCase();
        return routeName.contains(query) || description.contains(query);
      }).toList();
    });
  }

  Future<void> _loadRoutes() async {
    try {
      setState(() => _isLoading = true);

      final response = await Supabase.instance.client
          .from('official_routes')
          .select(
              'route_name, description, origin_lat, origin_lng, destination_lat, destination_lng, intermediate_coordinates, origin_name, destination_name, status')
          .eq('status', 'active')
          .order('route_name');

      if (response.isNotEmpty) {
        final statuses = response.map((route) => route['status']).toSet();
        debugPrint('Available statuses: $statuses');
      } else {
        debugPrint('No routes found in the database');
        if (mounted) {
          setState(() {
            _routes = [];
            _filteredRoutes = [];
            _isLoading = false;
          });
          Fluttertoast.showToast(
            msg: 'No routes available',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xFFF5F5F5),
            textColor: Color(0xFF121212),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _routes = List<Map<String, dynamic>>.from(response);
          _filteredRoutes = _routes;
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint("Error loading routes: $error");
      if (mounted) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: 'Error loading routes: $error',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Color(0xFFF5F5F5),
          textColor: Color(0xFF121212),
        );
      }
    }
  }

  void _selectRoute(Map<String, dynamic> route) async {
    // Make sure the route has an ID field
    if (route['officialroute_id'] == null) {
      // Try to get the ID from the database
      try {
        final routeDetails = await Supabase.instance.client
            .from('official_routes')
            .select('officialroute_id')
            .eq('route_name', route['route_name'])
            .single();

        if (routeDetails.isNotEmpty) {
          route['officialroute_id'] = routeDetails['officialroute_id'];
        }
      } catch (e) {
        debugPrint('Error retrieving route ID: $e');
      }
    }

    // Process coordinates and get polyline before returning
    if (route['origin_lat'] != null &&
        route['origin_lng'] != null &&
        route['destination_lat'] != null &&
        route['destination_lng'] != null) {
      final originLatLng = LatLng(
        double.parse(route['origin_lat'].toString()),
        double.parse(route['origin_lng'].toString()),
      );

      final destinationLatLng = LatLng(
        double.parse(route['destination_lat'].toString()),
        double.parse(route['destination_lng'].toString()),
      );

      route['origin_coordinates'] = originLatLng;
      route['destination_coordinates'] = destinationLatLng;

      // Process intermediate coordinates
      if (route['intermediate_coordinates'] != null) {
        // If it's a string, try to parse it as JSON
        if (route['intermediate_coordinates'] is String) {
          try {
            route['intermediate_coordinates'] =
                jsonDecode(route['intermediate_coordinates']);
          } catch (e) {
            debugPrint('Failed to parse intermediate_coordinates: $e');
          }
        }

        // Get polyline coordinates for the route
        try {
          final polylineCoordinates = await _getRoutePolyline(
            originLatLng,
            destinationLatLng,
            route['intermediate_coordinates'],
          );
          route['polyline_coordinates'] = polylineCoordinates;
        } catch (e) {
          debugPrint('Error getting polyline: $e');
        }
      }
    }

    // Show heavy traffic alert if density is high
    if (route.containsKey('origin_coordinates') &&
        route.containsKey('destination_coordinates')) {
      final origin = route['origin_coordinates'] as LatLng;
      final destination = route['destination_coordinates'] as LatLng;
      final isHeavyTraffic =
          await TrafficService().isRouteUnderHeavyTraffic(origin, destination);
      if (isHeavyTraffic) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertSequenceDialog(
            pages: const [RushHourDialogContent()],
          ),
        );
      }
    }

    // Save the route for persistence
    await RouteService.saveRoute(route);

    Navigator.pop(context, route);
  }

  Future<List<LatLng>> _getRoutePolyline(LatLng origin, LatLng destination,
      List<dynamic> intermediatePoints) async {
    try {
      final String apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;
      if (apiKey.isEmpty) {
        debugPrint('API key not found');
        return [];
      }
      // Convert intermediate coordinates to waypoints format
      List<Map<String, dynamic>> intermediates = [];
      if (intermediatePoints.isNotEmpty) {
        for (var point in intermediatePoints) {
          if (point is Map &&
              point.containsKey('lat') &&
              point.containsKey('lng')) {
            intermediates.add({
              'location': {
                'latLng': {
                  'latitude': double.parse(point['lat'].toString()),
                  'longitude': double.parse(point['lng'].toString())
                }
              }
            });
          }
        }
      }

      // Routes API request
      final uri = Uri.parse(
          'https://routes.googleapis.com/directions/v2:computeRoutes');
      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
      };

      final body = jsonEncode({
        'origin': {
          'location': {
            'latLng': {
              'latitude': origin.latitude,
              'longitude': origin.longitude,
            },
          },
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destination.latitude,
              'longitude': destination.longitude,
            },
          },
        },
        'intermediates': intermediates,
        'travelMode': 'DRIVE',
        'polylineEncoding': 'ENCODED_POLYLINE',
      });

      final response =
          await NetworkUtility.postUrl(uri, headers: headers, body: body);
      if (response == null) return [];

      final data = json.decode(response);
      if (data['routes'] == null || data['routes'].isEmpty) return [];

      final polyline = data['routes'][0]['polyline']?['encodedPolyline'];
      if (polyline == null) return [];

      // Decode the polyline
      List<PointLatLng> decodedPolyline =
          PolylinePoints.decodePolyline(polyline);
      return decodedPolyline
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } catch (e) {
      debugPrint('Error generating polyline: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: buildAppBar(isDarkMode),
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF2F2F2),
      body: Column(
        children: [
          Form(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextFormField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212),
                ),
                decoration: InputDecoration(
                  fillColor: isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFF5F5F5),
                  filled: true,
                  border: InputBorder.none,
                  hintText: 'Search Route',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    color: isDarkMode
                        ? const Color(0xFFAAAAAA)
                        : const Color(0xFF515151),
                  ),
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    margin: const EdgeInsets.only(right: 8), // Added margin
                    child: Icon(
                      Icons.route,
                      size: 20,
                      color: isDarkMode
                          ? const Color(0xFFAAAAAA)
                          : const Color(0xFF515151),
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDarkMode
                            ? const Color(0xFFFFCE21)
                            : const Color(0xFF067837),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredRoutes.length,
                    itemBuilder: (context, index) {
                      final route = _filteredRoutes[index];
                      return RouteSelectionWidget(
                        routeName: route['route_name'] ?? 'Unknown Route',
                        onTap: () => _selectRoute(route),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget buildAppBar(bool isDarkMode) {
    return AppBar(
      backgroundColor:
          isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
      elevation: 4,
      leading: Padding(
        padding: const EdgeInsets.only(left: 17),
        child: CircleAvatar(
          backgroundColor:
              isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
          radius: 15,
          child: Icon(
            Icons.route,
            size: 20,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ),
      ),
      title: Text(
        'Select Route',
        style: TextStyle(
          color: isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        CircleAvatar(
          backgroundColor:
              isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
          ),
        ),
        const SizedBox(width: 16)
      ],
    );
  }
}
