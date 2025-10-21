import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Optimized polyline manager that implements batch updates and prevents unnecessary recreations
class OptimizedPolylineManager {
  // Persistent polyline storage
  final Map<PolylineId, Polyline> _polylines = {};

  // Change detection
  bool _polylinesChanged = false;

  // State notifier for reactive updates
  final ValueNotifier<Set<Polyline>> _polylinesNotifier = ValueNotifier({});

  // Batch update queue
  final List<PolylineUpdate> _pendingUpdates = [];
  Timer? _batchUpdateTimer;

  // Animation timers for route drawing
  final Map<PolylineId, Timer> _animationTimers = {};

  // Callbacks
  Function()? onStateChanged;
  Function(String)? onError;

  OptimizedPolylineManager({
    this.onStateChanged,
    this.onError,
  });

  /// Get polylines notifier for reactive updates
  ValueNotifier<Set<Polyline>> get polylinesNotifier => _polylinesNotifier;

  /// Get current polylines
  Set<Polyline> get polylines => Set<Polyline>.of(_polylines.values);

  /// Batch update multiple polylines at once
  void batchUpdatePolylines(List<PolylineUpdate> updates) {
    _pendingUpdates.addAll(updates);

    // Cancel existing timer
    _batchUpdateTimer?.cancel();

    // Schedule batch update
    _batchUpdateTimer = Timer(const Duration(milliseconds: 16), () {
      _processBatchUpdates();
    });
  }

  /// Process all pending polyline updates in a single operation
  void _processBatchUpdates() {
    if (_pendingUpdates.isEmpty) return;

    bool hasChanges = false;

    for (final update in _pendingUpdates) {
      switch (update.type) {
        case PolylineUpdateType.add:
        case PolylineUpdateType.update:
          if (_shouldUpdatePolyline(update.polyline)) {
            _polylines[update.polyline.polylineId] = update.polyline;
            hasChanges = true;
          }
          break;
        case PolylineUpdateType.remove:
          if (_polylines.containsKey(update.polyline.polylineId)) {
            _polylines.remove(update.polyline.polylineId);
            hasChanges = true;
          }
          break;
      }
    }

    _pendingUpdates.clear();

    if (hasChanges) {
      _polylinesChanged = true;
      _notifyChanges();
    }
  }

  /// Check if polyline should be updated (points change threshold)
  bool _shouldUpdatePolyline(Polyline newPolyline) {
    final existingPolyline = _polylines[newPolyline.polylineId];
    if (existingPolyline == null) return true;

    // Only update if points changed significantly
    return !_arePolylinesSimilar(existingPolyline.points, newPolyline.points);
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

  /// Add or update a single polyline
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
    final polyline = Polyline(
      polylineId: id,
      points: points,
      color: color ?? const Color.fromARGB(255, 10, 179, 83),
      width: width ?? 4,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
    );

    batchUpdatePolylines([PolylineUpdate.add(polyline)]);
  }

  /// Animate polyline drawing point by point
  void _animatePolylineDrawing(
    PolylineId id,
    List<LatLng> fullRoute,
    Color? color,
    int? width,
  ) {
    int currentIndex = 0;
    const int pointsPerFrame =
        5; // Draw 5 points per frame for smooth animation

    _animationTimers[id] =
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (currentIndex >= fullRoute.length) {
        timer.cancel();
        _animationTimers.remove(id);
        return;
      }

      final endIndex =
          (currentIndex + pointsPerFrame).clamp(0, fullRoute.length);
      final currentPoints = fullRoute.sublist(0, endIndex);

      final polyline = Polyline(
        polylineId: id,
        points: currentPoints,
        color: color ?? const Color.fromARGB(255, 10, 179, 83),
        width: width ?? 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      );

      batchUpdatePolylines([PolylineUpdate.update(polyline)]);
      currentIndex = endIndex;
    });
  }

  /// Remove a polyline
  void removePolyline(PolylineId id) {
    // Cancel any animation
    _animationTimers[id]?.cancel();
    _animationTimers.remove(id);

    final existingPolyline = _polylines[id];
    if (existingPolyline != null) {
      batchUpdatePolylines([PolylineUpdate.remove(existingPolyline)]);
    }
  }

  /// Clear all polylines
  void clearAllPolylines() {
    // Cancel all animations
    for (final timer in _animationTimers.values) {
      timer.cancel();
    }
    _animationTimers.clear();

    if (_polylines.isNotEmpty) {
      final polylinesToRemove = _polylines.values
          .map((polyline) => PolylineUpdate.remove(polyline))
          .toList();
      batchUpdatePolylines(polylinesToRemove);
    }
  }

  /// Get polyline by ID
  Polyline? getPolyline(PolylineId id) => _polylines[id];

  /// Check if polyline exists
  bool hasPolyline(PolylineId id) => _polylines.containsKey(id);

  /// Get polyline count
  int get polylineCount => _polylines.length;

  /// Notify listeners of changes
  void _notifyChanges() {
    if (_polylinesChanged) {
      _polylinesNotifier.value = Set<Polyline>.of(_polylines.values);
      _polylinesChanged = false;
    }
    onStateChanged?.call();
  }

  /// Force update all notifiers (for initial load)
  void forceUpdate() {
    _polylinesNotifier.value = Set<Polyline>.of(_polylines.values);
    onStateChanged?.call();
  }

  /// Dispose resources
  void dispose() {
    _batchUpdateTimer?.cancel();
    for (final timer in _animationTimers.values) {
      timer.cancel();
    }
    _animationTimers.clear();
    _polylinesNotifier.dispose();
    _polylines.clear();
    _pendingUpdates.clear();
  }
}

/// Polyline update types
enum PolylineUpdateType { add, update, remove }

/// Polyline update operation
class PolylineUpdate {
  final PolylineUpdateType type;
  final Polyline polyline;

  PolylineUpdate._(this.type, this.polyline);

  factory PolylineUpdate.add(Polyline polyline) =>
      PolylineUpdate._(PolylineUpdateType.add, polyline);
  factory PolylineUpdate.update(Polyline polyline) =>
      PolylineUpdate._(PolylineUpdateType.update, polyline);
  factory PolylineUpdate.remove(Polyline polyline) =>
      PolylineUpdate._(PolylineUpdateType.remove, polyline);
}
