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

  // table creation for the local database
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

  // saves or updates the booking details locally
  Future<void> saveBookingDetails(BookingDetails details) async {
    try {
      final db = await database;
      await db?.insert(
        tableName,
        details.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Saved booking ${details.bookingId} to local DB');
    } catch (e) {
      debugPrint('Error saving booking ${details.bookingId} locally: $e');
    }
  }

  // retrieves booking details from the local database
  Future<BookingDetails?> getBookingDetails(int bookingId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'booking_id = ?',
        whereArgs: [bookingId],
      );

      if (maps.isNotEmpty) {
        debugPrint("Retrieved booking $bookingId from local DB.");
        return BookingDetails.fromMap(maps.first);
      }
      debugPrint("Booking $bookingId not found in local DB.");
      return null;
    } catch (e) {
      debugPrint('Error retrieving booking $bookingId locally: $e');
      return null;
    }
  }

  // updates the status ng local booking record
  Future<void> updateLocalBookingStatus(int bookingId, String newStatus) async {
    try {
      final db = await database;
      int count = await db.update(
        tableName,
        {'ride_status': newStatus},
        where: 'booking_id = ?',
        whereArgs: [bookingId],
      );
      if (count > 0) {
        debugPrint('Updated status for local booking $bookingId to $newStatus.');
      }
      else {
        debugPrint("Local booking $bookingId not found for status update.");
      }
    } catch (e) {
      debugPrint("Error updating status for local booking $bookingId: $e");
    }
  }


}