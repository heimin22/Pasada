import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pasada_passenger_app/location/autocompletePrediction.dart';
import 'package:pasada_passenger_app/location/recentSearch.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/models/stop.dart';
import 'package:pasada_passenger_app/network/networkUtilities.dart';
import 'package:pasada_passenger_app/screens/homeScreen.dart';
import 'package:pasada_passenger_app/services/allowedStopsServices.dart';
import 'package:pasada_passenger_app/services/recentSearchService.dart';
import 'package:pasada_passenger_app/widgets/optimized_svg_widget.dart';
import 'package:pasada_passenger_app/widgets/responsive_dialogs.dart';
import 'package:pasada_passenger_app/widgets/skeleton.dart';

import 'helpers/distance_helper.dart';
import 'helpers/location_validation_helper.dart';
import 'helpers/search_helper.dart';
import 'helpers/sorting_helper.dart';
import 'helpers/ui_components_helper.dart';
import 'locationListTile.dart';

class SearchLocationScreen extends StatefulWidget {
  final bool isPickup;
  final int? routeID;
  final Map<String, dynamic>? routeDetails;
  final List<LatLng>? routePolyline;
  final int? pickupOrder;
  final SelectedLocation? selectedPickUpLocation;
  final SelectedLocation? selectedDropOffLocation;

  const SearchLocationScreen({
    super.key,
    required this.isPickup,
    this.routeID,
    this.routeDetails,
    this.routePolyline,
    this.pickupOrder,
    this.selectedPickUpLocation,
    this.selectedDropOffLocation,
  });

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  final TextEditingController searchController = TextEditingController();
  List<AutocompletePrediction> placePredictions = [];
  List<RecentSearch> recentSearches = [];
  List<Stop> allowedStops = [];
  HomeScreenPageState? homeScreenState;
  bool hasMoreStops = true;
  int _currentStopOffset = 0;
  int _totalStopsCount = 0;
  static const int _pageSize = 50; // Load 50 stops at a time
  HomeScreenPageState? homeScreenPageState;
  LatLng? currentLocation;
  StopsService _stopsService = StopsService();

  // ValueNotifiers for frequently changing data to optimize rebuilds
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isLoadingMoreNotifier = ValueNotifier(false);
  final ValueNotifier<List<AutocompletePrediction>> _placePredictionsNotifier =
      ValueNotifier([]);
  final ValueNotifier<List<Stop>> _filteredStopsNotifier = ValueNotifier([]);

  // Cache for filtered stops to avoid recomputing in build
  List<Stop>? _cachedFilteredStops;
  List<Stop>? _cachedFilteredStopsAllowedStops;
  int? _cachedFilteredStopsAllowedStopsLength;
  LatLng? _cachedFilteredStopsLocation;
  String? _cachedFilteredStopsSortOption;
  String? _cachedFilteredStopsFilter;

  // Pre-computed distances cache (key: coordinates string, value: distance in meters)
  final Map<String, double> _stopDistances = {};
  final Map<String, double> _recentSearchDistances = {};

  // Helper classes
  final DistanceHelper _distanceHelper = DistanceHelper();
  final SortingHelper _sortingHelper = SortingHelper();
  final UIComponentsHelper _uiComponentsHelper = UIComponentsHelper();
  final LocationValidationHelper _validationHelper = LocationValidationHelper();
  final SearchHelper _searchHelper = SearchHelper();

  @override
  void initState() {
    super.initState();
    _searchHelper.initializeSearch(searchController, onSearchChanged);
    _stopsService = StopsService();

    // Initialize location service
    _initializeLocation();

    // Load stops and recent searches
    loadStops();
    loadRecentSearches();
  }

  // Helper method to check if a location is already selected
  bool _isLocationAlreadySelected(LatLng coordinates) {
    return _validationHelper.isLocationAlreadySelected(
      coordinates,
      widget.isPickup,
      widget.selectedPickUpLocation,
      widget.selectedDropOffLocation,
    );
  }

  // Clear distance cache when location changes
  void _clearDistanceCache() {
    _distanceHelper.clearCache();
    _stopDistances.clear();
    _recentSearchDistances.clear();
  }

  /// Pre-compute distances for all stops
  void _precomputeStopDistances(List<Stop> stops) {
    if (currentLocation == null) {
      _stopDistances.clear();
      return;
    }

    _stopDistances.clear();
    for (final stop in stops) {
      final key = '${stop.coordinates.latitude}_${stop.coordinates.longitude}';
      _stopDistances[key] = _distanceHelper.getCachedDistance(
        currentLocation!,
        stop.coordinates,
      );
    }
  }

  /// Pre-compute distances for all recent searches
  void _precomputeRecentSearchDistances(List<RecentSearch> searches) {
    if (currentLocation == null) {
      _recentSearchDistances.clear();
      return;
    }

    _recentSearchDistances.clear();
    for (final search in searches) {
      final key =
          '${search.coordinates.latitude}_${search.coordinates.longitude}';
      _recentSearchDistances[key] = _distanceHelper.getCachedDistance(
        currentLocation!,
        search.coordinates,
      );
    }
  }

  /// Get pre-computed distance for a stop
  double? _getStopDistance(Stop stop) {
    final key = '${stop.coordinates.latitude}_${stop.coordinates.longitude}';
    return _stopDistances[key];
  }

  /// Get pre-computed distance for a recent search
  double? _getRecentSearchDistance(RecentSearch search) {
    final key =
        '${search.coordinates.latitude}_${search.coordinates.longitude}';
    return _recentSearchDistances[key];
  }

  Future<void> loadStops({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMoreNotifier.value || !hasMoreStops) return;
      _isLoadingMoreNotifier.value = true;
    } else {
      _isLoadingNotifier.value = true;
      _currentStopOffset = 0;
      hasMoreStops = true;
      allowedStops = [];
      _filteredStopsNotifier.value = [];
    }

    try {
      List<Stop> stops = [];

      if (widget.routeID != null) {
        // Get total count if first load
        if (!loadMore) {
          _totalStopsCount =
              await _stopsService.getStopsCountForRoute(widget.routeID!);
        }

        // Load paginated stops
        stops = await _stopsService.getStopsForRoutePaginated(
          widget.routeID!,
          limit: _pageSize,
          offset: _currentStopOffset,
        );

        // For pick-up locations, filter out the last stop (end of route)
        if (widget.isPickup && stops.isNotEmpty) {
          // Find the stop with the highest order (the last stop)
          Stop? lastStop;
          int highestOrder = -1;

          for (var stop in stops) {
            if (stop.order > highestOrder) {
              highestOrder = stop.order;
              lastStop = stop;
            }
          }

          if (lastStop != null) {
            // Remove the last stop from the list
            stops = stops.where((stop) => stop.order != highestOrder).toList();
          }
        }
        // For drop-off locations, exclude stops at or before the pick-up stop order
        // Also exclude the first stop (order 1)
        else if (!widget.isPickup && widget.pickupOrder != null) {
          stops = stops
              .where(
                  (stop) => stop.order > widget.pickupOrder! && stop.order != 1)
              .toList();
        }
        // For drop-off locations without pickupOrder, still exclude the first stop (order 1)
        else if (!widget.isPickup) {
          stops = stops.where((stop) => stop.order != 1).toList();
        }
      } else {
        // Get total count if first load
        if (!loadMore) {
          _totalStopsCount = await _stopsService.getAllActiveStopsCount();
        }

        // Load paginated stops
        stops = await _stopsService.getAllActiveStopsPaginated(
          limit: _pageSize,
          offset: _currentStopOffset,
        );

        // For drop-off locations, exclude the first stop (order 1)
        if (!widget.isPickup) {
          stops = stops.where((stop) => stop.order != 1).toList();
        }
      }

      // Filter out already selected locations
      stops = stops
          .where((stop) => !_isLocationAlreadySelected(stop.coordinates))
          .toList();

      if (mounted) {
        // Pre-compute distances for new stops
        _precomputeStopDistances(stops);

        setState(() {
          if (loadMore) {
            // Append to existing list
            allowedStops.addAll(stops);
          } else {
            // Replace with new list
            allowedStops = stops;
          }

          // Clear cache since stops changed
          _clearFilteredStopsCache();

          // Update pagination state
          // Increment offset by page size (not filtered count) for next page
          if (loadMore) {
            _currentStopOffset += _pageSize;
          } else {
            _currentStopOffset = _pageSize; // Start at first page size
          }

          // Check if we have more stops to load
          // Compare loaded offset with total count
          hasMoreStops = _currentStopOffset < _totalStopsCount;

          if (loadMore) {
            _isLoadingMoreNotifier.value = false;
          } else {
            _isLoadingNotifier.value = false;
          }
        });

        // If we have more stops and initial load, continue loading in background
        if (!loadMore && hasMoreStops && stops.length >= _pageSize) {
          // Load next page in background (without blocking UI)
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && hasMoreStops && !_isLoadingMoreNotifier.value) {
              loadStops(loadMore: true);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading stops: $e');
      if (mounted) {
        if (loadMore) {
          _isLoadingMoreNotifier.value = false;
        } else {
          _isLoadingNotifier.value = false;
        }
      }
    }
  }

  /// Load more stops when user scrolls near the end
  Future<void> _loadMoreStops() async {
    if (!hasMoreStops || _isLoadingMoreNotifier.value) return;
    await loadStops(loadMore: true);
  }

  Future<void> loadRecentSearches() async {
    // Load route-specific recent searches if a route ID is provided
    List<RecentSearch> searches = widget.routeID != null
        ? await RecentSearchService.getRecentSearchesByRoute(widget.routeID)
        : await RecentSearchService.getRecentSearches();

    if (widget.isPickup && widget.routeID != null && mounted) {
      try {
        final List<Stop> stopsForRoute =
            await _stopsService.getStopsForRoute(widget.routeID!);
        if (stopsForRoute.isNotEmpty) {
          Stop? lastStop;
          int highestOrder = -1;
          for (var stop in stopsForRoute) {
            if (stop.order > highestOrder) {
              highestOrder = stop.order;
              lastStop = stop;
            }
          }

          if (lastStop != null) {
            // Define a radius to consider a recent search as "the last stop"
            // 100 meters
            const double exclusionRadiusMeters = 100.0;

            searches = searches.where((recent) {
              final distance = _distanceHelper.calculateDistance(
                  recent.coordinates, lastStop!.coordinates);
              return distance > exclusionRadiusMeters;
            }).toList();
          }
        }
      } catch (e) {
        debugPrint('Error filtering recent searches against last stop: $e');
      }
    }
    // For drop-off locations, exclude recent searches at or before the pick-up stop order
    // Also exclude recent searches at the first stop (order 1)
    if (!widget.isPickup &&
        widget.routeID != null &&
        widget.pickupOrder != null &&
        mounted) {
      try {
        final int routeId = widget.routeID!;
        final int pickupOrder = widget.pickupOrder!;
        final List<RecentSearch> filtered = [];
        for (var recent in searches) {
          final Stop? closestStop =
              await _stopsService.findClosestStop(recent.coordinates, routeId);
          if (closestStop != null &&
              closestStop.order > pickupOrder &&
              closestStop.order != 1) {
            filtered.add(recent);
          }
        }
        searches = filtered;
      } catch (e) {
        debugPrint('Error filtering recent searches for drop-off: $e');
      }
    }
    // For drop-off locations without pickupOrder, exclude recent searches at the first stop (order 1)
    else if (!widget.isPickup && widget.routeID != null && mounted) {
      try {
        final int routeId = widget.routeID!;
        final List<RecentSearch> filtered = [];
        for (var recent in searches) {
          final Stop? closestStop =
              await _stopsService.findClosestStop(recent.coordinates, routeId);
          if (closestStop != null && closestStop.order != 1) {
            filtered.add(recent);
          } else if (closestStop == null) {
            // If no closest stop found, include it (might be a custom location)
            filtered.add(recent);
          }
        }
        searches = filtered;
      } catch (e) {
        debugPrint(
            'Error filtering recent searches for drop-off (no pickupOrder): $e');
      }
    }
    // For drop-off locations without routeID, exclude recent searches at the first stop (order 1)
    // Check against all stops with order 1 from all routes
    else if (!widget.isPickup && mounted) {
      try {
        final List<RecentSearch> filtered = [];
        final List<Stop> allStops = await _stopsService.getAllActiveStops();
        final List<Stop> firstStops =
            allStops.where((stop) => stop.order == 1).toList();

        if (firstStops.isNotEmpty) {
          const double exclusionRadiusMeters = 100.0;
          for (var recent in searches) {
            bool isNearFirstStop = false;
            // Check if recent search is close to any stop with order 1
            for (var firstStop in firstStops) {
              final distance = _distanceHelper.calculateDistance(
                  recent.coordinates, firstStop.coordinates);
              if (distance <= exclusionRadiusMeters) {
                isNearFirstStop = true;
                break;
              }
            }
            // Only include if not near any first stop
            if (!isNearFirstStop) {
              filtered.add(recent);
            }
          }
          searches = filtered;
        }
        // If no first stops found, keep all searches
      } catch (e) {
        debugPrint(
            'Error filtering recent searches for drop-off (no routeID): $e');
      }
    }

    // Filter out already selected locations
    searches = searches
        .where((search) => !_isLocationAlreadySelected(search.coordinates))
        .toList();

    // Sort recent searches by distance if current location is available
    searches =
        _sortingHelper.sortRecentSearchesByDistance(searches, currentLocation);

    if (mounted) {
      // Pre-compute distances for recent searches
      _precomputeRecentSearchDistances(searches);

      setState(() {
        recentSearches = searches;
      });
    }
  }

  void onRecentSearchSelected(RecentSearch search) async {
    // Check if this location is already selected
    if (_isLocationAlreadySelected(search.coordinates)) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      await showDialog(
        context: context,
        builder: (context) => ResponsiveDialog(
          title: 'Location Already Selected',
          contentPadding: const EdgeInsets.all(24),
          content: Text(
            'This location is already selected as your ${widget.isPickup ? 'drop-off' : 'pick-up'} location. Please choose a different location.',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              fontSize: 13,
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                backgroundColor: const Color(0xFF00CC58),
                foregroundColor: const Color(0xFFF5F5F5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (widget.isPickup) {
      final shouldProceed = await checkPickupDistance(search.coordinates);
      if (!shouldProceed) return;

      // Check if the location is near the final stop
      if (widget.routeID != null) {
        final isNearFinalStop =
            await isLocationNearFinalStop(search.coordinates);
        if (isNearFinalStop) {
          // Show warning dialog
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          await showDialog(
            context: context,
            builder: (context) => ResponsiveDialog(
              title: 'Invalid Pick-up Location',
              contentPadding: const EdgeInsets.all(24),
              content: Text(
                'This location is too close to the final stop of the route. Please select a different pick-up location.',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    backgroundColor: const Color(0xFF00CC58),
                    foregroundColor: const Color(0xFFF5F5F5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
          return;
        }
      }
    }

    Navigator.pop(
      context,
      SelectedLocation(search.address, search.coordinates),
    );
  }

  void onStopSelected(Stop stop) async {
    // Check if this location is already selected
    if (_isLocationAlreadySelected(stop.coordinates)) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      await showDialog(
        context: context,
        builder: (context) => ResponsiveDialog(
          title: 'Location Already Selected',
          contentPadding: const EdgeInsets.all(24),
          content: Text(
            'This location is already selected as your ${widget.isPickup ? 'drop-off' : 'pick-up'} location. Please choose a different location.',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              fontSize: 13,
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                backgroundColor: const Color(0xFF00CC58),
                foregroundColor: const Color(0xFFF5F5F5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (widget.isPickup) {
      final shouldProceed = await checkPickupDistance(stop.coordinates);
      if (!shouldProceed) return;
    } else if (widget.routeID != null && widget.pickupOrder != null) {
      // This is a dropoff location, enforce stop order
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      if (stop.order <= widget.pickupOrder!) {
        await showDialog(
          context: context,
          builder: (context) => ResponsiveDialog(
            title: 'Invalid Stop Order',
            contentPadding: const EdgeInsets.all(24),
            content: Text(
              'Drop-off must be after pick-up for this route.',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                fontSize: 13,
                color: isDarkMode
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFF121212),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  backgroundColor: const Color(0xFF00CC58),
                  foregroundColor: const Color(0xFFF5F5F5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
        return;
      }
    }

    final selectedLocation = SelectedLocation(
      "${stop.name}\n${stop.address}",
      stop.coordinates,
    );

    // Save to recent searches with route ID
    await RecentSearchService.addRecentSearch(selectedLocation,
        routeId: widget.routeID);

    Navigator.pop(context, selectedLocation);
  }

  @override
  void dispose() {
    // Dispose ValueNotifiers
    _isLoadingNotifier.dispose();
    _isLoadingMoreNotifier.dispose();
    _placePredictionsNotifier.dispose();
    _filteredStopsNotifier.dispose();
    // Dispose search helper first (removes listener and cancels timer)
    _searchHelper.dispose();
    // Dispose text controller (listener already removed by search helper)
    searchController.dispose();
    super.dispose();
  }

  void onSearchChanged() {
    _searchHelper.onSearchChanged(
      searchController,
      () {
        // Clear search results immediately when query is empty
        if (mounted) {
          _filteredStopsNotifier.value = [];
          _placePredictionsNotifier.value = [];
          _isLoadingNotifier.value = false;
        }
      },
      (query) {
        // Set loading state before search (called after debounce)
        if (mounted) {
          _isLoadingNotifier.value = true;
        }
        searchAllowedStops(query);
      },
      (query) => placeAutocomplete(query),
    );
  }

  Future<void> searchAllowedStops(String query) async {
    // Check if query is still valid (might have changed during async operation)
    if (query != searchController.text.trim()) {
      return; // Query changed, abort this search
    }

    try {
      final filteredStops = await _searchHelper.searchAllowedStops(
        query,
        allowedStops,
        _isLocationAlreadySelected,
      );

      // Double-check query hasn't changed during async operation
      if (query != searchController.text.trim()) {
        return; // Query changed, ignore results
      }

      if (filteredStops.isNotEmpty) {
        if (mounted) {
          _filteredStopsNotifier.value = filteredStops;
          _placePredictionsNotifier.value = [];
          _isLoadingNotifier.value = false;
        }
      } else {
        // Only call placeAutocomplete if query still matches
        if (query == searchController.text.trim()) {
          await placeAutocomplete(query);
        }
      }
    } catch (e) {
      debugPrint('Error searching stops: $e');
      // Only call placeAutocomplete if query still matches and we're still searching
      if (query == searchController.text.trim() && mounted) {
        await placeAutocomplete(query);
      }
    }
  }

  Future<void> placeAutocomplete(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      if (mounted) {
        _placePredictionsNotifier.value = [];
        _isLoadingNotifier.value = false;
      }
      return;
    }

    // Check if query still matches (might have changed)
    if (trimmedQuery != searchController.text.trim()) {
      return; // Query changed, abort
    }

    try {
      final predictions = await _searchHelper.placeAutocomplete(trimmedQuery);

      // Final check before updating state
      if (mounted && trimmedQuery == searchController.text.trim()) {
        _placePredictionsNotifier.value = predictions;
        _isLoadingNotifier.value = false;
      }
    } catch (e) {
      debugPrint('Error in placeAutocomplete: $e');
      if (mounted && trimmedQuery == searchController.text.trim()) {
        _isLoadingNotifier.value = false;
      }
    }
  }

  void onPlaceSelected(AutocompletePrediction prediction) async {
    final apiKey = dotenv.env['ANDROID_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) return;
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
      if (_isLocationAlreadySelected(selectedLocation.coordinates)) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        await showDialog(
          context: context,
          builder: (context) => ResponsiveDialog(
            title: 'Location Already Selected',
            contentPadding: const EdgeInsets.all(24),
            content: Text(
              'This location is already selected as your ${widget.isPickup ? 'drop-off' : 'pick-up'} location. Please choose a different location.',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                fontSize: 13,
                color: isDarkMode
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFF121212),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  backgroundColor: const Color(0xFF00CC58),
                  foregroundColor: const Color(0xFFF5F5F5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
        return;
      }

      if (widget.isPickup) {
        final shouldProceed =
            await checkPickupDistance(selectedLocation.coordinates);
        if (!shouldProceed) return;

        // Additional check for final stop
        if (widget.routeID != null) {
          final isNearFinalStop =
              await isLocationNearFinalStop(selectedLocation.coordinates);
          if (isNearFinalStop) {
            // Show warning dialog that this is too close to the final stop
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            await showDialog(
              context: context,
              builder: (context) => ResponsiveDialog(
                title: 'Invalid Pick-up Location',
                contentPadding: const EdgeInsets.all(24),
                content: Text(
                  'This location is too close to the final stop of the route. Please select a different pick-up location.',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: isDarkMode
                        ? const Color(0xFFF5F5F5)
                        : const Color(0xFF121212),
                  ),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                      ),
                      backgroundColor: const Color(0xFF00CC58),
                      foregroundColor: const Color(0xFFF5F5F5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
            return;
          }
        }
      }

      // Save to recent searches with route ID
      await RecentSearchService.addRecentSearch(selectedLocation,
          routeId: widget.routeID);

      if (mounted) {
        Navigator.pop(context, selectedLocation);
      }
    }
  }

  Future<bool> checkPickupDistance(LatLng pickupLocation) async {
    return _validationHelper.checkPickupDistance(
        pickupLocation, currentLocation, context);
  }

  Future<void> _initializeLocation() async {
    try {
      final Location locationService = Location();
      final LocationData locationData = await locationService.getLocation();
      if (mounted) {
        // Clear distance cache when location changes
        _clearDistanceCache();

        // Batch all state updates together
        setState(() {
          currentLocation = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );
          // Pre-compute distances with new location (within setState for single rebuild)
          _precomputeStopDistances(allowedStops);
          _precomputeRecentSearchDistances(recentSearches);
          // Clear filtered stops cache since location affects distance sorting
          _clearFilteredStopsCache();
        });
      }
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        elevation: 4,
        leading: Padding(
          padding: const EdgeInsets.only(left: 17),
          child: CircleAvatar(
            backgroundColor:
                isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
            radius: 15,
            child: OptimizedSvgWidget(
              'assets/svg/navigation.svg',
              height: 16,
              width: 16,
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
          ),
        ),
        title: Text(
          'Set ${widget.isPickup ? 'Pick-up' : 'Drop-off'} Location',
          style: TextStyle(
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
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
      ),
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF2F2F2),
      body: Column(
        children: [
          Form(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextFormField(
                controller: searchController,
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
                  hintText: 'Search stops or locations...',
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
                    child: OptimizedSvgWidget(
                      'assets/svg/pindropoff.svg',
                      height: 12,
                      width: 12,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),
          Divider(
            height: 0,
            thickness: 2,
            color:
                isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFE9E9E9),
          ),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _isLoadingNotifier,
              builder: (context, isLoading, child) {
                return isLoading
                    ? Builder(
                        builder: (context) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          return ListSkeleton(
                            itemCount: 8,
                            screenWidth: screenWidth,
                            itemPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          );
                        },
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification notification) {
                          if (notification is ScrollUpdateNotification) {
                            final metrics = notification.metrics;
                            // Load more when user scrolls within 300 pixels of the end
                            if (metrics.pixels >=
                                metrics.maxScrollExtent - 300) {
                              _loadMoreStops();
                            }
                          }
                          return false;
                        },
                        child: ListView(
                          children: [
                            // Show recent searches if available and search is empty
                            if (searchController.text.isEmpty &&
                                recentSearches.isNotEmpty) ...[
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? const Color(0xFF1E1E1E)
                                      : const Color(0xFFF5F5F5),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(12)),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? const Color(0xFF333333)
                                        : const Color(0xFFE0E0E0),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.history,
                                              size: 18,
                                              color: Color(0xFF00CC58),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Recent Searches (${recentSearches.length})',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDarkMode
                                                    ? const Color(0xFFF5F5F5)
                                                    : const Color(0xFF121212),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Add Clear All button with better styling
                                        GestureDetector(
                                          onTap: () async {
                                            final bool? confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (context) =>
                                                  ResponsiveDialog(
                                                title: 'Clear Recent Searches',
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.clear_all,
                                                      size: 48,
                                                      color: Color(0xFFD7481D),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Are you sure you want to clear all recent searches?',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontFamily: 'Inter',
                                                        color: isDarkMode
                                                            ? const Color(
                                                                0xFFF5F5F5)
                                                            : const Color(
                                                                0xFF121212),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        side: BorderSide(
                                                          color: const Color(
                                                              0xFFD7481D),
                                                          width: 2,
                                                        ),
                                                      ),
                                                      elevation: 0,
                                                      shadowColor:
                                                          Colors.transparent,
                                                      minimumSize:
                                                          const Size(120, 44),
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      foregroundColor:
                                                          const Color(
                                                              0xFFD7481D),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 24,
                                                          vertical: 12),
                                                    ),
                                                    child: const Text(
                                                      'Cancel',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontFamily: 'Inter',
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      elevation: 0,
                                                      shadowColor:
                                                          Colors.transparent,
                                                      minimumSize:
                                                          const Size(120, 44),
                                                      backgroundColor:
                                                          const Color(
                                                              0xFFD7481D),
                                                      foregroundColor:
                                                          const Color(
                                                              0xFFF5F5F5),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 24,
                                                          vertical: 12),
                                                    ),
                                                    child: const Text(
                                                      'Clear All',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontFamily: 'Inter',
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                actionsAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                              ),
                                            );

                                            if (confirm == true) {
                                              if (widget.routeID != null) {
                                                await RecentSearchService
                                                    .clearRecentSearchesByRoute(
                                                        widget.routeID!);
                                              } else {
                                                await RecentSearchService
                                                    .clearRecentSearches();
                                              }
                                              setState(() {
                                                recentSearches = [];
                                              });
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD7481D)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(8)),
                                              border: Border.all(
                                                color: const Color(0xFFD7481D)
                                                    .withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.clear_all,
                                                  size: 14,
                                                  color: Color(0xFFD7481D),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Clear All',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        const Color(0xFFD7481D),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Recent searches list with improved styling (lazy loading)
                                    SizedBox(
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        cacheExtent:
                                            200.0, // Pre-render items above/below viewport
                                        // Removed fixed itemExtent to allow dynamic height based on content
                                        itemCount:
                                            recentSearches.take(5).length,
                                        itemBuilder: (context, index) {
                                          final search = recentSearches[index];
                                          return _uiComponentsHelper
                                              .buildRecentSearchTile(
                                            search,
                                            isDarkMode,
                                            currentLocation,
                                            () =>
                                                onRecentSearchSelected(search),
                                            precomputedDistance:
                                                _getRecentSearchDistance(
                                                    search),
                                          );
                                        },
                                      ),
                                    ),
                                    if (recentSearches.length > 5) ...[
                                      const SizedBox(height: 8),
                                      Center(
                                        child: Text(
                                          '${recentSearches.length - 5} more searches...',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: isDarkMode
                                                ? const Color(0xFFAAAAAA)
                                                : const Color(0xFF666666),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            // Show allowed stops if available
                            if (searchController.text.isEmpty &&
                                allowedStops.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Available Stops${hasMoreStops ? ' (${allowedStops.length}+)' : ' (${allowedStops.length})'}',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode
                                            ? const Color(0xFFF5F5F5)
                                            : const Color(0xFF121212),
                                      ),
                                    ),
                                    // Add sort/filter button
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.sort,
                                        color: isDarkMode
                                            ? const Color(0xFFF5F5F5)
                                            : const Color(0xFF121212),
                                        size: 20,
                                      ),
                                      onSelected: (String value) {
                                        setState(() {
                                          _sortingHelper.setSortOption(value);
                                          _clearFilteredStopsCache(); // Clear cache when sort changes
                                        });
                                      },
                                      itemBuilder: (BuildContext context) =>
                                          _uiComponentsHelper
                                              .buildSortMenuItems(_sortingHelper
                                                  .currentSortOption),
                                    ),
                                  ],
                                ),
                              ),
                              // Add filter chips
                              if (allowedStops.length > 5) ...[
                                Container(
                                  height: 50,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    cacheExtent:
                                        100.0, // Pre-render filter chips
                                    itemCount: _sortingHelper
                                        .getFilterOptions()
                                        .length,
                                    itemBuilder: (context, index) {
                                      final filter = _sortingHelper
                                          .getFilterOptions()[index];
                                      final isSelected =
                                          _sortingHelper.selectedFilter ==
                                              filter;
                                      return RepaintBoundary(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: FilterChip(
                                            label:
                                                Text(_getFilterLabel(filter)),
                                            selected: isSelected,
                                            onSelected: (selected) {
                                              setState(() {
                                                _sortingHelper
                                                    .setFilter(filter);
                                                _clearFilteredStopsCache(); // Clear cache when filter changes
                                              });
                                            },
                                            backgroundColor: isDarkMode
                                                ? const Color(0xFF1E1E1E)
                                                : const Color(0xFFF5F5F5),
                                            selectedColor:
                                                const Color(0xFF00CC58)
                                                    .withValues(alpha: 0.2),
                                            checkmarkColor:
                                                const Color(0xFF00CC58),
                                            labelStyle: TextStyle(
                                              color: isSelected
                                                  ? const Color(0xFF00CC58)
                                                  : (isDarkMode
                                                      ? const Color(0xFFF5F5F5)
                                                      : const Color(
                                                          0xFF121212)),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              // Show stops with improved layout and lazy loading
                              Builder(
                                builder: (context) {
                                  // Compute filtered stops once (cached internally)
                                  final filteredStops = _getFilteredStops();
                                  return Column(
                                    children: [
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        cacheExtent:
                                            300.0, // Pre-render stops above/below viewport
                                        // Removed fixed itemExtent to allow dynamic height based on content
                                        itemCount: filteredStops.length,
                                        itemBuilder: (context, index) {
                                          final stop = filteredStops[index];
                                          return _uiComponentsHelper
                                              .buildStopTile(
                                            stop,
                                            isDarkMode,
                                            currentLocation,
                                            () => onStopSelected(stop),
                                            precomputedDistance:
                                                _getStopDistance(stop),
                                          );
                                        },
                                      ),
                                      // Loading indicator for pagination
                                      ValueListenableBuilder<bool>(
                                        valueListenable: _isLoadingMoreNotifier,
                                        builder:
                                            (context, isLoadingMore, child) {
                                          return hasMoreStops && isLoadingMore
                                              ? const Padding(
                                                  padding: EdgeInsets.all(16.0),
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        Color(0xFF00CC58),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox.shrink();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ]
                            // Show filtered stops if searching
                            else if (searchController.text.isNotEmpty) ...[
                              ValueListenableBuilder<List<Stop>>(
                                valueListenable: _filteredStopsNotifier,
                                builder: (context, filteredStops, child) {
                                  return ValueListenableBuilder<
                                      List<AutocompletePrediction>>(
                                    valueListenable: _placePredictionsNotifier,
                                    builder:
                                        (context, placePredictions, child) {
                                      if (filteredStops.isNotEmpty) {
                                        return Column(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Text(
                                                'Search Results',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDarkMode
                                                      ? const Color(0xFFF5F5F5)
                                                      : const Color(0xFF121212),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                cacheExtent:
                                                    300.0, // Pre-render search results
                                                itemExtent:
                                                    62.0, // Fixed height for LocationListTile items
                                                itemCount: filteredStops.length,
                                                itemBuilder: (context, index) {
                                                  final stop =
                                                      filteredStops[index];
                                                  return LocationListTile(
                                                    press: () =>
                                                        onStopSelected(stop),
                                                    location:
                                                        "${stop.name}\n${stop.address}",
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      } else if (placePredictions.isNotEmpty) {
                                        return Column(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Text(
                                                'Search Results',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDarkMode
                                                      ? const Color(0xFFF5F5F5)
                                                      : const Color(0xFF121212),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                cacheExtent:
                                                    300.0, // Pre-render place predictions
                                                itemExtent:
                                                    62.0, // Fixed height for LocationListTile items
                                                itemCount:
                                                    placePredictions.length,
                                                itemBuilder: (context, index) {
                                                  final prediction =
                                                      placePredictions[index];
                                                  return LocationListTile(
                                                    press: () =>
                                                        onPlaceSelected(
                                                            prediction),
                                                    location:
                                                        prediction.description!,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      } else {
                                        return Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Center(
                                            child: Text(
                                              'No locations found',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDarkMode
                                                    ? const Color(0xFFF5F5F5)
                                                    : const Color(0xFF121212),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

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

  // Helper method to check if selected location is too close to the final stop
  Future<bool> isLocationNearFinalStop(LatLng location) async {
    return _validationHelper.isLocationNearFinalStop(location, widget.routeID);
  }

  // Helper methods for filtering
  String _getFilterLabel(String filter) {
    return _sortingHelper.getFilterLabel(filter);
  }

  /// Get filtered and sorted stops with caching
  List<Stop> _getFilteredStops() {
    // Check if cache is still valid
    final currentSortOption = _sortingHelper.currentSortOption;
    final currentFilter = _sortingHelper.selectedFilter;

    // Check if cache is valid by comparing list reference, length, and other dependencies
    if (_cachedFilteredStops != null &&
        identical(_cachedFilteredStopsAllowedStops, allowedStops) &&
        _cachedFilteredStopsAllowedStopsLength == allowedStops.length &&
        _cachedFilteredStopsLocation == currentLocation &&
        _cachedFilteredStopsSortOption == currentSortOption &&
        _cachedFilteredStopsFilter == currentFilter) {
      // Cache is valid, return cached result
      return _cachedFilteredStops!;
    }

    // Cache is invalid, recompute and cache
    final filteredStops =
        _sortingHelper.getFilteredAndSortedStops(allowedStops, currentLocation);

    _cachedFilteredStops = filteredStops;
    _cachedFilteredStopsAllowedStops =
        allowedStops; // Store reference for comparison
    _cachedFilteredStopsAllowedStopsLength =
        allowedStops.length; // Store length to detect mutations
    _cachedFilteredStopsLocation = currentLocation;
    _cachedFilteredStopsSortOption = currentSortOption;
    _cachedFilteredStopsFilter = currentFilter;

    return filteredStops;
  }

  /// Clear the filtered stops cache (call when stops or filters change)
  void _clearFilteredStopsCache() {
    _cachedFilteredStops = null;
    _cachedFilteredStopsAllowedStops = null;
    _cachedFilteredStopsAllowedStopsLength = null;
    _cachedFilteredStopsLocation = null;
    _cachedFilteredStopsSortOption = null;
    _cachedFilteredStopsFilter = null;
  }
}
