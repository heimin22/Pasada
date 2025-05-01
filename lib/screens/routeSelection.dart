import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

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

      final session = Supabase.instance.client.auth.currentSession;
      debugPrint('Current session: ${session != null ? "Active" : "None"}');
      if (session != null) {
        debugPrint('User ID: ${session.user.id}');
      }

      debugPrint('Attempting to query official_routes table...');

      final countResponse = await Supabase.instance.client
          .from('official_routes')
          .select('*')
          .count(CountOption.exact);

      debugPrint('Count Response: $countResponse');

      final response = await Supabase.instance.client
          .from('official_routes')
          .select(
              'route_name, description, origin_lat, origin_lng, destination_lat, destination_lng, intermediate_coordinates, origin_name, destination_name, status')
          .eq('status', 'active')
          .order('route_name');

      debugPrint('Raw Response: $response');
      debugPrint('Response type: ${response.runtimeType}');
      debugPrint('Supabase Response: $response');

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
    // Debug the route data before returning
    debugPrint('Selected route data: $route');

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
        debugPrint(
            'Route has intermediate coordinates: ${route['intermediate_coordinates']}');

        // If it's a string, try to parse it as JSON
        if (route['intermediate_coordinates'] is String) {
          try {
            route['intermediate_coordinates'] =
                jsonDecode(route['intermediate_coordinates']);
            debugPrint(
                'Parsed intermediate_coordinates from string to: ${route['intermediate_coordinates']}');
          } catch (e) {
            debugPrint('Failed to parse intermediate_coordinates: $e');
          }
        }
      } else {
        debugPrint('No intermediate coordinates for this route');
      }
    }

    Navigator.pop(context, route);
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
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        elevation: 1,
                        color:
                            isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _selectRoute(route),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? const Color(0xFF2A2A2A)
                                        : const Color(0xFFEEEEEE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.route,
                                    size: 20,
                                    color: const Color(0xFF00CC58),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        route['route_name'] ?? 'Unknown Route',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode
                                              ? const Color(0xFFF5F5F5)
                                              : const Color(0xFF121212),
                                        ),
                                      ),
                                      if (route['description'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          route['description'],
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: isDarkMode
                                                ? const Color(0xFFAAAAAA)
                                                : const Color(0xFF515151),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right,
                                  color: isDarkMode
                                      ? const Color(0xFFAAAAAA)
                                      : const Color(0xFF515151),
                                ),
                              ],
                            ),
                          ),
                        ),
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
