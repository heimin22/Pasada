import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'locationController.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  LocationData? currentLocation;
  final Location location = Location();

  @override
  void initState() {
    super.initState();
    checkLocationPermissions();
  }

  Future<void> checkLocationPermissions() async {
    try {
      final serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        final serviceRequestResult = await location.requestService();
        if (!serviceRequestResult) {
          showAlertDialog(
            'Enable Location Services',
            'Location services are disabled. Please enable them to use this feature.',
          );
          return;
        }
      }

      final permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        final permissionRequestResult = await location.requestPermission();
        if (permissionRequestResult != PermissionStatus.granted) {
          showAlertDialog(
            'Permission Required',
            'This app needs location permission to work. Please allow it in your settings.',
          );
          return;
        }
      }

      currentLocation = await location.getLocation();
      if (currentLocation == null) {
        showAlertDialog(
          'Location Error',
          'Unable to fetch the current location. Please try again later.',
        );
      }
      else {
        setState(() {});
      }
    }
    catch (e) {
      showError('An error occurred while fetching the location.');
    }
  }

  void onMapCreated(GoogleMapController controller) => mapController = controller;

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
        )
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    currentLocation!.latitude!, currentLocation!.longitude!),
                zoom: 15.0,
              ),
            ),
    );
  }
}
