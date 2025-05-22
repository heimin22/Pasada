import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pasada_passenger_app/location/recentSearch.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';

class RecentSearchService {
  static const String key = 'recent_searches';
  static const int maxRecentSearches = 5;

  // Get all recent searches
  static Future<List<RecentSearch>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searchesJson = prefs.getStringList(key) ?? [];

    return searchesJson
        .map((json) => RecentSearch.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get recent searches filtered by route ID
  static Future<List<RecentSearch>> getRecentSearchesByRoute(
      int? routeId) async {
    if (routeId == null) {
      return getRecentSearches();
    }

    final allSearches = await getRecentSearches();

    // Filter searches by route ID
    return allSearches.where((search) => search.routeId == routeId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> addRecentSearch(SelectedLocation location,
      {int? routeId}) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = await getRecentSearches();

    // remove if already exists (with same address and route ID)
    searches.removeWhere((search) =>
        search.address == location.address && search.routeId == routeId);

    // add new search to the beginning of the list
    searches.insert(
        0,
        RecentSearch(location.address, location.coordinates, DateTime.now(),
            routeId: routeId));

    // limit to maxRecentSearches per route
    var routeSearches =
        searches.where((search) => search.routeId == routeId).toList();
    if (routeSearches.length > maxRecentSearches) {
      // Find the oldest search with this route ID
      routeSearches.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final oldestRouteSearch = routeSearches.first;
      searches.remove(oldestRouteSearch);
    }

    // save to shared prefs
    await prefs.setStringList(
      key,
      searches.map((search) => jsonEncode(search.toJson())).toList(),
    );
  }

  static Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // Clear recent searches for a specific route
  static Future<void> clearRecentSearchesByRoute(int routeId) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = await getRecentSearches();

    // Remove searches matching the route ID
    searches.removeWhere((search) => search.routeId == routeId);

    // Save the filtered list
    await prefs.setStringList(
      key,
      searches.map((search) => jsonEncode(search.toJson())).toList(),
    );
  }
}
