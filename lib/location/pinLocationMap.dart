import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/landmarkService.dart';
import 'package:pasada_passenger_app/location/locationButton.dart';
import 'package:pasada_passenger_app/screens/mapScreen.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pasada_passenger_app/network/networkUtilities.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/utils/memory_manager.dart';

class PinLocationStateless extends StatelessWidget {
  const PinLocationStateless({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const PinLocationStateful(isPickup: true),
      routes: <String, WidgetBuilder>{},
    );
  }
}

class PinLocationStateful extends StatefulWidget {
  final bool isPickup;
  const PinLocationStateful({super.key, required this.isPickup});

  @override
  State<PinLocationStateful> createState() => _PinLocationStatefulState();
}

class _PinLocationStatefulState extends State<PinLocationStateful> {
  final MemoryManager _memoryManager = MemoryManager();
  static const String MAP_CACHE_KEY = 'map_state';
  static const String LAST_LOCATION_KEY = 'last_known_location';
  static const String MAP_STYLE_KEY = 'map_style';

  // Add dark mode map style
  final String darkMapStyle = '''[
    {
      "elementType": "geometry",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#746855"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d59563"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d59563"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#263c3f"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#6b9a76"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#38414e"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#212a37"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#9ca5b3"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#746855"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#1f2835"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#f3d19c"}]
    },
    {
      "featureType": "transit",
      "elementType": "geometry",
      "stylers": [{"color": "#2f3948"}]
    },
    {
      "featureType": "transit.station",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d59563"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#17263c"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#515c6d"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#17263c"}]
    }
  ]''';

  // Add this variable to store the current map style
  String _currentMapStyle = '';

  // global key for the map
  final GlobalKey<MapScreenState> mapScreenKey = GlobalKey<MapScreenState>();

  // map controller for map settings
  late GoogleMapController mapController;

  // current location and pinned location
  LatLng? currentLocation;
  LatLng? pinnedLocation;

  // location services
  final Location locationService = Location();

  // selected pinned location
  SelectedLocation? selectedPinnedLocation;

  // placeholder value for the location handler
  final ValueNotifier<String> addressNotifier = ValueNotifier('');

  // loading ba nigga? (flag)
  bool isLoading = true;

  // finding landmark flag
  bool isFindingLandmark = false;

  // landmark name
  String landmarkName = '';

  LatLng? snappedLocation;
  bool isSnapping = false;
  bool isMapReady = false;

  // for the google logo's responsiveness
  late double bottomContainerHeight = 0.0;
  final GlobalKey bottomContainerKey = GlobalKey();
  final fabVerticalSpacing = 10.0;

  List<String> splitLocation(String location) {
    final List<String> parts = location.split(',');
    if (parts.length < 2) return [location, ''];
    return [parts[0], parts.sublist(1).join(', ')];
  }

  @override
  void initState() {
    super.initState();
    _initializeMapState();

    // Initialize map style based on theme and cache
    _initializeMapStyle();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    locationService.changeSettings(
      interval: 1000,
      accuracy: LocationAccuracy.high,
    );
  }

  void _initializeMapStyle() {
    // Get cached map style
    final cachedStyle = _memoryManager.getFromCache(MAP_STYLE_KEY);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isDarkMode) {
      _currentMapStyle = cachedStyle ?? darkMapStyle;
      if (cachedStyle == null) {
        _memoryManager.addToCache(MAP_STYLE_KEY, darkMapStyle);
      }
    } else {
      _currentMapStyle = '';
    }
  }

  Future<void> _initializeMapState() async {
    // Try to get cached location first
    final cachedLocation = _memoryManager.getFromCache(LAST_LOCATION_KEY);

    if (cachedLocation != null) {
      setState(() {
        currentLocation =
            LatLng(cachedLocation['latitude'], cachedLocation['longitude']);
        isLoading = false;
      });
    }

    // Get fresh location in background
    getCurrentLocation();
  }

  @override
  void dispose() {
    addressNotifier.dispose();
    // Clear temporary caches
    _memoryManager.clearCacheItem(MAP_CACHE_KEY);
    super.dispose();
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    isMapReady = true;

    // Debounce camera movements
    _memoryManager.debounce(() {
      if (currentLocation != null) {
        controller.animateCamera(CameraUpdate.newLatLng(currentLocation!));
      }
    }, const Duration(milliseconds: 300), 'camera_movement');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update map style when theme changes
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final newStyle = isDarkMode ? darkMapStyle : '';
    if (_currentMapStyle != newStyle) {
      setState(() {
        _currentMapStyle = newStyle;
      });
    }
  }

  void handleMapTap(LatLng tappedPosition) async {
    setState(() {
      isFindingLandmark = true;
      pinnedLocation = tappedPosition;
      addressNotifier.value = "Searching...";
    });

    await Future.delayed(Duration(seconds: 1));

    final landmark = await LandmarkService.getNearestLandmark(tappedPosition);
    if (landmark != null) {
      setState(() {
        pinnedLocation = landmark['location'];
        landmarkName = landmark['name'];
        // addressNotifier.value = "${landmark['name']}\n${landmark['address']}";
        final selectedLoc = SelectedLocation(
            "${landmark['name']}\n${landmark['address']}", tappedPosition);
        Navigator.pop(context, selectedLoc);
      });
    } else {
      final location = await reverseGeocode(tappedPosition);
      addressNotifier.value = location?.address ?? "Unable to find location";
    }
    setState(() => isFindingLandmark = false);
  }

  Future<void> updateLocation() async {
    if (!isMapReady) return;

    final visibleRegion = await mapController.getVisibleRegion();
    final center = LatLng(
      (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2,
      (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) /
          2,
    );

    final location = await reverseGeocode(center);
    if (location != null) {
      addressNotifier.value = location.address;
      setState(() {
        pinnedLocation = center;
        selectedPinnedLocation = location;
      });
    }
  }

  // try natin gumawa ng method para mas accurate yung sentro ng map
  Future<LatLng> getMapCenter() async {
    if (!isMapReady) {
      return currentLocation ?? const LatLng(14.617494, 120.971770);
    }

    final visibleRegion = await mapController.getVisibleRegion();
    // calculate natin yung exact center
    final centerLat =
        (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) /
            2;
    final centerLng = (visibleRegion.northeast.longitude +
            visibleRegion.southwest.longitude) /
        2;

    return LatLng(centerLat, centerLng);
  }

  // papalitan ko yung snapToLandmark method kasi ang panget gago
  // try ko yung sa implementation ng Grab
  Future<void> fetchLocationAtCenter() async {
    if (!isMapReady) {
      debugPrint("Map not ready");
      return;
    }

    // Debounce location fetching
    _memoryManager.debounce(() async {
      try {
        setState(() {
          isFindingLandmark = true;
          addressNotifier.value = "Searching...";
        });

        final center = await getMapCenter();
        final cacheKey = 'location_${center.latitude}_${center.longitude}';

        // Check cache first
        final cachedLocation = _memoryManager.getFromCache(cacheKey);
        if (cachedLocation != null && mounted) {
          setState(() {
            landmarkName = cachedLocation['name'];
            addressNotifier.value = cachedLocation['address'];
            pinnedLocation = center;
            isFindingLandmark = false;
          });
          return;
        }

        // If not in cache, fetch from API
        final landmark = await LandmarkService.getNearestLandmark(center);
        if (landmark != null && mounted) {
          final locationData = {
            'name': landmark['name'],
            'address': "${landmark['name']}\n${landmark['address']}"
          };

          // Cache the result
          _memoryManager.addToCache(cacheKey, locationData);

          setState(() {
            landmarkName = landmark['name'];
            addressNotifier.value = locationData['address']!;
            pinnedLocation = center;
            isFindingLandmark = false;
          });
          return;
        }

        // Fallback to reverse geocoding
        final location = await reverseGeocode(center);
        if (mounted) {
          final address = location?.address ?? "Unable to find location";
          _memoryManager.addToCache(cacheKey, {'name': '', 'address': address});

          setState(() {
            addressNotifier.value = address;
            isFindingLandmark = false;
          });
        }
      } catch (e) {
        debugPrint("Error fetching location: $e");
        if (mounted) {
          setState(() {
            addressNotifier.value = "Error finding location";
            isFindingLandmark = false;
          });
        }
      }
    }, const Duration(milliseconds: 500), 'fetch_location');
  }

  Future<void> getCurrentLocation() async {
    try {
      final LocationData locationData = await locationService.getLocation();
      final newLocation = LatLng(
        locationData.latitude!,
        locationData.longitude!,
      );

      // Cache the location
      _memoryManager.addToCache(LAST_LOCATION_KEY, {
        'latitude': newLocation.latitude,
        'longitude': newLocation.longitude,
      });

      if (mounted) {
        setState(() {
          pinnedLocation = newLocation;
          currentLocation = newLocation;
          isLoading = false;
        });
      }

      if (isMapReady) {
        // Throttle camera updates
        _memoryManager.throttle(() async {
          await mapController.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: newLocation, zoom: 15),
            ),
          );
          fetchLocationAtCenter();
        }, const Duration(milliseconds: 300), 'camera_update');
      }
    } catch (e) {
      debugPrint("Error in getCurrentLocation: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // reverseGeocode method from locationSearchScreen.dart
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
      if (data['status'] == 'REQUEST_DENIED') return null;

      if (data['results'] != null && data['results'].isNotEmpty) {
        return SelectedLocation(
            data['results'][0]['formatted_address'], position);
      }
    } catch (e) {
      debugPrint("Error in reverseGeocode: $e");
    }
    return null;
  }

  Future<void> animateToCurrentLocation() async {
    if (!isMapReady) return;

    try {
      // use natin yung existing location if available

      if (currentLocation != null) {
        await mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: currentLocation!, zoom: 17),
          ),
        );
        return;
      }

      final locationData = await locationService.getLocation();
      final currentLatLng =
          LatLng(locationData.latitude!, locationData.longitude!);

      await mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLatLng,
            zoom: 17,
          ),
        ),
      );

      // Only update the current location marker without reloading the screen
      if (mounted) {
        setState(() => currentLocation = currentLatLng);
      }
    } catch (e) {
      debugPrint("Error in animateToCurrentLocation: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final responsivePadding = screenWidth * 0.02;

    // measuring container height
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (bottomContainerKey.currentContext != null) {
        final RenderBox box =
            bottomContainerKey.currentContext!.findRenderObject() as RenderBox;
        final newHeight = box.size.height;
        if (newHeight != bottomContainerHeight) {
          setState(() => bottomContainerHeight = newHeight);
        }
      }
    });

    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF067837),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            style: _currentMapStyle,
            padding: EdgeInsets.only(
              bottom: bottomContainerHeight +
                  MediaQuery.of(context).size.height * 0.01,
            ),
            onMapCreated: onMapCreated,
            onTap: (position) {
              mapController.animateCamera(
                CameraUpdate.newLatLng(position),
              );
            },
            initialCameraPosition: CameraPosition(
              target: currentLocation ?? const LatLng(14.617494, 120.971770),
              zoom: 15,
            ),
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            indoorViewEnabled: false,
            myLocationButtonEnabled: true,
            onCameraMove: (position) {
              if (isFindingLandmark) {
                setState(() => isFindingLandmark = false);
              }
            },
            onCameraIdle: () {
              fetchLocationAtCenter();
            },
          ),
          Center(
            child: Container(
              margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.15),
              child: Icon(
                Icons.location_pin,
                color: Color(0xFFFFCE21),
                size: 48,
              ),
            ),
          ),
          // Back button - now rendered on top of the map
          Positioned(
            top: MediaQuery.of(context).size.height * 0.07,
            left: MediaQuery.of(context).size.width * 0.03,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF121212),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212),
                ),
              ),
            ),
          ),
          Positioned(
            right: responsivePadding,
            bottom: bottomContainerHeight + fabVerticalSpacing,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                LocationFAB(
                  heroTag: "pinLocationFAB",
                  onPressed: animateToCurrentLocation,
                  icon: Icons.gps_fixed,
                  iconColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF00E865)
                      : const Color(0xFF00CC58),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFF5F5F5),
                  buttonSize: screenWidth * 0.12,
                  iconSize: screenWidth * 0.06,
                ),
                SizedBox(height: fabVerticalSpacing),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child:
                pinnedLocationContainer(screenWidth, key: bottomContainerKey),
          ),
        ],
      ),
    );
  }

  Widget pinnedLocationContainer(double screenWidth, {Key? key}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: key,
      width: screenWidth,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black12 : const Color(0xFFD2D2D2),
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildLocationInfo(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // check kapag nagsesearch pa rin
              if (isFindingLandmark) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text("Still finding location, please wait a moment..."),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              // check kapag may valid location na mapapass back
              if (pinnedLocation != null &&
                  addressNotifier.value.isNotEmpty &&
                  addressNotifier.value != "Searching..." &&
                  addressNotifier.value != "Searching for location..." &&
                  addressNotifier.value != "Unable to find location") {
                Navigator.pop(context,
                    SelectedLocation(addressNotifier.value, pinnedLocation!));
              } else if (pinnedLocation != null) {
                // may coordinates pero walang readable address
                // use na lang ng generic address pukingina niyan
                Navigator.pop(context,
                    SelectedLocation(addressNotifier.value, pinnedLocation!));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'Unable to confirm this location. Please try a different area.'),
                  duration: Duration(seconds: 3),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF067837),
              minimumSize: Size(double.infinity, 50),
            ),
            child: Text(
              'Confirm ${widget.isPickup ? 'Pick-up' : 'Drop-off'} Location',
              style: TextStyle(
                color: const Color(0xFFF5F5F5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget buildLocationInfo() {
    return ValueListenableBuilder(
      valueListenable: addressNotifier,
      builder: (context, address, _) {
        final bool isSearching = address == "Searching..." ||
            address == "Searching for location..." ||
            isFindingLandmark;

        final parts = address.isNotEmpty ? splitLocation(address) : ['', ''];
        final landmark = parts[0];
        final addressDetail = parts[1];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SvgPicture.asset(
              "assets/svg/pindropoff.svg",
              width: 24,
              height: 24,
            ),
            SizedBox(width: 14),
            Expanded(
              child: isSearching
                  ? Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF067837),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Finding location...",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Inter',
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFF5F5F5)
                                    : const Color(0xFF121212),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          landmark.isNotEmpty
                              ? landmark
                              : "Move the map to select a location",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFF5F5F5)
                                    : const Color(0xFF121212),
                          ),
                        ),
                        if (addressDetail.isNotEmpty)
                          Text(
                            addressDetail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Inter',
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFFAAAAAA)
                                  : const Color(0xFF515151),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
