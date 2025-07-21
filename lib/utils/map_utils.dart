import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

double calculateDistanceKm(LatLng a, LatLng b) {
  const R = 6371; // km
  final lat1 = a.latitude * pi / 180;
  final lon1 = a.longitude * pi / 180;
  final lat2 = b.latitude * pi / 180;
  final lon2 = b.longitude * pi / 180;
  final dLat = lat2 - lat1;
  final dLon = lon2 - lon1;
  final h = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  return R * 2 * atan2(sqrt(h), sqrt(1 - h));
}

/// Finds nearest point on a segment
LatLng findNearestPointOnSegment(LatLng p, LatLng s, LatLng e) {
  final x = p.latitude, y = p.longitude;
  final x1 = s.latitude, y1 = s.longitude;
  final x2 = e.latitude, y2 = e.longitude;
  final l2 = (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1);
  if (l2 == 0) return s;
  final t = ((x - x1) * (x2 - x1) + (y - y1) * (y2 - y1)) / l2;
  final tt = t.clamp(0.0, 1.0);
  return LatLng(x1 + tt * (x2 - x1), y1 + tt * (y2 - y1));
}

String formatDuration(int secs) {
  final dt = DateTime.now().add(Duration(seconds: secs));
  return '${dt.hour % 12 == 0 ? 12 : dt.hour % 12}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour < 12 ? 'AM' : 'PM'}';
}
