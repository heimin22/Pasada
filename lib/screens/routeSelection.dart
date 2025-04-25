import 'package:flutter/material.dart';
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Selection')),
    );
  }
}
