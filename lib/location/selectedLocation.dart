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

// List<List<double>> decodePolyline(String encoded) {
//   List<List<double>> points = [];
//   int index = 0;
//   int len = encoded.length;
//   int lat = 0;
//   int lng = 0;
//
//   while (index < len) {
//     int b;
//     int shift = 0;
//     int result = 0;
//
//     // ito yung magdedecode sa latitude
//     do {
//       b = encoded.codeUnitAt(index++) - 63;
//       result |= (b & 0x1F) << shift;
//       shift += 5;
//     } while (b >= 0x20);
//
//     int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//     lat += dlat;
//
//     // ito naman yung magdedecode sa longitude
//     shift = 0;
//     result = 0;
//     do {
//       b = encoded.codeUnitAt(index++) - 63;
//       result |= (b & 0x1F) << shift;
//       shift += 5;
//     } while (b >= 0x20);
//
//     int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//     lng += dlng;
//
//     points.add([lat / 1E5, lng / 1E5]);
//   }
//
//   return points;
// }