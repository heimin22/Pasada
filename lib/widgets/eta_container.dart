import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/eta_service.dart';
import '../utils/memory_manager.dart';

class EtaContainer extends StatefulWidget {
  final LatLng? destination;
  final LatLng?
      currentLocation; // Allow passing current location to avoid fetching

  const EtaContainer({
    super.key,
    required this.destination,
    this.currentLocation,
  });

  @override
  _EtaContainerState createState() => _EtaContainerState();
}

class _EtaContainerState extends State<EtaContainer> {
  String? _etaText;
  bool _isLoading = true;
  bool _isUpdating = false; // Separate loading state for updates
  Timer? _timer;
  LatLng? _cachedLocation;
  LatLng? _lastEtaLocation;

  // Distance threshold for ETA updates (100 meters)
  static const double _ETA_UPDATE_THRESHOLD = 100.0;

  @override
  void initState() {
    super.initState();
    _initializeEta();
    // Reduce timer frequency and use smart updates
    _timer =
        Timer.periodic(const Duration(minutes: 2), (_) => _smartUpdateEta());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Fast initialization with cached data
  Future<void> _initializeEta() async {
    final dest = widget.destination;
    if (dest == null) {
      setState(() {
        _etaText = null;
        _isLoading = false;
      });
      return;
    }

    try {
      // Try to get location from multiple sources (fastest first)
      LatLng? location = await _getFastLocation();

      if (location != null) {
        await _calculateEta(location, dest, isInitial: true);
      } else {
        setState(() {
          _etaText = 'Location unavailable';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('EtaContainer _initializeEta error: $e');
      setState(() {
        _etaText = null;
        _isLoading = false;
      });
    }
  }

  // Smart ETA update that only recalculates when necessary
  Future<void> _smartUpdateEta() async {
    final dest = widget.destination;
    if (dest == null) return;

    try {
      setState(() => _isUpdating = true);

      LatLng? location = await _getFastLocation();
      if (location == null) return;

      // Check if we need to update ETA based on distance moved
      if (_shouldUpdateEta(location)) {
        await _calculateEta(location, dest, isInitial: false);
      }
    } catch (e) {
      debugPrint('EtaContainer _smartUpdateEta error: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  // Get location from fastest available source
  Future<LatLng?> _getFastLocation() async {
    // Priority 1: Use passed current location
    if (widget.currentLocation != null) {
      _cachedLocation = widget.currentLocation;
      return widget.currentLocation;
    }

    // Priority 2: Use cached location
    if (_cachedLocation != null) {
      return _cachedLocation;
    }

    // Priority 3: Try to get from shared preferences (fastest)
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('last_latitude');
      final lng = prefs.getDouble('last_longitude');
      if (lat != null && lng != null) {
        _cachedLocation = LatLng(lat, lng);
        return _cachedLocation;
      }
    } catch (e) {
      debugPrint('Failed to get cached location: $e');
    }

    // Priority 4: Get fresh location (slowest)
    try {
      final locationService = Location();
      final locData = await locationService.getLocation();
      if (locData.latitude != null && locData.longitude != null) {
        _cachedLocation = LatLng(locData.latitude!, locData.longitude!);
        return _cachedLocation;
      }
    } catch (e) {
      debugPrint('Failed to get fresh location: $e');
    }

    return null;
  }

  // Check if ETA should be updated based on distance moved
  bool _shouldUpdateEta(LatLng currentLocation) {
    if (_lastEtaLocation == null) return true;

    double distance = _calculateDistance(
      currentLocation.latitude,
      currentLocation.longitude,
      _lastEtaLocation!.latitude,
      _lastEtaLocation!.longitude,
    );

    return distance > _ETA_UPDATE_THRESHOLD;
  }

  // Calculate ETA with caching
  Future<void> _calculateEta(LatLng origin, LatLng destination,
      {required bool isInitial}) async {
    try {
      // Create cache key
      final cacheKey =
          'eta_${origin.latitude.toStringAsFixed(4)}_${origin.longitude.toStringAsFixed(4)}'
          '_${destination.latitude.toStringAsFixed(4)}_${destination.longitude.toStringAsFixed(4)}';

      // Try to get from cache first (valid for 2 minutes)
      final cached = MemoryManager.instance.getFromCache(cacheKey);
      if (cached is Map<String, dynamic> && !isInitial) {
        final cacheTime = cached['timestamp'] as DateTime?;
        if (cacheTime != null &&
            DateTime.now().difference(cacheTime).inMinutes < 2) {
          final seconds = cached['eta_seconds'] as int? ?? 0;
          final arrival = DateTime.now().add(Duration(seconds: seconds));
          final formatted = DateFormat('h:mma').format(arrival);

          setState(() {
            _etaText = 'Arriving at $formatted';
            _isLoading = false;
          });
          return;
        }
      }

      // Make API call
      final features = {
        'origin': {
          'lat': origin.latitude,
          'lng': origin.longitude,
        },
        'destination': {
          'lat': destination.latitude,
          'lng': destination.longitude,
        },
      };

      final resp = await ETAService().getETA(features);
      final seconds = resp['eta_seconds'] as int? ?? 0;
      final arrival = DateTime.now().add(Duration(seconds: seconds));
      final formatted = DateFormat('h:mma').format(arrival);

      // Cache the result
      MemoryManager.instance.addToCache(cacheKey, {
        'eta_seconds': seconds,
        'timestamp': DateTime.now(),
      });

      _lastEtaLocation = origin;

      if (mounted) {
        setState(() {
          _etaText = 'Arriving at $formatted';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('EtaContainer _calculateEta error: $e');
      if (mounted) {
        setState(() {
          _etaText = null;
          _isLoading = false;
        });
      }
    }
  }

  // Calculate distance between two points in meters
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth radius in meters
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 0),
        ],
      ),
      child: _isLoading
          ? const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00CC58),
                ),
              ),
            )
          : Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 24,
                  color: _isUpdating
                      ? const Color(0xFF00CC58).withValues(alpha: 0.6)
                      : const Color(0xFF00CC58),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ETA',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? const Color(0xFFBBBBBB)
                                  : const Color(0xFF515151),
                            ),
                          ),
                          if (_isUpdating) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: isDarkMode
                                    ? const Color(0xFFBBBBBB)
                                    : const Color(0xFF515151),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _etaText ?? 'N/A',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                          color: _isUpdating
                              ? (isDarkMode
                                  ? const Color(0xFFF5F5F5)
                                      .withValues(alpha: 0.7)
                                  : const Color(0xFF121212)
                                      .withValues(alpha: 0.7))
                              : (isDarkMode
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFF121212)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
