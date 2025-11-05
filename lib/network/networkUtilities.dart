import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pasada_passenger_app/utils/app_logger.dart';

class NetworkUtility {
  /// Perform a GET and return the raw response, regardless of status code.
  /// If [timeout] is provided, applies a client-side timeout.
  static Future<http.Response?> getRaw(
    Uri uri, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final future = http.get(uri, headers: headers);
      final response =
          timeout != null ? await future.timeout(timeout) : await future;
      return response;
    } on TimeoutException {
      AppLogger.warn('GET Request Timeout (raw) for $uri',
          tag: 'NetworkUtility');
      return null;
    } catch (e) {
      AppLogger.error('Error making raw GET request to $uri: $e',
          tag: 'NetworkUtility');
      return null;
    }
  }

  static Future<String?> fetchUrl(Uri uri,
      {Map<String, String>? headers}) async {
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Log non-200 status codes with response body if available
        String errorBody = '';
        try {
          errorBody = response.body.isNotEmpty
              ? response.body.substring(
                  0, response.body.length > 200 ? 200 : response.body.length)
              : 'Empty response body';
        } catch (_) {
          errorBody = 'Unable to read response body';
        }
        AppLogger.error(
            'GET Request Failed: ${response.statusCode} for $uri\nResponse: $errorBody',
            tag: 'NetworkUtility');
      }
    } catch (e) {
      AppLogger.error('Error making GET request to $uri: $e',
          tag: 'NetworkUtility');
    }
    return null;
  }

  /// Fetches a URL with a client-side timeout. Throws [TimeoutException] on timeout.
  static Future<String?> fetchUrlWithTimeout(
    Uri uri, {
    Map<String, String>? headers,
    required Duration timeout,
  }) async {
    try {
      final response = await http.get(uri, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Log non-200 status codes with response body if available
        String errorBody = '';
        try {
          errorBody = response.body.isNotEmpty
              ? response.body.substring(
                  0, response.body.length > 200 ? 200 : response.body.length)
              : 'Empty response body';
        } catch (_) {
          errorBody = 'Unable to read response body';
        }
        AppLogger.error(
            'GET Request Failed: ${response.statusCode} for $uri\nResponse: $errorBody',
            tag: 'NetworkUtility');
      }
    } on TimeoutException {
      AppLogger.warn('GET Request Timeout after ${timeout.inSeconds}s for $uri',
          tag: 'NetworkUtility');
      // Re-throw to allow callers to distinguish timeouts
      rethrow;
    } catch (e) {
      AppLogger.error('Error making GET request to $uri: $e',
          tag: 'NetworkUtility');
    }
    return null;
  }

  static Future<String?> postUrl(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // captures API error message
        final errorMessage =
            json.decode(response.body)['error']['message'] ?? 'Unknown error';
        AppLogger.error(
            'POST Request Failed: (${response.statusCode}): $errorMessage',
            tag: 'NetworkUtility');
      }
    } catch (e) {
      AppLogger.error('Error making POST request: $e', tag: 'NetworkUtility');
      return null;
    }
    return null;
  }
}
