import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        final _routeName = route['route_name'].toString().toLowerCase();
        final _description = route['description'].toString().toLowerCase();
        return _routeName.contains(query) || _description.contains(query);
      }).toList();
    });
  }

  Future<void> _loadRoutes() async {
    try {
      final response = await Supabase.instance.client
          .from('official_routes')
          .select('route_name, description')
          .eq('status', 'active');

      if (mounted) {
        setState(() {
          _routes = List<Map<String, dynamic>>.from(response);
          _filteredRoutes = _routes;
          _isLoading = false;
        });
      }
    } catch (error) {
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: buildAppBar(_isDarkMode),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search a route...',
                hintStyle: TextStyle(
                  color: _isDarkMode ? Color(0xFFAAAAAA) : Color(0xFF515151),
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: _isDarkMode
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFF5F5F5),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00CC58)),
                  )
                : ListView.builder(
                    itemCount: _filteredRoutes.length,
                    itemBuilder: (context, index) {
                      final _route = _filteredRoutes[index];
                      return ListTile(
                        title: Text(
                          _route['route_name'] ?? 'Unknown Route',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _isDarkMode
                                ? Color(0xFFF5F5F5)
                                : Color(0xFF121212),
                          ),
                        ),
                        subtitle: Text(
                          _route['description'] ?? 'No description available',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: _isDarkMode
                                ? Color(0xFFAAAAAA)
                                : Color(0xFF515151),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context, _route);
                        },
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
      title: Text(
        'Select Route',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
        ),
      ),
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      foregroundColor:
          isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
      elevation: 1.0,
    );
  }
}
