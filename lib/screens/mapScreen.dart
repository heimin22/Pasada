import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/utils/map_camera_manager.dart';
import 'package:pasada_passenger_app/utils/map_dialog_manager.dart';
import 'package:pasada_passenger_app/utils/map_directional_bus_manager.dart';
import 'package:pasada_passenger_app/utils/map_driver_animation_manager.dart';
import 'package:pasada_passenger_app/utils/map_driver_tracker.dart';
import 'package:pasada_passenger_app/utils/map_location_manager.dart';
import 'package:pasada_passenger_app/utils/map_marker_manager.dart';
import 'package:pasada_passenger_app/utils/map_polyline_state_manager.dart';
import 'package:pasada_passenger_app/utils/map_route_manager.dart';
import 'package:pasada_passenger_app/utils/map_stable_state_manager.dart';
import 'package:pasada_passenger_app/widgets/skeleton.dart';

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
  LatLng? currentLocation;
  final String apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;

  @override
  bool get wantKeepAlive => true;

  // Manager instances
  late MapLocationManager _locationManager;
  late MapCameraManager _cameraManager;
  late MapRouteManager _routeManager;
  late MapMarkerManager _markerManager;
  late MapDialogManager _dialogManager;
  late MapDriverTracker _driverTracker;
  late MapPolylineStateManager _polylineStateManager;
  late MapDriverAnimationManager _driverAnimationManager;
  late MapDirectionalBusManager _directionalBusManager;
  late MapStableStateManager _stableStateManager;

  // State variables
  LatLng? selectedPickupLatLng;
  LatLng? selectedDropOffLatLng;
  LatLng? driverLocation;
  String? etaText;
  double fareAmount = 0.0;
  bool showRouteEndIndicator = false;
  String routeEndName = '';
  GoogleMapController? _mapController;

  // Override methods
  /// state of the app
  @override
  void initState() {
    super.initState();
    _initializeManagers();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeMapComponents();
      }
    });
  }

  /// Initialize all manager instances
  void _initializeManagers() {
    // Initialize location manager
    _locationManager = MapLocationManager(
      onLocationUpdated: (location) {
        if (mounted) {
          setState(() => currentLocation = location);
          widget.onLocationUpdated?.call(location);
        }
      },
      onError: (error) => _dialogManager.showError(error),
      onLocationPermissionDenied: () =>
          _dialogManager.showLocationPermissionDialog(),
      onLocationServiceDisabled: () => _dialogManager.showLocationErrorDialog(
        onRetry: () => _locationManager.initializeLocation(),
      ),
      onPrePromptLocationPermission: () =>
          _dialogManager.showPrePromptLocationPermission(),
      onPrePromptLocationService: () =>
          _dialogManager.showPrePromptLocationService(),
    );

    // Initialize camera manager
    _cameraManager = MapCameraManager(
      mapController: mapController,
      onAnimationStateChanged: (isAnimating) {
        if (mounted) setState(() {});
      },
    );

    // Initialize route manager
    _routeManager = MapRouteManager(
      onFareUpdated: (fare) {
        fareAmount = fare;
        widget.onFareUpdated?.call(fare);
        if (mounted) setState(() {});
      },
      onError: (error) => _dialogManager.showError(error),
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );

    // Initialize marker manager
    _markerManager = MapMarkerManager(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );

    // Initialize dialog manager
    _dialogManager = MapDialogManager(context);

    // Initialize polyline state manager
    _polylineStateManager = MapPolylineStateManager(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
      onError: (error) => _dialogManager.showError(error),
    );

    // Initialize driver animation manager
    _driverAnimationManager = MapDriverAnimationManager(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
      onError: (error) => _dialogManager.showError(error),
    );

    // Initialize directional bus manager
    _directionalBusManager = MapDirectionalBusManager(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
      onError: (error) => _dialogManager.showError(error),
    );

    // Initialize stable state manager
    _stableStateManager = MapStableStateManager(
      onStateChanged: () {
        // Don't call setState - use ValueListenableBuilder instead
      },
      onError: (error) => _dialogManager.showError(error),
    );

    // Initialize driver tracker
    _driverTracker = MapDriverTracker(
      onDriverRouteUpdated: (driverLocation, route) {
        // Use stable state manager to prevent flickering
        _stableStateManager.updatePolyline(
          const PolylineId('driver_route_live'),
          route,
          color: const Color.fromARGB(255, 10, 179, 83),
          width: 4,
        );
      },
      onError: (error) => _dialogManager.showError(error),
    );
  }

  /// Initialize map components after managers are ready
  Future<void> _initializeMapComponents() async {
    // Initialize marker icons
    await _markerManager.initializeIcons();

    // Initialize driver animation manager
    await _driverAnimationManager.initializeBusIcon();

    // Initialize directional bus manager
    await _directionalBusManager.initializeBusIcons();

    // Test: Create a marker at a default location to verify icons are working
    if (currentLocation != null) {
      _directionalBusManager.updateDriverPosition(currentLocation!,
          rideStatus: 'test');
    }

    // Remove any existing driver markers from stable state manager
    _stableStateManager.removeDriverMarker();

    // Remove any existing driver markers from marker manager
    _markerManager.removeDriverMarker();

    // Initialize camera manager with map controller
    _cameraManager.initialize(mapController);

    // Load cached location and animate to it
    final cachedLocation = await _locationManager.getCachedLocation();
    if (cachedLocation != null && mounted) {
      setState(() => currentLocation = cachedLocation);
      await _cameraManager.animateToLocation(cachedLocation);
    }

    // Initialize location tracking
    await _locationManager.initializeLocation();

    // Handle route updates based on widget parameters
    handleLocationUpdates();
  }

  /// disposing of functions
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    _locationManager.dispose();
    _cameraManager.dispose();
    _routeManager.dispose();
    _markerManager.dispose();
    _driverTracker.dispose();
    _polylineStateManager.dispose();
    _driverAnimationManager.dispose();
    _directionalBusManager.dispose();
    _stableStateManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // here once the app is opened,
    // intiate the location and get the location updates
    final isScreenActive = state == AppLifecycleState.resumed;
    _locationManager.setScreenActive(isScreenActive);

    if (isScreenActive) {
      handleLocationUpdates();
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
      _dialogManager.showLocationSelectionRequired();
      return;
    }
    // generate the polylines calling selectedPickupLatlng and selectedDropOffLatLng
    _renderRouteBetween(selectedPickupLatLng!, selectedDropOffLatLng!);
  }

  // handle yung location updates for the previous widget to generate polylines
  Future<void> handleLocationUpdates() async {
    if (widget.pickUpLocation != null && widget.dropOffLocation != null) {
      if (widget.routePolyline?.isNotEmpty == true) {
        final segment = await _routeManager.renderRouteAlongPolyline(
          widget.pickUpLocation!,
          widget.dropOffLocation!,
          widget.routePolyline!,
        );

        if (segment.isNotEmpty) {
          // Use stable state manager for consistent rendering
          _stableStateManager.updatePolyline(
            const PolylineId('route'),
            segment,
            color: const Color(0xFFFFCE21),
            width: 4,
          );

          // Zoom camera to the segment bounds
          await _cameraManager.moveCameraToRoute(
            segment,
            widget.pickUpLocation!,
            widget.dropOffLocation!,
          );
        }
      } else {
        final route = await _routeManager.renderRouteBetween(
          widget.pickUpLocation!,
          widget.dropOffLocation!,
        );

        if (route.isNotEmpty) {
          // Use stable state manager for consistent rendering
          _stableStateManager.updatePolyline(
            const PolylineId('route'),
            route,
            color: const Color.fromARGB(255, 4, 197, 88),
            width: 4,
          );

          await _cameraManager.moveCameraToRoute(
            route,
            widget.pickUpLocation!,
            widget.dropOffLocation!,
          );
        }
      }
    }
  }

  // animate yung current location marker
  void pulseCurrentLocationMarker() {
    if (!mounted) return;
    _cameraManager.pulseCurrentLocationMarker();
  }

  Future<bool> checkPickupDistance(LatLng pickupLocation) async {
    if (currentLocation == null) return true;

    return await _dialogManager.showPickupDistanceWarning(
      pickupLocation,
      currentLocation!,
    );
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

  // animate yung camera papunta sa current location ng user
  Future<void> animateToLocation(LatLng target) async {
    await _cameraManager.animateToLocation(target);
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
      List<LatLng> route = [];

      if (widget.routePolyline?.isNotEmpty == true) {
        route = await _routeManager.renderRouteAlongPolyline(
          selectedPickupLatLng!,
          selectedDropOffLatLng!,
          widget.routePolyline!,
        );

        if (route.isNotEmpty) {
          _stableStateManager.updatePolyline(
            const PolylineId('route'),
            route,
            color: const Color(0xFFFFCE21),
            width: 4,
          );
        }
      } else {
        // Direct route fallback
        route = await _routeManager.renderRouteBetween(
          selectedPickupLatLng!,
          selectedDropOffLatLng!,
        );

        if (route.isNotEmpty) {
          _stableStateManager.updatePolyline(
            const PolylineId('route'),
            route,
            color: const Color.fromARGB(255, 4, 197, 88),
            width: 4,
          );
        }
      }

      if (route.isNotEmpty) {
        await _cameraManager.moveCameraToRoute(
          route,
          selectedPickupLatLng!,
          selectedDropOffLatLng!,
        );
      }
    }
  }

  Future<bool> checkNetworkConnection() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      _dialogManager.showNetworkError();
      return false;
    }
    return true;
  }

  // Helper method for backward compatibility
  Future<void> _renderRouteBetween(LatLng start, LatLng destination) async {
    final route = await _routeManager.renderRouteBetween(start, destination);
    if (route.isNotEmpty) {
      // Update polyline in stable state manager
      _stableStateManager.updatePolyline(
        const PolylineId('route'),
        route,
        color: const Color.fromARGB(255, 4, 197, 88),
        width: 4,
      );
      await _cameraManager.moveCameraToRoute(route, start, destination);
    }
  }

  // Expose camera bounds zoom for external callers
  Future<void> zoomToBounds(List<LatLng> polylineCoordinates) async {
    await _cameraManager.zoomToBounds(polylineCoordinates);
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

  // Update driver marker and draw road-following polyline to pickup/dropoff
  Future<void> updateDriverLocation(LatLng location, String rideStatus,
      {double? heading}) async {
    if (!mounted) return;

    // Update driver location using stable state manager (prevents flickering)
    _stableStateManager.updateDriverLocation(location, rideStatus);

    // Remove any existing driver markers from stable state manager
    _stableStateManager.removeDriverMarker();

    // Remove any existing driver markers from marker manager
    _markerManager.removeDriverMarker();

    // Update directional bus marker with heading
    debugPrint(
        'MapScreen: Calling directional bus manager with location: $location, heading: $heading, rideStatus: $rideStatus');
    _directionalBusManager.updateDriverPosition(location,
        heading: heading, rideStatus: rideStatus);

    // Update local state for other components
    driverLocation = location;

    // Handle status-specific UI changes
    if (rideStatus == 'accepted') {
      _markerManager.removeMarker('route_destination');
      showRouteEndIndicator = false;

      // Remove any existing pickup->dropoff polylines
      _routeManager.removePolyline(const PolylineId('route'));
      _routeManager.removePolyline(const PolylineId('route_path'));
    }

    // Use driver tracker to handle route generation and caching
    // This will update polylines through the stable state manager
    await _driverTracker.updateDriverLocation(
      location,
      rideStatus,
      pickupLocation: widget.pickUpLocation,
      dropoffLocation: widget.dropOffLocation,
    );
  }

  // Helper to generate and update polyline for driver route without clearing other polylines
  // Driver route generation is handled by RideService; remove inline implementation.

  Set<Marker> buildMarkers() {
    final markers = _markerManager.buildMarkers(
      pickupLocation: widget.pickUpLocation,
      dropoffLocation: widget.dropOffLocation,
      driverLocation: null, // Don't use regular driver marker
    );

    // Add directional bus marker if available
    final busMarker = _directionalBusManager.driverMarker;
    if (busMarker != null) {
      markers.add(busMarker);
    }

    // Add markers from stable state manager
    markers.addAll(_stableStateManager.markers);

    return markers;
  }

  // Public interface methods for external access
  /// Animate route drawing (delegates to route manager)
  void animateRouteDrawing(
    PolylineId id,
    List<LatLng> fullRoute,
    Color color,
    int width,
  ) {
    _routeManager.animateRouteDrawing(id, fullRoute, color, width);
  }

  /// Initialize location services (delegates to location manager)
  Future<void> initializeLocation() async {
    await _locationManager.initializeLocation();
  }

  /// Check if location is initialized (delegates to location manager)
  bool get isLocationInitialized => _locationManager.isLocationInitialized;

  /// Move camera to show booking bounds (driver, pickup, dropoff)
  Future<void> showBookingBounds() async {
    if (widget.pickUpLocation == null || widget.dropOffLocation == null) return;

    await _cameraManager.showBookingBounds(
      driverLocation,
      widget.pickUpLocation!,
      widget.dropOffLocation!,
    );
  }

  // Helper methods that delegate to managers
  LatLng findNearestPointOnRoute(LatLng point, List<LatLng> routePolyline) {
    return _routeManager.findNearestPointOnRoute(point, routePolyline);
  }

  double calculateDistance(LatLng point1, LatLng point2) {
    return _routeManager.calculateDistance(point1, point2);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_locationManager.isLocationInitialized) {
        _locationManager.initializeLocation();
      }
    });

    return Scaffold(
      body: RepaintBoundary(
        child: Stack(
          children: [
            ValueListenableBuilder<Set<Polyline>>(
              valueListenable: _stableStateManager.polylinesNotifier,
              builder: (context, polylines, child) {
                return ValueListenableBuilder<Set<Marker>>(
                  valueListenable: _stableStateManager.markersNotifier,
                  builder: (context, stableMarkers, child) {
                    // Combine regular markers with stable markers
                    final allMarkers = <Marker>{};
                    allMarkers.addAll(_markerManager.buildMarkers(
                      pickupLocation: widget.pickUpLocation,
                      dropoffLocation: widget.dropOffLocation,
                      driverLocation: null, // Don't use regular driver marker
                    ));
                    allMarkers.addAll(stableMarkers);

                    // Add directional bus marker if available
                    final busMarker = _directionalBusManager.driverMarker;
                    if (busMarker != null) {
                      allMarkers.add(busMarker);
                    }
                    return GoogleMap(
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
                        target:
                            currentLocation ?? const LatLng(14.5995, 120.9842),
                        zoom: currentLocation != null ? 15.0 : 10.0,
                      ),
                      markers: allMarkers,
                      polylines: polylines,
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
                    );
                  },
                );
              },
            ),
            if (currentLocation == null)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: Container(
                    color: Colors.transparent,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: screenWidth * 0.06,
                      right: screenWidth * 0.06,
                      bottom: screenHeight * widget.bottomPadding + 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SkeletonCircle(size: 36),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SkeletonLine(
                                  width: screenWidth * 0.6, height: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SkeletonLine(width: screenWidth * 0.4, height: 14),
                        const Spacer(),
                        // Bottom controls placeholder (where pick/drop UI usually sits)
                        SkeletonBlock(
                          width: double.infinity,
                          height: 90,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ],
                    ),
                  ),
                ),
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
      _routeManager.clearAllPolylines();
      _polylineStateManager.clearAllPolylines();
      _stableStateManager.clearAll();
      _markerManager.clearAllMarkers();
      _driverAnimationManager.dispose();
      _directionalBusManager.dispose();
      fareAmount = 0.0;
      etaText = null;
    });
  }
}
