import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:h3_flutter/h3_flutter.dart';
import 'package:flutter/foundation.dart';

class GeospatialService {
  // use factory para sa WebAssembly
  final h3 = H3Factory().load();

  // so ito yung configuration
  /*
     Higher resolution = smaller hexagons, mas precise per mas maraming computations
     Level 9: ~174m edge length. Good balance for city blocks.
     Level 10: ~66m edge length. More granular.
  */
  final int h3Resolution = 9;

  // convert ko yung latlng coordinates to an H3 index string configured resolution
  String latLngToH3Index(LatLng coordinates) {
    try {
      // longitude muna kinukuha ni h3 for geoToH3
      final h3Index = h3.geoToH3(
        GeoCoord(lon: coordinates.longitude, lat: coordinates.latitude), h3Resolution
      );

      // return natin as hex string para mas madali storage/comparison
      return h3Index.toRadixString(16);
    } catch (e) {
      debugPrint('Error converting Latlng to H3: $e');
      return '';
    }
  }

  // convert yung h3 index string back sa LatLng coordinates
  LatLng h3IndexToLatLng(String h3IndexHex) {
    try {
      final h3Index = BigInt.parse(h3IndexHex, radix: 16);
      final geoCoord = h3.h3ToGeo(h3Index);
      // h3 returns lon, let - convert natin back to LatLng (lat, lon)
      return LatLng(geoCoord.lat, geoCoord.lon);
    } catch (e) {
      debugPrint("Error converting H3 hex to LatLng: $e");
      // return ng default ot throw
      return const LatLng(0, 0);
    }
  }

  //
}