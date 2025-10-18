import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/widgets/location_input_container.dart';

/// Location display container for the home screen
class HomeLocationDisplay extends StatelessWidget {
  final bool isRouteSelected;
  final SelectedLocation? selectedPickUpLocation;
  final SelectedLocation? selectedDropOffLocation;
  final double currentFare;
  final double originalFare;
  final String? selectedPaymentMethod;
  final ValueNotifier<String> selectedDiscountSpecification;
  final ValueNotifier<String> seatingPreference;
  final ValueNotifier<String?> selectedIdImageUrl;
  final double screenWidth;
  final double responsivePadding;
  final Function(bool) onNavigateToLocationSearch;
  final VoidCallback onShowSeatingPreferenceDialog;
  final VoidCallback onShowDiscountSelectionDialog;
  final VoidCallback onConfirmBooking;
  final VoidCallback? onFareUpdated;

  const HomeLocationDisplay({
    super.key,
    required this.isRouteSelected,
    required this.selectedPickUpLocation,
    required this.selectedDropOffLocation,
    required this.currentFare,
    required this.originalFare,
    required this.selectedPaymentMethod,
    required this.selectedDiscountSpecification,
    required this.seatingPreference,
    required this.selectedIdImageUrl,
    required this.screenWidth,
    required this.responsivePadding,
    required this.onNavigateToLocationSearch,
    required this.onShowSeatingPreferenceDialog,
    required this.onShowDiscountSelectionDialog,
    required this.onConfirmBooking,
    this.onFareUpdated,
  });

  /// Splits location address into primary and secondary parts
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
    final isSmallScreen = screenWidth < 400;
    final containerPadding =
        isSmallScreen ? responsivePadding * 1.2 : responsivePadding * 1.4;
    final borderRadius =
        isSmallScreen ? screenWidth * 0.03 : screenWidth * 0.04;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: isSmallScreen ? screenWidth * 0.02 : screenWidth * 0.03,
            spreadRadius:
                isSmallScreen ? screenWidth * 0.003 : screenWidth * 0.005,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          LocationInputContainer.showBottomSheet(
            context: context,
            isRouteSelected: isRouteSelected,
            selectedPickUpLocation: selectedPickUpLocation,
            selectedDropOffLocation: selectedDropOffLocation,
            currentFare: currentFare,
            originalFare: originalFare,
            selectedPaymentMethod: selectedPaymentMethod,
            selectedDiscountSpecification: selectedDiscountSpecification,
            seatingPreference: seatingPreference,
            selectedIdImageUrl: selectedIdImageUrl,
            onNavigateToLocationSearch: onNavigateToLocationSearch,
            onShowSeatingPreferenceDialog: onShowSeatingPreferenceDialog,
            onShowDiscountSelectionDialog: onShowDiscountSelectionDialog,
            onConfirmBooking: onConfirmBooking,
            onFareUpdated: onFareUpdated,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row with Total Fare and Arrow
            if (isRouteSelected) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Fare: ",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFF121212),
                    ),
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ValueListenableBuilder<String>(
                            valueListenable: selectedDiscountSpecification,
                            builder: (context, discount, _) {
                              if (discount.isNotEmpty && discount != 'None') {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "₱${originalFare.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500,
                                        fontSize: isSmallScreen ? 12 : 14,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 1 : 2),
                                    Text(
                                      "₱${currentFare.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w700,
                                        fontSize: isSmallScreen ? 14 : 16,
                                        color: Color(0xFF00CC58),
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 1 : 2),
                                    Text(
                                      "20% Discount",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: isSmallScreen ? 10 : 12,
                                        color: Color(0xFF00CC58),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return Text(
                                  "₱${currentFare.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: Color(0xFF00CC58),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_up,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF121212),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                  height:
                      isSmallScreen ? screenWidth * 0.04 : screenWidth * 0.06),
            ] else ...[
              // Just the arrow when no route is selected
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.keyboard_arrow_up,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFF5F5F5)
                        : const Color(0xFF121212),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
            ],

            // Pickup Location with Icon
            Row(
              children: [
                SvgPicture.asset(
                  'assets/svg/pinpickup.svg',
                  height: isSmallScreen ? 12 : 15,
                  width: isSmallScreen ? 12 : 15,
                ),
                SizedBox(
                    width: isSmallScreen
                        ? screenWidth * 0.02
                        : screenWidth * 0.03),
                Expanded(
                  child: selectedPickUpLocation != null
                      ? _buildLocationDisplay(
                          selectedPickUpLocation!.address, context)
                      : Text(
                          'Pick-up location',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w700,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFF5F5F5)
                                    : const Color(0xFF121212),
                          ),
                        ),
                ),
              ],
            ),

            // Divider and Drop-off Location
            if (selectedDropOffLocation != null) ...[
              Padding(
                padding:
                    EdgeInsets.symmetric(vertical: isSmallScreen ? 6.0 : 8.0),
                child: Divider(),
              ),

              // Drop-off Location with Icon
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/svg/pindropoff.svg',
                    height: isSmallScreen ? 12 : 15,
                    width: isSmallScreen ? 12 : 15,
                  ),
                  SizedBox(
                      width: isSmallScreen
                          ? screenWidth * 0.02
                          : screenWidth * 0.03),
                  Expanded(
                    child: _buildLocationDisplay(
                        selectedDropOffLocation!.address, context),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDisplay(String address, BuildContext context) {
    final locationParts = _splitLocation(address);
    final isSmallScreen = screenWidth < 400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          locationParts[0],
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFF5F5F5)
                : const Color(0xFF121212),
          ),
        ),
        if (locationParts[1].isNotEmpty)
          Text(
            locationParts[1],
            maxLines: 1,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFAAAAAA)
                  : const Color(0xFF515151),
            ),
          ),
      ],
    );
  }
}
