import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'locationController.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_maps_webservices/places.dart';

class LocationSearchDialog extends StatelessWidget {
  final GoogleMapController? mapController;

  const LocationSearchDialog({
    Key? key,
    required this.mapController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    final suggestionsController = SuggestionsController();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Positioned(
      top: screenHeight * 0.02, // 2% from the top of the screen
      left: screenWidth * 0.05, // 5% padding from the left
      right: screenWidth * 0.05, // 5% padding from the right
      child: Material(
        borderRadius: BorderRadius.circular(24),
        elevation: 3,
        child: Container(
          height: screenHeight * 0.06,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
          ),
          child: TypeAheadField(
            suggestionsController: suggestionsController,
            builder: (context, searchController, focusNode) {
              return Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                          hintText: 'Search for pick-up location',
                          border: InputBorder.none,
                          hintStyle: const TextStyle(
                            color: Color(0xFFA2A2A2),
                          )),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              );
            },
            suggestionsCallback: (pattern) async {
              return await Get.find<LocationController>()
                  .searchLocation(context, pattern);
            },
            itemBuilder: (context, suggestion) {
              final Prediction pred = suggestion as Prediction;
              return Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    const Icon(Icons.location_on),
                    Expanded(
                      child: Text(
                        pred.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            },
            onSelected: (suggestion) {
              final Prediction pred = suggestion as Prediction;
              if (kDebugMode) print('Selected location: ${pred.description!}');
              Get.back();
            },
            decorationBuilder: (context, child) {
              return Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: Color(0xFFF5F5F5),
                child: child,
              );
            },
            hideOnUnfocus: true,
            hideOnSelect: true,
            offset: const Offset(0, 8),
          ),
        ),
      ),
    );
  }
}
