import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pasada_passenger_app/location/autocompletePrediction.dart';
import 'package:pasada_passenger_app/location/placeAutocompleteResponse.dart';
import 'package:pasada_passenger_app/location/recentSearch.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/models/stop.dart';
import 'package:pasada_passenger_app/network/networkUtilities.dart';
import 'package:pasada_passenger_app/screens/homeScreen.dart';
import 'package:pasada_passenger_app/services/allowedStopsServices.dart';
import 'package:pasada_passenger_app/services/recentSearchService.dart';
import 'package:pasada_passenger_app/widgets/responsive_dialogs.dart';
import 'package:pasada_passenger_app/widgets/skeleton.dart';

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
  Timer? _debounce;
  bool isLoading = false;
  HomeScreenPageState? homeScreenPageState;
  LatLng? currentLocation;
  StopsService _stopsService = StopsService();
  String _selectedFilter = 'all';
  final List<String> _filterOptions = ['all', 'nearby'];

  @override
  void initState() {
    super.initState();
    searchController.addListener(onSearchChanged);
    _stopsService = StopsService();

    // Initialize location service
    _initializeLocation();

    // Load stops and recent searches
    loadStops();
    loadRecentSearches();
  }

  // Helper method to check if a location is already selected
  bool _isLocationAlreadySelected(LatLng coordinates) {
    // Get the already selected location (the opposite of what we're currently selecting)
    SelectedLocation? alreadySelected = widget.isPickup
        ? widget.selectedDropOffLocation
        : widget.selectedPickUpLocation;

    if (alreadySelected == null) return false;

    // Check if coordinates are within 50 meters of the already selected location
    const double thresholdMeters = 50.0;
    final distance =
        calculateDistance(coordinates, alreadySelected.coordinates);
    return distance < thresholdMeters;
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
        else if (!widget.isPickup && widget.pickupOrder != null) {
          stops =
              stops.where((stop) => stop.order > widget.pickupOrder!).toList();
        }
      } else {
        stops = await _stopsService.getAllActiveStops();
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
              final distance =
                  calculateDistance(recent.coordinates, lastStop!.coordinates);
              return distance > exclusionRadiusMeters;
            }).toList();
          }
        }
      } catch (e) {
        debugPrint('Error filtering recent searches against last stop: $e');
      }
    }
    // For drop-off locations, exclude recent searches at or before the pick-up stop order
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
          if (closestStop != null && closestStop.order > pickupOrder) {
            filtered.add(recent);
          }
        }
        searches = filtered;
      } catch (e) {
        debugPrint('Error filtering recent searches for drop-off: $e');
      }
    }

    // Filter out already selected locations
    searches = searches
        .where((search) => !_isLocationAlreadySelected(search.coordinates))
        .toList();

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
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    setState(() => isLoading = true);

    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (searchController.text.isEmpty) {
        setState(() {
          placePredictions = [];
          _filteredStops = allowedStops;
          isLoading = false;
        });
        return;
      }

      // If we have stops, search them first
      if (allowedStops.isNotEmpty) {
        searchAllowedStops(searchController.text);
      } else {
        placeAutocomplete(searchController.text);
      }
    });
  }

  Future<void> searchAllowedStops(String query) async {
    try {
      // Filter stops locally since we can't modify the database
      final filteredStops = allowedStops.where((stop) {
        final matchesQuery =
            stop.name.toLowerCase().contains(query.toLowerCase()) ||
                stop.address.toLowerCase().contains(query.toLowerCase());
        final notAlreadySelected =
            !_isLocationAlreadySelected(stop.coordinates);
        return matchesQuery && notAlreadySelected;
      }).toList();

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

    final String apiKey = dotenv.env["ANDROID_MAPS_API_KEY"] ?? '';
    if (apiKey.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

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
        setState(() {
          placePredictions = result.prediction ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (currentLocation == null) return true;

    final selectedLoc = SelectedLocation("", pickupLocation);
    final distance = selectedLoc.distanceFrom(currentLocation!);

    if (distance > 1.0) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => ResponsiveDialog(
          title: 'Distance Warning',
          contentPadding:
              EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
          content: Text(
            'The selected pick-up location is quite far from your current location',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              fontSize: 13,
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: const Color(0xFFD7481D),
                    width: 3,
                  ),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                minimumSize: const Size(150, 40),
                backgroundColor: Colors.transparent,
                foregroundColor: isDarkMode
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFF121212),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  fontSize: 15,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                minimumSize: const Size(150, 40),
                backgroundColor: const Color(0xFFD7481D),
                foregroundColor: const Color(0xFFF5F5F5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );
      return proceed ?? false;
    }
    return true;
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
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                              'Clear Recent Searches'),
                                          content: const Text(
                                            'Are you sure you want to clear all recent searches?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    const Color(0xFFD7481D),
                                              ),
                                              child: const Text('Clear All'),
                                            ),
                                          ],
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
                                  _buildRecentSearchTile(search, isDarkMode)),
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
                                    switch (value) {
                                      case 'name':
                                        allowedStops.sort(
                                            (a, b) => a.name.compareTo(b.name));
                                        break;
                                      case 'order':
                                        allowedStops.sort((a, b) =>
                                            a.order.compareTo(b.order));
                                        break;
                                      case 'distance':
                                        // Sort by distance from current location if available
                                        if (currentLocation != null) {
                                          allowedStops.sort((a, b) {
                                            final distanceA = calculateDistance(
                                                currentLocation!,
                                                a.coordinates);
                                            final distanceB = calculateDistance(
                                                currentLocation!,
                                                b.coordinates);
                                            return distanceA
                                                .compareTo(distanceB);
                                          });
                                        }
                                        break;
                                    }
                                  });
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem<String>(
                                    value: 'order',
                                    child: Text('Sort by Route Order'),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'name',
                                    child: Text('Sort by Name'),
                                  ),
                                  if (currentLocation != null)
                                    const PopupMenuItem<String>(
                                      value: 'distance',
                                      child: Text('Sort by Distance'),
                                    ),
                                ],
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
                              itemCount: _filterOptions.length,
                              itemBuilder: (context, index) {
                                final filter = _filterOptions[index];
                                final isSelected = _selectedFilter == filter;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(_getFilterLabel(filter)),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedFilter = filter;
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
                          _buildLazyStopList(_getFilteredStops(), isDarkMode)
                        else
                          ..._getFilteredStops()
                              .map((stop) => _buildStopTile(stop, isDarkMode)),
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

  // Add this method to check if a point is close to the polyline
  bool isPointNearPolyline(LatLng point, double threshold) {
    if (widget.routePolyline == null || widget.routePolyline!.isEmpty) {
      return true; // If no polyline, allow all points
    }

    // Find the minimum distance from the point to any segment of the polyline
    double minDistance = double.infinity;

    for (int i = 0; i < widget.routePolyline!.length - 1; i++) {
      final LatLng start = widget.routePolyline![i];
      final LatLng end = widget.routePolyline![i + 1];

      // Calculate distance from point to line segment
      final double distance = distanceToLineSegment(point, start, end);
      if (distance < minDistance) {
        minDistance = distance;
      }

      // Early exit if we found a close enough point
      if (minDistance <= threshold) {
        return true;
      }
    }

    return minDistance <= threshold;
  }

  // Helper method to calculate distance from point to line segment
  double distanceToLineSegment(LatLng p, LatLng v, LatLng w) {
    // Calculate squared length of line segment
    final double l2 = calculateSquaredDistance(v, w);
    if (l2 == 0.0) return calculateDistance(p, v); // v == w case

    final double t = max(0, min(1, dotProduct(p, v, w) / l2));
    final LatLng projection = LatLng(
      v.latitude + t * (w.latitude - v.latitude),
      v.longitude + t * (w.longitude - v.longitude),
    );

    return calculateDistance(p, projection);
  }

  // Calculate squared distance between two points
  double calculateSquaredDistance(LatLng p1, LatLng p2) {
    final double dx = p1.latitude - p2.latitude;
    final double dy = p1.longitude - p2.longitude;
    return dx * dx + dy * dy;
  }

  // Calculate actual distance between two points in meters
  double calculateDistance(LatLng p1, LatLng p2) {
    // Using the Haversine formula to calculate distance
    const double earthRadius = 6371000; // Earth radius in meters
    final double lat1 = p1.latitude * pi / 180;
    final double lat2 = p2.latitude * pi / 180;
    final double dLat = (p2.latitude - p1.latitude) * pi / 180;
    final double dLon = (p2.longitude - p1.longitude) * pi / 180;

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  // Calculate dot product for projection calculation
  double dotProduct(LatLng p, LatLng v, LatLng w) {
    return (p.latitude - v.latitude) * (w.latitude - v.latitude) +
        (p.longitude - v.longitude) * (w.longitude - v.longitude);
  }

  // Helper method to check if selected location is too close to the final stop
  Future<bool> isLocationNearFinalStop(LatLng location) async {
    if (widget.routeID == null) return false;

    try {
      // Get all stops for the route
      final stops = await _stopsService.getStopsForRoute(widget.routeID!);

      // Find the stop with the highest order (the final stop)
      Stop? finalStop;
      int highestOrder = -1;

      for (var stop in stops) {
        if (stop.order > highestOrder) {
          highestOrder = stop.order;
          finalStop = stop;
        }
      }

      if (finalStop == null) return false;

      // Check if the location is within X meters of the final stop (using 300m as threshold)
      final distance = calculateDistance(location, finalStop.coordinates);

      return distance < 300; // Return true if within 300 meters of final stop
    } catch (e) {
      debugPrint('Error checking distance to final stop: $e');
      return false;
    }
  }

  // Helper methods for filtering
  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'All Stops';
      case 'nearby':
        return 'Nearby';
      default:
        return 'All';
    }
  }

  List<Stop> _getFilteredStops() {
    switch (_selectedFilter) {
      case 'nearby':
        if (currentLocation == null) return allowedStops;
        return allowedStops.where((stop) {
          final distance =
              calculateDistance(currentLocation!, stop.coordinates);
          return distance <= 2000; // Within 2km
        }).toList();
      default:
        return allowedStops;
    }
  }

  void _applyFilter() {
    setState(() {
      // Filter is applied in _getFilteredStops()
    });
  }

  // Build lazy loading list for performance with large datasets
  Widget _buildLazyStopList(List<Stop> stops, bool isDarkMode) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stops.length,
      itemBuilder: (context, index) {
        return _buildStopTile(stops[index], isDarkMode);
      },
    );
  }

  // Build improved recent search tile
  Widget _buildRecentSearchTile(RecentSearch search, bool isDarkMode) {
    final distance = currentLocation != null
        ? calculateDistance(currentLocation!, search.coordinates)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF00CC58).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.history,
            size: 16,
            color: Color(0xFF00CC58),
          ),
        ),
        title: Text(
          search.address,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: distance != null
            ? Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 12,
                    color: const Color(0xFF00CC58),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(distance / 1000).toStringAsFixed(1)} km away',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF00CC58),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: isDarkMode ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
        ),
        onTap: () => onRecentSearchSelected(search),
      ),
    );
  }

  // Build improved stop tile with more information
  Widget _buildStopTile(Stop stop, bool isDarkMode) {
    final distance = currentLocation != null
        ? calculateDistance(currentLocation!, stop.coordinates)
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF00CC58).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${stop.order}',
              style: const TextStyle(
                color: Color(0xFF00CC58),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          stop.name,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              stop.address,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: isDarkMode
                    ? const Color(0xFFAAAAAA)
                    : const Color(0xFF666666),
              ),
            ),
            if (distance != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: const Color(0xFF00CC58),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(distance / 1000).toStringAsFixed(1)} km away',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF00CC58),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDarkMode ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
        ),
        onTap: () => onStopSelected(stop),
      ),
    );
  }
}
