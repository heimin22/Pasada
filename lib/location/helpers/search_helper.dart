import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/location/autocompletePrediction.dart';
import 'package:pasada_passenger_app/location/placeAutocompleteResponse.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/models/stop.dart';
import 'package:pasada_passenger_app/network/networkUtilities.dart';

/// Helper class for search functionality
class SearchHelper {
  Timer? _debounce;
  TextEditingController? _searchController;
  VoidCallback? _searchChangedCallback;

  /// Initialize search with debounce
  void initializeSearch(
      TextEditingController searchController, VoidCallback onSearchChanged) {
    _searchController = searchController;
    _searchChangedCallback = onSearchChanged;
    searchController.addListener(onSearchChanged);
  }

  /// Handle search changes with debounce
  void onSearchChanged(
    TextEditingController searchController,
    Function() onClearResults, // Called to clear results immediately when empty
    Function(String) onSearchAllowedStops,
    Function(String) onPlaceAutocomplete,
  ) {
    // Cancel previous debounce timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final query = searchController.text.trim();

    // Clear results immediately if query is empty
    if (query.isEmpty) {
      onClearResults();
      return;
    }

    // Debounce the actual search operation (400ms delay)
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final currentQuery = searchController.text.trim();

      // Double-check query is still valid
      if (currentQuery.isEmpty) {
        onClearResults();
        return;
      }

      // If we have stops, search them first
      onSearchAllowedStops(currentQuery);
    });
  }

  /// Search allowed stops locally
  Future<List<Stop>> searchAllowedStops(
    String query,
    List<Stop> allowedStops,
    Function(LatLng) isLocationAlreadySelected,
  ) async {
    try {
      // Filter stops locally since we can't modify the database
      final filteredStops = allowedStops.where((stop) {
        final matchesQuery =
            stop.name.toLowerCase().contains(query.toLowerCase()) ||
                stop.address.toLowerCase().contains(query.toLowerCase());
        final notAlreadySelected = !isLocationAlreadySelected(stop.coordinates);
        return matchesQuery && notAlreadySelected;
      }).toList();

      return filteredStops;
    } catch (e) {
      debugPrint('Error searching stops: $e');
      return [];
    }
  }

  /// Perform place autocomplete search
  Future<List<AutocompletePrediction>> placeAutocomplete(String query) async {
    if (query.isEmpty) return [];

    final String apiKey = dotenv.env["ANDROID_MAPS_API_KEY"] ?? '';
    if (apiKey.isEmpty) return [];

    Uri uri = Uri.https(
      "maps.googleapis.com",
      "maps/api/place/autocomplete/json",
      {
        "input": query,
        "key": apiKey,
        "components": "country:PH",
      },
    );

    try {
      final response = await NetworkUtility.fetchUrl(uri);
      if (response != null) {
        final result =
            PlaceAutocompleteResponse.parseAutocompleteResult(response);
        return result.prediction ?? [];
      }
    } catch (e) {
      debugPrint('Error in place autocomplete: $e');
    }
    return [];
  }

  /// Handle place selection
  Future<SelectedLocation?> handlePlaceSelection(
    AutocompletePrediction prediction,
    Function(LatLng) isLocationAlreadySelected,
    Function(LatLng) checkPickupDistance,
    Function(LatLng) isLocationNearFinalStop,
    int? routeID,
    bool isPickup,
  ) async {
    final apiKey = dotenv.env['ANDROID_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) return null;

    final uri = Uri.https(
      "maps.googleapis.com",
      "maps/api/place/details/json",
      {
        "place_id": prediction.placeID,
        "key": apiKey,
        "fields": "geometry,name"
      },
    );

    final response = await NetworkUtility.fetchUrl(uri);
    if (response != null) {
      final data = json.decode(response);
      final location = data['result']['geometry']['location'];
      final selectedLocation = SelectedLocation(
        prediction.description!,
        LatLng(location['lat'], location['lng']),
      );

      // Check if this location is already selected
      if (isLocationAlreadySelected(selectedLocation.coordinates)) {
        return null; // Will be handled by the calling function
      }

      if (isPickup) {
        // Check pickup distance
        // This will be handled by the calling function
      }

      // Additional check for final stop
      if (isPickup && routeID != null) {
        final isNearFinalStop =
            await isLocationNearFinalStop(selectedLocation.coordinates);
        if (isNearFinalStop) {
          return null; // Will be handled by the calling function
        }
      }

      return selectedLocation;
    }
    return null;
  }

  /// Reverse geocode a position
  Future<SelectedLocation?> reverseGeocode(LatLng position) async {
    final apiKey = dotenv.env['ANDROID_MAPS_API_KEY'] ?? '';
    final uri = Uri.https("maps.googleapis.com", "maps/api/geocode/json", {
      "latlng": "${position.latitude},${position.longitude}",
      "key": apiKey,
    });

    try {
      final response = await NetworkUtility.fetchUrl(uri);
      if (response == null) return null;

      final data = json.decode(response);
      if (data['status'] == 'REQUEST_DENIED') {
        return null;
      }

      if (data['results'] != null && data['results'].isNotEmpty) {
        return SelectedLocation(
          data['results'][0]['formatted_address'],
          position,
        );
      }
    } catch (e) {
      debugPrint("Error in reverseGeocode: $e");
    }
    return null;
  }

  /// Dispose resources
  void dispose() {
    // Cancel and clear debounce timer
    _debounce?.cancel();
    _debounce = null;

    // Remove listener from text controller if it exists
    if (_searchController != null && _searchChangedCallback != null) {
      _searchController!.removeListener(_searchChangedCallback!);
    }

    // Clear references
    _searchController = null;
    _searchChangedCallback = null;
  }
}
