import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

class MapMarkerManager {
  // Markers storage
  Map<MarkerId, Marker> markers = {};

  // Custom icons
  BitmapDescriptor? busIcon;
  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? dropoffIcon;

  // Callbacks
  Function()? onStateChanged;

  MapMarkerManager({
    this.onStateChanged,
  });

  /// Initialize custom marker icons
  Future<void> initializeIcons() async {
    busIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(48, 48)),
      'assets/png/bus.png',
    );
    pickupIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(48, 48)),
      'assets/png/pin_pickup.png',
    );
    dropoffIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(48, 48)),
      'assets/png/pin_dropoff.png',
    );
  }

  /// Add pickup location marker
  void addPickupMarker(LatLng location) {
    if (pickupIcon == null) return;

    final pickupMarkerId = MarkerId('pickup');
    markers[pickupMarkerId] = Marker(
      markerId: pickupMarkerId,
      position: location,
      icon: pickupIcon!,
    );
    onStateChanged?.call();
  }

  /// Add dropoff location marker
  void addDropoffMarker(LatLng location) {
    if (dropoffIcon == null) return;

    final dropoffMarkerId = MarkerId('dropoff');
    markers[dropoffMarkerId] = Marker(
      markerId: dropoffMarkerId,
      position: location,
      icon: dropoffIcon!,
    );
    onStateChanged?.call();
  }

  /// Add or update driver marker
  void updateDriverMarker(LatLng location) {
    if (busIcon == null) return;

    final driverMarkerId = MarkerId('driver');
    markers[driverMarkerId] = Marker(
      markerId: driverMarkerId,
      position: location,
      icon: busIcon!,
    );
    onStateChanged?.call();
  }

  /// Add custom marker
  void addMarker(
    String id,
    LatLng position, {
    BitmapDescriptor? icon,
    String? infoWindowTitle,
    String? infoWindowSnippet,
    Function(MarkerId)? onTap,
  }) {
    final markerId = MarkerId(id);
    markers[markerId] = Marker(
      markerId: markerId,
      position: position,
      icon: icon ?? BitmapDescriptor.defaultMarker,
      infoWindow: InfoWindow(
        title: infoWindowTitle,
        snippet: infoWindowSnippet,
      ),
      onTap: onTap != null ? () => onTap(markerId) : null,
    );
    onStateChanged?.call();
  }

  /// Remove specific marker
  void removeMarker(String id) {
    final markerId = MarkerId(id);
    markers.remove(markerId);
    onStateChanged?.call();
  }

  /// Remove pickup marker
  void removePickupMarker() {
    removeMarker('pickup');
  }

  /// Remove dropoff marker
  void removeDropoffMarker() {
    removeMarker('dropoff');
  }

  /// Remove driver marker
  void removeDriverMarker() {
    removeMarker('driver');
  }

  /// Clear all markers
  void clearAllMarkers() {
    markers.clear();
    onStateChanged?.call();
  }

  /// Build markers set for GoogleMap
  Set<Marker> buildMarkers({
    LatLng? pickupLocation,
    LatLng? dropoffLocation,
    LatLng? driverLocation,
  }) {
    final markerSet = <Marker>{};

    // Add pickup marker if location provided and icon available
    if (pickupLocation != null && pickupIcon != null) {
      final pickupMarkerId = MarkerId('pickup');
      markers[pickupMarkerId] = Marker(
        markerId: pickupMarkerId,
        position: pickupLocation,
        icon: pickupIcon!,
      );
    }

    // Add dropoff marker if location provided and icon available
    if (dropoffLocation != null && dropoffIcon != null) {
      final dropoffMarkerId = MarkerId('dropoff');
      markers[dropoffMarkerId] = Marker(
        markerId: dropoffMarkerId,
        position: dropoffLocation,
        icon: dropoffIcon!,
      );
    }

    // Add driver marker if location provided and icon available
    if (driverLocation != null && busIcon != null) {
      final driverMarkerId = MarkerId('driver');
      markers[driverMarkerId] = Marker(
        markerId: driverMarkerId,
        position: driverLocation,
        icon: busIcon!,
      );
    }

    // Convert map to set
    markerSet.addAll(markers.values);
    return markerSet;
  }

  /// Get marker by ID
  Marker? getMarker(String id) {
    final markerId = MarkerId(id);
    return markers[markerId];
  }

  /// Check if marker exists
  bool hasMarker(String id) {
    final markerId = MarkerId(id);
    return markers.containsKey(markerId);
  }

  /// Update marker position
  void updateMarkerPosition(String id, LatLng newPosition) {
    final markerId = MarkerId(id);
    final existingMarker = markers[markerId];

    if (existingMarker != null) {
      markers[markerId] = existingMarker.copyWith(
        positionParam: newPosition,
      );
      onStateChanged?.call();
    }
  }

  /// Update marker icon
  void updateMarkerIcon(String id, BitmapDescriptor newIcon) {
    final markerId = MarkerId(id);
    final existingMarker = markers[markerId];

    if (existingMarker != null) {
      markers[markerId] = existingMarker.copyWith(
        iconParam: newIcon,
      );
      onStateChanged?.call();
    }
  }

  /// Get all current markers
  Set<Marker> get allMarkers => Set<Marker>.of(markers.values);

  /// Get marker count
  int get markerCount => markers.length;

  /// Get pickup marker location
  LatLng? get pickupLocation {
    final marker = getMarker('pickup');
    return marker?.position;
  }

  /// Get dropoff marker location
  LatLng? get dropoffLocation {
    final marker = getMarker('dropoff');
    return marker?.position;
  }

  /// Get driver marker location
  LatLng? get driverLocation {
    final marker = getMarker('driver');
    return marker?.position;
  }

  /// Check if icons are loaded
  bool get iconsLoaded =>
      busIcon != null && pickupIcon != null && dropoffIcon != null;

  /// Dispose resources
  void dispose() {
    clearAllMarkers();
  }
}
