import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/location/mapScreen.dart';
import '../location/locationSearchScreen.dart';
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
        'map' : (BuildContext context) => const MapScreen(),
        'searchLocation' : (BuildContext context) => const SearchLocationScreen()
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const MapScreen(),
            // Floating search bar
            Positioned(
              top: screenHeight * 0.02, // 2% from the top of the screen
              left: screenWidth * 0.05, // 5% padding from the left
              right: screenWidth * 0.05, // 5% padding from the right
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, 'searchLocation');
                },
                style: ElevatedButton.styleFrom(
                  elevation: 3,
                  backgroundColor: Color(0xFFF5F5F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: EdgeInsets.zero,
                  minimumSize: Size(0, screenHeight * 0.06),
                ),
                // elevation: 3,
                // borderRadius: BorderRadius.circular(24),
                // child: Container(
                //   height:
                //   screenHeight * 0.06, // Adjust height based on screen size
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(24),
                //     color: Colors.white,
                //   ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16), // Left padding
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Where to?',
                          style: TextStyle(
                            color: const Color(0xFFA2A2A2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16), // Right padding
                    ],
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