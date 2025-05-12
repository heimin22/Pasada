import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  final String baseUrl;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() : baseUrl = dotenv.env['API_URL'] ?? '';

  final supabase = Supabase.instance.client;

  Future<Map<String, String>> _getHeaders() async {
    final token = supabase.auth.currentSession?.accessToken;

    if (token == null) {
      throw ApiException('No access token found');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<T?> get<T>(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      );

      return _handleResponse<T>(response);
    } catch (e) {
      debugPrint('GET request failed: $e');
      return null;
    }
  }

  Future<T?> post<T>(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response);
    } catch (e) {
      debugPrint('POST request failed: $e');
      return null;
    }
  }

  Future<T?> put<T>(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response);
    } catch (e) {
      debugPrint('PUT request failed: $e');
      return null;
    }
  }

  T? _handleResponse<T>(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;

      final jsonResponse = jsonDecode(response.body);
      return jsonResponse as T;
    } else {
      debugPrint('API error: ${response.statusCode} - ${response.body}');
      throw ApiException(
        'Request failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }
}
