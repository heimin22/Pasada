import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Manages polyline state to prevent flickering during driver location updates
class MapPolylineStateManager {
  // Persistent polyline storage
  final Map<PolylineId, Polyline> _polylines = {};

  // State change notifier
  final ValueNotifier<Set<Polyline>> _polylinesNotifier = ValueNotifier({});

  // Animation timers for route drawing
  final Map<PolylineId, Timer> _animationTimers = {};

  // Callbacks
  Function()? onStateChanged;
  Function(String)? onError;

  MapPolylineStateManager({
    this.onStateChanged,
    this.onError,
  });

  /// Get current polylines as a ValueNotifier for reactive updates
  ValueNotifier<Set<Polyline>> get polylinesNotifier => _polylinesNotifier;

  /// Get current polylines set
  Set<Polyline> get polylines => Set<Polyline>.of(_polylines.values);

  /// Add or update a polyline without triggering full rebuild
  void updatePolyline(
    PolylineId id,
    List<LatLng> points, {
    Color? color,
    int? width,
    bool animate = false,
  }) {
    // Cancel any existing animation for this polyline
    _animationTimers[id]?.cancel();
    _animationTimers.remove(id);

    if (animate && points.length > 1) {
      _animatePolylineDrawing(id, points, color, width);
    } else {
      _addStaticPolyline(id, points, color, width);
    }
  }

  /// Add static polyline without animation
  void _addStaticPolyline(
    PolylineId id,
    List<LatLng> points,
    Color? color,
    int? width,
  ) {
    _polylines[id] = Polyline(
      polylineId: id,
      points: points,
      color: color ?? const Color.fromARGB(255, 10, 179, 83),
      width: width ?? 4,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
    );

    _notifyStateChanged();
  }

  /// Animate polyline drawing point by point
  void _animatePolylineDrawing(
    PolylineId id,
    List<LatLng> fullRoute,
    Color? color,
    int? width,
  ) {
    int count = 0;
    final total = fullRoute.length;
    final effectiveColor = color ?? const Color.fromARGB(255, 10, 179, 83);
    final effectiveWidth = width ?? 4;

    final timer = Timer.periodic(const Duration(milliseconds: 26), (timer) {
      count += 2;
      final int currentCount = count.clamp(0, total);
      final segment = fullRoute.sublist(0, currentCount);

      _polylines[id] = Polyline(
        polylineId: id,
        points: segment,
        color: effectiveColor,
        width: effectiveWidth,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      );

      _notifyStateChanged();

      if (count >= total) {
        timer.cancel();
        _animationTimers.remove(id);
      }
    });

    _animationTimers[id] = timer;
  }

  /// Remove specific polyline
  void removePolyline(PolylineId id) {
    _animationTimers[id]?.cancel();
    _animationTimers.remove(id);
    _polylines.remove(id);
    _notifyStateChanged();
  }

  /// Clear all polylines
  void clearAllPolylines() {
    // Cancel all animations
    for (final timer in _animationTimers.values) {
      timer.cancel();
    }
    _animationTimers.clear();

    _polylines.clear();
    _notifyStateChanged();
  }

  /// Check if polyline exists
  bool hasPolyline(PolylineId id) => _polylines.containsKey(id);

  /// Get polyline by ID
  Polyline? getPolyline(PolylineId id) => _polylines[id];

  /// Get total number of polylines
  int get polylineCount => _polylines.length;

  /// Update existing polyline points only (for driver route updates)
  void updatePolylinePoints(PolylineId id, List<LatLng> newPoints) {
    final existingPolyline = _polylines[id];
    if (existingPolyline != null) {
      _polylines[id] = existingPolyline.copyWith(
        pointsParam: newPoints,
      );
      _notifyStateChanged();
    }
  }

  /// Update polyline color
  void updatePolylineColor(PolylineId id, Color color) {
    final existingPolyline = _polylines[id];
    if (existingPolyline != null) {
      _polylines[id] = existingPolyline.copyWith(
        colorParam: color,
      );
      _notifyStateChanged();
    }
  }

  /// Update polyline width
  void updatePolylineWidth(PolylineId id, int width) {
    final existingPolyline = _polylines[id];
    if (existingPolyline != null) {
      _polylines[id] = existingPolyline.copyWith(
        widthParam: width,
      );
      _notifyStateChanged();
    }
  }

  /// Notify listeners of state changes
  void _notifyStateChanged() {
    _polylinesNotifier.value = Set<Polyline>.of(_polylines.values);
    onStateChanged?.call();
  }

  /// Check if any animations are running
  bool get hasActiveAnimations => _animationTimers.isNotEmpty;

  /// Cancel all animations
  void cancelAllAnimations() {
    for (final timer in _animationTimers.values) {
      timer.cancel();
    }
    _animationTimers.clear();
  }

  /// Dispose resources
  void dispose() {
    cancelAllAnimations();
    clearAllPolylines();
    _polylinesNotifier.dispose();
  }
}
