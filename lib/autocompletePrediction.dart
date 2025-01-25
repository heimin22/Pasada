import 'package:flutter_google_maps_webservices/places.dart';

class AutocompletePrediction {
  // ito yung human-readable name ng returned result. pwepwede ring business name ng establishment
  late final String? description;

  // [structuredFormatting] pre-formatted text na lalabas sa results
  late final StructuredFormatting? structuredFormatting;

  // unique textual identifier ng place pass yung ID sa Places ID para maretrieve yung lugar
  late final String? placeID;

  // reference
  late final String? reference;

  AutocompletePrediction({
    this.description,
    this.structuredFormatting,
    this.placeID,
    this.reference,
  });

  factory AutocompletePrediction.fromJson(Map<String, dynamic> json) {
    return AutocompletePrediction(
      description: json['description'] as String?,
      placeID: json['place_id'] as String?,
      reference: json['reference'] as String?,
      structuredFormatting: json['structured_formatting'] != null
        ? StructuredFormatting.fromJson(json['structured_formatting']) : null,
    );
  }
}

class StructuredFormatting {
  // mainText yung nagcocontain ng text ng prediction, name na rin ng place
  final String? mainText;
  // secondaryText yung nagcocontain ng secondary text ng prediction, additional info ng place ganun
  final String? secondaryText;

  StructuredFormatting({this.mainText, this.secondaryText});

  factory StructuredFormatting.fromJson(Map<String, dynamic> json) {
    return StructuredFormatting(
      mainText: json['main_text'] as String?,
      secondaryText: json['secondary_text'] as String,
    );
  }
}
