// ignore_for_file: file_names

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/widgets/responsive_dialogs.dart';
import 'package:intl/intl.dart';

import '../network/networkUtilities.dart';

class MapScreen extends StatefulWidget {
  final LatLng? pickUpLocation;
  final LatLng? dropOffLocation;
  final double bottomPadding;
  final Function(String)? onEtaUpdated;
  final Function(double)? onFareUpdated;
  final Map<String, dynamic>? selectedRoute;
  final List<LatLng>? routePolyline;

  const MapScreen({
    super.key,
    this.pickUpLocation,
    this.dropOffLocation,
    this.bottomPadding = 0.07,
    this.onEtaUpdated,
    this.onFareUpdated,
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

  // PolylineId for the driver's live route
  static const PolylineId driverRoutePolylineId =
      PolylineId('driver_route_live');

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
        initializeLocation();
        handleLocationUpdates();
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
    generatePolylineBetween(selectedPickupLatLng!, selectedDropOffLatLng!);
  }

  // handle yung location updates for the previous widget to generate polylines
  void handleLocationUpdates() {
    locationSubscription = location.onLocationChanged
        .where((data) => data.latitude != null && data.longitude != null)
        .listen((newLocation) {
      if (mounted && isScreenActive) {
        setState(() => currentLocation =
            LatLng(newLocation.latitude!, newLocation.longitude!));
      }
    });
    if (widget.pickUpLocation != null && widget.dropOffLocation != null) {
      debugPrint('MapScreen - Both pickup and dropoff locations are set');
      // Use the selected route's polyline segment if available
      if (widget.routePolyline != null && widget.routePolyline!.isNotEmpty) {
        debugPrint('MapScreen - Using route polyline');
        generatePolylineAlongRoute(
          widget.pickUpLocation!,
          widget.dropOffLocation!,
          widget.routePolyline!,
        );
      } else {
        // Fallback to direct route if no official polyline
        debugPrint('MapScreen - Using direct route');
        generatePolylineBetween(
            widget.pickUpLocation!, widget.dropOffLocation!);
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

      setState(() => currentLocation =
          LatLng(locationData.latitude!, locationData.longitude!));

      final controller = await mapController.future;
      controller.animateCamera(CameraUpdate.newLatLng(currentLocation!));

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
  Future<void> updateLocations({LatLng? pickup, LatLng? dropoff}) async {
    if (pickup != null) {
      final shouldProceed = await checkPickupDistance(pickup);
      if (!shouldProceed) return;
      selectedPickupLatLng = pickup;
    }

    if (dropoff != null) selectedDropOffLatLng = dropoff;

    if (selectedPickupLatLng != null && selectedDropOffLatLng != null) {
      // Check if we have route polyline data from the route selection
      if (widget.routePolyline != null && widget.routePolyline!.isNotEmpty) {
        // Generate a polyline that follows the official route
        generatePolylineAlongRoute(selectedPickupLatLng!,
            selectedDropOffLatLng!, widget.routePolyline!);
      } else {
        // Fallback to direct route if no official route polyline is available
        generatePolylineBetween(selectedPickupLatLng!, selectedDropOffLatLng!);
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

  Future<void> generateRoutePolyline(List<dynamic> intermediateCoordinates,
      {LatLng? originCoordinates,
      LatLng? destinationCoordinates,
      String? destinationName}) async {
    try {
      final hasConnection = await checkNetworkConnection();
      if (!hasConnection) return;

      final String apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;
      if (apiKey.isEmpty) {
        if (kDebugMode) {
          print('API key not found');
        }
        return;
      }

      final polylinePoints = PolylinePoints();

      // Convert intermediate coordinates to waypoints format
      List<Map<String, dynamic>> intermediates = [];
      if (intermediateCoordinates.isNotEmpty) {
        for (var point in intermediateCoordinates) {
          if (point is Map &&
              point.containsKey('lat') &&
              point.containsKey('lng')) {
            intermediates.add({
              'location': {
                'latLng': {
                  'latitude': double.parse(point['lat'].toString()),
                  'longitude': double.parse(point['lng'].toString())
                }
              }
            });
          }
        }
      }

      // Routes API request
      final uri = Uri.parse(
          'https://routes.googleapis.com/directions/v2:computeRoutes');
      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask':
            'routes.polyline.encodedPolyline,routes.legs.duration.seconds',
      };

      final body = jsonEncode({
        'origin': {
          'location': {
            'latLng': {
              'latitude': originCoordinates?.latitude,
              'longitude': originCoordinates?.longitude,
            },
          },
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destinationCoordinates?.latitude,
              'longitude': destinationCoordinates?.longitude,
            },
          },
        },
        'intermediates': intermediates,
        'travelMode': 'DRIVE',
        'polylineEncoding': 'ENCODED_POLYLINE',
        'computeAlternativeRoutes': false,
        'routingPreference': 'TRAFFIC_AWARE',
      });

      debugPrint('Request Body: $body');

      final response =
          await NetworkUtility.postUrl(uri, headers: headers, body: body);

      if (response == null) {
        showError('Please try again.');
        if (kDebugMode) {
          print('No response from the server');
        }
        return;
      }

      final data = json.decode(response);

      // Add response validation
      if (data['routes'] == null || data['routes'].isEmpty) {
        if (kDebugMode) {
          print('No routes found');
        }
        return;
      }

      // Null checking for nested properties
      final polyline = data['routes'][0]['polyline']?['encodedPolyline'];
      if (polyline == null) {
        if (kDebugMode) {
          print('No polyline found in the response');
        }
        return;
      }

      // Decode the polyline
      List<PointLatLng> decodedPolyline =
          polylinePoints.decodePolyline(polyline);
      List<LatLng> polylineCoordinates = decodedPolyline
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      // Update UI with the polyline
      if (mounted) {
        setState(() {
          polylines.clear();
          polylines[const PolylineId('route_path')] = Polyline(
            polylineId: const PolylineId('route_path'),
            points: polylineCoordinates,
            color: const Color(0xFFFFCE21),
            width: 8,
          );

          // Add destination marker if provided
          if (destinationCoordinates != null) {
            // Create a custom marker for the destination
            final BitmapDescriptor customIcon =
                BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            );

            // Add the destination marker
            final markerId = MarkerId('route_destination');
            markers[markerId] = Marker(
              markerId: markerId,
              position: destinationCoordinates,
              icon: customIcon,
              infoWindow: InfoWindow(
                title: 'End of Route',
                snippet: destinationName ?? 'Final destination',
              ),
            );

            // Show the info window immediately
            Future.delayed(Duration(milliseconds: 500), () async {
              if (mounted) {
                final GoogleMapController controller =
                    await mapController.future;
                controller.showMarkerInfoWindow(markerId);
              }
            });

            // Enable the route end indicator
            showRouteEndIndicator = true;
            routeEndName = destinationName ?? 'End of Route';
          }
        });

        // Calculate bounds for camera
        double southLat = polylineCoordinates.first.latitude;
        double northLat = polylineCoordinates.first.latitude;
        double westLng = polylineCoordinates.first.longitude;
        double eastLng = polylineCoordinates.first.longitude;

        for (LatLng point in polylineCoordinates) {
          southLat = math.min(southLat, point.latitude);
          northLat = math.max(northLat, point.latitude);
          westLng = math.min(westLng, point.longitude);
          eastLng = math.max(eastLng, point.longitude);
        }

        // Add padding to the bounds
        final double padding = 0.01;
        southLat -= padding;
        northLat += padding;
        westLng -= padding;
        eastLng += padding;

        final GoogleMapController controller = await mapController.future;
        controller.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(southLat, westLng),
              northeast: LatLng(northLat, eastLng),
            ),
            20,
          ),
        );

        // Debug the points to verify they're in the correct order
        debugPrint(
            'Route points in order (${polylineCoordinates.length} points):');
        for (int i = 0; i < polylineCoordinates.length; i++) {
          debugPrint(
              'Point $i: ${polylineCoordinates[i].latitude}, ${polylineCoordinates[i].longitude}');
        }
      }
    } catch (e) {
      debugPrint('Error generating route polyline: $e');
      showError('Error: ${e.toString()}');
    }
  }

  Future<void> generatePolylineBetween(LatLng start, LatLng destination) async {
    try {
      final hasConnection = await checkNetworkConnection();
      if (!hasConnection) return;

      final String apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;
      if (apiKey.isEmpty) {
        if (kDebugMode) {
          print('API key not found');
        }
        return;
      }

      final polylinePoints = PolylinePoints();

      // routes API request
      final uri = Uri.parse(
          'https://routes.googleapis.com/directions/v2:computeRoutes');
      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask':
            'routes.polyline.encodedPolyline,routes.legs.duration.seconds',
      };
      final body = jsonEncode({
        'origin': {
          'location': {
            'latLng': {
              'latitude': start.latitude,
              'longitude': start.longitude,
            },
          },
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destination.latitude,
              'longitude': destination.longitude,
            },
          },
        },
        'travelMode': 'DRIVE',
        'polylineEncoding': 'ENCODED_POLYLINE',
        'computeAlternativeRoutes': false,
        'routingPreference': 'TRAFFIC_AWARE',
      });

      debugPrint('Request Body: $body');

      // ito naman na yung gagamitin yung NetworkUtility
      final response =
          await NetworkUtility.postUrl(uri, headers: headers, body: body);

      if (response == null) {
        // No response, skip polyline generation
        debugPrint('generatePolylineBetween: no response from server');
        return;
      }

      final data = json.decode(response);

      // Handle routes which may be a List or a single Map
      final dynamic routesObj = data['routes'];
      List<dynamic> routesList;
      if (routesObj is List) {
        routesList = routesObj;
      } else if (routesObj is Map) {
        routesList = [routesObj];
      } else {
        if (kDebugMode) {
          print('Unexpected routes format: ${routesObj.runtimeType}');
        }
        return;
      }
      if (routesList.isEmpty) {
        if (kDebugMode) print('No routes found');
        return;
      }
      final Map<String, dynamic> firstRoute =
          Map<String, dynamic>.from(routesList.first);
      final dynamic polylineObj = firstRoute['polyline'];
      String? encodedPolyline;

      if (polylineObj is Map && polylineObj['encodedPolyline'] is String) {
        encodedPolyline = polylineObj['encodedPolyline'] as String;
      }

      if (encodedPolyline == null) {
        if (kDebugMode) print('No polyline found in the response');
        return;
      }

      List<PointLatLng> decodedPolyline =
          polylinePoints.decodePolyline(encodedPolyline);
      List<LatLng> polylineCoordinates = decodedPolyline
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      if (mounted) {
        final double routeDistance = getRouteDistance(polylineCoordinates);
        final double fare = calculateFare(routeDistance);

        debugPrint('Route distance: ${routeDistance.toStringAsFixed(2)} km');
        debugPrint('Calculated fare: ₱${fare.toStringAsFixed(2)}');

        setState(() {
          polylines = {
            const PolylineId('route'): Polyline(
              polylineId: const PolylineId('route'),
              points: polylineCoordinates,
              color: Color(0xFF067837),
              width: 8,
            )
          };

          fareAmount = fare;
        });

        if (widget.onFareUpdated != null) {
          debugPrint(
              'Calling onFareUpdated with fare: ₱${fare.toStringAsFixed(2)}');
          widget.onFareUpdated!(fare);
        } else {
          debugPrint('onFareUpdated callback is null');
        }

        // Add ETA update similar to generatePolylineAlongRoute
        final legs = routesList[0]['legs'];
        if (legs is List && legs.isNotEmpty) {
          final firstLeg = legs[0];
          final duration = firstLeg['duration'];
          if (duration != null && duration['seconds'] != null) {
            final durationSeconds = duration['seconds'];
            final etaTextValue = formatDuration(durationSeconds);
            debugPrint('MapScreen - ETA calculated: $etaTextValue');
            setState(() {
              etaText = etaTextValue;
            });
            if (widget.onEtaUpdated != null) {
              debugPrint(
                  'MapScreen - Calling onEtaUpdated with: $etaTextValue');
              widget.onEtaUpdated!(etaTextValue);
            } else {
              debugPrint('MapScreen - onEtaUpdated is null');
            }
          } else {
            debugPrint('MapScreen - duration or seconds is null');
          }
        } else {
          debugPrint('MapScreen - legs is empty or not a list');
        }

        // calculate bounds that include start, destination and all polyline points
        double southLat = start.latitude;
        double northLat = start.latitude;
        double westLng = start.longitude;
        double eastLng = start.longitude;

        // include the destination point
        southLat = min(southLat, destination.latitude);
        northLat = max(northLat, destination.latitude);
        westLng = min(westLng, destination.longitude);
        eastLng = max(eastLng, destination.longitude);

        // include all polyline points
        for (LatLng point in polylineCoordinates) {
          southLat = min(southLat, point.latitude);
          northLat = max(northLat, point.latitude);
          westLng = min(westLng, point.longitude);
          eastLng = max(eastLng, point.longitude);
        }

        // add padding to the bounds
        final double padding = 0.01;
        southLat -= padding;
        northLat += padding;
        westLng -= padding;
        eastLng += padding;

        // create a new camera position centered within the bounds
        final GoogleMapController controller = await mapController.future;
        controller.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(southLat, westLng),
              northeast: LatLng(northLat, eastLng),
            ),
            20,
          ),
          duration: const Duration(milliseconds: 1000),
        );
      }

      if (kDebugMode) {
        print('Failed to generate route: $response');
      }
    } catch (e) {
      // Suppress map errors on polyline generate during restore
      debugPrint('generatePolylineBetween error: $e');
    }
  }

  double calculateFare(double distanceInKm) {
    const double baseFare = 15.0;
    const double ratePerKm = 2.2;

    double calculatedFare = 0.0;
    if (distanceInKm <= 4.0) {
      calculatedFare = baseFare;
    } else {
      calculatedFare = baseFare + (distanceInKm - 4.0) * ratePerKm;
    }

    // Add debug print to verify calculation
    debugPrint(
        'Distance: ${distanceInKm.toStringAsFixed(2)} km, Calculated fare: ₱${calculatedFare.toStringAsFixed(2)}');

    return calculatedFare;
  }

  double getRouteDistance(List<LatLng> polylineCoordinates) {
    double totalDistance = 0.0;

    for (int i = 0; i < polylineCoordinates.length - 1; i++) {
      final SelectedLocation start = SelectedLocation(
        '',
        polylineCoordinates[i],
      );
      final SelectedLocation end = SelectedLocation(
        '',
        polylineCoordinates[i + 1],
      );
      totalDistance += start.distanceFrom(end.coordinates);
      debugPrint(
          'Distance between points: ${start.distanceFrom(end.coordinates)}');
    }
    return totalDistance;
  }

  String formatDuration(int totalSeconds) {
    // Calculate arrival time based on current time and duration
    final now = DateTime.now();
    final arrivalTime = now.add(Duration(seconds: totalSeconds));
    return DateFormat('h:mm a').format(arrivalTime);
  }

  void showDebugToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
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
  }

  // Update driver marker and draw road-following polyline to pickup/dropoff
  Future<void> updateDriverLocation(LatLng location, String rideStatus) async {
    if (!mounted) return;
    setState(() {
      driverLocation = location;
      // Update driver marker
      final markerId = MarkerId('driver');
      markers[markerId] = Marker(
        markerId: markerId,
        position: driverLocation!,
        icon: busIcon,
      );
      // Clear all existing polylines immediately
      polylines.clear();
    });

    // Use routing API to draw polyline along roads
    if (rideStatus == 'accepted' && widget.pickUpLocation != null) {
      await generatePolylineBetween(location, widget.pickUpLocation!);
    } else if (rideStatus == 'ongoing' && widget.dropOffLocation != null) {
      await generatePolylineBetween(location, widget.dropOffLocation!);
    }
  }

  Set<Marker> buildMarkers() {
    final markerSet = <Marker>{};

    // Add pickup marker
    if (widget.pickUpLocation != null) {
      final pickupMarkerId = MarkerId('pickup');
      markers[pickupMarkerId] = Marker(
        markerId: pickupMarkerId,
        position: widget.pickUpLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
    }

    // Add dropoff marker
    if (widget.dropOffLocation != null) {
      final dropoffMarkerId = MarkerId('dropoff');
      markers[dropoffMarkerId] = Marker(
        markerId: dropoffMarkerId,
        position: widget.dropOffLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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
    const double earthRadius = 6371; // in kilometers

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

    return earthRadius * c; // Distance in kilometers
  }

  Future<void> generatePolylineAlongRoute(
      LatLng start, LatLng end, List<LatLng> routePolyline) async {
    debugPrint(
        'MapScreen - generatePolylineAlongRoute called with start: $start, end: $end');

    // Find the nearest points on the route to our start and end points
    LatLng startOnRoute = findNearestPointOnRoute(start, routePolyline);
    LatLng endOnRoute = findNearestPointOnRoute(end, routePolyline);

    // Find indices of these points in the route
    int startIdx = 0;
    int endIdx = routePolyline.length - 1;
    double minStartDist = double.infinity;
    double minEndDist = double.infinity;

    for (int i = 0; i < routePolyline.length; i++) {
      final double startDist =
          calculateDistance(startOnRoute, routePolyline[i]);
      final double endDist = calculateDistance(endOnRoute, routePolyline[i]);

      if (startDist < minStartDist) {
        minStartDist = startDist;
        startIdx = i;
      }

      if (endDist < minEndDist) {
        minEndDist = endDist;
        endIdx = i;
      }
    }

    // Ensure start comes before end on the route
    if (startIdx > endIdx) {
      final temp = startIdx;
      startIdx = endIdx;
      endIdx = temp;
    }

    // Extract the portion of the route between start and end
    final List<LatLng> routeSegment = [];
    routeSegment.add(start); // Add actual start point

    // Add all points along the route between start and end indices
    routeSegment.addAll(routePolyline.sublist(startIdx + 1, endIdx));

    routeSegment.add(end); // Add actual end point

    // Update the polyline
    setState(() {
      polylines.clear();
      polylines[const PolylineId('route_path')] = Polyline(
        polylineId: const PolylineId('route_path'),
        points: routeSegment,
        color: const Color(0xFF067837),
        width: 8,
      );

      // Calculate fare based on this segment
      final double routeDistance = getRouteDistance(routeSegment);
      final double fare = calculateFare(routeDistance);
      fareAmount = fare;

      if (widget.onFareUpdated != null) {
        widget.onFareUpdated!(fare);
      }
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
        child: currentLocation == null
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF067837),
                ),
              )
            : Stack(
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
                            }
                          ]'''
                        : '',
                    initialCameraPosition: CameraPosition(
                      target: currentLocation!,
                      zoom: 15.0,
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
                    myLocationEnabled: true,
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
