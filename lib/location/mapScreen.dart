import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'networkUtilities.dart';


class MapScreen extends StatefulWidget {
  final LatLng? pickUpLocation;
  final LatLng? dropOffLocation;
  final double bottomPadding;
  final Function(String)? onEtaUpdated;

  const MapScreen({
    super.key,
    this.pickUpLocation,
    this.dropOffLocation,
    this.bottomPadding = 0.07,
    this.onEtaUpdated,
  });

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final Completer<GoogleMapController> mapController = Completer();
  LatLng? currentLocation; // Location Data
  final Location location = Location();
  final String apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;
  StreamSubscription<LocationData>? locationSubscription;

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


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    /// default coords for testing
    // currentLocation = const LatLng(14.617494, 120.971770);
    initLocation();
    getLocationUpdates();
  }

  @override
  void dispose() {
    locationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      initLocation();
    }
  }

  void calculateRoute() {
    if (selectedPickupLatLng == null || selectedDropOffLatLng == null) {
      showDebugToast('Select both locations first.');
      return;
    }
    generatePolylineBetween(selectedPickupLatLng!, selectedDropOffLatLng!);
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pickUpLocation != oldWidget.pickUpLocation ||
        widget.dropOffLocation != oldWidget.dropOffLocation) {
      handleLocationUpdates();
    }
  }

  void handleLocationUpdates() {
    if (widget.pickUpLocation != null && widget.dropOffLocation != null) {
      generatePolylineBetween(widget.pickUpLocation!, widget.dropOffLocation!);
      showDebugToast('Generating route');
    }
  }

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

  // service status check helper
  Future<bool> checkLocationService() async {
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
      }
      return serviceEnabled;
    } on PlatformException {
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> initLocation() async {
    final serviceAvailable = await checkLocationService();
    if (!serviceAvailable) {
      if (mounted) showLocationErrorDialog();
      return;
    }

    await getLocationUpdates();
  }

  // animate yung camera papunta sa current location ng user
  Future<void> animateToLocation(LatLng target) async {
    final GoogleMapController controller = await mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: 17.0,
        )
      ),
    );

    pulseCurrentLocationMarker();
  }

  Future<void> getLocationUpdates() async {
    try {
      // check if yung location services ay available
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          if (mounted) {
            showAlertDialog(
              'Enable Location Services',
              'Location services are disabled. Please enable them to use this feature.',
            );
            return;
          }
        }
      }
      // check ng location permissions
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied || permissionGranted == PermissionStatus.deniedForever) {
        final permission = await location.requestPermission();
        if (permission != PermissionStatus.granted) {
          if (mounted) {
            showAlertDialog(
              'Permission Required',
              'This app needs location permission to work. Please allow it in your settings.',
            );
            return;
          }
        }
      }

      // kuha ng current location
      LocationData locationData = await location.getLocation();
      if (mounted) {
        setState(() {
          currentLocation =
              LatLng(locationData.latitude!, locationData.longitude!);
        });
      }
      // listen sa location updates
      location.onLocationChanged.listen((LocationData newLocation) {
        if (newLocation.latitude != null && newLocation.longitude != null) {
          setState(() {
            currentLocation =
                LatLng(newLocation.latitude!, newLocation.longitude!);
          });
        }
      });

      locationSubscription = location.onLocationChanged.listen((LocationData newLocation) {
        if (mounted && newLocation.latitude != null && newLocation.longitude != null) {
          setState(() {
            currentLocation = LatLng(newLocation.latitude!, newLocation.longitude!);
          });
        }
      });
    } on PlatformException catch (e) {
      if (mounted) {
        showError(
            'Location Error: ${e.message ?? "Service status unavailable"}');
      }
      debugPrint('PlatformException: ${e.code} - ${e.message}');
    } catch (e) {
      // showError('An error occurred while fetching the location.');
      if (mounted) showError(e.toString());
    }
  }


  // ito yung method para sa pick-up and drop-off location
  void updateLocations({LatLng? pickup, LatLng? dropoff}) {
    if (pickup != null) selectedPickupLatLng = pickup;

    if (dropoff != null) selectedDropOffLatLng = dropoff;

    if (selectedPickupLatLng != null && selectedDropOffLatLng != null) {
      generatePolylineBetween(selectedPickupLatLng!, selectedDropOffLatLng!);
    }
    // if naset na parehas yung pick-up and yung drop-off, maggegenerate na sila ng polyline
  }

  Future<void> generatePolylineBetween(LatLng start, LatLng destination) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      showDebugToast('No internet connection');
      return;
    }
    try {
      final String apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;
      if (apiKey == null) {
        showDebugToast('API key not found');
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
        'X-Goog-FieldMask': 'routes.polyline.encodedPolyline,routes.legs.duration.seconds',
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
        showDebugToast('No response from the server');
        if (kDebugMode) {
          print('No response from the server');
        }
        return;
      }

      final data = json.decode(response);

      // add ng response validation
      if (data['routes'] == null || data['routes'].isEmpty) {
        showDebugToast('No routes found');
        if (kDebugMode) {
          print('No routes found');
        }
        return;
      }

      // null checking for nested properties
      final polyline = data['routes'][0]['polyline']?['encodedPolyline'];
      if (polyline == null) {
        showDebugToast('No polyline found in the response');
        if (kDebugMode) {
          print('No polyline found in the response');
        }
        return;
      }

      if (response != null) {
        final data = json.decode(response);
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
                  color: Color(0xFFD7481D),
                  width: 8,
                )
              };
            });
          }

          showDebugToast('Route generated successfully');

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
      }
      showDebugToast('Failed to generate route');
      if (kDebugMode) {
        print('Failed to generate route: $response');
      }
    } catch (e) {
      showDebugToast('Error: ${e.toString()}');
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Error'),
        content: const Text(
            'Location services are disabled. Please enable them to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Confirm'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await initLocation();
              getLocationUpdates();
            },
            child: const Text('Retry'),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
                onMapCreated: (controller) =>
                    mapController.complete(controller),
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
