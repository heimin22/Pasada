import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pasada_passenger_app/location/locationButton.dart';
import 'package:pasada_passenger_app/location/mapScreen.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import '../location/locationSearchScreen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pasada_passenger_app/location/autocompletePrediction.dart';
import 'package:pasada_passenger_app/location/networkUtilities.dart';
import 'package:pasada_passenger_app/location/placeAutocompleteResponse.dart';
import 'locationListTile.dart';
import 'package:pasada_passenger_app/home/homeScreen.dart';

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
      routes: <String, WidgetBuilder>{

      },
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
  final GlobalKey<MapScreenState> mapScreenKey = GlobalKey<MapScreenState>();
  late GoogleMapController mapController;
  LatLng? currentLocation;
  LatLng? pinnedLocation;
  final Location locationService = Location();
  SelectedLocation? selectedPinnedLocation;
  final ValueNotifier<String> addressNotifier = ValueNotifier('');
  bool isLoading = true;

  List<String> splitLocation(String location) {
    final List<String> parts = location.split(',');
    if (parts.length < 2) return [location, ''];
    return [parts[0], parts.sublist(1).join(', ')];
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  @override
  void dispose() {
    addressNotifier.dispose();
    super.dispose();
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    updateLocation();
  }

  void handleMapTap(LatLng tappedPosition) async {
    setState(() {
      pinnedLocation = tappedPosition;
      addressNotifier.value = "Searching...";
    });

    final location = await reverseGeocode(tappedPosition);
    if (location != null) {
      setState(() {
        addressNotifier.value = location.address;
        selectedPinnedLocation = location;
      });
    }
    else {
      setState(() => addressNotifier.value = "Location not found. Try again.");
    }
  }
  
  Future<void> updateLocation() async {
    if (mapController == null) return;

    final visibleRegion = await mapController!.getVisibleRegion();
    final center  = LatLng(
        (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2,
        (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) / 2,
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

  Future<void> getCurrentLocation() async {
    try {
      // get current location
      LocationData locationData = await locationService.getLocation();
      setState(() {
        currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
        isLoading = false;
      });

      // initialize map position
      if (currentLocation != null) {
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentLocation!,
              zoom: 15,
            ),
          ),
        );
      }
    }
    catch (e) {
      debugPrint("Error in getCurrentLocation: $e");
      setState(() => isLoading = false);
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
          address: data['results'][0]['formatted_address'],
          coordinates: position,
        );
      }
    }
    catch (e) {
      debugPrint("Error in reverseGeocode: $e");
    }
    return null;
  }

  Future<void> animateToCurrentLocation() async {
    try {
      final locationData = await locationService.getLocation();
      final currentLatLng = LatLng(locationData.latitude!, locationData.longitude!);

      await mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          currentLatLng, 17,
        ),
      );

      // force update after animation completes
      await Future.delayed(Duration(milliseconds: 500));
      updateLocation();
    }
    catch (e) {
      debugPrint("Error in animateToCurrentLocation: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final responsivePadding = screenWidth * 0.02;
    final fabVerticalSpacing = 10.0;

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
          Positioned(
            top: MediaQuery.of(context).size.height * 0.07,
            left: MediaQuery.of(context).size.width * 0.03, // Use width for horizontal positioning
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // Add background
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: Color(0xFF121212)),
                color: Color(0xFFF5F5F5),
              ),
            ),
          ),
          GoogleMap(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.3,
            ),
            onMapCreated: onMapCreated,
            onTap: handleMapTap,
            initialCameraPosition: CameraPosition(
              target: currentLocation ?? const LatLng(14.617494, 120.971770),
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onCameraMove: (_) => updateLocation(),
            onCameraIdle: () => updateLocation(),
          ),

          // center pin marker
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 24,
            top: MediaQuery.of(context).size.height / 2 - 48,
            child: Icon(
              Icons.location_pin,
              size: 48,
              color: Color(0xFFFFCE21),
            ),
          ),

          Positioned(
            right: responsivePadding,
            bottom: screenHeight * 0.13 + fabVerticalSpacing,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                LocationFAB (
                  heroTag: "pinLocationFAB",
                  onPressed: animateToCurrentLocation,
                  icon: Icons.gps_fixed,
                  iconColor: const Color(0xFF067837),
                  backgroundColor: Colors.white,
                  buttonSize: screenWidth * 0.12,
                  iconSize: screenWidth * 0.06,
                ),
                SizedBox(height: fabVerticalSpacing),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: pinnedLocationContainer(screenWidth),
          ),
        ],
      ),
    );
  }

  Widget pinnedLocationContainer(double screenWidth) {
    return Container(
      width: screenWidth,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFD2D2D2),
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
              if (pinnedLocation != null) {
                Navigator.pop(context, SelectedLocation(address: addressNotifier.value, coordinates: pinnedLocation!));
              }
              else {
                addressNotifier.value = "Unable to find location";
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF067837),
              minimumSize: Size(double.infinity, 50),
            ),
            child: Text(
              'Confirm ${widget.isPickup ? 'Pick-up' : 'Drop-off'} Location',
              style: const TextStyle(
                color: Color(0xFFF5F5F5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLocationInfo() {
    return ValueListenableBuilder(
      valueListenable: addressNotifier,
      builder: (context, address, _) {
        final parts = splitLocation(address);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pinnedLocation != null) ...[
                Text(
                  '${pinnedLocation!.latitude.toStringAsFixed(6)}, '
                  '${pinnedLocation!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF515151),
                  ),
                ),
                SizedBox(height: 8),
              ],
              Text(
                parts[0],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF121212),
              ),
            ),
            if (parts[1].isNotEmpty) ...[
              Text(
                parts[1],
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF515151)
                ),
              )
            ],
          ],
        );
      }
    );
  }
}

