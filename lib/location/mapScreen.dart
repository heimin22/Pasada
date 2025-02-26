import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
// import 'package:pasada_passenger_app/location/locationButton.dart';
// import 'selectedLocation.dart';
// import 'package:pasada_passenger_app/home/homeScreen.dart';

class MapScreen extends StatefulWidget {
  final LatLng? pickUpLocation;
  final LatLng? dropOffLocation;

  const MapScreen({super.key, this.pickUpLocation, this.dropOffLocation});

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

  @override
  void initState() {
    super.initState();
    initLocation();
    // listen for location updates (if kailangan ng current position)
    getLocationUpdates();
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

  Future<void> initLocation() async {
    await location.getLocation().then((location) {
      setState(() => currentLocation = LatLng(location.latitude!, location.longitude!));
    });
    location.onLocationChanged.listen((location) {
      setState(() => currentLocation = LatLng(location.latitude!, location.longitude!));
    });
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
        currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
      });
      // listen sa location updates
      location.onLocationChanged.listen((LocationData newLocation) {
        if (newLocation.latitude != null && newLocation.longitude != null) {
          setState(() {
            currentLocation = LatLng(newLocation.latitude!, newLocation.longitude!);
          });
          animateCameraToCurrentLocation();
        }
      });
    }
    catch (e) {
      showError('An error occurred while fetching the location.');
    }
  }

  // animate yung camera sa current location
  Future<void> animateCameraToCurrentLocation() async {
    if (currentLocation == null) return;
    final GoogleMapController controller = await mapController.future;
    final currentLatLng =
        LatLng(currentLocation!.latitude, currentLocation!.longitude);
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: currentLatLng, zoom: 14),
      ),
    );
  }

  // ito yung method para sa pick-up and drop-off location
  void updateLocations({LatLng? pickup, LatLng? dropoff}) {
    if (pickup != null) selectedPickupLatLng = pickup;
      // selectedPickupMarker = Marker(
      //   markerId: const MarkerId("pickup"),
      //   position: pickup,
      //   icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      // );
    if (dropoff != null) selectedDropOffLatLng = dropoff;
      // selectedDropOffMarker = Marker(
      //   markerId: const MarkerId("dropoff"),
      //   position: dropoff,
      //   icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      // );

    if (selectedPickupLatLng != null && selectedDropOffLatLng != null) {
      generatePolylineBetween(selectedPickupLatLng!, selectedDropOffLatLng!);
    }
    // if naset na parehas yung pick-up and yung drop-off, maggegenerate na sila ng polyline
  }

  Future<void> generatePolylineBetween(LatLng start, LatLng destination) async {
    try {
      Fluttertoast.showToast(msg: "Generating route");
      debugPrint('Start: $start\nEnd: $destination');

      /// retrieve yung API key duon sa dotenv
      final String? apiKey = dotenv.env["ANDROID_MAPS_API_KEY"];
      if (apiKey == null || apiKey.isEmpty) {
        showDebugToast("Missing API Key");
        return;
      }

      final polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: apiKey,
        request: PolylineRequest(
          origin: PointLatLng(start.latitude, start.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isEmpty) {
        showDebugToast('No route found: ${result.errorMessage}');
        return;
      }

      final polylineCoordinates = result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      setState(() {
        polylines = {
          const PolylineId("route"): Polyline(
            polylineId: const PolylineId("route"),
            color: const Color(0xFF5f3fc4),
            points: polylineCoordinates,
            width: 8,
          )
        };
      });

      showDebugToast('Route generated with ${polylineCoordinates.length} points');
    }
    catch (e) {
      showDebugToast('Error: ${e.toString()}');
    }
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
    animateCameraToCurrentLocation();
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
    // combine na lahat ng markers
    // final markers = <Marker> {
    //   if (selectedPickupMarker != null) selectedPickupMarker!,
    //   if (selectedDropOffMarker != null) selectedDropOffMarker!,
    // };
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) => mapController.complete(controller),
              initialCameraPosition: CameraPosition(
                target: currentLocation!,
                zoom: 15.0,
              ),
              markers: buildMarkers(),
              polylines: Set<Polyline>.of(polylines.values),
              // markers: widget.markers ?? {},
              // polylines: widget.polyline != null ? {widget.polyline!} : {},
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationEnabled: true,
              trafficEnabled: true,
              myLocationButtonEnabled: false,
              padding: EdgeInsets.only(
                bottom: screenHeight * 0.15,
                right: screenWidth * 0.1,
              ),
            ),
    );
  }
}
