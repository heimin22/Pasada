import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/screens/paymentMethodScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationInputContainer extends StatelessWidget {
  final BuildContext parentContext;
  final double screenWidth;
  final double responsivePadding;
  final double iconSize;
  final bool isRouteSelected;
  final SelectedLocation? selectedPickUpLocation;
  final SelectedLocation? selectedDropOffLocation;
  final String etaText;
  final double currentFare;
  final String? selectedPaymentMethod;
  final ValueNotifier<String> seatingPreference;
  final Function(bool) onNavigateToLocationSearch;
  final VoidCallback onShowSeatingPreferenceDialog;
  final VoidCallback onConfirmBooking;
  // Callback to update payment method in parent
  final Function(String) onPaymentMethodSelected;

  const LocationInputContainer({
    super.key,
    required this.parentContext,
    required this.screenWidth,
    required this.responsivePadding,
    required this.iconSize,
    required this.isRouteSelected,
    this.selectedPickUpLocation,
    this.selectedDropOffLocation,
    required this.etaText,
    required this.currentFare,
    this.selectedPaymentMethod,
    required this.seatingPreference,
    required this.onNavigateToLocationSearch,
    required this.onShowSeatingPreferenceDialog,
    required this.onConfirmBooking,
    required this.onPaymentMethodSelected,
  });

  List<String> _splitLocation(String location) {
    final List<String> parts = location.split(',');
    if (parts.length < 2) {
      return [location, ''];
    }
    return [parts[0], parts.sublist(1).join(', ')];
  }

  Widget _buildLocationRow(
    BuildContext context,
    String svgAsset,
    SelectedLocation? location,
    bool isPickup,
    double iconSize, {
    required bool enabled,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    List<String> locationParts =
        location != null ? _splitLocation(location.address) : ['', ''];
    // Use the passed iconSize for SVG, adjust specific icon size if needed
    double displayIconSize = isPickup ? 15 : 15;

    return InkWell(
      onTap: enabled ? () => onNavigateToLocationSearch(isPickup) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPickup) ...[
            Row(
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
                Text(
                  "₱${currentFare.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: enabled ? const Color(0xFF00CC58) : Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ETA: ",
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
                Text(
                  etaText != '--' ? etaText : 'Calculating...',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: enabled
                        ? (isDarkMode
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF515151))
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.08)
          ],
          Row(
            children: [
              SvgPicture.asset(
                svgAsset,
                height: displayIconSize, // Use modified displayIconSize
                width: displayIconSize, // Use modified displayIconSize
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
                          : (isPickup
                              ? 'Pick-up location'
                              : 'Drop-off location'),
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String svgAssetPickup = 'assets/svg/pinpickup.svg';
    String svgAssetDropOff = 'assets/svg/pindropoff.svg';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(responsivePadding),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: screenWidth * 0.03,
            spreadRadius: screenWidth * 0.005,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLocationRow(
            context,
            svgAssetPickup,
            selectedPickUpLocation,
            true,
            iconSize, // Pass original iconSize here
            enabled: isRouteSelected,
          ),
          const Divider(),
          _buildLocationRow(
            context,
            svgAssetDropOff,
            selectedDropOffLocation,
            false,
            iconSize, // Pass original iconSize here
            enabled: isRouteSelected,
          ),
          SizedBox(height: 27),
          if (isRouteSelected)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: onShowSeatingPreferenceDialog,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event_seat,
                          size: 24,
                          color: const Color(0xFF00CC58),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Preference:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isRouteSelected
                                ? (isDarkMode
                                    ? const Color(0xFFF5F5F5)
                                    : const Color(0xFF121212))
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        ValueListenableBuilder<String>(
                          valueListenable: seatingPreference,
                          builder: (context, preference, _) => Text(
                            preference,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isRouteSelected
                                  ? (isDarkMode
                                      ? const Color(0xFFF5F5F5)
                                      : const Color(0xFF121212))
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: isRouteSelected
                              ? (isDarkMode
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFF121212))
                              : Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          InkWell(
            onTap: (isRouteSelected &&
                    selectedPickUpLocation != null &&
                    selectedDropOffLocation != null)
                ? () async {
                    final result = await Navigator.push<String>(
                      parentContext, // Use parentContext for navigation
                      MaterialPageRoute(
                        builder: (context) => PaymentMethodScreen(
                          currentSelection: selectedPaymentMethod,
                          fare: currentFare,
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                    if (result != null) {
                      onPaymentMethodSelected(result); // Use callback
                    }
                  }
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.payment,
                      size: 24,
                      color: const Color(0xFF00CC58),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      selectedPaymentMethod ?? 'Select Payment Method',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: (isRouteSelected &&
                                selectedPickUpLocation != null &&
                                selectedDropOffLocation != null)
                            ? (isDarkMode
                                ? const Color(0xFFF5F5F5)
                                : const Color(0xFF121212))
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: (isRouteSelected &&
                          selectedPickUpLocation != null &&
                          selectedDropOffLocation != null)
                      ? (isDarkMode
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFF121212))
                      : Colors.grey,
                ),
              ],
            ),
          ),
          SizedBox(height: screenWidth * 0.05),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (selectedPickUpLocation != null &&
                      selectedDropOffLocation != null &&
                      selectedPaymentMethod != null &&
                      isRouteSelected)
                  ? onConfirmBooking
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00CC58),
                disabledBackgroundColor: const Color(0xFFD3D3D3),
                foregroundColor: const Color(0xFFF5F5F5),
                disabledForegroundColor: const Color(0xFFF5F5F5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Confirm Booking',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
