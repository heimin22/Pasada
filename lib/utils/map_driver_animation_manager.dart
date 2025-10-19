import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Manages smooth animation of driver marker movement
class MapDriverAnimationManager {
  // Animation state
  LatLng? _currentPosition;
  LatLng? _targetPosition;
  Timer? _animationTimer;
  bool _isAnimating = false;

  // Animation settings
  static const Duration _animationDuration = Duration(milliseconds: 1000);
  static const int _animationSteps = 20;

  // Driver marker properties
  BitmapDescriptor? _busIcon;
  final Map<MarkerId, Marker> _markers = {};

  // Callbacks
  Function()? onStateChanged;
  Function(String)? onError;

  MapDriverAnimationManager({
    this.onStateChanged,
    this.onError,
  });

  /// Initialize the bus icon
  Future<void> initializeBusIcon() async {
    try {
      _busIcon = await BitmapDescriptor.asset(
        ImageConfiguration(size: Size(48, 48)),
        'assets/png/bus.png',
      );
    } catch (e) {
      onError?.call('Failed to load bus icon: ${e.toString()}');
    }
  }

  /// Update driver position with smooth animation
  void updateDriverPosition(LatLng newPosition, {bool animate = true}) {
    if (_busIcon == null) {
      onError?.call('Bus icon not initialized');
      return;
    }

    // If not animating, just update position immediately
    if (!animate || _isAnimating) {
      _setDriverMarker(newPosition);
      return;
    }

    // Start smooth animation to new position
    _targetPosition = newPosition;
    _currentPosition ??= newPosition;

    if (_currentPosition!.latitude == newPosition.latitude &&
        _currentPosition!.longitude == newPosition.longitude) {
      return; // Already at target position
    }

    _startAnimation();
  }

  /// Start smooth animation between current and target position
  void _startAnimation() {
    if (_currentPosition == null || _targetPosition == null) return;

    _isAnimating = true;
    int step = 0;
    final double startLat = _currentPosition!.latitude;
    final double startLng = _currentPosition!.longitude;
    final double deltaLat = _targetPosition!.latitude - startLat;
    final double deltaLng = _targetPosition!.longitude - startLng;

    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(
      Duration(
          milliseconds: _animationDuration.inMilliseconds ~/ _animationSteps),
      (timer) {
        step++;
        final double progress = step / _animationSteps;

        // Use easing function for smooth animation
        final double easedProgress = _easeInOutCubic(progress);

        final double currentLat = startLat + (deltaLat * easedProgress);
        final double currentLng = startLng + (deltaLng * easedProgress);

        _currentPosition = LatLng(currentLat, currentLng);
        _setDriverMarker(_currentPosition!);

        if (step >= _animationSteps) {
          _currentPosition = _targetPosition;
          _setDriverMarker(_currentPosition!);
          _isAnimating = false;
          timer.cancel();
        }
      },
    );
  }

  /// Easing function for smooth animation
  double _easeInOutCubic(double t) {
    return t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
  }

  /// Set driver marker at specific position
  void _setDriverMarker(LatLng position) {
    final driverMarkerId = MarkerId('driver');
    _markers[driverMarkerId] = Marker(
      markerId: driverMarkerId,
      position: position,
      icon: _busIcon!,
      anchor: const Offset(0.5, 0.5),
    );

    onStateChanged?.call();
  }

  /// Get current driver marker
  Marker? get driverMarker => _markers[MarkerId('driver')];

  /// Get all markers
  Set<Marker> get allMarkers => Set<Marker>.of(_markers.values);

  /// Check if animation is in progress
  bool get isAnimating => _isAnimating;

  /// Get current driver position
  LatLng? get currentPosition => _currentPosition;

  /// Get target position
  LatLng? get targetPosition => _targetPosition;

  /// Stop current animation
  void stopAnimation() {
    _animationTimer?.cancel();
    _isAnimating = false;
    if (_targetPosition != null) {
      _currentPosition = _targetPosition;
      _setDriverMarker(_currentPosition!);
    }
  }

  /// Force update to specific position without animation
  void forceUpdatePosition(LatLng position) {
    stopAnimation();
    _currentPosition = position;
    _targetPosition = position;
    _setDriverMarker(position);
  }

  /// Check if bus icon is loaded
  bool get isBusIconLoaded => _busIcon != null;

  /// Dispose resources
  void dispose() {
    _animationTimer?.cancel();
    _markers.clear();
  }
}
