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
        final routeName = route['route_name'].toString().toLowerCase();
        final description = route['description'].toString().toLowerCase();
        return routeName.contains(query) || description.contains(query);
      }).toList();
    });
  }

  Future<void> _loadRoutes() async {
    try {
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
          .select('route_name, description')
          .order('route_name');
      // .select('route_name, description')
      // .eq('status', 'active');

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
        debugPrint('Routes loaded: ${_routes.length}');
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
                      return SizedBox(
                        height: 57,
                        child: ListTile(
                          horizontalTitleGap: 0,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          leading: Icon(
                            Icons.route,
                            size: 16,
                            color: isDarkMode
                                ? const Color(0xFFF5F5F5)
                                : const Color(0xFF121212),
                          ),
                          title: Text(
                            route['route_name'] ?? 'Unknown Route',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFF121212),
                            ),
                          ),
                          subtitle: Text(
                            route['description'] ?? 'No description available',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: isDarkMode
                                  ? const Color(0xFFAAAAAA)
                                  : const Color(0xFF515151),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context, route);
                          },
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
