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
}