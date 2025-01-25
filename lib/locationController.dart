import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_google_maps_webservices/src/places.dart';
import 'locationService.dart';

class LocationController extends GetxController{
  Placemark pickPlacemark = Placemark();
  Placemark get pickedPlacemark => pickPlacemark;

  List<Prediction> predictionList = [];

  Future<List<Prediction>> searchLocation(BuildContext context, String text) async {
    if(text != null && text.isNotEmpty) {
      http.Response response = await getLocationData(text);
      var data = jsonDecode(response.body.toString());
      if (kDebugMode) print('Status: ' + data['status']);
      if (data['status'] == 'OK') {
        predictionList = [];
        data['predictions'].forEach((prediction) => predictionList.add(Prediction.fromJson(prediction)));
      }
      else {
        // ApiChecker.checkApi(response);
      }
    }
    return predictionList;
  }
}