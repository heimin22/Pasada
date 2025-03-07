// import 'dart:convert';
// import 'dart:math' show min,max;
// import 'package:flutter/foundation.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

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
        'searchLocation': (BuildContext context) => const SearchLocationScreen(isPickup: true),
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
  final GlobalKey containerKey = GlobalKey();
  double containerHeight = 0.0;
  final GlobalKey<MapScreenState> mapScreenKey =
      GlobalKey<MapScreenState>(); // global key para maaccess si MapScreenState
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
  void initState() {
    // TODO: implement initState
    super.initState();
    // magmemeasure dapat ito after ng first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => measureContainer());
  }

  void measureContainer() {
    final RenderBox? box = containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      setState(() {
        containerHeight = box.size.height;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final responsivePadding = screenWidth * 0.05;
          final iconSize = screenWidth * 0.06;
          final bottomNavBarHeight = 20.0;
          final double fabVerticalSpacing = 10.0;

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
                child: buildSearchBar(
                  context,
                  screenWidth,
                  screenHeight,
                ),
              ),

              Positioned(
                bottom: bottomNavBarHeight,
                left: responsivePadding,
                right: responsivePadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Location FAB
                    LocationFAB(
                      heroTag: "homeLocationFAB",
                      onPressed: () => mapScreenKey.currentState,
                      iconSize: iconSize,
                      buttonSize: screenWidth * 0.12,
                    ),
                    SizedBox(height: fabVerticalSpacing),
                    // Location Container
                    Container(
                      key: containerKey,
                      child: buildLocationContainer(
                        context,
                        screenWidth,
                        responsivePadding,
                        iconSize,
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget buildSearchBar(
      BuildContext context, double screenWidth, double screenHeight) {
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, 'searchLocation'),
      style: ElevatedButton.styleFrom(
        elevation: 3,
        backgroundColor: Color(0xFFF5F5F5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.10),
        ),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        minimumSize: Size(double.infinity, screenHeight * 0.065),
      ),
      child: Row(
        children: [
          /// add icon through svg asset
          IconButton(
            onPressed: () => Navigator.pushNamed(context, 'searchLocation'),
            icon: SvgPicture.asset(
              'assets/svg/pinpickup.svg',
              height: 18,
              width: 18,
            ),
          ),
          SizedBox(width: screenWidth * 0.01),
          Expanded(
            child: Text(
              'Pick-up at?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6D6D6D),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildLocationContainer(BuildContext context, double screenWidth,
      double padding, double iconSize) {
    String svgAssetPickup = 'assets/svg/pinpickup.svg';
    String svgAssetDropOff = 'assets/svg/locationPin.svg';

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
        mainAxisSize: MainAxisSize.min,
        children: [
          buildLocationRow(svgAssetPickup, selectedPickUpLocation, true, screenWidth, iconSize),
          const Divider(),
          buildLocationRow(svgAssetDropOff, selectedDropOffLocation, false,
              screenWidth, iconSize)
        ],
      ),
    );
  }

  Widget buildLocationRow(String svgAsset, SelectedLocation? location,
      bool isPickup, double screenWidth, double iconSize) {
    return InkWell(
      onTap: () => navigateToSearch(context, isPickup),
      child: Row(
        children: [
          SvgPicture.asset(
            svgAsset,
            height: 24,
            width: 24,
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Text(
              location?.address ??
                  (isPickup ? 'Pick-up location' : 'Drop-off location'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
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
