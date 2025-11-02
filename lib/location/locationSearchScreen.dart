import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  List<Stop> _filteredStops = [];
  HomeScreenPageState? homeScreenState;
  bool isLoading = false;
  HomeScreenPageState? homeScreenPageState;
  LatLng? currentLocation;
  StopsService _stopsService = StopsService();

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
  }

  Future<void> loadStops() async {
    setState(() => isLoading = true);

    try {
      List<Stop> stops = [];

      if (widget.routeID != null) {
        stops = await _stopsService.getStopsForRoute(widget.routeID!);

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
        stops = await _stopsService.getAllActiveStops();
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
        setState(() {
          allowedStops = stops;
          _filteredStops = stops;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stops: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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
                  borderRadius: BorderRadius.circular(10),
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
                      borderRadius: BorderRadius.circular(10),
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
                  borderRadius: BorderRadius.circular(10),
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
                    borderRadius: BorderRadius.circular(10),
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
    _searchHelper.dispose();
    searchController.dispose();
    super.dispose();
  }

  void onSearchChanged() {
    _searchHelper.onSearchChanged(
      searchController,
      () => setState(() => isLoading = true),
      (query) => searchAllowedStops(query),
      (query) => placeAutocomplete(query),
    );
  }

  Future<void> searchAllowedStops(String query) async {
    try {
      final filteredStops = await _searchHelper.searchAllowedStops(
        query,
        allowedStops,
        _isLocationAlreadySelected,
      );

      if (filteredStops.isNotEmpty) {
        setState(() {
          _filteredStops = filteredStops;
          placePredictions = [];
          isLoading = false;
        });
      } else {
        placeAutocomplete(query);
      }
    } catch (e) {
      debugPrint('Error searching stops: $e');
      placeAutocomplete(query);
    }
  }

  Future<void> placeAutocomplete(String query) async {
    if (query.isEmpty) {
      setState(() {
        placePredictions = [];
        isLoading = false;
      });
      return;
    }

    try {
      final predictions = await _searchHelper.placeAutocomplete(query);
      setState(() {
        placePredictions = predictions;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
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
                    borderRadius: BorderRadius.circular(10),
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
                        borderRadius: BorderRadius.circular(10),
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
        setState(() {
          currentLocation = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );
        });
        // Clear distance cache when location changes
        _clearDistanceCache();
        // Refresh sorting to update distances
        _refreshSorting();
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
            child: SvgPicture.asset(
              'assets/svg/navigation.svg',
              height: 16,
              width: 16,
              colorFilter: ColorFilter.mode(
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
                BlendMode.srcIn,
              ),
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
                    child: SvgPicture.asset(
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
            child: isLoading
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
                : ListView(
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
                            borderRadius: BorderRadius.circular(12),
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
                                      Icon(
                                        Icons.history,
                                        size: 18,
                                        color: const Color(0xFF00CC58),
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
                                        builder: (context) => ResponsiveDialog(
                                          title: 'Clear Recent Searches',
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.clear_all,
                                                size: 48,
                                                color: const Color(0xFFD7481D),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Are you sure you want to clear all recent searches?',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: 'Inter',
                                                  color: isDarkMode
                                                      ? const Color(0xFFF5F5F5)
                                                      : const Color(0xFF121212),
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              style: ElevatedButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  side: BorderSide(
                                                    color:
                                                        const Color(0xFFD7481D),
                                                    width: 2,
                                                  ),
                                                ),
                                                elevation: 0,
                                                shadowColor: Colors.transparent,
                                                minimumSize:
                                                    const Size(120, 44),
                                                backgroundColor:
                                                    Colors.transparent,
                                                foregroundColor:
                                                    const Color(0xFFD7481D),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 24,
                                                        vertical: 12),
                                              ),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Inter',
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                elevation: 0,
                                                shadowColor: Colors.transparent,
                                                minimumSize:
                                                    const Size(120, 44),
                                                backgroundColor:
                                                    const Color(0xFFD7481D),
                                                foregroundColor:
                                                    const Color(0xFFF5F5F5),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 24,
                                                        vertical: 12),
                                              ),
                                              child: const Text(
                                                'Clear All',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Inter',
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                          actionsAlignment:
                                              MainAxisAlignment.spaceEvenly,
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
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFD7481D)
                                              .withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.clear_all,
                                            size: 14,
                                            color: const Color(0xFFD7481D),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Clear All',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFD7481D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Recent searches list with improved styling
                              ...recentSearches.take(5).map((search) =>
                                  _uiComponentsHelper.buildRecentSearchTile(
                                    search,
                                    isDarkMode,
                                    currentLocation,
                                    () => onRecentSearchSelected(search),
                                  )),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Available Stops (${allowedStops.length})',
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
                                  });
                                },
                                itemBuilder: (BuildContext context) =>
                                    _uiComponentsHelper.buildSortMenuItems(
                                        _sortingHelper.currentSortOption),
                              ),
                            ],
                          ),
                        ),
                        // Add filter chips
                        if (allowedStops.length > 5) ...[
                          Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  _sortingHelper.getFilterOptions().length,
                              itemBuilder: (context, index) {
                                final filter =
                                    _sortingHelper.getFilterOptions()[index];
                                final isSelected =
                                    _sortingHelper.selectedFilter == filter;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(_getFilterLabel(filter)),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _sortingHelper.setFilter(filter);
                                        _applyFilter();
                                      });
                                    },
                                    backgroundColor: isDarkMode
                                        ? const Color(0xFF1E1E1E)
                                        : const Color(0xFFF5F5F5),
                                    selectedColor: const Color(0xFF00CC58)
                                        .withValues(alpha: 0.2),
                                    checkmarkColor: const Color(0xFF00CC58),
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFF00CC58)
                                          : (isDarkMode
                                              ? const Color(0xFFF5F5F5)
                                              : const Color(0xFF121212)),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        // Show stops with improved layout and lazy loading
                        if (_getFilteredStops().length > 20)
                          _uiComponentsHelper.buildLazyStopList(
                            _getFilteredStops(),
                            isDarkMode,
                            currentLocation,
                            onStopSelected,
                          )
                        else
                          ..._getFilteredStops()
                              .map((stop) => _uiComponentsHelper.buildStopTile(
                                    stop,
                                    isDarkMode,
                                    currentLocation,
                                    () => onStopSelected(stop),
                                  )),
                      ]
                      // Show filtered stops if searching
                      else if (searchController.text.isNotEmpty &&
                          _filteredStops.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(16.0),
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
                        ..._filteredStops.map((stop) => LocationListTile(
                              press: () => onStopSelected(stop),
                              location: "${stop.name}\n${stop.address}",
                            )),
                      ]
                      // Show place predictions if available
                      else if (placePredictions.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(16.0),
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
                        ...placePredictions
                            .map((prediction) => LocationListTile(
                                  press: () => onPlaceSelected(prediction),
                                  location: prediction.description!,
                                )),
                      ]
                      // Show no locations found message
                      else if (searchController.text.isNotEmpty) ...[
                        Padding(
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
                        ),
                      ],
                    ],
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

  List<Stop> _getFilteredStops() {
    return _sortingHelper.getFilteredAndSortedStops(
        allowedStops, currentLocation);
  }

  void _applyFilter() {
    setState(() {
      // Filter is applied in _getFilteredStops()
    });
  }

  // Refresh sorting when location changes
  void _refreshSorting() {
    if (mounted) {
      setState(() {
        // This will trigger a rebuild with updated distances
      });
    }
  }
}
