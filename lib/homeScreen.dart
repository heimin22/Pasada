import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/notificationScreen.dart';
import 'package:pasada_passenger_app/activityScreen.dart';
import 'package:pasada_passenger_app/profileSettingsScreen.dart';
import 'package:pasada_passenger_app/settingsScreen.dart';
import 'package:pasada_passenger_app/homeScreen.dart';

void main() => runApp(const HomeScreen());

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
   late GoogleMapController mapController;
   LocationData? _currentLocation;
   late Location _location;

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

   // Future<void> _openGoogleMapsWithCurrentLocation(Location location) async {
   //   try {
   //   // get the user's current location
   //   LocationData locationData = await location.getLocation();
   //   // launch Waze
   //   final latitude = locationData.latitude;
   //   final longitude = locationData.longitude;
   //
   //   if (latitude != null && longitude != null) {
   //     final url = 'https://www.google.com/maps/dir/?api=1&destination=<latitude>,<longitude>';
   //     if (await canLaunch(url)) {
   //       await launch(url);
   //     } else {
   //       _showError('Could not launch Google Maps');
   //     }
   //   } else {
   //     _showError('Could not fetch location.');
   //   }
   // } catch (e) {
   //   _showError(e.toString());
   //   }
   // }

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
     if (_currentLocation == null) {
       return Scaffold(
         body: Center(child: CircularProgressIndicator()),
       );
     }
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Flexible(
              child: Container(
                // padding: ,
                child: Text(
                    'Home'
                ),
              ),
            )
          ],
        ),
        // child: GoogleMap(
        //   onMapCreated: _onMapCreated,
        //   initialCameraPosition: CameraPosition(
        //     target: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        //     zoom: 15,
        //   ),
        //   myLocationEnabled: true,
        //   myLocationButtonEnabled: true,
        // ),
      ),
    );
  }
}