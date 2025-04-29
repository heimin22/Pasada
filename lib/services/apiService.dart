import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (status code: $statusCode)';
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  final String baseUrl;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() : baseUrl = dotenv.env['API_URL'] ?? '';

  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> _getHeaders() async {
    final token = supabase.auth.currentSession?.accessToken;

    if (token == null) {
      throw ApiException('No access token found');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<T> _handleResponse<T>(
    http.Response response, {
    T? Function(Map<String, dynamic>)? parser,
  }) async {
    try {
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (parser != null) {
          return parser(body) as T; // Ensure type safety
        }
        return body as T; // Ensure type safety
      } else {
        throw ApiException(
          body['error'] ?? 'Request failed',
          statusCode: response.statusCode,
          data: body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error parsing response: $e',
          statusCode: response.statusCode);
    }
  }

  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T? Function(Map<String, dynamic>)? parser,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/$endpoint')
          .replace(queryParameters: queryParameters);
      final response = await http.get(
        uri,
        headers: (await _getHeaders())
            .map((key, value) => MapEntry(key, value.toString())),
      );
      return _handleResponse<T>(response, parser: parser);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error making GET request: $e');
    }
  }

  Future<T> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T? Function(Map<String, dynamic>)? parser,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: (await _getHeaders())
            .map((key, value) => MapEntry(key, value.toString())),
        body: jsonEncode(body),
      );
      return _handleResponse<T>(response, parser: parser);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error making POST request: $e');
    }
  }

  Future<T> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T? Function(Map<String, dynamic>)? parser,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: (await _getHeaders())
            .map((key, value) => MapEntry(key, value.toString())),
        body: jsonEncode(body),
      );
      return _handleResponse<T>(response, parser: parser);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error making PUT request: $e');
    }
  }

  Future<T> delete<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T? Function(Map<String, dynamic>)? parser,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: (await _getHeaders())
            .map((key, value) => MapEntry(key, value.toString())),
        body: jsonEncode(body),
      );
      return _handleResponse<T>(response, parser: parser);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error making DELETE request: $e');
    }
  }
}
