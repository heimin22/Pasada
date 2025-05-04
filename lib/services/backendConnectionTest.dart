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
      final response = await http.get(Uri.parse('$backendUrl/health'));
      debugPrint('Direct connection test:');
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
    } catch (e) {
      debugPrint('Direct connection test failed: $e');
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
