import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pasada_passenger_app/location/locationButton.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/models/stop.dart';
import 'package:pasada_passenger_app/network/networkUtilities.dart';
import 'package:pasada_passenger_app/screens/mapScreen.dart';
import 'package:pasada_passenger_app/services/allowedStopsServices.dart';
import 'package:pasada_passenger_app/services/landmarkService.dart';
import 'package:pasada_passenger_app/utils/memory_manager.dart';
import 'package:pasada_passenger_app/widgets/responsive_dialogs.dart';

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
      home: PinLocationStateful(
        locationType: 'pickup',
        onLocationSelected: (location) {
          debugPrint('Location selected: ${location.address}');
        },
      ),
      routes: <String, WidgetBuilder>{},
    );
  }
}

class PinLocationStateful extends StatefulWidget {
  final String locationType; // 'pickup' or 'dropoff'
  final Function(SelectedLocation) onLocationSelected;
  final List<LatLng>? routePolyline;
  final LatLng? initialLocation;
  final LatLng? pickupLocation; // Add this to know the pickup location
  final Map<String, dynamic>? selectedRoute;

  const PinLocationStateful({
    super.key,
    required this.locationType,
    required this.onLocationSelected,
    this.routePolyline,
    this.initialLocation,
    this.pickupLocation,
    this.selectedRoute,
  });

  @override
  State<PinLocationStateful> createState() => _PinLocationStatefulState();
}

class _PinLocationStatefulState extends State<PinLocationStateful> {
  final MemoryManager _memoryManager = MemoryManager();
  static const String MAP_CACHE_KEY = 'map_state';
  static const String LAST_LOCATION_KEY = 'last_known_location';
  static const String MAP_STYLE_KEY = 'map_style';
  bool isLocationValid = false;

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

  // Add this variable to store the GoogleMapController
  GoogleMapController? _mapController;

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

    // Don't access Theme.of(context) here
    _currentMapStyle = cachedStyle ?? '';

    if (cachedStyle == null) {
      _memoryManager.addToCache(MAP_STYLE_KEY, '');
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
    _mapController = controller;
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
    // Move theme-dependent code here
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final newStyle = isDarkMode ? darkMapStyle : '';
    if (_currentMapStyle != newStyle) {
      setState(() {
        _currentMapStyle = newStyle;
        if (_mapController != null) {
          // Use GoogleMap.style property instead of deprecated setMapStyle
          // This will be applied when the map is rebuilt
          _currentMapStyle = newStyle;
        }
      });

      // Update cache if needed
      _memoryManager.addToCache(MAP_STYLE_KEY, newStyle);
    }
  }

  void handleMapTap(LatLng tappedPosition) async {
    // Check if the tapped position is near the polyline
    bool isNearRoute = true;
    if (widget.routePolyline != null) {
      isNearRoute = isPointNearPolyline(tappedPosition, 100);
    }

    // Check if the selection follows route direction
    bool isValidDirection = await validateRouteDirection(tappedPosition);

    setState(() {
      isLocationValid = isNearRoute && isValidDirection;
    });

    if (!isNearRoute) {
      Fluttertoast.showToast(
        msg: "Please select a location along the route",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    if (!isValidDirection) {
      return; // Toast already shown in validateRouteDirection
    }

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
        // Navigator.pop(context, selectedLoc);
        widget.onLocationSelected(selectedLoc);
      });
    } else {
      final location = await reverseGeocode(tappedPosition);
      addressNotifier.value = location?.address ?? "Unable to find location";
    }
    setState(() => isFindingLandmark = false);
  }

  Future<void> checkDistanceAndReturn(SelectedLocation selectedLocation) async {
    if (currentLocation == null) {
      Navigator.pop(context, selectedLocation);
      return;
    }

    final distance = selectedLocation.distanceFrom(LatLng(
      currentLocation!.latitude,
      currentLocation!.longitude,
    ));

    if (distance > 1.0) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          return ResponsiveDialog(
            title: 'Distance Warning',
            content: Text(
              'The selected ${widget.locationType == 'pickup' ? 'pick-up' : 'drop-off'} location is quite far from your current location. Do you want to continue?',
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
                    side: const BorderSide(color: Color(0xFFD7481D), width: 3),
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
          );
        },
      );
      if (proceed ?? false) {
        Navigator.pop(context, selectedLocation);
      }
    } else {
      Navigator.pop(context, selectedLocation);
    }
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

        bool isNearRoute = true;
        if (widget.routePolyline != null) {
          isNearRoute = isPointNearPolyline(center, 100);
        }

        setState(() {
          isLocationValid = isNearRoute;
        });

        if (!isNearRoute) {
          setState(() {
            addressNotifier.value = "Please select a location along the route";
            isFindingLandmark = false;
          });
          return;
        }

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
            isLocationValid = false;
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

  Future<bool> validateRouteDirection(LatLng newLocation) async {
    // If this is a pickup location or we don't have route info, no validation needed
    if (widget.locationType != 'dropoff' || widget.selectedRoute == null) {
      return true;
    }

    if (widget.pickupLocation != null) {
      final int routeId = widget.selectedRoute!['officialroute_id'] ?? 0;
      final stops = await StopsService().getStopsForRoute(routeId);

      // Find the closest stops to our pickup and potential dropoff
      Stop? closestPickupStop;
      Stop? closestDropoffStop;
      double minPickupDist = double.infinity;
      double minDropoffDist = double.infinity;

      for (var stop in stops) {
        // Calculate distance to pickup
        final pickupDist = calculateDistance(
            LatLng(stop.coordinates.latitude, stop.coordinates.longitude),
            widget.pickupLocation!);

        // Calculate distance to potential dropoff
        final dropoffDist = calculateDistance(
            LatLng(stop.coordinates.latitude, stop.coordinates.longitude),
            newLocation);

        if (pickupDist < minPickupDist) {
          minPickupDist = pickupDist;
          closestPickupStop = stop;
        }

        if (dropoffDist < minDropoffDist) {
          minDropoffDist = dropoffDist;
          closestDropoffStop = stop;
        }
      }

      // Check if dropoff comes after pickup in the route
      if (closestPickupStop != null &&
          closestDropoffStop != null &&
          closestDropoffStop.order <= closestPickupStop.order) {
        Fluttertoast.showToast(
          msg:
              'Invalid selection: drop-off must be after pick-up on this route',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
        );
        return false;
      }
    }

    return true;
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

  // Calculate distance from point to line segment
  double distanceToLineSegment(LatLng point, LatLng start, LatLng end) {
    // Convert to cartesian coordinates for simplicity
    final double x = point.latitude;
    final double y = point.longitude;
    final double x1 = start.latitude;
    final double y1 = start.longitude;
    final double x2 = end.latitude;
    final double y2 = end.longitude;

    // Calculate squared length of segment
    final double l2 = (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1);
    if (l2 == 0) {
      // If segment is a point, return distance to that point
      return sqrt(pow(x - x1, 2) + pow(y - y1, 2));
    }

    // Calculate projection of point onto line
    final double t =
        max(0, min(1, ((x - x1) * (x2 - x1) + (y - y1) * (y2 - y1)) / l2));

    // Calculate nearest point on line segment
    final double projX = x1 + t * (x2 - x1);
    final double projY = y1 + t * (y2 - y1);

    // Return distance to nearest point
    return sqrt(pow(x - projX, 2) + pow(y - projY, 2)) *
        111000; // Convert to meters (approx)
  }

  // Helper method to calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // in meters

    // Convert latitude and longitude from degrees to radians
    final double lat1 = point1.latitude * (pi / 180);
    final double lon1 = point1.longitude * (pi / 180);
    final double lat2 = point2.latitude * (pi / 180);
    final double lon2 = point2.longitude * (pi / 180);

    // Haversine formula
    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Distance in meters
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
          RepaintBoundary(
            child: GoogleMap(
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
              polylines: widget.routePolyline != null
                  ? {
                      Polyline(
                        polylineId: const PolylineId('route_polyline'),
                        points: widget.routePolyline!,
                        color: const Color(0xFF067837),
                        width: 5,
                      )
                    }
                  : <Polyline>{},
            ),
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
            onPressed: (isLocationValid &&
                    pinnedLocation != null &&
                    addressNotifier.value.isNotEmpty &&
                    addressNotifier.value != "Searching..." &&
                    addressNotifier.value != "Searching for location..." &&
                    addressNotifier.value != "Unable to find location" &&
                    addressNotifier.value !=
                        "Please select a location along the route" &&
                    !isFindingLandmark)
                ? () {
                    final selectedLoc = SelectedLocation(
                        addressNotifier.value, pinnedLocation!);
                    widget.onLocationSelected(selectedLoc);
                  }
                : null, // Disable button if location is invalid
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF067837),
              disabledBackgroundColor: const Color(0xFFD3D3D3),
              minimumSize: Size(double.infinity, 50),
            ),
            child: Text(
              'Confirm ${widget.locationType == 'pickup' ? 'Pick-up' : 'Drop-off'} Location',
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

        final bool isInvalidLocation =
            address == "Please select a location along the route" ||
                !isLocationValid;

        final parts = address.isNotEmpty ? splitLocation(address) : ['', ''];
        final landmark = parts[0];
        final addressDetail = parts[1];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Change to warning icon when location is invalid
            isInvalidLocation
                ? Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 24,
                  )
                : SvgPicture.asset(
                    "assets/svg/pindropoff.svg",
                    width: 24,
                    height: 24,
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: isSearching
                  ? Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF00E865)
                                    : const Color(0xFF067837),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Searching for location...",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
                          isInvalidLocation
                              ? "Invalid Location"
                              : (landmark.isNotEmpty
                                  ? landmark
                                  : "Move the map to select a location"),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                            color: isInvalidLocation
                                ? Colors.red
                                : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFFF5F5F5)
                                    : const Color(0xFF121212),
                          ),
                        ),
                        Text(
                          isInvalidLocation
                              ? "Please select a location along the route"
                              : (addressDetail.isNotEmpty ? addressDetail : ""),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Inter',
                            color: isInvalidLocation
                                ? Colors.redAccent
                                : Theme.of(context).brightness ==
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
