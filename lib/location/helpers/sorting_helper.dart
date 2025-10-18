import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/location/recentSearch.dart';
import 'package:pasada_passenger_app/models/stop.dart';

import 'distance_helper.dart';

/// Helper class for sorting and filtering stops and recent searches
class SortingHelper {
  final DistanceHelper _distanceHelper = DistanceHelper();

  String _currentSortOption = 'order';
  String _selectedFilter = 'all';

  // Getters
  String get currentSortOption => _currentSortOption;
  String get selectedFilter => _selectedFilter;

  // Setters
  void setSortOption(String option) {
    _currentSortOption = option;
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
  }

  /// Apply sorting to stops based on current sort option
  List<Stop> applySorting(List<Stop> stops, LatLng? currentLocation) {
    final sortedStops = List<Stop>.from(stops);

    switch (_currentSortOption) {
      case 'name':
        sortedStops.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'distance':
        if (currentLocation != null) {
          sortedStops.sort((a, b) {
            final distanceA = _distanceHelper.getCachedDistance(
                currentLocation, a.coordinates);
            final distanceB = _distanceHelper.getCachedDistance(
                currentLocation, b.coordinates);
            return distanceA.compareTo(distanceB);
          });
        }
        break;
      case 'order':
      default:
        sortedStops.sort((a, b) => a.order.compareTo(b.order));
        break;
    }
    return sortedStops;
  }

  /// Apply filtering to stops based on current filter
  List<Stop> applyFiltering(List<Stop> stops, LatLng? currentLocation) {
    List<Stop> filteredStops = stops;

    switch (_selectedFilter) {
      case 'nearby':
        if (currentLocation == null) return stops;
        filteredStops = stops.where((stop) {
          final distance = _distanceHelper.getCachedDistance(
              currentLocation, stop.coordinates);
          return distance <= 2000; // Within 2km
        }).toList();
        break;
      case 'all':
      default:
        filteredStops = stops;
    }

    return filteredStops;
  }

  /// Get filtered and sorted stops
  List<Stop> getFilteredAndSortedStops(
      List<Stop> stops, LatLng? currentLocation) {
    final filteredStops = applyFiltering(stops, currentLocation);
    return applySorting(filteredStops, currentLocation);
  }

  /// Sort recent searches by distance
  List<RecentSearch> sortRecentSearchesByDistance(
      List<RecentSearch> searches, LatLng? currentLocation) {
    if (currentLocation == null) return searches;

    final sortedSearches = List<RecentSearch>.from(searches);
    sortedSearches.sort((a, b) {
      final distanceA =
          _distanceHelper.getCachedDistance(currentLocation, a.coordinates);
      final distanceB =
          _distanceHelper.getCachedDistance(currentLocation, b.coordinates);
      return distanceA.compareTo(distanceB);
    });

    return sortedSearches;
  }

  /// Get filter label
  String getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'All Stops';
      case 'nearby':
        return 'Nearby (2km)';
      default:
        return 'All';
    }
  }

  /// Get available filter options
  List<String> getFilterOptions() {
    return ['all', 'nearby'];
  }

  /// Get available sort options
  List<String> getSortOptions() {
    return ['order', 'name', 'distance'];
  }

  /// Clear distance cache
  void clearDistanceCache() {
    _distanceHelper.clearCache();
  }
}
