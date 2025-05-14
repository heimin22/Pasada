import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pasada_passenger_app/location/autocompletePrediction.dart';
import 'package:pasada_passenger_app/location/recentSearch.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/network/networkUtilities.dart';
import 'package:pasada_passenger_app/location/pinLocationMap.dart';
import 'package:pasada_passenger_app/location/placeAutocompleteResponse.dart';
import 'package:pasada_passenger_app/services/recentSearchService.dart';
import 'package:pasada_passenger_app/services/allowedStopsServices.dart';
import 'package:pasada_passenger_app/models/stop.dart';
import 'locationListTile.dart';
import 'package:pasada_passenger_app/screens/homeScreen.dart';

class SearchLocationScreen extends StatefulWidget {
  final bool isPickup;
  final int? routeID;
  final Map<String, dynamic>? routeDetails;
  final List<LatLng>? routePolyline;

  const SearchLocationScreen({
    super.key,
    required this.isPickup,
    this.routeID,
    this.routeDetails,
    this.routePolyline,
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

  Future<void> loadStops() async {
    setState(() => isLoading = true);

    try {
      List<Stop> stops = [];

      if (widget.routeID != null) {
        debugPrint('Loading stops for route ID: ${widget.routeID}');
        stops = await _stopsService.getStopsForRoute(widget.routeID!);
        debugPrint('Loaded ${stops.length} stops for route ${widget.routeID}');
      } else {
        stops = await _stopsService.getAllActiveStops();
        debugPrint('Loaded ${stops.length} active stops across all routes');
      }

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
    final searches = await RecentSearchService.getRecentSearches();
    setState(() {
      recentSearches = searches;
    });
  }

  void onRecentSearchSelected(RecentSearch search) async {
    if (widget.isPickup) {
      final shouldProceed = await checkPickupDistance(search.coordinates);
      if (!shouldProceed) return;
    }

    Navigator.pop(
      context,
      SelectedLocation(search.address, search.coordinates),
    );
  }

  void onStopSelected(Stop stop) async {
    if (widget.isPickup) {
      final shouldProceed = await checkPickupDistance(stop.coordinates);
      if (!shouldProceed) return;
    }

    final selectedLocation = SelectedLocation(
      "${stop.name}\n${stop.address}",
      stop.coordinates,
    );

    // Save to recent searches
    await RecentSearchService.addRecentSearch(selectedLocation);

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
        return stop.name.toLowerCase().contains(query.toLowerCase()) ||
            stop.address.toLowerCase().contains(query.toLowerCase());
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
      if (kDebugMode) print("API Key is not configured!");
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
      if (kDebugMode) print("Error fetching places: $e");
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

      if (widget.isPickup) {
        final shouldProceed =
            await checkPickupDistance(selectedLocation.coordinates);
        if (!shouldProceed) return;
      }

      // Save to recent searches
      await RecentSearchService.addRecentSearch(selectedLocation);

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
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: const EdgeInsets.all(24),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distance Warning',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                    fontSize: 24,
                    color: isDarkMode
                        ? const Color(0xFFF5F5F5)
                        : const Color(0xFF121212),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212),
                  width: double.infinity,
                ),
              ],
            ),
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
                  minimumSize: const Size(150, 60),
                  backgroundColor: Colors.transparent,
                  foregroundColor:
                      Theme.of(context).brightness == Brightness.dark
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
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(150, 60),
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
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          );
        },
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
    final loadingColor = isDarkMode
        ? const Color(0xFF00E865) // Brighter green for dark mode
        : const Color(0xFF067837); // Original green for light mode

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
                  hintText: 'Search Location',
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
          if (widget.isPickup) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final Location locationService = Location();
                  try {
                    final LocationData locationData =
                        await locationService.getLocation();
                    final LatLng currentLatLng =
                        LatLng(locationData.latitude!, locationData.longitude!);

                    // Check if current location is near the route
                    bool isNearRoute = true;
                    if (widget.routePolyline != null &&
                        widget.routePolyline!.isNotEmpty) {
                      isNearRoute = isPointNearPolyline(currentLatLng, 100);
                    }

                    if (!isNearRoute) {
                      // Show warning dialog
                      final bool? proceed = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          final isDarkMode =
                              Theme.of(context).brightness == Brightness.dark;
                          return AlertDialog(
                            contentPadding: const EdgeInsets.all(24),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location Warning',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Inter',
                                    fontSize: 24,
                                    color: isDarkMode
                                        ? const Color(0xFFF5F5F5)
                                        : const Color(0xFF121212),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  height: 1,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFFF5F5F5)
                                      : const Color(0xFF121212),
                                  width: double.infinity,
                                ),
                              ],
                            ),
                            content: Text(
                              'Your current location is not within the selected route.',
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
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00CC58),
                                    foregroundColor: const Color(0xFFF5F5F5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: Text(
                                    'OK',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: const Color(0xFFF5F5F5),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (proceed != true) return;
                    }

                    final SelectedLocation? currentLocation =
                        await reverseGeocode(currentLatLng);
                    if (currentLocation != null && mounted) {
                      Navigator.pop(
                        context,
                        SelectedLocation(currentLocation.address,
                            currentLocation.coordinates),
                      );
                    }
                  } catch (e) {
                    debugPrint("Error getting location: $e");
                  }
                },
                icon: SvgPicture.asset(
                  'assets/svg/navigation.svg',
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF121212),
                    BlendMode.srcIn,
                  ),
                ),
                label: const Text(
                  'Use My Current Location',
                  style: TextStyle(
                    color: Color(0xFF121212),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCE21),
                  foregroundColor: const Color(0xFF121212),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 85),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
          Divider(
            height: 0,
            thickness: 2,
            color:
                isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFE9E9E9),
          ),
          if (isLoading) ...[
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: loadingColor,
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: ListView(
                children: [
                  // Show recent searches if available and search is empty
                  if (searchController.text.isEmpty &&
                      recentSearches.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Searches',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFF121212),
                            ),
                          ),
                          // Add Clear All button
                          GestureDetector(
                            onTap: () async {
                              await RecentSearchService.clearRecentSearches();
                              setState(() {
                                recentSearches = [];
                              });
                            },
                            child: Text(
                              'Clear All',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF067837),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Recent searches list
                    ...recentSearches.map((search) => LocationListTile(
                          press: () => onRecentSearchSelected(search),
                          location: search.address,
                        )),
                  ],

                  // Show allowed stops if available
                  if (searchController.text.isEmpty &&
                      allowedStops.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Available Stops',
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
                    ...allowedStops.map((stop) => LocationListTile(
                          press: () => onStopSelected(stop),
                          location: "${stop.name}\n${stop.address}",
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
                    ...placePredictions.map((prediction) => LocationListTile(
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
          // Pin location button at the bottom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PinLocationStateful(
                      isPickup: widget.isPickup,
                      routePolyline: widget.routePolyline, // Pass the polyline
                    ),
                  ),
                ).then((result) {
                  if (result != null && result is SelectedLocation) {
                    Navigator.pop(context, result);
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFF5F5F5),
                foregroundColor: isDarkMode
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFF121212),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 20,
                    color: isDarkMode
                        ? const Color(0xFFF5F5F5)
                        : const Color(0xFF121212),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Pin on Maps",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDarkMode
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFF121212),
                    ),
                  ),
                ],
              ),
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
        debugPrint("Request denied: ${data['error_message']}");
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

  Widget pinFromTheMaps() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFD2D2D2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PinLocationStateful(
                isPickup: widget.isPickup,
                routePolyline: widget.routePolyline, // Pass the polyline
              ),
            ),
          ).then((result) {
            if (result != null && result is SelectedLocation) {
              Navigator.pop(context, result);
            }
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFF5F5F5),
          foregroundColor: const Color(0xFF121212),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 20),
            const SizedBox(width: 8),
            Text(
              "Pin on Maps",
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF121212),
              ),
            ),
          ],
        ),
      ),
    );
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
}
