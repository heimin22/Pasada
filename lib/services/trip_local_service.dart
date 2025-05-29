import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/trip.dart';

class TripLocalService {
  static Database? _db;
  static const String _dbName = 'passenger_data.db';
  static const int _dbVersion = 1;
  static const String tripsTable = 'trips';
  static const String journalTable = 'sync_journal';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tripsTable (
        id TEXT PRIMARY KEY,
        status TEXT,
        origin_address TEXT,
        destination_address TEXT,
        fare REAL,
        driver_id TEXT,
        passenger_id TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $journalTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT,
        item_id TEXT,
        action TEXT,
        data TEXT,
        timestamp INTEGER
      )
    ''');
  }

  Future<void> cacheTrips(List<Trip> trips) async {
    final db = await database;
    final batch = db.batch();
    for (var trip in trips) {
      batch.insert(
        tripsTable,
        {
          'id': trip.id,
          'status': trip.status,
          'origin_address': trip.originAddress,
          'destination_address': trip.destinationAddress,
          'fare': trip.fare,
          'driver_id': trip.driverId,
          'passenger_id': trip.passengerId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Trip>> getCachedTrips() async {
    final db = await database;
    final maps = await db.query(tripsTable);
    return maps
        .map((m) => Trip.fromJson({
              'booking_id': m['id'],
              'ride_status': m['status'],
              'pickup_address': m['origin_address'],
              'dropoff_address': m['destination_address'],
              'fare': m['fare'],
              'driver_id': m['driver_id'],
              'passenger_id': m['passenger_id'],
            }))
        .toList();
  }

  Future<void> recordLocalChange(
      String itemId, String action, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      journalTable,
      {
        'table_name': tripsTable,
        'item_id': itemId,
        'action': action,
        'data': json.encode(data),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getPendingChanges() async {
    final db = await database;
    return await db.query(journalTable, orderBy: 'timestamp ASC');
  }

  Future<void> clearAppliedChanges(List<int> ids) async {
    final db = await database;
    await db.delete(journalTable, where: 'id IN (${ids.join(',')})');
  }
}
