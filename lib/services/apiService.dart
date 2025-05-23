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

  ApiService._internal() : baseUrl = dotenv.env['API_URL'] ?? '' {
    debugPrint('API URL configured as: $baseUrl');
    if (baseUrl.isEmpty) {
      debugPrint('WARNING: API_URL is empty in .env file');
    }
  }

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

    // Debug helper to show the full response structure
    _debugPrintResponseStructure(responseBody);

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
        errorMessage =
            errorJson['message'] ?? errorJson['error'] ?? 'Unknown error';
      } catch (_) {
        errorMessage = responseBody;
      }

      throw ApiException(errorMessage, statusCode: statusCode);
    }
  }

  // Helper to print the full response structure for debugging
  void _debugPrintResponseStructure(String responseBody) {
    try {
      if (responseBody.isEmpty) {
        debugPrint('API DEBUG: Empty response body');
        return;
      }

      final data = jsonDecode(responseBody);
      debugPrint('API DEBUG: Response structure:');

      if (data is Map) {
        data.forEach((key, value) {
          debugPrint('  $key: ${_formatValue(value)}');

          if (value is Map) {
            value.forEach((subKey, subValue) {
              debugPrint('    $subKey: ${_formatValue(subValue)}');
            });
          } else if (value is List && value.isNotEmpty) {
            debugPrint('    [List with ${value.length} items]');
            if (value.first is Map) {
              final firstItem = value.first as Map;
              debugPrint('    First item keys: ${firstItem.keys.toList()}');
              firstItem.forEach((itemKey, itemValue) {
                debugPrint('      $itemKey: ${_formatValue(itemValue)}');
              });
            } else {
              debugPrint('    First item: ${_formatValue(value.first)}');
            }
          }
        });
      } else if (data is List) {
        debugPrint('  [List with ${data.length} items]');
        if (data.isNotEmpty) {
          if (data.first is Map) {
            final firstItem = data.first as Map;
            debugPrint('  First item keys: ${firstItem.keys.toList()}');
          } else {
            debugPrint('  First item: ${data.first}');
          }
        }
      } else {
        debugPrint('  Raw data: $data');
      }
    } catch (e) {
      debugPrint('API DEBUG: Error parsing response JSON: $e');
    }
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    if (value is Map) return '{Map with ${value.length} entries}';
    if (value is List) return '[List with ${value.length} items]';
    return value.toString();
  }
}
