import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocalDatabaseService {
  static Database? database;
  static const String dbName = 'passenger_bookings.db';
  static const String tableName = 'bookings';

  Future<Database> get BookingDatabase async {
    if (database != null) return database!;
    database = await initDatabase();
    return database!;
  }

  Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: onCreate,
    );
  }

  Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        booking_id INTEGER PRIMARY KEY,
        driver_id INTEGER NOT NULL,
        route_id INTEGER NOT NULL,
        ride_status TEXT NOT NULL CHECK(ride_status IN ('searching', 'assigned', 'in_progress', 'completed', 'cancelled', 'no_driver')),
        pickup_address TEXT NOT NULL,
        pickup_lat REAL NOT NULL,
        pickup_lng REAL NOT NULL,
        dropoff_address TEXT NOT NULL,
        dropoff_lat REAL NOT NULL,
        dropoff_lng REAL NOT NULL,
        start_time TEXT NOT NULL,
        created_at TEXT NOT NULL,
        fare REAL NOT NULL,
        assigned_at TEXT NOT NULL,
        end_time TEXT NOT NULL,
        passenger_id TEXT NOT NULL
      )
    ''');
    debugPrint("Local SQLite table '$tableName' created.");
  }
}