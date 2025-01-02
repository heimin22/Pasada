import 'package:flutter/foundation.dart';
import 'package:pasada_passenger_app/databaseSetup.dart';

void main() async {
  var dbService = DatabaseService();
  bool isConnected = await dbService.connectToDatabase();

  if (kDebugMode) {
    print(isConnected
      ? 'Verifier: The database connection is confirmed as successful.'
      : 'Verifier: Failed to connect to the database.');
  }
}
