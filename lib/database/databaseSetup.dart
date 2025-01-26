import 'package:postgres/postgres.dart';
import 'package:flutter/foundation.dart';
import 'package:pasada_passenger_app/home/main.dart';
import 'package:pasada_passenger_app/authenticationAccounts/createAccountCred.dart';
import 'package:pasada_passenger_app/home/activityScreen.dart';
import 'package:pasada_passenger_app/authenticationAccounts/createAccount.dart';
import 'package:pasada_passenger_app/home/homeScreen.dart';
import 'package:pasada_passenger_app/authenticationAccounts/loginAccount.dart';
import 'package:pasada_passenger_app/home/notificationScreen.dart';
import 'package:pasada_passenger_app/home/profileSettingsScreen.dart';
import 'package:pasada_passenger_app/home/settingsScreen.dart';
import 'package:postgres/postgres.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  // initialize supabase client
  final supabase = Supabase.instance.client;

  // check database connection
  Future<bool> checkDatabaseConnection() async {
    try {
      // test database connection: query table
      final response = await supabase
          .from('sampleAccount') // table name
          .select()
          .limit(1);

      // if response is successful but no data, return true
      if (response.isEmpty) {
        if (kDebugMode) print('Database connection successful: No data found');
        return true;
      }
      // if response is successful, return true
      if (kDebugMode) print('Database connection successful');
      return true;
    }
    catch (e) {
      if (kDebugMode) print('Error connecting to the database: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    try {
      final response = await supabase
          .from('sampleAccount')
          .select();

      return response;
    }
    catch (e) {
      if (kDebugMode) print('Error inserting data: $e');
      throw Exception('Failed to insert data');
    }
  }
}

// class DatabaseService {
//   Future<bool> connectToDatabase() async {
//     try{
//       // initializing postgreSQL connection
//       var connection = await Connection.open(
//         Endpoint(
//           host: 'aws-0-ap-southeast-1.pooler.supabase.com',
//           port: 5432,
//           database: 'postgres',
//           username: 'postgres.otbwhitwrmnfqgpmnjvf',
//           password: 'FrierenTheSlayerCAFE',
//         ),
//       );
//
//       if (!connection.isOpen) {
//         if (kDebugMode) print('Connection failed: Database is not open.');
//         return false;
//       }
//       if (kDebugMode) print('Database connected successfully!');
//       return true;
//     }
//     catch (e) {
//       if (kDebugMode) print('Error connecting to the database: $e');
//       return false;
//     }
//   }
// }
