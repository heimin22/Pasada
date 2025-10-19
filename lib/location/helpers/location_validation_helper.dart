import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/models/stop.dart';
import 'package:pasada_passenger_app/services/allowedStopsServices.dart';
import 'package:pasada_passenger_app/widgets/responsive_dialogs.dart';

import 'distance_helper.dart';

/// Helper class for location validation logic
class LocationValidationHelper {
  final DistanceHelper _distanceHelper = DistanceHelper();
  final StopsService _stopsService = StopsService();

  /// Check if a location is already selected
  bool isLocationAlreadySelected(
    LatLng coordinates,
    bool isPickup,
    SelectedLocation? selectedPickUpLocation,
    SelectedLocation? selectedDropOffLocation,
  ) {
    // Get the already selected location (the opposite of what we're currently selecting)
    SelectedLocation? alreadySelected =
        isPickup ? selectedDropOffLocation : selectedPickUpLocation;

    if (alreadySelected == null) return false;

    // Check if coordinates are within 50 meters of the already selected location
    const double thresholdMeters = 50.0;
    final distance = _distanceHelper.calculateDistance(
        coordinates, alreadySelected.coordinates);
    return distance < thresholdMeters;
  }

  /// Check if selected location is too close to the final stop
  Future<bool> isLocationNearFinalStop(LatLng location, int? routeID) async {
    if (routeID == null) return false;

    try {
      // Get all stops for the route
      final stops = await _stopsService.getStopsForRoute(routeID);

      // Find the stop with the highest order (the final stop)
      Stop? finalStop;
      int highestOrder = -1;

      for (var stop in stops) {
        if (stop.order > highestOrder) {
          highestOrder = stop.order;
          finalStop = stop;
        }
      }

      if (finalStop == null) return false;

      // Check if the location is within X meters of the final stop (using 300m as threshold)
      final distance =
          _distanceHelper.calculateDistance(location, finalStop.coordinates);
      return distance < 300; // Return true if within 300 meters of final stop
    } catch (e) {
      debugPrint('Error checking distance to final stop: $e');
      return false;
    }
  }

  /// Check pickup distance and show warning if needed
  Future<bool> checkPickupDistance(
    LatLng pickupLocation,
    LatLng? currentLocation,
    BuildContext context,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (currentLocation == null) return true;

    final selectedLoc = SelectedLocation("", pickupLocation);
    final distance = selectedLoc.distanceFrom(currentLocation);

    if (distance > 1.0) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => ResponsiveDialog(
          title: 'Distance Warning',
          content: Text(
            'The selected pick-up location is quite far from your current location',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              fontSize: 13,
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFF00CC58), width: 3),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                minimumSize: const Size(150, 40),
                backgroundColor: Colors.transparent,
                foregroundColor: isDarkMode
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFF121212),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  fontSize: 15,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                minimumSize: const Size(150, 40),
                backgroundColor: const Color(0xFF00CC58),
                foregroundColor: const Color(0xFFF5F5F5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );
      return proceed ?? false;
    }
    return true;
  }

  /// Show location already selected dialog
  Future<void> showLocationAlreadySelectedDialog(
    BuildContext context,
    bool isPickup,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Already Selected'),
        content: Text(
          'This location is already selected as your ${isPickup ? 'drop-off' : 'pick-up'} location. Please choose a different location.',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            fontSize: 13,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show invalid pickup location dialog
  Future<void> showInvalidPickupLocationDialog(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid Pick-up Location'),
        content: Text(
          'This location is too close to the final stop of the route. Please select a different pick-up location.',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            fontSize: 13,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show invalid stop order dialog
  Future<void> showInvalidStopOrderDialog(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid Stop Order'),
        content: Text(
          'Drop-off must be after pick-up for this route.',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            fontSize: 13,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
