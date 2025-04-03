import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'geospatialService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// enum para sa clarity ng driver status
enum DriverStatus { online, idle, offline }

class DriverService {
  final SupabaseClient supabaseClient = Supabase.instance.client;
  final GeospatialService geospatialService = GeospatialService();


}