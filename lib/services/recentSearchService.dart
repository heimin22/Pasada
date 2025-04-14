import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pasada_passenger_app/location/recentSearch.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';

class RecentSearchService {
  static const String key = 'recent_searches';
  static const int maxRecentSearches = 5;

  static Future<List<RecentSearch>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searchesJson = prefs.getStringList(key) ?? [];

    return searchesJson
        .map((json) => RecentSearch.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> addRecentSearch(SelectedLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = await getRecentSearches();

    // remove if already exists
    searches.removeWhere((search) => search.address == location.address);

    // add new search to the beginning of the list
    searches.insert(0,
        RecentSearch(location.address, location.coordinates, DateTime.now()));

    // limit to maxRecentSearches
    while (searches.length > maxRecentSearches) {
      searches.removeLast();
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
}
