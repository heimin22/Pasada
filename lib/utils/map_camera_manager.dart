import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/utils/map_camera_utils.dart';

class MapCameraManager {
  Completer<GoogleMapController>? mapController;
  bool isAnimatingLocation = false;

  // Callback for animation state changes
  Function(bool)? onAnimationStateChanged;

  MapCameraManager({
    this.mapController,
    this.onAnimationStateChanged,
  });

  /// Initialize with map controller
  void initialize(Completer<GoogleMapController> controller) {
    mapController = controller;
  }

  /// Animate camera to a specific location with zoom
  Future<void> animateToLocation(LatLng target, {double zoom = 17.0}) async {
    if (mapController == null) return;

    final GoogleMapController controller = await mapController!.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: target,
        zoom: zoom,
      )),
    );

    // Trigger location pulse animation
    pulseCurrentLocationMarker();
  }

  /// Move camera to fit route bounds
  Future<void> moveCameraToRoute(
    List<LatLng> polylineCoordinates,
    LatLng start,
    LatLng destination, {
    double padding = 0.01,
    double boundPadding = 20.0,
  }) async {
    if (mapController == null || polylineCoordinates.isEmpty) return;

    final controller = await mapController!.future;
    await moveCameraToBounds(
      controller,
      polylineCoordinates,
      padding: padding,
      boundPadding: boundPadding,
    );
  }

  /// Zoom camera to fit bounds of coordinates
  Future<void> zoomToBounds(
    List<LatLng> coordinates, {
    double padding = 0.01,
    double boundPadding = 20.0,
  }) async {
    if (coordinates.isEmpty || mapController == null) return;

    final LatLng start = coordinates.first;
    final LatLng end = coordinates.last;
    await moveCameraToRoute(coordinates, start, end,
        padding: padding, boundPadding: boundPadding);
  }

  /// Animate to current location with cached fallback
  Future<void> animateToLocationWithCache(
    LatLng? currentLocation,
    LatLng? cachedLocation,
  ) async {
    if (mapController == null) return;

    final controller = await mapController!.future;

    if (currentLocation != null) {
      await controller
          .animateCamera(CameraUpdate.newLatLngZoom(currentLocation, 17.0));
      pulseCurrentLocationMarker();
    } else if (cachedLocation != null) {
      await controller
          .animateCamera(CameraUpdate.newLatLngZoom(cachedLocation, 17.0));
      pulseCurrentLocationMarker();
    }
  }

  /// Start location marker pulse animation
  void pulseCurrentLocationMarker() {
    if (isAnimatingLocation) return;

    isAnimatingLocation = true;
    onAnimationStateChanged?.call(true);

    // Reset animation after delay
    Future.delayed(const Duration(seconds: 2), () {
      isAnimatingLocation = false;
      onAnimationStateChanged?.call(false);
    });
  }

  /// Check if currently animating
  bool get isAnimating => isAnimatingLocation;

  /// Move camera to show both pickup and dropoff locations
  Future<void> showPickupAndDropoff(
    LatLng pickup,
    LatLng dropoff, {
    double padding = 0.05,
  }) async {
    if (mapController == null) return;

    final controller = await mapController!.future;

    // Create bounds that include both points
    final coordinates = [pickup, dropoff];
    await moveCameraToBounds(
      controller,
      coordinates,
      padding: padding,
      boundPadding: 50.0,
    );
  }

  /// Move camera to show booking bounds including driver, pickup, and dropoff locations
  Future<void> showBookingBounds(
    LatLng? driverLocation,
    LatLng pickup,
    LatLng dropoff, {
    double padding = 0.05,
  }) async {
    if (mapController == null) return;

    final controller = await mapController!.future;

    // Create bounds that include all relevant points
    final coordinates = <LatLng>[pickup, dropoff];
    if (driverLocation != null) {
      coordinates.add(driverLocation);
    }

    await moveCameraToBounds(
      controller,
      coordinates,
      padding: padding,
      boundPadding: 50.0,
    );
  }

  /// Set camera position without animation
  Future<void> setCameraPosition(
    LatLng target, {
    double zoom = 15.0,
  }) async {
    if (mapController == null) return;

    final controller = await mapController!.future;
    await controller.moveCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: target,
        zoom: zoom,
      )),
    );
  }

  /// Get current camera position
  Future<CameraPosition?> getCurrentCameraPosition() async {
    if (mapController == null) return null;

    try {
      final controller = await mapController!.future;
      return await controller.getVisibleRegion().then((bounds) async {
        // This is a workaround since there's no direct getCameraPosition method
        // We'll use the center of visible region as camera position
        final center = LatLng(
          (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
          (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
        );

        return CameraPosition(target: center, zoom: 15.0);
      });
    } catch (e) {
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    mapController = null;
  }
}
