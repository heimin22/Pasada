import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Optimized marker manager that implements batch updates and prevents unnecessary recreations
class OptimizedMarkerManager {
  // Persistent marker storage
  final Map<MarkerId, Marker> _markers = {};

  // Change detection
  bool _markersChanged = false;

  // State notifier for reactive updates
  final ValueNotifier<Set<Marker>> _markersNotifier = ValueNotifier({});

  // Batch update queue
  final List<MarkerUpdate> _pendingUpdates = [];
  Timer? _batchUpdateTimer;

  // Callbacks
  Function()? onStateChanged;
  Function(String)? onError;

  OptimizedMarkerManager({
    this.onStateChanged,
    this.onError,
  });

  /// Get markers notifier for reactive updates
  ValueNotifier<Set<Marker>> get markersNotifier => _markersNotifier;

  /// Get current markers
  Set<Marker> get markers => Set<Marker>.of(_markers.values);

  /// Batch update multiple markers at once
  void batchUpdateMarkers(List<MarkerUpdate> updates) {
    _pendingUpdates.addAll(updates);

    // Cancel existing timer
    _batchUpdateTimer?.cancel();

    // Schedule batch update
    _batchUpdateTimer = Timer(const Duration(milliseconds: 16), () {
      _processBatchUpdates();
    });
  }

  /// Process all pending marker updates in a single operation
  void _processBatchUpdates() {
    if (_pendingUpdates.isEmpty) return;

    bool hasChanges = false;

    for (final update in _pendingUpdates) {
      switch (update.type) {
        case MarkerUpdateType.add:
        case MarkerUpdateType.update:
          if (_shouldUpdateMarker(update.marker)) {
            _markers[update.marker.markerId] = update.marker;
            hasChanges = true;
          }
          break;
        case MarkerUpdateType.remove:
          if (_markers.containsKey(update.marker.markerId)) {
            _markers.remove(update.marker.markerId);
            hasChanges = true;
          }
          break;
      }
    }

    _pendingUpdates.clear();

    if (hasChanges) {
      _markersChanged = true;
      _notifyChanges();
    }
  }

  /// Check if marker should be updated (position change threshold)
  bool _shouldUpdateMarker(Marker newMarker) {
    final existingMarker = _markers[newMarker.markerId];
    if (existingMarker == null) return true;

    // Only update if position changed significantly (threshold: ~10 meters)
    const double threshold = 0.0001;
    final positionChanged =
        (existingMarker.position.latitude - newMarker.position.latitude).abs() >
                threshold ||
            (existingMarker.position.longitude - newMarker.position.longitude)
                    .abs() >
                threshold;

    return positionChanged || existingMarker.icon != newMarker.icon;
  }

  /// Add or update a single marker
  void updateMarker(Marker marker) {
    batchUpdateMarkers([MarkerUpdate.add(marker)]);
  }

  /// Remove a marker
  void removeMarker(String id) {
    final markerId = MarkerId(id);
    final existingMarker = _markers[markerId];
    if (existingMarker != null) {
      batchUpdateMarkers([MarkerUpdate.remove(existingMarker)]);
    }
  }

  /// Update marker position only
  void updateMarkerPosition(String id, LatLng newPosition) {
    final markerId = MarkerId(id);
    final existingMarker = _markers[markerId];
    if (existingMarker != null) {
      final updatedMarker = existingMarker.copyWith(positionParam: newPosition);
      batchUpdateMarkers([MarkerUpdate.update(updatedMarker)]);
    }
  }

  /// Update marker icon only
  void updateMarkerIcon(String id, BitmapDescriptor newIcon) {
    final markerId = MarkerId(id);
    final existingMarker = _markers[markerId];
    if (existingMarker != null) {
      final updatedMarker = existingMarker.copyWith(iconParam: newIcon);
      batchUpdateMarkers([MarkerUpdate.update(updatedMarker)]);
    }
  }

  /// Clear all markers
  void clearAllMarkers() {
    if (_markers.isNotEmpty) {
      final markersToRemove =
          _markers.values.map((marker) => MarkerUpdate.remove(marker)).toList();
      batchUpdateMarkers(markersToRemove);
    }
  }

  /// Get marker by ID
  Marker? getMarker(String id) {
    final markerId = MarkerId(id);
    return _markers[markerId];
  }

  /// Check if marker exists
  bool hasMarker(String id) {
    final markerId = MarkerId(id);
    return _markers.containsKey(markerId);
  }

  /// Get marker count
  int get markerCount => _markers.length;

  /// Notify listeners of changes
  void _notifyChanges() {
    if (_markersChanged) {
      _markersNotifier.value = Set<Marker>.of(_markers.values);
      _markersChanged = false;
    }
    onStateChanged?.call();
  }

  /// Force update all notifiers (for initial load)
  void forceUpdate() {
    _markersNotifier.value = Set<Marker>.of(_markers.values);
    onStateChanged?.call();
  }

  /// Dispose resources
  void dispose() {
    _batchUpdateTimer?.cancel();
    _markersNotifier.dispose();
    _markers.clear();
    _pendingUpdates.clear();
  }
}

/// Marker update types
enum MarkerUpdateType { add, update, remove }

/// Marker update operation
class MarkerUpdate {
  final MarkerUpdateType type;
  final Marker marker;

  MarkerUpdate._(this.type, this.marker);

  factory MarkerUpdate.add(Marker marker) =>
      MarkerUpdate._(MarkerUpdateType.add, marker);
  factory MarkerUpdate.update(Marker marker) =>
      MarkerUpdate._(MarkerUpdateType.update, marker);
  factory MarkerUpdate.remove(Marker marker) =>
      MarkerUpdate._(MarkerUpdateType.remove, marker);
}
