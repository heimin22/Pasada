import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/landmarkService.dart';
import 'package:pasada_passenger_app/location/locationButton.dart';
import 'package:pasada_passenger_app/location/mapScreen.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pasada_passenger_app/network/networkUtilities.dart';

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
    getCurrentLocation();
  }

  @override
  void dispose() {
    addressNotifier.dispose();
    super.dispose();
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    isMapReady = true;

    Future.delayed(Duration(milliseconds: 300), () {
      getCurrentLocation();
    });
  }

  void handleMapTap(LatLng tappedPosition) async {
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
       if (landmark != null) {
         final selectedLoc = SelectedLocation(
             "${landmark['name']}\n${landmark['address']}",
             tappedPosition
         );
         Navigator.pop(context, selectedLoc);
       }
      });
    }
    else {
      final location = await reverseGeocode(tappedPosition);
      addressNotifier.value = location?.address ?? "Unable to find location";
    }
    setState(() => isFindingLandmark = false);
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

  // try natin gumawa ng method para mas accurate yung sentro ng map
  Future<LatLng> getMapCenter() async {
    if (!isMapReady || mapController == null) {
      return currentLocation ?? const LatLng(14.617494, 120.971770);
    }

    final visibleRegion = await mapController!.getVisibleRegion();
    // calculate natin yung exact center
    final centerLat = (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2;
    final centerLng = (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) / 2;

    return LatLng(centerLat, centerLng);
  }

  // papalitan ko yung snapToLandmark method kasi ang panget gago
  // try ko yung sa implementation ng Grab
  Future<void> fetchLocationAtCenter() async {
    if (!isMapReady || mapController == null) {
      debugPrint("Map not ready");
      return;
    }

    try {
      setState(() {
        isFindingLandmark = true;
        addressNotifier.value = "Searching...";
      });

      final center = await getMapCenter();

      debugPrint("Map Center: ${center.latitude}, ${center.longitude}");

      // update pinnedLocation duon sa center ng map
      /// PUTANGINAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
      setState(() => pinnedLocation = center);

      // try to get a landmark first para mas maayos yung UX
      final landmark = await LandmarkService.getNearestLandmark(center);

      if (landmark != null && mounted) {
        // nakahanap ng landmark, pero wag muna igalaw yung mapa duon
        // update lang muna ng information display
        setState(() {
          landmarkName = landmark['name'];
          final selectedLoc = SelectedLocation(
            "${landmark['name']}\n${landmark['address']}",
            center,
          );
          addressNotifier.value = selectedLoc.address;
          isFindingLandmark = false;
        });
        return;
      }

      // kapag walang nahanap na landmark, fall back to reverse geocoding
      final location = await reverseGeocode(center);
      if (mounted) {
        setState(() {
          addressNotifier.value =
              location?.address ?? "Unable to find location";
          isFindingLandmark = false;
        });
      }
    }
    catch (e) {
      debugPrint("Error fetching location: $e");
      if (mounted) {
        setState(() {
          addressNotifier.value = "Error finding location";
          isFindingLandmark = false;
        });
      }
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      // get current location
      final LocationData locationData = await locationService.getLocation();
      final newLocation = LatLng(
        locationData.latitude! ?? 14.617494,
        locationData.longitude! ?? 120.971770,
      );

      if (mounted) {
        setState(() {
          pinnedLocation = newLocation;
          currentLocation = newLocation;
          isLoading = false;
        });
      }

      if (isMapReady && mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: newLocation, zoom: 15),
          ),
        );

        fetchLocationAtCenter(); // Initial snap after load
      }
    }
    catch (e) {
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
          data['results'][0]['formatted_address'],
          position
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
      setState(() => isLoading = true);

      final locationData = await locationService.getLocation();
      final currentLatLng = LatLng(locationData.latitude!, locationData.longitude!);

      setState(() {
        currentLocation = currentLatLng;
        isLoading = false;
      });

      await mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          currentLatLng, 17,
        ),
      );
    }
    catch (e) {
      debugPrint("Error in animateToCurrentLocation: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final responsivePadding = screenWidth * 0.02;

    // measuring container height
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (bottomContainerKey.currentContext != null) {
        final RenderBox box = bottomContainerKey.currentContext!.findRenderObject() as RenderBox;
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
              bottom: bottomContainerHeight + MediaQuery.of(context).size.height * 0.01,
            ),
            onMapCreated: onMapCreated,
            onTap: (position) {
              mapController?.animateCamera(
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
              // don't do anything when the camera is moving
              // prevent na rin para walang jumping/snapping during movement
              if (isFindingLandmark) {
                setState(() => isFindingLandmark = false);
              }
            },
            onCameraIdle: () {
              fetchLocationAtCenter();
            },
          ),

          Center(
            child: Container(
              // Offset it slightly to account for bottom sheet
              margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.15),
              child: Icon(
                Icons.location_pin,
                color: Color(0xFFFFCE21),
                size: 48,
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
            child: pinnedLocationContainer(screenWidth, key: bottomContainerKey),
          ),
        ],
      ),
    );
  }

  Widget pinnedLocationContainer(double screenWidth, {Key? key}) {
    return Container(
      key: key,
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
              // check kapag nagsesearch pa rin
              if (isFindingLandmark) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("Still finding location, please wait a moment..."),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              // check kapag may valid location na mapapass back
              if (pinnedLocation != null && addressNotifier.value.isNotEmpty && addressNotifier.value != "Searching..." && addressNotifier.value != "Searching for location..." && addressNotifier.value != "Unable to find location") {
                Navigator.pop(context, SelectedLocation(addressNotifier.value, pinnedLocation!));
              }
              else if (pinnedLocation != null) {
                // may coordinates pero walang readable address
                // use na lang ng generic address pukingina niyan
                Navigator.pop(context, SelectedLocation(addressNotifier.value, pinnedLocation!));
              }
              else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Unable to confirm this location. Please try a different area.'),
                      duration: Duration(seconds: 3),
                    )
                );
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
        final bool isSearching = address == "Searching..." ||
            address == "Searching for location..." ||
            isFindingLandmark;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSearching)
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF067837),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Finding location...",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF515151),
                    ),
                  ),
                ],
              )
            else
              Text(
                address.isNotEmpty ? address : "Move the map to select a location",
                style: TextStyle(
                  fontSize: 14,
                  color: address.isNotEmpty ? Color(0xFF121212) : Color(0xFF515151),
                ),
              ),
          ],
        );
      },
    );
  }
}

