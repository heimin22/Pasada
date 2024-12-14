import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
   // final String apiKey = dotenv.env['API_KEY']!;
   late GoogleMapController mapController;
   LocationData? _currentLocation;
   late Location _location;
   String _searchText = "";

   @override
   void initState() {
     super.initState();
     _location = Location();
     _checkPermissionsAndNavigate();
   }

   Future<void> _checkPermissionsAndNavigate() async {
     try {
       // check if location service is enabled
       bool serviceEnabled = await _location.serviceEnabled();
       if (!serviceEnabled) {
         serviceEnabled = await _location.requestService();
         if (!serviceEnabled) {
           _showLocationServicesDialog();
           return;
         }
       }
       // check for and request location permissions
       PermissionStatus permissionGranted = await _location.hasPermission();
       if (permissionGranted == PermissionStatus.denied) {
         permissionGranted = await _location.requestPermission();
         if (permissionGranted != PermissionStatus.granted) {
           _showPermissionDialog();
           return;
         }
       }
       // get current location
       _currentLocation = await _location.getLocation();
       if (_currentLocation != null) {
         setState(() {});
       } else {
         _showLocationErrorDialog();
       }
     } catch (e) {
       _showErrorDialog("An error occurred while fetching the location.");
     }
  }

   void _onMapCreated(GoogleMapController controller) {
     mapController = controller;
   }

   void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(
          'This app needs location permission to work. Please allow it in your settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Ok'),
          ),
        ],
      ),
    );
  }

  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enable Location Services'),
        content: Text(
          'Location services are disabled. Please enable them to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

   void _showLocationErrorDialog() {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text('Location Error'),
         content: Text('Unable to fetch the current location. Please try again later.'),
         actions: [
           TextButton(
             onPressed: () => Navigator.of(context).pop(),
             child: Text('OK'),
           ),
         ],
       ),
     );
   }

   void _showErrorDialog(String message) {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text('Error'),
         content: Text(message),
         actions: [
           TextButton(
             onPressed: () => Navigator.of(context).pop(),
             child: Text('OK'),
           ),
         ],
       ),
     );
   }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // ensure that the location is fetched before building the map
    if (_currentLocation == null) {
       return Scaffold(
         body: Center(child: CircularProgressIndicator()),
       );
     }
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentLocation!.latitude!,
                  _currentLocation!.longitude!,
                ),
                zoom: 15,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
            ),
            // Floating search bar
            Positioned(
              top: screenHeight * 0.02, // 2% from the top of the screen
              left: screenWidth * 0.05, // 5% padding from the left
              right: screenWidth * 0.15, // 5% padding from the right
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height:
                  screenHeight * 0.06, // Adjust height based on screen size
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16), // Left padding
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchText =
                                  value; // Update state with search input
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search for routes',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                                color: Color(0xFFA2A2A2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16), // Right padding
                    ],
                  ),
                ),
              ),
            ),
            // Displaying search input for testing purposes
          ],
        ),
      ),
    );
  }
}