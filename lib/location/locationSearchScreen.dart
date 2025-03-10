import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pasada_passenger_app/location/autocompletePrediction.dart';
import 'package:pasada_passenger_app/location/networkUtilities.dart';
import 'package:pasada_passenger_app/location/placeAutocompleteResponse.dart';
import 'locationListTile.dart';
// import 'package:pasada_passenger_app/home/selectionScreen.dart';
import 'package:pasada_passenger_app/home/homeScreen.dart';
// import 'package:http/http.dart' as http;
import 'selectedLocation.dart';


class SearchLocationScreen extends StatefulWidget {
  // final Function(SelectedLocation)? onLocationSelected;
  final bool isPickup;
  const SearchLocationScreen({super.key, required this.isPickup});

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  final TextEditingController searchController = TextEditingController();
  List<AutocompletePrediction> placePredictions = [];
  HomeScreenPageState? homeScreenState;

  @override
  void initState() {
    super.initState();
    searchController.addListener(onSearchChanged);
  }

  void onSearchChanged() => placeAutocomplete(searchController.text);


  Future<void> placeAutocomplete(String query) async {
    if (query.isEmpty) {
      setState(() => placePredictions = []);
      return;
    }

    final String apiKey = dotenv.env["ANDROID_MAPS_API_KEY"] ?? '';
    if (apiKey.isEmpty) {
      if (kDebugMode) print("API Key is not configured!");
      return;
    }

    Uri uri = Uri.https(
      "maps.googleapis.com",
      "maps/api/place/autocomplete/json",
      {
        "input": query,
        "key": apiKey,
        "components": "country:PH", // Optional: limit to Philippines
      },
    );

    final response = await NetworkUtility.fetchUrl(uri);
    if (response != null) {
      final result = PlaceAutocompleteResponse.parseAutocompleteResult(
          response);
      setState(() => placePredictions = result.prediction ?? []);
    }
  }


  void onPlaceSelected(AutocompletePrediction prediction) async {
    final apiKey = dotenv.env['ANDROID_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) return;
    final uri = Uri.https(
      "maps.googleapis.com",
      "maps/api/place/details/json",
      {
        "place_id": prediction.placeID, // Ensure correct property name
        "key": apiKey,
        "fields": "geometry,name"
      },
    );

    final response = await NetworkUtility.fetchUrl(uri);
    if (response != null) {
      final data = json.decode(response);
      final location = data['result']['geometry']['location'];
      Navigator.pop(
        context,
        SelectedLocation(
          address: prediction.description!,
          coordinates: LatLng(location['lat'], location['lng']),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// searching location label
        appBar: AppBar(
          backgroundColor: Color(0xFFF5F5F5),
          elevation: 4,
          leading: Padding(
            padding: const EdgeInsets.only(left: 17),
            child: CircleAvatar(
              backgroundColor: Color(0xFFf5f5f5),
              radius: 15,
              child: SvgPicture.asset(
                'assets/svg/navigation.svg',
                height: 16,
                width: 16,
              ),
            ),
          ),
          title: Text(
            'Set ${widget.isPickup ? 'Pick-up' : 'Drop-off'} Location',
            style: TextStyle(
              color: Color(0xFF121212),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            CircleAvatar(
              backgroundColor: Color(0xFFF5F5F5),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF121212)),
              ),
            ),
            const SizedBox(width: 16)
          ],
        ),
        body: Column(
          children: [
            Form(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextFormField(
                  onChanged: (value) {
                    placeAutocomplete(value);
                  },
                  textInputAction: TextInputAction.search,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF121212),
                  ),
                  decoration: InputDecoration(
                    fillColor: Color(0xFFf5f5f5),
                    border: InputBorder.none,
                    hintText: 'Search location',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: SvgPicture.asset(
                        'assets/svg/locationPin.svg',
                        height: 12,
                        width: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Divider(
              height: 0,
              thickness: 4,
              color: Color(0xFFE9E9E9),
            ),
            if (widget.isPickup) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              // padding: const EdgeInsets.all(ShimmerEffect.defaultPadding) ,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final Location locationService = Location();

                  // get current position
                  try {
                    final LocationData locationData =
                        await locationService.getLocation();
                    final LatLng currentLatLng =
                        LatLng(locationData.latitude!, locationData.longitude!);

                    // get address using reverse geocoding
                    final SelectedLocation? currentLocation =
                        await reverseGeocode(currentLatLng);

                    if (currentLocation != null && mounted) {
                      Navigator.pop(context, currentLocation);
                    }
                  } catch (e) {
                    debugPrint("Error getting location: $e");
                  }
                },
                icon: SvgPicture.asset(
                  'assets/svg/navigation.svg',
                  height: 16,
                ),
                label: const Text(
                  'Use My Current Location',
                  style: TextStyle(
                    color: Color(0xFF121212),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFDADADA),
                  foregroundColor: Color(0xFF000000),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 85),
                  // fixedSize: const Size(double.infinity, 40),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
          const Divider(
              height: 0,
              thickness: 4,
              color: Color(0xFFE9E9E9),
            ),
            Expanded(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ListView.builder(
                  itemCount: placePredictions.length,
                  itemBuilder: (context, index) => SizedBox(
                    height: 57,
                    child: LocationListTile(
                      press: () => onPlaceSelected(placePredictions[index]),
                      location: placePredictions[index].description?.toString() ?? 'Unknown',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

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
      if (data['status'] == 'REQUEST_DENIED') {
        debugPrint("Request denied: ${data['error_message']}");
        return null;
      }

      if (data['results'] != null && data['results'].isNotEmpty) {
        return SelectedLocation(
          address: data['results'][0]['formatted_address'],
          coordinates: position,
        );
      }
    } catch (e) {
      debugPrint("Error in reverseGeocode: $e");
    }
    return null;
  }

  Widget pinFromTheMaps() {
    return Container(

    );
  }


  @override
  void dispose() {
    searchController.removeListener(onSearchChanged);
    searchController.dispose();
    super.dispose();
  }
}
