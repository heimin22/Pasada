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

  Future<T?> get<T>(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/$endpoint').replace(
        queryParameters: queryParams,
      );

      debugPrint('GET request to: $uri');
      final response = await http.get(uri, headers: headers);

      return _handleResponse<T>(response);
    } catch (e) {
      debugPrint('GET request failed: $e');
      rethrow; // Rethrow to allow proper error handling upstream
    }
  }

  Future<T?> post<T>(String endpoint,
      {Map<String, dynamic>? body, Map<String, String>? queryParams}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/$endpoint').replace(
        queryParameters: queryParams,
      );

      debugPrint('POST request to: $uri with body: $body');
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response);
    } catch (e) {
      debugPrint('POST request failed: $e');
      rethrow; // Rethrow to allow proper error handling upstream
    }
  }

  Future<T?> put<T>(String endpoint,
      {Map<String, dynamic>? body, Map<String, String>? queryParams}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/$endpoint').replace(
        queryParameters: queryParams,
      );

      debugPrint('PUT request to: $uri with body: $body');
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response);
    } catch (e) {
      debugPrint('PUT request failed: $e');
      rethrow; // Rethrow to allow proper error handling upstream
    }
  }

  T? _handleResponse<T>(http.Response response) {
    final statusCode = response.statusCode;
    final responseBody = response.body;

    debugPrint('Response status: $statusCode, body: $responseBody');

    if (statusCode >= 200 && statusCode < 300) {
      if (responseBody.isEmpty) return null;

      try {
        final jsonResponse = jsonDecode(responseBody);
        return jsonResponse as T;
      } catch (e) {
        debugPrint('Error parsing response: $e');
        throw ApiException('Invalid response format', statusCode: statusCode);
      }
    } else {
      String errorMessage;
      try {
        final errorJson = jsonDecode(responseBody);
        errorMessage = errorJson['message'] ?? 'Unknown error';
      } catch (_) {
        errorMessage = responseBody;
      }

      throw ApiException(errorMessage, statusCode: statusCode);
    }
  }
}
