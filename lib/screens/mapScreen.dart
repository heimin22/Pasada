// ignore_for_file: file_names

import 'dart:async';
import 'dart:convert';
import 'dart:math';
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

import '../network/networkUtilities.dart';

class MapScreen extends StatefulWidget {
  final LatLng? pickUpLocation;
  final LatLng? dropOffLocation;
  final double bottomPadding;
  final Function(String)? onEtaUpdated;
  final Map<String, dynamic>? selectedRoute;

  const MapScreen({
    super.key,
    this.pickUpLocation,
    this.dropOffLocation,
    this.bottomPadding = 0.07,
    this.onEtaUpdated,
    this.selectedRoute,
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

  // Add this field to store the current controller
  GoogleMapController? _mapController;

  // Override methods
  /// state of the app
  @override
  void initState() {
    super.initState();
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
      generatePolylineBetween(widget.pickUpLocation!, widget.dropOffLocation!);
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
      generatePolylineBetween(selectedPickupLatLng!, selectedDropOffLatLng!);
    }
    // if naset na parehas yung pick-up and yung drop-off, maggegenerate na sila ng polyline
  }

  Future<bool> checkNetworkConnection() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      showError('No internet connection');
      return false;
    }
    return true;
  }

  Future<void> generatePolylineBetween(LatLng start, LatLng destination) async {
    try {
      final hasConnection = await checkNetworkConnection();
      if (!hasConnection) return;

      final String apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;
      if (apiKey.isEmpty) {
        showError('API Key is not configured!');
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

      final bool isUsingPredefinedRoute = widget.selectedRoute != null &&
          widget.selectedRoute!['route_name'] != 'Select Route';

      Map<String, dynamic> requestBody = {
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
      };

      if (isUsingPredefinedRoute &&
          widget.selectedRoute!['intermediate_coordinates'] != null) {
        List<Map<String, dynamic>> intermediates = [];

        final coordinates = widget.selectedRoute!['intermediate_coordinates'];
        if (coordinates is List) {
          for (var coordinate in coordinates) {
            intermediates.add({
              'location': {
                'latLng': {
                  'latitude': double.parse(coordinate['lat'].toString()),
                  'longitude': double.parse(coordinate['lng'].toString()),
                },
              },
            });
          }
        }

        if (intermediates.isNotEmpty) {
          requestBody['waypoints'] = intermediates;
          debugPrint(
              'Added ${intermediates.length} intermediate points to route request');
        }
      }

      final body = json.encode(requestBody);
      debugPrint('Request Body: $requestBody');

      // ito naman na yung gagamitin yung NetworkUtility
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

      // add ng response validation
      if (data['routes'] == null || data['routes'].isEmpty) {
        if (kDebugMode) {
          print('No routes found');
        }
        return;
      }

      // null checking for nested properties
      final polyline = data['routes'][0]['polyline']?['encodedPolyline'];
      if (polyline == null) {
        if (kDebugMode) {
          print('No polyline found in the response');
        }
        return;
      }

      debugPrint('API Response: $data');
      debugPrint('Routes; ${data['routes']}');

      if (data['routes']?.isNotEmpty ?? false) {
        final polyline = data['routes'][0]['polyline']['encodedPolyline'];
        List<PointLatLng> decodedPolyline =
            polylinePoints.decodePolyline(polyline);
        List<LatLng> polylineCoordinates = decodedPolyline
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        if (mounted) {
          setState(() {
            polylines = {
              const PolylineId('route'): Polyline(
                polylineId: const PolylineId('route'),
                points: polylineCoordinates,
                color: Color(0xFF067837),
                width: 8,
              )
            };
          });

          // calculate bounds that include start, destination and all ppolyline points
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

        final legs = data['routes'][0]['legs'];
        if (legs is! List || legs.isEmpty) {
          debugPrint('Legs data is invalid: $legs');
          setState(() => etaText = 'N/A');
          return;
        }

        final firstLeg = legs[0];
        final duration = firstLeg['duration'];
        if (duration is! String || !duration.endsWith('s')) {
          debugPrint('Invalid duration format: $duration');
          setState(() => etaText = 'N/A');
          return;
        }

        final secondsString = duration.replaceAll(RegExp(r'[^0-9]'), '');
        final durationSeconds = int.tryParse(secondsString) ?? 0;
        final durationText = formatDuration(durationSeconds);

        setState(() => etaText = durationText);
        if (widget.onEtaUpdated != null) {
          widget.onEtaUpdated!(durationText);
        }

        // debug testing
        debugPrint('API Response: ${json.encode(data)}'); // Full response
        debugPrint('Legs Type: ${legs.runtimeType}'); // Verify list type
        debugPrint('Duration Type: ${duration.runtimeType}'); // Verify map type
        return;
      }
      if (kDebugMode) {
        print('Failed to generate route: $response');
      }
    } catch (e) {
      showError('Error: ${e.toString()}');
    }
  }

  String formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    return hours > 0
        ? '${hours}h ${minutes}m'
        : minutes > 0
            ? '$minutes mins'
            : '<1 min';
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
      builder: (context) => AlertDialog(
        title: Text(title),
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
      builder: (context) => AlertDialog(
        title: const Text('Location Error'),
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
              // Navigator.of(context).pop();
              // await initLocation();
              // if (mounted) getLocationUpdates();
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

  Set<Marker> buildMarkers() {
    final markers = <Marker>{};

    // Pickup marker
    if (widget.pickUpLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickUpLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    // Dropoff marker
    if (widget.dropOffLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: widget.dropOffLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
            : GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  mapController.complete(controller);
                },
                style: Theme.of(context).brightness == Brightness.dark
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
      ),
    );
  }
}
