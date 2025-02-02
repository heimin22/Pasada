import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pasada_passenger_app/location/autocompletePrediction.dart';
import 'package:pasada_passenger_app/location/networkUtilities.dart';
import 'package:pasada_passenger_app/location/placeAutocompleteResponse.dart';
import 'locationListTile.dart';
import 'package:pasada_passenger_app/home/selectionScreen.dart';
import 'package:pasada_passenger_app/home/homeScreen.dart';


class SearchLocationStateless extends StatelessWidget {
  const SearchLocationStateless({super.key});

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
      home: const SearchLocationScreen(),
      routes: <String, WidgetBuilder>{
        'selection': (context) => const selectionScreen(),
        'homeScreen': (context) => const HomeScreen(),
      },
    );
  }
}

class SearchLocationScreen extends StatefulWidget {
  const SearchLocationScreen({super.key});

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {

  List<AutocompletePrediction> placePredictions = [];

  Future<void> placeAutocomplete(String query) async {
    final String apiKey = dotenv.env["MAPS_API_KEY"] ?? '';

    if (apiKey.isEmpty) {
      if (kDebugMode) print("API Key is not configured!");
      return;
    }

    Uri uri = Uri.https(
      "maps.googleapis.com",
      "maps/api/place/autocomplete/json", // decoder path
      {
        "input": query, // query parameter
        "key": apiKey, //
      });
    if (kDebugMode) print(uri);
    String? response = await NetworkUtility.fetchUrl(uri);

    if (response != null) {
      PlaceAutocompleteResponse result = PlaceAutocompleteResponse.parseAutocompleteResult(response);
      if (result.prediction != null) {
        setState(() {
          placePredictions = result.prediction!;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
            'Set Pick-up Location',
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
                  hintText: 'Search your location',
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
                onPressed: () {
                },
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
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 85),
                // fixedSize: const Size(double.infinity, 40),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          ),
          const Divider(
            height: 4,
            thickness: 4,
            color: Color(0xFFE9E9E9),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: placePredictions.length,
                itemBuilder: (context, index) => LocationListTile(
                  press: () {},
                  location: placePredictions[index].description!,
                ),
              ),
          ),
          ],
      )
    );
  }
}
