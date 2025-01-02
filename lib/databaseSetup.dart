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
import 'dart:convert';
import 'package:http/http.dart' as http;

class APIService {
  static const String baseUrl = "http://localhost:3000";

  // health check request
  static Future<bool> checkDatabaseConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if(kDebugMode) {
          print('Verifier: Database connection success');
          print('Timestamp: ${data['timestamp']}');
        }
        return true;
      }
      else {
        if (kDebugMode) {
          print('Verifier: Database connection failed');
        }
        return false;
      }
    }
    catch (e) {
      if (kDebugMode) {
        print('Verifier: Error checking database connection: $e');
      }
      return false;
    }
  }

  // login request
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200){
      return json.decode(response.body);
    } else {
      throw Exception('Failed to login');
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
