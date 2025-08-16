import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/screens/routeSelection.dart';
import 'package:pasada_passenger_app/location/locationSearchScreen.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';

/// Navigates to the route selection screen and returns the selected route map.
Future<Map<String, dynamic>?> navigateToRouteSelection(
    BuildContext context) async {
  return await Navigator.push<Map<String, dynamic>>(
    context,
    MaterialPageRoute(builder: (_) => RouteSelection()),
  );
}

/// Navigates to the location search screen and returns the selected location.
Future<SelectedLocation?> navigateToLocationSearch(
  BuildContext context, {
  required bool isPickup,
  int? routeID,
  Map<String, dynamic>? routeDetails,
  List<LatLng>? routePolyline,
  int? pickupOrder,
  SelectedLocation? selectedPickUpLocation,
  SelectedLocation? selectedDropOffLocation,
}) async {
  return await Navigator.of(context).push<SelectedLocation>(
    MaterialPageRoute(
      builder: (ctx) => SearchLocationScreen(
        isPickup: isPickup,
        routeID: routeID,
        routeDetails: routeDetails,
        routePolyline: routePolyline,
        pickupOrder: pickupOrder,
        selectedPickUpLocation: selectedPickUpLocation,
        selectedDropOffLocation: selectedDropOffLocation,
      ),
    ),
  );
}
