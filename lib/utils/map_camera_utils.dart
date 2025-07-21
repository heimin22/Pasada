import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Moves the camera to fit the given list of LatLng points within view, with padding.
Future<void> moveCameraToBounds(
  GoogleMapController controller,
  List<LatLng> coords, {
  double padding = 0.01,
  int boundPadding = 20,
}) async {
  if (coords.isEmpty) return;

  double southLat = coords.first.latitude;
  double northLat = coords.first.latitude;
  double westLng = coords.first.longitude;
  double eastLng = coords.first.longitude;

  for (final LatLng point in coords) {
    southLat = min(southLat, point.latitude);
    northLat = max(northLat, point.latitude);
    westLng = min(westLng, point.longitude);
    eastLng = max(eastLng, point.longitude);
  }

  southLat -= padding;
  northLat += padding;
  westLng -= padding;
  eastLng += padding;

  final bounds = LatLngBounds(
    southwest: LatLng(southLat, westLng),
    northeast: LatLng(northLat, eastLng),
  );

  await controller.animateCamera(
    CameraUpdate.newLatLngBounds(bounds, boundPadding),
  );
}
