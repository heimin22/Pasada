// ignore_for_file: file_names

import 'dart:async';
import 'dart:math';
// import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/widgets/responsive_dialogs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pasada_passenger_app/utils/map_utils.dart';
import 'package:pasada_passenger_app/services/map_location_service.dart';
import 'package:pasada_passenger_app/services/fare_service.dart';
import 'package:pasada_passenger_app/services/ride_service.dart';
import 'package:pasada_passenger_app/services/polyline_service.dart';
import 'package:pasada_passenger_app/utils/map_camera_utils.dart';

class MapScreen extends StatefulWidget {
  final LatLng? pickUpLocation;
  final LatLng? dropOffLocation;
  final double bottomPadding;
  final Function(String)? onEtaUpdated;
  final Function(double)? onFareUpdated;
  final Function(LatLng)? onLocationUpdated;
  final Map<String, dynamic>? selectedRoute;
  final List<LatLng>? routePolyline;

  const MapScreen({
    super.key,
    this.pickUpLocation,
    this.dropOffLocation,
    this.bottomPadding = 0.07,
    this.onEtaUpdated,
    this.onFareUpdated,
    this.onLocationUpdated,
    this.selectedRoute,
    this.routePolyline,
  });

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final Completer<GoogleMapController> mapController = Completer();
  LatLng? currentLocation; // Location Data
  final Location location = Location();
  final String apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;
  StreamSubscription<LocationData>? locationSubscription;

  bool isScreenActive = true;

  @override
  bool get wantKeepAlive => true;

  // Markers para sa pick-up and drop-off
  Marker? selectedPickupMarker;
  Marker? selectedDropOffMarker;

  // polylines sa mapa nigga
  Map<PolylineId, Polyline> polylines = {};

  // mauupdate ito kapag nakapagsearch na ng location si user
  LatLng? selectedPickupLatLng;
  LatLng? selectedDropOffLatLng;

  // null muna ito until mafetch yung current location
  LatLng? currentPosition;

  // animation ng location to kapag pinindot yung Location FAB
  // animation flag
  bool isAnimatingLocation = false;

  // ETA text lang naman to nigga
  String? etaText;

  // Class variable for location initialization
  bool isLocationInitialized = false;
  bool errorDialogVisible = false;

  GoogleMapController? _mapController;

  bool showRouteEndIndicator = false;
  String routeEndName = '';

  Map<MarkerId, Marker> markers = {};

  double fareAmount = 0.0;

  // Field to store driver location and bus icon
  LatLng? driverLocation;
  late BitmapDescriptor busIcon;
  late BitmapDescriptor pickupIcon;
  late BitmapDescriptor dropoffIcon;

  // PolylineId for the driver's live route
  static const PolylineId driverRoutePolylineId =
      PolylineId('driver_route_live');

  late final MapLocationService _locationService;
  late final RideService _rideService;

  // Override methods
  /// state of the app
  @override
  void initState() {
    super.initState();
    // Load custom bus icon for driver marker
    _loadBusIcon();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Load last known location from cache for faster initial display and center map
        (() async {
          final prefs = await SharedPreferences.getInstance();
          final lat = prefs.getDouble('last_latitude');
          final lng = prefs.getDouble('last_longitude');
          if (lat != null && lng != null && mounted) {
            setState(() {
              currentLocation = LatLng(lat, lng);
            });
            final controller = await mapController.future;
            await controller.animateCamera(
                CameraUpdate.newLatLngZoom(currentLocation!, 17.0));
            pulseCurrentLocationMarker();
          }
          // Now fetch fresh location updates
          await initializeLocation();
          handleLocationUpdates();
        })();
        // Initialize ride service
        _rideService = RideService();
        // Initialize and subscribe to device location
        _locationService.initialize((loc) {
          if (mounted) {
            setState(() => currentLocation = loc);
            widget.onLocationUpdated?.call(loc);
          }
        });
      }
    });
  }

  /// disposing of functions
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    locationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // here once the app is opened,
    // intiate the location and get the location updates
    isScreenActive = state == AppLifecycleState.resumed;
    if (isScreenActive) {
      handleLocationUpdates();
    } else {
      locationSubscription?.pause();
    }
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    // get the location from previous widget
    // then call the handleLocationUpdates
    super.didUpdateWidget(oldWidget);
    if (widget.pickUpLocation != oldWidget.pickUpLocation ||
        widget.dropOffLocation != oldWidget.dropOffLocation) {
      handleLocationUpdates();
    }
  }

  void calculateRoute() {
    //  make sure there's a null check before placing polylines
    if (selectedPickupLatLng == null || selectedDropOffLatLng == null) {
      showError('Select both locations first.');
      return;
    }
    // generate the polylines calling selectedPickupLatlng and selectedDropOffLatLng
    renderRouteBetween(selectedPickupLatLng!, selectedDropOffLatLng!);
  }

  // handle yung location updates for the previous widget to generate polylines
  Future<void> handleLocationUpdates() async {
    // Cancel previous subscription to avoid duplicate callbacks
    locationSubscription?.cancel();
    // Subscribe to location updates for map and routing
    locationSubscription = location.onLocationChanged
        .where((data) => data.latitude != null && data.longitude != null)
        .listen((newLocation) {
      if (mounted && isScreenActive) {
        setState(() => currentLocation =
            LatLng(newLocation.latitude!, newLocation.longitude!));
        widget.onLocationUpdated?.call(currentLocation!);
      }
    });
    if (widget.pickUpLocation != null && widget.dropOffLocation != null) {
      debugPrint('MapScreen - Both pickup and dropoff locations are set');
      final polyService = PolylineService();
      if (widget.routePolyline?.isNotEmpty == true) {
        debugPrint('MapScreen - Rendering official route segment');
        final segment = polyService.generateAlongRoute(
          widget.pickUpLocation!,
          widget.dropOffLocation!,
          widget.routePolyline!,
        );
        animateRouteDrawing(
          const PolylineId('route'),
          segment,
          const Color(0xFFFFCE21),
          8,
        );
        // Calculate fare based on the segment
        final fare = FareService.calculateFareForPolyline(segment);
        fareAmount = fare;
        if (widget.onFareUpdated != null) widget.onFareUpdated!(fare);
        // Zoom camera to the segment bounds
        _moveCameraToRoute(
            segment, widget.pickUpLocation!, widget.dropOffLocation!);
      } else {
        debugPrint('MapScreen - Rendering direct route');
        await renderRouteBetween(
          widget.pickUpLocation!,
          widget.dropOffLocation!,
        );
      }
    } else {
      debugPrint('MapScreen - Missing pickup or dropoff location');
    }
  }

  // animate yung current location marker
  void pulseCurrentLocationMarker() {
    if (!mounted) return;
    setState(() => isAnimatingLocation = true);

    // reset ng animation after ng delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => isAnimatingLocation = false);
      }
    });
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
          title: 'Distance warning',
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
        ),
      );
      return proceed ?? false;
    }

    return true;
  }

  Future<void> handleSearchLocationSelection(
      SelectedLocation location, bool isPickup) async {
    if (isPickup) {
      final shouldProceed = await checkPickupDistance(location.coordinates);
      if (!shouldProceed) return;
    }
    if (isPickup) {
      setState(() {
        selectedPickupLatLng = location.coordinates;
        // Update any other necessary pickup-related state
      });
    } else {
      setState(() {
        selectedDropOffLatLng = location.coordinates;
        // Update any other necessary dropoff-related state
      });
    }
  }

  // replace ko yung initLocation ko ng ganito
  Future<void> initializeLocation() async {
    if (isLocationInitialized || !mounted) return;

    // service check
    final serviceReady = await checkLocationService();
    if (!serviceReady) return;

    // permission check
    final permissionGranted = await verifyLocationPermissions();
    if (!permissionGranted) return;

    // fetch updates
    await getLocationUpdates();
    isLocationInitialized = true;
  }

  // service status check helper
  Future<bool> checkLocationService() async {
    try {
      // serviceEnabled variable to check the location services
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        // if not enabled then request for the activation
        serviceEnabled = await location.requestService();
        if (!serviceEnabled && mounted) {
          showLocationErrorDialog();
          return false;
        }
      }
      return true;
    } on PlatformException catch (e) {
      if (mounted) showError('Service Error: ${e.message ?? 'Unknown'}');
      return false;
    }
  }

  Future<bool> verifyLocationPermissions() async {
    final status = await location.hasPermission();
    if (status == PermissionStatus.granted) return true;

    final newStatus = await location.requestPermission();
    if (newStatus != PermissionStatus.granted && mounted) {
      showAlertDialog(
        'Permission Required',
        'Enable location permissions device settings',
      );
      return false;
    }
    return true;
  }

  // animate yung camera papunta sa current location ng user
  Future<void> animateToLocation(LatLng target) async {
    final GoogleMapController controller = await mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: target,
        zoom: 17.0,
      )),
    );
    pulseCurrentLocationMarker();
  }

  Future<void> getLocationUpdates() async {
    try {
      // kuha ng current location
      LocationData locationData = await location.getLocation();
      if (!mounted) return;
      // Cache this location for next app start
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_latitude', locationData.latitude!);
      await prefs.setDouble('last_longitude', locationData.longitude!);

      setState(() => currentLocation =
          LatLng(locationData.latitude!, locationData.longitude!));
      widget.onLocationUpdated?.call(currentLocation!);

      final controller = await mapController.future;
      await controller
          .animateCamera(CameraUpdate.newLatLngZoom(currentLocation!, 17.0));
      pulseCurrentLocationMarker();

      // Cancel previous subscription to avoid duplicate callbacks
      locationSubscription?.cancel();
      locationSubscription = location.onLocationChanged
          .where((data) => data.latitude != null && data.longitude != null)
          .listen((newLocation) {
        if (!mounted) return;
        setState(() => currentLocation =
            LatLng(newLocation.latitude!, newLocation.longitude!));
      });
    } catch (e) {
      // showError('An error occurred while fetching the location.');
      if (mounted) showError('Location Error: ${e.toString()}');
    }
  }

  // ito yung method para sa pick-up and drop-off location
  Future<void> updateLocations(
      {LatLng? pickup, LatLng? dropoff, bool skipDistanceCheck = false}) async {
    if (pickup != null) {
      if (!skipDistanceCheck) {
        final shouldProceed = await checkPickupDistance(pickup);
        if (!shouldProceed) return;
      }
      selectedPickupLatLng = pickup;
    }

    if (dropoff != null) selectedDropOffLatLng = dropoff;

    if (selectedPickupLatLng != null && selectedDropOffLatLng != null) {
      // Generate and draw route using PolylineService
      final polyService = PolylineService();
      if (widget.routePolyline?.isNotEmpty == true) {
        final segment = polyService.generateAlongRoute(
          selectedPickupLatLng!,
          selectedDropOffLatLng!,
          widget.routePolyline!,
        );
        animateRouteDrawing(
          const PolylineId('route'),
          segment,
          const Color(0xFFFFCE21),
          8,
        );
      } else {
        // Direct route fallback
        await renderRouteBetween(
          selectedPickupLatLng!,
          selectedDropOffLatLng!,
        );
      }
    }
  }

  Future<bool> checkNetworkConnection() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      showError('No internet connection');
      return false;
    }
    return true;
  }

  // Replaced inline routing logic with service-based implementations
  Future<void> renderRouteBetween(LatLng start, LatLng destination,
      {bool updateFare = true}) async {
    final polyService = PolylineService();
    final List<LatLng> polylineCoordinates =
        await polyService.generateBetween(start, destination);
    if (!mounted || polylineCoordinates.isEmpty) return;
    final double routeDistance =
        await polyService.calculateRouteDistanceKm(start, destination);
    final double fare = FareService.calculateFare(routeDistance);
    if (updateFare) {
      fareAmount = fare;
      widget.onFareUpdated?.call(fare);
    }
    animateRouteDrawing(
      const PolylineId('route'),
      polylineCoordinates,
      const Color.fromARGB(255, 4, 197, 88),
      8,
    );
    _moveCameraToRoute(polylineCoordinates, start, destination);
  }

  Future<void> _moveCameraToRoute(List<LatLng> polylineCoordinates,
      LatLng start, LatLng destination) async {
    final controller = await mapController.future;
    await moveCameraToBounds(controller, polylineCoordinates,
        padding: 0.01, boundPadding: 20);
  }

  // Expose camera bounds zoom for external callers
  Future<void> zoomToBounds(List<LatLng> polylineCoordinates) async {
    if (polylineCoordinates.isEmpty) return;
    final LatLng start = polylineCoordinates.first;
    final LatLng end = polylineCoordinates.last;
    await _moveCameraToRoute(polylineCoordinates, start, end);
  }

  void onMapCreated(GoogleMapController controller) {
    mapController.complete(controller);
  }

  // Add this method to update map style
  void _updateMapStyle() {
    if (_mapController == null) return;
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    _updateMapStyle();
  }

  // helper function for showing alert dialogs to reduce repetition
  void showAlertDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: title,
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // specific error dialog using the helper function
  void showLocationErrorDialog() {
    if (errorDialogVisible) return;
    errorDialogVisible = true;

    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Location Error',
        content: const Text('Enable location services to continue.'),
        actions: [
          TextButton(
            onPressed: () {
              errorDialogVisible = false;
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              errorDialogVisible = false;
              Navigator.pop(context);
              await initializeLocation();
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  // generic error dialog using the helper function
  void showError(String message) {
    showAlertDialog('Error', message);
  }

  // Load the bus.svg asset as a BitmapDescriptor
  Future<void> _loadBusIcon() async {
    busIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(48, 48)),
      'assets/png/bus.png',
    );
    pickupIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(48, 48)),
      'assets/png/pin_pickup.png',
    );
    dropoffIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(48, 48)),
      'assets/png/pin_dropoff.png',
    );
  }

  // Update driver marker and draw road-following polyline to pickup/dropoff
  Future<void> updateDriverLocation(LatLng location, String rideStatus) async {
    if (!mounted) return;
    setState(() {
      driverLocation = location;
      // Update driver marker
      final driverMarkerId = MarkerId('driver');
      markers[driverMarkerId] = Marker(
        markerId: driverMarkerId,
        position: driverLocation!,
        icon: busIcon,
      );
      // Remove any existing pickup->dropoff polylines
      polylines.remove(const PolylineId('route'));
      polylines.remove(const PolylineId('route_path'));
      // When accepted, remove end-of-route pin and indicator
      if (rideStatus == 'accepted') {
        markers.remove(const MarkerId('route_destination'));
        showRouteEndIndicator = false;
      }
    });

    // Generate and draw driver route polyline for accepted or ongoing rides
    List<LatLng> route = [];
    if (rideStatus == 'accepted') {
      route = await _rideService.getRoute(location, widget.pickUpLocation);
    } else if (rideStatus == 'ongoing') {
      route = await _rideService.getRoute(location, widget.dropOffLocation);
    }
    if (route.isNotEmpty) {
      animateRouteDrawing(
        const PolylineId('driver_route_live'),
        route,
        const Color.fromARGB(255, 10, 179, 83),
        8,
      );
      // Animate camera to include driver and target location
      final controller = await mapController.future;
      await moveCameraToBounds(controller, route,
          padding: 0.01, boundPadding: 20.0);
    }
  }

  // Helper to generate and update polyline for driver route without clearing other polylines
  // Driver route generation is handled by RideService; remove inline implementation.

  Set<Marker> buildMarkers() {
    final markerSet = <Marker>{};

    // Add pickup marker
    if (widget.pickUpLocation != null) {
      final pickupMarkerId = MarkerId('pickup');
      markers[pickupMarkerId] = Marker(
        markerId: pickupMarkerId,
        position: widget.pickUpLocation!,
        icon: pickupIcon,
      );
    }

    // Add dropoff marker
    if (widget.dropOffLocation != null) {
      final dropoffMarkerId = MarkerId('dropoff');
      markers[dropoffMarkerId] = Marker(
        markerId: dropoffMarkerId,
        position: widget.dropOffLocation!,
        icon: dropoffIcon,
      );
    }

    // Add driver marker
    if (driverLocation != null) {
      final driverMarkerId = MarkerId('driver');
      markers[driverMarkerId] = Marker(
        markerId: driverMarkerId,
        position: driverLocation!,
        icon: busIcon,
      );
    }

    // Convert map to set
    markerSet.addAll(markers.values);
    return markerSet;
  }

  // Add this method to find the nearest point on the route polyline
  LatLng findNearestPointOnRoute(LatLng point, List<LatLng> routePolyline) {
    if (routePolyline.isEmpty) return point;

    double minDistance = double.infinity;
    LatLng nearestPoint = routePolyline.first;

    for (int i = 0; i < routePolyline.length - 1; i++) {
      final LatLng start = routePolyline[i];
      final LatLng end = routePolyline[i + 1];

      // Find the nearest point on this segment
      final LatLng nearestOnSegment =
          findNearestPointOnSegment(point, start, end);
      final double distance = calculateDistance(point, nearestOnSegment);

      if (distance < minDistance) {
        minDistance = distance;
        nearestPoint = nearestOnSegment;
      }
    }

    return nearestPoint;
  }

  // Helper method to find nearest point on a line segment
  LatLng findNearestPointOnSegment(LatLng point, LatLng start, LatLng end) {
    final double x = point.latitude;
    final double y = point.longitude;
    final double x1 = start.latitude;
    final double y1 = start.longitude;
    final double x2 = end.latitude;
    final double y2 = end.longitude;

    // Calculate squared length of segment
    final double l2 = (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1);
    if (l2 == 0) return start; // If segment is a point, return that point

    // Calculate projection of point onto line
    final double t =
        max(0, min(1, ((x - x1) * (x2 - x1) + (y - y1) * (y2 - y1)) / l2));

    // Calculate nearest point on line segment
    final double projX = x1 + t * (x2 - x1);
    final double projY = y1 + t * (y2 - y1);

    return LatLng(projX, projY);
  }

  // Helper method to calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    return calculateDistanceKm(point1, point2);
  }

  // Helper to animate drawing a polyline point-by-point
  void animateRouteDrawing(
      PolylineId id, List<LatLng> fullRoute, Color color, int width) {
    // Cancel any existing polyline with this id
    polylines.remove(id);
    int count = 0;
    final total = fullRoute.length;
    Timer.periodic(const Duration(milliseconds: 26), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      count += 2;
      final int currentCount = count.clamp(0, total);
      final segment = fullRoute.sublist(0, currentCount);
      setState(() {
        polylines[id] = Polyline(
          polylineId: id,
          points: segment,
          color: color,
          width: width,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        );
      });
      if (count >= total) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isLocationInitialized) {
        initializeLocation();
      }
    });

    return Scaffold(
      body: RepaintBoundary(
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                mapController.complete(controller);
              },
              style: isDarkMode
                  ? '''[
        {
          "elementType": "geometry",
          "stylers": [{"color": "#1f2c4d"}]
        },
        {
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#8ec3b9"}]
        },
        {
          "elementType": "labels.text.stroke",
          "stylers": [{"color": "#1a3646"}]
        },
        {
          "featureType": "administrative.country",
          "elementType": "geometry.stroke",
          "stylers": [{"color": "#4e4e4e"}]
        },
        {
          "featureType": "administrative.land_parcel",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#64779e"}]
        },
        {
          "featureType": "poi",
          "elementType": "geometry",
          "stylers": [{"color": "#283d6a"}]
        },
        {
          "featureType": "poi",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#6f9ba5"}]
        },
        {
          "featureType": "poi.park",
          "elementType": "geometry.fill",
          "stylers": [{"color": "#023e58"}]
        },
        {
          "featureType": "poi.park",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#3c7680"}]
        },
        {
          "featureType": "road",
          "elementType": "geometry",
          "stylers": [{"color": "#304a7d"}]
        },
        {
          "featureType": "road",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#98a5be"}]
        },
        {
          "featureType": "road",
          "elementType": "labels.text.stroke",
          "stylers": [{"color": "#1f2835"}]
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
      ]'''
                  : '',
              initialCameraPosition: CameraPosition(
                target: currentLocation ?? const LatLng(14.5995, 120.9842),
                zoom: currentLocation != null ? 15.0 : 10.0,
              ),
              markers: buildMarkers(),
              polylines: Set<Polyline>.of(polylines.values),
              padding: EdgeInsets.only(
                bottom: screenHeight * widget.bottomPadding,
                left: screenWidth * 0.04,
              ),
              mapType: MapType.normal,
              buildingsEnabled: false,
              myLocationButtonEnabled: false,
              indoorViewEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: true,
              trafficEnabled: false,
              rotateGesturesEnabled: true,
              myLocationEnabled: currentLocation != null,
            ),
          ],
        ),
      ),
    );
  }

  // Clears all map overlays and selected locations
  void clearAll() {
    setState(() {
      selectedPickupLatLng = null;
      selectedDropOffLatLng = null;
      polylines.clear();
      markers.clear();
      fareAmount = 0.0;
      etaText = null;
    });
  }
}
