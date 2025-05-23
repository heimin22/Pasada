import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'apiService.dart';

class BackendConnectionTest {
  final ApiService _apiService = ApiService();
  final String backendUrl;

  BackendConnectionTest() : backendUrl = dotenv.env['API_URL'] ?? '';

  Future<void> testDirectConnection() async {
    try {
      debugPrint('Attempting to connect to: $backendUrl/health');
      final response = await http.get(Uri.parse('$backendUrl/health'));
      debugPrint('Direct connection test:');
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      // Add status code interpretation
      if (response.statusCode == 502) {
        debugPrint(
            'ERROR: 502 Bad Gateway - The server is likely down or misconfigured');
      } else if (response.statusCode != 200) {
        debugPrint(
            'ERROR: Unexpected status code - Server is responding but with errors');
      }
    } catch (e) {
      if (e is SocketException) {
        debugPrint(
            'Socket error: ${e.message}, address: ${e.address}, port: ${e.port}');
      } else {
        debugPrint('Connection error: $e');
      }
    }
  }

  Future<void> testApiServiceConnection() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>('health');
      debugPrint('ApiService connection test:');
      debugPrint('Response: $response');
    } catch (e) {
      debugPrint('ApiService connection test failed: $e');
    }
  }

  Future<void> runAllTests() async {
    debugPrint('===== BACKEND CONNECTION TESTS =====');
    debugPrint('Testing connection to: $backendUrl');

    await testDirectConnection();
    await testApiServiceConnection();

    debugPrint('===== TESTS COMPLETED =====');
  }
}
