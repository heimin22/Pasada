import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/home/selectionScreen.dart';
import 'package:pasada_passenger_app/location/locationButton.dart';
import 'package:pasada_passenger_app/location/mapScreen.dart';
import '../location/locationSearchScreen.dart';
import 'package:pasada_passenger_app/location/locationButton.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:pasada_passenger_app/notificationScreen.dart';
// import 'package:pasada_passenger_app/activityScreen.dart';
// import 'package:pasada_passenger_app/profileSettingsScreen.dart';
// import 'package:pasada_passenger_app/settingsScreen.dart';
// import 'package:pasada_passenger_app/homeScreen.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(const HomeScreen());
// WidgetsFlutterBinding.ensureInitialized();
// await dotenv.load(fileName: ".env");

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pasada',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const HomeScreenStateful(title: 'Pasada'),
      routes: <String, WidgetBuilder>{
        'map': (BuildContext context) => const MapScreen(),
        'searchLocation': (BuildContext context) => const SearchLocationScreen()
      },
    );
  }
}

class HomeScreenStateful extends StatefulWidget {
  const HomeScreenStateful({super.key, required this.title});

  final String title;

  @override
  State<HomeScreenStateful> createState() => HomeScreenPageState();
}

class HomeScreenPageState extends State<HomeScreenStateful> {
  final GlobalKey<MapScreenState> mapScreenKey = GlobalKey();
  String pickupLocation = "Pick-up location";
  String dropOffLocation = "Drop-off location";
  // Position? currentPosition;
  //
  // Future<void> goToCurrentLocation() async {
  //   try {
  //     final position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.best,
  //     );
  //     setState(() => currentPosition = position);
  //     print('Lat: ${position.latitude}, Lng: ${position.longitude}');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
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
              const MapScreen(key: ValueKey('mapScreen')),
              
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
                  onPressed: () => mapScreenKey.currentState?.centerMapOnCurrentLocation(),
                  iconSize: screenWidth * 0.06,
                  buttonSize: screenWidth * 0.12,
                ),
              )
            ],
          );
        },
      ),
    );
    // return Scaffold(
    //   body: SafeArea(
    //     child: Stack(
    //       children: [
    //         MapScreen(key: mapScreenKey),
    //         // Floating search bar
    //         Positioned(
    //           top: screenHeight * 0.02, // 2% from the top of the screen
    //           left: screenWidth * 0.05, // 5% padding from the left
    //           right: screenWidth * 0.05, // 5% padding from the right
    //           child: ElevatedButton(
    //             onPressed: () {
    //               Navigator.pushNamed(context, 'searchLocation');
    //             },
    //             style: ElevatedButton.styleFrom(
    //               elevation: 3,
    //               backgroundColor: Color(0xFFF5F5F5),
    //               shape: RoundedRectangleBorder(
    //                 borderRadius: BorderRadius.circular(24),
    //               ),
    //               padding: EdgeInsets.zero,
    //               minimumSize: Size(0, screenHeight * 0.06),
    //             ),
    //             child: Row(
    //               children: [
    //                 const SizedBox(width: 16), // Left padding
    //                 const Icon(Icons.search, color: Colors.grey),
    //                 const SizedBox(width: 8),
    //                 Expanded(
    //                   child: Text(
    //                     'Where to?',
    //                     style: TextStyle(
    //                       color: const Color(0xFFA2A2A2),
    //                     ),
    //                   ),
    //                 ),
    //                 const SizedBox(width: 16), // Right padding
    //               ],
    //             ),
    //           ),
    //         ),
    //         // Drop-off and Pick-up Location Container
    //         Positioned(
    //           top: screenHeight * 0.12,
    //           left: screenWidth * 0.05,
    //           right: screenWidth * 0.05,
    //           child: Container(
    //             padding: const EdgeInsets.all(16),
    //             decoration: BoxDecoration(
    //               borderRadius: BorderRadius.circular(12),
    //               color: Color(0xFFF5F5F5),
    //               boxShadow: [
    //                 BoxShadow(
    //                   color: Colors.black12,
    //                   spreadRadius: 2,
    //                   blurRadius: 10,
    //                   offset: const Offset(0, 2),
    //                 )
    //               ],
    //             ),
    //             // child: Column(
    //             //   mainAxisSize: MainAxisSize.min,
    //             //   children: [
    //             //     _buildLocationRow(
    //             //
    //             //     )
    //             //   ],
    //             // ),
    //           ),
    //         )
    //         // Displaying search input for testing purposes
    //       ],
    //     ),
    //   ),
    // );
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
          buildLocationRow(
            Icons.my_location,
            pickupLocation,
            screenWidth,
            iconSize,
          ),
          Divider(
            height: screenWidth * 0.05
          ),
          buildLocationRow(
            Icons.location_on,
            dropOffLocation,
            screenWidth,
            iconSize,
          ),
        ],
      ),
    );
  }

  Widget buildLocationRow(IconData icon, String text, double screenWidth, double iconSize) {
    return Row(
      children: [
        Icon(icon, size: iconSize, color: Colors.blue),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
