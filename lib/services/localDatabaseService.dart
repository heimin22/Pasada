import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocalDatabaseService {
  static Database? database;
  static const String dbName = 'passenger_bookings.db';
  static const String tableName = 'bookings';



}