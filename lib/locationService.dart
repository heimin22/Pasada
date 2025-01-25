import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

Future<http.Response> getLocationData(String text) async {
  http.Response response;

  response = await http.get(
    Uri.parse('http://mvs.bslmeiyu.com/api/v1/config/place-api-autocomplete?search_text=$text'),
    headers: {'Content-Type': 'application/json'},
  );

  if (kDebugMode) print(jsonDecode(response.body));
  return response;
}