import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A stable state manager that prevents unnecessary rebuilds and flickering
class MapStableStateManager {
  // Stable polyline storage - only updates when route actually changes
  final Map<PolylineId, Polyline> _stablePolylines = {};

  // Stable marker storage - only updates when markers actually change
  final Map<MarkerId, Marker> _stableMarkers = {};

  // Driver location tracking
  LatLng? _lastDriverLocation;
  String? _lastRideStatus;

  // Change detection
  bool _polylinesChanged = false;
  bool _markersChanged = false;

  // State notifiers for reactive updates
  final ValueNotifier<Set<Polyline>> _polylinesNotifier = ValueNotifier({});
  final ValueNotifier<Set<Marker>> _markersNotifier = ValueNotifier({});

  // Callbacks
  Function()? onStateChanged;
  Function(String)? onError;

  MapStableStateManager({
    this.onStateChanged,
    this.onError,
  });

  /// Get polylines notifier for reactive updates
  ValueNotifier<Set<Polyline>> get polylinesNotifier => _polylinesNotifier;

  /// Get markers notifier for reactive updates
  ValueNotifier<Set<Marker>> get markersNotifier => _markersNotifier;

  /// Get current polylines
  Set<Polyline> get polylines => Set<Polyline>.of(_stablePolylines.values);

  /// Get current markers
  Set<Marker> get markers => Set<Marker>.of(_stableMarkers.values);

  /// Update driver location with intelligent change detection
  void updateDriverLocation(LatLng location, String rideStatus) {
    // Only update if location or status actually changed
    if (_lastDriverLocation != null &&
        _lastRideStatus == rideStatus &&
        _isLocationSimilar(_lastDriverLocation!, location)) {
      // quiet: skip noisy log
      return; // No significant change, skip update
    }

    // quiet
    _lastDriverLocation = location;
    _lastRideStatus = rideStatus;

    // Don't update driver marker here - use directional bus manager instead
    // _updateDriverMarker(location);

    // Notify changes
    _notifyChanges();
  }

  /// Check if two locations are similar (within 10 meters)
  bool _isLocationSimilar(LatLng loc1, LatLng loc2) {
    const double threshold = 0.0001; // ~10 meters
    return (loc1.latitude - loc2.latitude).abs() < threshold &&
        (loc1.longitude - loc2.longitude).abs() < threshold;
  }

  /// Update polyline with change detection
  void updatePolyline(
    PolylineId id,
    List<LatLng> points, {
    Color? color,
    int? width,
    bool forceUpdate = false,
  }) {
    final existingPolyline = _stablePolylines[id];

    // Check if polyline actually changed
    if (!forceUpdate &&
        existingPolyline != null &&
        _arePolylinesSimilar(existingPolyline.points, points)) {
      // quiet
      return; // No significant change, skip update
    }

    // quiet
    _stablePolylines[id] = Polyline(
      polylineId: id,
      points: points,
      color: color ?? const Color.fromARGB(255, 10, 179, 83),
      width: width ?? 4,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
    );

    _polylinesChanged = true;
    _notifyChanges();
  }

  /// Check if two polyline point lists are similar
  bool _arePolylinesSimilar(List<LatLng> points1, List<LatLng> points2) {
    if (points1.length != points2.length) return false;

    const double threshold = 0.0001; // ~10 meters
    for (int i = 0; i < points1.length; i++) {
      if ((points1[i].latitude - points2[i].latitude).abs() > threshold ||
          (points1[i].longitude - points2[i].longitude).abs() > threshold) {
        return false;
      }
    }
    return true;
  }

  /// Add or update marker
  void updateMarker(
    String id,
    LatLng position, {
    BitmapDescriptor? icon,
  }) {
    final markerId = MarkerId(id);
    final existingMarker = _stableMarkers[markerId];

    // Check if marker actually changed
    if (existingMarker != null &&
        _isLocationSimilar(existingMarker.position, position)) {
      return; // No significant change, skip update
    }

    _stableMarkers[markerId] = Marker(
      markerId: markerId,
      position: position,
      icon: icon ?? BitmapDescriptor.defaultMarker,
    );

    _markersChanged = true;
    _notifyChanges();
  }

  /// Remove polyline
  void removePolyline(PolylineId id) {
    if (_stablePolylines.containsKey(id)) {
      _stablePolylines.remove(id);
      _polylinesChanged = true;
      _notifyChanges();
    }
  }

  /// Remove marker
  void removeMarker(String id) {
    final markerId = MarkerId(id);
    if (_stableMarkers.containsKey(markerId)) {
      _stableMarkers.remove(markerId);
      _markersChanged = true;
      _notifyChanges();
    }
  }

  /// Clear all polylines
  void clearAllPolylines() {
    if (_stablePolylines.isNotEmpty) {
      _stablePolylines.clear();
      _polylinesChanged = true;
      _notifyChanges();
    }
  }

  /// Clear all markers
  void clearAllMarkers() {
    if (_stableMarkers.isNotEmpty) {
      _stableMarkers.clear();
      _markersChanged = true;
      _notifyChanges();
    }
  }

  /// Remove driver marker specifically
  void removeDriverMarker() {
    final driverMarkerId = MarkerId('driver');
    if (_stableMarkers.containsKey(driverMarkerId)) {
      _stableMarkers.remove(driverMarkerId);
      _markersChanged = true;
      _notifyChanges();
      // quiet
    }
  }

  /// Clear all overlays
  void clearAll() {
    clearAllPolylines();
    clearAllMarkers();
  }

  /// Notify listeners of changes
  void _notifyChanges() {
    if (_polylinesChanged) {
      _polylinesNotifier.value = Set<Polyline>.of(_stablePolylines.values);
      _polylinesChanged = false;
    }

    if (_markersChanged) {
      _markersNotifier.value = Set<Marker>.of(_stableMarkers.values);
      _markersChanged = false;
    }

    onStateChanged?.call();
  }

  /// Force update all notifiers (for initial load)
  void forceUpdate() {
    _polylinesNotifier.value = Set<Polyline>.of(_stablePolylines.values);
    _markersNotifier.value = Set<Marker>.of(_stableMarkers.values);
    onStateChanged?.call();
  }

  /// Get polyline by ID
  Polyline? getPolyline(PolylineId id) => _stablePolylines[id];

  /// Get marker by ID
  Marker? getMarker(String id) => _stableMarkers[MarkerId(id)];

  /// Check if polyline exists
  bool hasPolyline(PolylineId id) => _stablePolylines.containsKey(id);

  /// Check if marker exists
  bool hasMarker(String id) => _stableMarkers.containsKey(MarkerId(id));

  /// Get polyline count
  int get polylineCount => _stablePolylines.length;

  /// Get marker count
  int get markerCount => _stableMarkers.length;

  /// Dispose resources
  void dispose() {
    _polylinesNotifier.dispose();
    _markersNotifier.dispose();
    _stablePolylines.clear();
    _stableMarkers.clear();
  }
}
