import 'package:postgres/postgres.dart';
import 'package:flutter/foundation.dart';
import 'package:pasada_passenger_app/main.dart';
import 'package:pasada_passenger_app/createAccountCred.dart';
import 'package:pasada_passenger_app/activityScreen.dart';
import 'package:pasada_passenger_app/createAccount.dart';
import 'package:pasada_passenger_app/homeScreen.dart';
import 'package:pasada_passenger_app/loginAccount.dart';
import 'package:pasada_passenger_app/notificationScreen.dart';
import 'package:pasada_passenger_app/profileSettingsScreen.dart';
import 'package:pasada_passenger_app/settingsScreen.dart';
import 'package:postgres/postgres.dart';

class DatabaseService {
  Future<bool> connectToDatabase() async {
    try{
      // initializing postgreSQL connection
      var connection = await Connection.open(
        Endpoint(
          host: 'aws-0-ap-southeast-1.pooler.supabase.com',
          port: 5432,
          database: 'postgres',
          username: 'postgres.otbwhitwrmnfqgpmnjvf',
          password: 'FrierenTheSlayerCAFE',
        ),
      );

      if (!connection.isOpen) {
        if (kDebugMode) print('Connection failed: Database is not open.');
        return false;
      }
      if (kDebugMode) print('Database connected successfully!');
      return true;
    }
    catch (e) {
      if (kDebugMode) print('Error connecting to the database: $e');
      return false;
    }
  }
}
