import 'dart:async';
import 'dart:convert';
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
import 'locationListTile.dart';
import 'package:pasada_passenger_app/screens/homeScreen.dart';

class SearchLocationScreen extends StatefulWidget {
  // final Function(SelectedLocation)? onLocationSelected;
  final bool isPickup;
  const SearchLocationScreen({super.key, required this.isPickup});

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  final TextEditingController searchController = TextEditingController();
  List<AutocompletePrediction> placePredictions = [];
  List<RecentSearch> recentSearches = [];
  HomeScreenPageState? homeScreenState;
  Timer? _debounce;
  bool isLoading = false;
  HomeScreenPageState? homeScreenPageState;
  LatLng? currentLocation;

  @override
  void initState() {
    super.initState();
    searchController.addListener(onSearchChanged);
    loadRecentSearches();
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

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    setState(() => isLoading = true);

    _debounce = Timer(const Duration(milliseconds: 1500), () {
      placeAutocomplete(searchController.text);
    });
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
        "components": "country:PH", // limit to Philippines
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
        "place_id": prediction.placeID, // Ensure correct property name
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
            title: Text(
              'Distance warning',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
                fontSize: 16,
                color: isDarkMode
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFF121212),
              ),
            ),
            content: Text(
              'The selected pick-up location is quite far from your current location. Do you want to continue?',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                fontSize: 14,
                color: isDarkMode
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFF121212),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF067837),
                ),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
      return proceed ?? false;
    }

    return true;
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
          if (searchController.text.isEmpty && recentSearches.isNotEmpty) ...[
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
                  TextButton(
                    onPressed: () async {
                      await RecentSearchService.clearRecentSearches();
                      loadRecentSearches();
                    },
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: isDarkMode
                            ? const Color(0xFFFFCE21)
                            : const Color(0xFF067837),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: recentSearches.length,
                itemBuilder: (context, index) => LocationListTile(
                  press: () => onRecentSearchSelected(recentSearches[index]),
                  location: recentSearches[index].address,
                ),
              ),
            ),
          ] else if (isLoading) ...[
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
                ),
              ),
            )
          ] else ...[
            Expanded(
              child: ListView.builder(
                itemCount: placePredictions.length,
                itemBuilder: (context, index) => SizedBox(
                  height: 57,
                  child: LocationListTile(
                    press: () => onPlaceSelected(placePredictions[index]),
                    location: placePredictions[index].description?.toString() ??
                        'Unknown',
                  ),
                ),
              ),
            ),
          ],
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF1E1E1E)
                  : const Color(0xFFF5F5F5),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? const Color(0xFF000000)
                      : const Color(0xFFD2D2D2),
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
                    builder: (context) =>
                        PinLocationStateful(isPickup: widget.isPickup),
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
              builder: (context) =>
                  PinLocationStateful(isPickup: widget.isPickup),
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
}
