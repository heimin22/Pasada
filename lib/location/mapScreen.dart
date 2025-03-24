import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:http/http.dart' as http;

// import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'networkUtilities.dart';


class MapScreen extends StatefulWidget {
  final LatLng? pickUpLocation;
  final LatLng? dropOffLocation;
  final double bottomPadding;
  final Function(String)? onEtaUpdated;

  const MapScreen({super.key, this.pickUpLocation, this.dropOffLocation, this.bottomPadding = 0.13, this.onEtaUpdated});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> mapController = Completer();
  LatLng? currentLocation; // Location Data
  final Location location = Location();
  final String apiKey = dotenv.env['ANDROID_MAPS_API_KEY']!;

  // Markers para sa pick-up and drop-off
  Marker? selectedPickupMarker;
  Marker? selectedDropOffMarker;

  // polylines map
  Map<PolylineId, Polyline> polylines = {};

  // mauupdate ito kapag nakapagsearch na ng location si user
  LatLng? selectedPickupLatLng;
  LatLng? selectedDropOffLatLng;

  // ito muna yung fallback positions kung kailangan (hindi pa naman final ito niggas)
  static const LatLng defaultSource = LatLng(14.617494, 120.971770);
  static const LatLng defaultDestination = LatLng(14.619620, 120.971219);

  // optional, show a marker sa current location
  LatLng? currentPosition;

  // animation ng location to kapag pinindot yung Location FAB
  bool isAnimatingLocation = false;

  String? etaText;

  @override
  void initState() {
    super.initState();
    initLocation();
    // listen for location updates (if kailangan ng current position)
    getLocationUpdates();
  }

  void calculateRoute() {
    if (selectedPickupLatLng == null || selectedDropOffLatLng == null) {
      showDebugToast('Select both locations first.');
      return;
    }
    generatePolylineBetween(selectedPickupLatLng!, selectedDropOffLatLng!);
  }

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
    setState(() => isAnimatingLocation = true);

    // reset ng animation after ng delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => isAnimatingLocation = false);
      }
    });
  }

  Future<void> initLocation() async {
    await location.getLocation().then((location) {
      setState(() =>
          currentLocation = LatLng(location.latitude!, location.longitude!));
    });
    location.onLocationChanged.listen((location) {
      setState(() =>
          currentLocation = LatLng(location.latitude!, location.longitude!));
    });
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
          showAlertDialog(
            'Enable Location Services',
            'Location services are disabled. Please enable them to use this feature.',
          );
          return;
        }
      }

      // check ng location permissions
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          showAlertDialog(
            'Permission Required',
            'This app needs location permission to work. Please allow it in your settings.',
          );
          return;
        }
      }

      // kuha ng current location
      LocationData locationData = await location.getLocation();
      setState(() {
        currentLocation =
            LatLng(locationData.latitude!, locationData.longitude!);
      });
      // listen sa location updates
      location.onLocationChanged.listen((LocationData newLocation) {
        if (newLocation.latitude != null && newLocation.longitude != null) {
          setState(() {
            currentLocation =
                LatLng(newLocation.latitude!, newLocation.longitude!);
          });
        }
      });
    } catch (e) {
      showError('An error occurred while fetching the location.');
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
        // 'X-Goog-FieldMask': 'routes.distanceMeters',
        // 'X-Goog-FieldMask': 'routes.duration',
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
        print('API Response: $data');
        print('Routes; ${data['routes']}');
        if (data['routes']?.isNotEmpty ?? false) {
          final polyline = data['routes'][0]['polyline']['encodedPolyline'];
          List<PointLatLng> decodedPolyline =
              polylinePoints.decodePolyline(polyline);
          List<LatLng> polylineCoordinates = decodedPolyline
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

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
    //
    // if (hours > 0) {
    //   return '${hours}h ${minutes}m';
    // } else if (minutes > 0) {
    //   return '$minutes mins';
    // } else {
    //   return 'Less than a min';
    // }
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
    showAlertDialog(
      'Location Error',
      'Unable to fetch the current location. Please try again later.',
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
                  bottom: screenHeight * (widget.bottomPadding + 0.05),
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
