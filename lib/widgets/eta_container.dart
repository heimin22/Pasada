import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import '../services/eta_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class EtaContainer extends StatefulWidget {
  final LatLng? destination;
  const EtaContainer({
    super.key,
    required this.destination,
  });

  @override
  _EtaContainerState createState() => _EtaContainerState();
}

class _EtaContainerState extends State<EtaContainer> {
  String? _etaText;
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateEta();
    _timer = Timer.periodic(const Duration(minutes: 2), (_) => _updateEta());
  }

  Future<void> _updateEta() async {
    final dest = widget.destination;
    if (dest == null) {
      setState(() {
        _etaText = null;
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    debugPrint('EtaContainer _updateEta: destination = $dest');
    try {
      // Ensure location services and permissions
      final locationService = Location();
      bool serviceEnabled = await locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await locationService.requestService();
        if (!serviceEnabled) {
          throw Exception('Location services disabled');
        }
      }
      var permissionStatus = await locationService.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        permissionStatus = await locationService.requestPermission();
        if (permissionStatus != PermissionStatus.granted) {
          throw Exception('Location permission denied');
        }
      }
      final locData = await locationService.getLocation();
      final features = {
        'origin': {
          'lat': locData.latitude,
          'lng': locData.longitude,
        },
        'destination': {
          'lat': dest.latitude,
          'lng': dest.longitude,
        },
      };
      debugPrint('EtaContainer _updateEta: features = $features');
      final resp = await ETAService().getETA(features);
      debugPrint('EtaContainer _updateEta: resp = $resp');
      final seconds = resp['eta_seconds'] as int? ?? 0;
      final arrival = DateTime.now().add(Duration(seconds: seconds));
      final formatted = DateFormat('h:mma').format(arrival);
      setState(() {
        _etaText = 'Arriving at $formatted';
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('EtaContainer _updateEta error: $e');
      debugPrint('$st');
      setState(() {
        _etaText = null;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
                const Icon(
                  Icons.access_time,
                  size: 24,
                  color: Color(0xFF00CC58),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 4),
                    Text(
                      _etaText ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF121212),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
