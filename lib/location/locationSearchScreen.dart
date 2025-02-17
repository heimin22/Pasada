import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/location/autocompletePrediction.dart';
import 'package:pasada_passenger_app/location/networkUtilities.dart';
import 'package:pasada_passenger_app/location/placeAutocompleteResponse.dart';
import 'locationListTile.dart';
import 'package:pasada_passenger_app/home/selectionScreen.dart';
import 'package:pasada_passenger_app/home/homeScreen.dart';
import 'package:http/http.dart' as http;
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

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   // Find the HomeScreenPageState from the widget tree
  //   final modalRoute = ModalRoute.of(context);
  //   if (modalRoute != null) {
  //     final navigator = Navigator.of(context);
  //     // Check if the navigator's key is a GlobalKey
  //     if (navigator.widget.key is GlobalKey) {
  //       final GlobalKey navKey = navigator.widget.key as GlobalKey;
  //       final navigatorState = navKey.currentState as NavigatorState;
  //       // **Safe check to ensure pages list is not empty before accessing first element**
  //       if (navigatorState.widget.pages.isNotEmpty) {
  //         final homeScreenPage = navigatorState.widget.pages.first;
  //         if (homeScreenPage.key is GlobalKey<HomeScreenPageState>) {
  //           // Cast to GlobalKey<HomeScreenPageState> only if the key is of the correct type
  //           final homeScreenKey = homeScreenPage.key as GlobalKey<HomeScreenPageState>;
  //           homeScreenState = homeScreenKey.currentState;
  //         } else {
  //           print("Warning: First page key is not GlobalKey<HomeScreenPageState>");
  //         }
  //       } else {
  //         print("Warning: Navigator pages list is empty, cannot access first page.");
  //       }
  //     } else {
  //       print("Warning: Navigator key is not a GlobalKey.");
  //     }
  //   }
  // }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   // hahanapin yung HomeScreenPageState from the widget tree
  //   final modalRoute = ModalRoute.of(context);
  //   if (modalRoute != null) {
  //     final navigator = Navigator.of(context);
  //     if (navigator.widget.key is GlobalKey) {
  //       final GlobalKey navKey = navigator.widget.key as GlobalKey;
  //       final navigatorState = navKey.currentState as NavigatorState;
  //       if (navigatorState.widget.pages.isNotEmpty) {
  //         final homeScreenPage = navigatorState.widget.pages.first;
  //         if (homeScreenPage.key is GlobalKey<HomeScreenPageState>) {
  //           final homeScreen = navigatorState.widget.pages.first.key
  //           as GlobalKey<HomeScreenPageState>;
  //         }
  //       }
  //       homeScreenState = homeScreen.currentState;
  //     }
  //   }
  // }

  Future<void> placeAutocomplete(String query) async {
    if (query.isEmpty) {
      setState(() => placePredictions = []);
      return;
    }

    final String apiKey = dotenv.env["MAPS_API_KEY"] ?? '';
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
      final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';
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
      // final url = Uri.parse(
      //   'https://maps.googleapis.com/maps/api/place/details/json?place_id=${prediction.placeID}&key=$apiKey',
      // );

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
    // final isPickup = homeScreenState?.isSearchingPickup ?? true;
    // final searchType = isPickup ? 'Pick-up' : 'Drop-off';
    return Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 17),
            child: CircleAvatar(
              backgroundColor: Color(0xFFDADADA),
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
              color: Color(0xFF000000),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            CircleAvatar(
              backgroundColor: Color(0xFFDADADA),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF000000)),
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
                  decoration: InputDecoration(
                    fillColor: Color(0xFFf5f5f5),
                    border: InputBorder.none,
                    hintText: 'Search location',
                    hintStyle: TextStyle(
                      fontSize: 14,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
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
            Padding(
              padding: const EdgeInsets.all(ShimmerEffect.defaultPadding),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: SvgPicture.asset(
                  'assets/svg/navigation.svg',
                  height: 16,
                ),
                label: const Text(
                  'Use My Current Location',
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
            const Divider(
              height: 0,
              thickness: 4,
              color: Color(0xFFE9E9E9),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: placePredictions.length,
                itemBuilder: (context, index) => LocationListTile(
                  press: () => onPlaceSelected(placePredictions[index]),
                  location: placePredictions[index].description!,
                ),
              ),
            ),
          ],
        ));
  }
}
