import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';

class LocationRowWidget extends StatelessWidget {
  final String svgAsset;
  final SelectedLocation? location;
  final bool isPickup;
  final double iconSize;
  final bool enabled;
  final double screenWidth;
  final double currentFare;
  final double originalFare;
  final ValueNotifier<String> selectedDiscountSpecification;
  final Function(bool) onNavigateToLocationSearch;

  const LocationRowWidget({
    super.key,
    required this.svgAsset,
    this.location,
    required this.isPickup,
    required this.iconSize,
    required this.enabled,
    required this.screenWidth,
    required this.currentFare,
    required this.originalFare,
    required this.selectedDiscountSpecification,
    required this.onNavigateToLocationSearch,
  });

  List<String> _splitLocation(String location) {
    // Handle newline-based addresses (e.g., stop selections with "name\naddress")
    if (location.contains('\n')) {
      final lines = location.split('\n');
      final primary = lines[0].trim();
      final remainder = lines.length > 1 ? lines[1] : '';
      final remainderParts = remainder.split(',');
      final city = remainderParts.length >= 2
          ? remainderParts[1].trim()
          : remainderParts[0].trim();
      return [primary, city];
    }
    // Fallback to comma-based splitting
    final parts = location.split(',');
    final primary = parts.isNotEmpty ? parts[0].trim() : location;
    final city = parts.length >= 2 ? parts[1].trim() : '';
    return [primary, city];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    List<String> locationParts =
        location != null ? _splitLocation(location!.address) : ['', ''];
    // Use the passed iconSize for SVG, adjust specific icon size if needed
    double displayIconSize = isPickup ? 15 : 15;

    return InkWell(
      onTap: enabled ? () => onNavigateToLocationSearch(isPickup) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPickup) ...[
            FareDisplaySection(
              enabled: enabled,
              isDarkMode: isDarkMode,
              selectedDiscountSpecification: selectedDiscountSpecification,
              originalFare: originalFare,
              currentFare: currentFare,
            ),
            SizedBox(height: screenWidth * 0.08),
          ],
          LocationInfoRow(
            svgAsset: svgAsset,
            displayIconSize: displayIconSize,
            screenWidth: screenWidth,
            location: location,
            locationParts: locationParts,
            isPickup: isPickup,
            enabled: enabled,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }
}

class FareDisplaySection extends StatelessWidget {
  final bool enabled;
  final bool isDarkMode;
  final ValueNotifier<String> selectedDiscountSpecification;
  final double originalFare;
  final double currentFare;

  const FareDisplaySection({
    super.key,
    required this.enabled,
    required this.isDarkMode,
    required this.selectedDiscountSpecification,
    required this.originalFare,
    required this.currentFare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Total Fare: ",
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: enabled
                ? (isDarkMode
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFF121212))
                : Colors.grey,
          ),
        ),
        FareAmountDisplay(
          selectedDiscountSpecification: selectedDiscountSpecification,
          originalFare: originalFare,
          currentFare: currentFare,
          enabled: enabled,
        ),
      ],
    );
  }
}

class FareAmountDisplay extends StatelessWidget {
  final ValueNotifier<String> selectedDiscountSpecification;
  final double originalFare;
  final double currentFare;
  final bool enabled;

  const FareAmountDisplay({
    super.key,
    required this.selectedDiscountSpecification,
    required this.originalFare,
    required this.currentFare,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ValueListenableBuilder<String>(
          valueListenable: selectedDiscountSpecification,
          builder: (context, discountValue, _) {
            if (discountValue.isNotEmpty && discountValue != 'None') {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₱${originalFare.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: enabled ? Colors.grey : Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        Text(
          "₱${currentFare.toStringAsFixed(2)}",
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: enabled ? const Color(0xFF00CC58) : Colors.grey,
          ),
        ),
        ValueListenableBuilder<String>(
          valueListenable: selectedDiscountSpecification,
          builder: (context, discountValue, _) {
            if (discountValue.isNotEmpty && discountValue != 'None') {
              return Column(
                children: [
                  const SizedBox(height: 2),
                  Text(
                    "20% discount",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: enabled ? const Color(0xFF00CC58) : Colors.grey,
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class LocationInfoRow extends StatelessWidget {
  final String svgAsset;
  final double displayIconSize;
  final double screenWidth;
  final SelectedLocation? location;
  final List<String> locationParts;
  final bool isPickup;
  final bool enabled;
  final bool isDarkMode;

  const LocationInfoRow({
    super.key,
    required this.svgAsset,
    required this.displayIconSize,
    required this.screenWidth,
    required this.location,
    required this.locationParts,
    required this.isPickup,
    required this.enabled,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          svgAsset,
          height: displayIconSize,
          width: displayIconSize,
        ),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                location != null
                    ? locationParts[0]
                    : (isPickup ? 'Pick-up location' : 'Drop-off location'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: enabled
                      ? (isDarkMode
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFF121212))
                      : Colors.grey,
                ),
              ),
              if (locationParts[1].isNotEmpty) ...[
                Text(
                  locationParts[1],
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: enabled
                        ? (isDarkMode
                            ? const Color(0xFFAAAAAA)
                            : const Color(0xFF515151))
                        : Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
