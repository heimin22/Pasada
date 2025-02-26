// import 'dart:convert';
// import 'dart:math' show min,max;
// import 'package:flutter/foundation.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:geolocator/geolocator.dart';
// // import 'package:flutter_svg/flutter_svg.dart';
// // import 'package:url_launcher/url_launcher.dart';
// import 'package:location/location.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:pasada_passenger_app/home/selectionScreen.dart';
// import 'package:pasada_passenger_app/location/autocompletePrediction.dart';
import 'package:pasada_passenger_app/location/locationButton.dart';
import 'package:pasada_passenger_app/location/mapScreen.dart';
// import 'package:pasada_passenger_app/location/networkUtilities.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import '../location/locationSearchScreen.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:pasada_passenger_app/location/locationButton.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:pasada_passenger_app/notificationScreen.dart';
// import 'package:pasada_passenger_app/activityScreen.dart';
// import 'package:pasada_passenger_app/profileSettingsScreen.dart';
// import 'package:pasada_passenger_app/settingsScreen.dart';
// import 'package:pasada_passenger_app/homeScreen.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// WidgetsFlutterBinding.ensureInitialized();
// await dotenv.load(fileName: ".env");

// stateless tong widget na to so meaning yung mga properties niya ay di na mababago

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const HomeScreenStateful(),
      routes: <String, WidgetBuilder>{
        'map': (BuildContext context) => const MapScreen(),
      },
    );
  }
}

// stateful na makakapagrebuild dynamically kapag nagbago yung data
class HomeScreenStateful extends StatefulWidget {
  const HomeScreenStateful({super.key});

  @override
  // creates the mutable state para sa widget
  State<HomeScreenStateful> createState() => HomeScreenPageState();
}

class HomeScreenPageState extends State<HomeScreenStateful> {
  final GlobalKey<MapScreenState> mapScreenKey = GlobalKey<MapScreenState>(); // global key para maaccess si MapScreenState
  // GoogleMapController? mapController;
  SelectedLocation? selectedPickUpLocation;
  SelectedLocation? selectedDropOffLocation;
  bool isSearchingPickup = true; // true = pick-up, false - drop-off


  /// Update yung proper location base duon sa search type
  void updateLocation(SelectedLocation location, bool isPickup) {
    setState(() {
      if (isPickup) {
        selectedPickUpLocation = location;
      } else {
        selectedDropOffLocation = location;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // final screenHeight = MediaQuery.of(context).size.height;
    // final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final responsivePadding = screenWidth * 0.05;
          final iconSize = screenWidth * 0.06;
          final bottomNavBarHeight = 20.0;
          
          return Stack(
            children: [
              MapScreen(
                key: mapScreenKey,
                pickUpLocation: selectedPickUpLocation?.coordinates,
                dropOffLocation: selectedDropOffLocation?.coordinates,
              ),
              
              // Search bar
              Positioned(
                top: screenHeight * 0.08,
                left: responsivePadding,
                right: responsivePadding,
                child: buildSearchBar(context, screenWidth, screenHeight),
                ),

              // Location Container
              Positioned (
                bottom: bottomNavBarHeight,
                left: responsivePadding,
                right: responsivePadding,
                child: buildLocationContainer(
                  context,
                  screenWidth,
                  responsivePadding,
                  iconSize,
                ),
              ),

              // Location FAB
              Positioned(
                bottom: bottomNavBarHeight + 120,
                right: responsivePadding,
                child: LocationFAB(
                  heroTag: 'homeLocationFAB',
                  onPressed: () => mapScreenKey.currentState?.animateCameraToCurrentLocation(),
                  iconSize: screenWidth * 0.06,
                  buttonSize: screenWidth * 0.12,
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget buildSearchBar (BuildContext context, double screenWidth, double screenHeight) {
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, 'searchLocation'),
      style: ElevatedButton.styleFrom(
        elevation: 3,
        backgroundColor: Color(0xFFF5F5F5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
        ),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        minimumSize: Size(double.infinity, screenHeight * 0.065),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: screenWidth * 0.06, color: Color(0xFF505050)),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Text(
              'Where to?',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                color: Color(0xFF505050),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildLocationContainer(BuildContext context, double screenWidth, double padding, double iconSize) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: screenWidth * 0.03,
            spreadRadius: screenWidth * 0.005,
          ),
        ],
      ),
      child: Column(
        children: [
          buildLocationRow(Icons.my_location, selectedPickUpLocation, true, screenWidth, iconSize),
          const Divider(),
          buildLocationRow(Icons.my_location, selectedDropOffLocation, false, screenWidth, iconSize)
        ],
      ),
    );
  }

  Widget buildLocationRow(IconData icon, SelectedLocation? location, bool isPickup, double screenWidth, double iconSize) {
    return InkWell(
      onTap: () => navigateToSearch(context, isPickup),
      child: Row(
        children: [
          Icon(icon, size: iconSize, color: Colors.blue),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Text(
              location?.address ?? (isPickup ? 'Pick-up location' : 'Drop-off location'),
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void navigateToSearch(BuildContext context, bool isPickup) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchLocationScreen(isPickup: isPickup),
      ),
    );
    if (result != null && result is SelectedLocation) {
      setState(() {
        if (isPickup) {
          selectedPickUpLocation = result;
        } else {
          selectedDropOffLocation = result;
        }
      });
    }
  }
}
