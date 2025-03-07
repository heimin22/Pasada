import 'package:google_maps_flutter/google_maps_flutter.dart';

class SelectedLocation {
  // final String placeID;
  final String address;
  final LatLng coordinates;

  SelectedLocation({
    // required this.placeID,
    required this.address,
    required this.coordinates,
  });
}

