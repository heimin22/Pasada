import 'package:http/http.dart' as http;
import 'dart:convert';

class ETAService {
  // to be placed with a server soon
  final String baseUrl = 'http://192.168.1.10:5000';

  Future<Map<String, dynamic>> getETAWithGemini(
      Map<String, dynamic> features) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict_eta_with_gemini'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(features),
      );
    } catch (e) {
      throw Exception('Error: $e');
    }

    return {};
  }
}
