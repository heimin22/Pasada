import 'dart:convert';
import '../models/trip.dart';

/// Parses a JSON string into a list of [Trip] objects using a background isolate.
List<Trip> parseTrips(String jsonStr) {
  final List<dynamic> decoded = json.decode(jsonStr);
  return decoded
      .cast<Map<String, dynamic>>()
      .map((m) => Trip.fromJson(m))
      .toList();
}
