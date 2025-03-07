import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class NetworkUtility {
  static Future<String?> fetchUrl(Uri uri,
      {Map<String, String>? headers}) async {
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      debugPrint(e.toString());
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
        final errorMessage = json.decode(response.body)['error']['message'] ?? 'Unknown error';
        debugPrint('POST Request Failed: (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      debugPrint('Error making POST request: $e');
      return null;
    }
    return null;
  }
}
