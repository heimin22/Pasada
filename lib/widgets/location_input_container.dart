import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/widgets/discount_selection_dialog.dart';
import 'package:pasada_passenger_app/widgets/id_image_container.dart';
import 'package:pasada_passenger_app/widgets/location_row_widget.dart';

class LocationInputContainer extends StatelessWidget {
  final double screenWidth;
  final double responsivePadding;
  final double iconSize;
  final bool isRouteSelected;
  final SelectedLocation? selectedPickUpLocation;
  final SelectedLocation? selectedDropOffLocation;
  final double currentFare;
  final double originalFare;
  final String? selectedPaymentMethod;
  final ValueNotifier<String> selectedDiscountSpecification;
  final ValueNotifier<String> seatingPreference;
  final ValueNotifier<String?> selectedIdImagePath;
  final Function(bool) onNavigateToLocationSearch;
  final VoidCallback onShowSeatingPreferenceDialog;
  final VoidCallback onShowDiscountSelectionDialog;
  final VoidCallback onConfirmBooking;
  final VoidCallback? onFareUpdated; // New callback for fare update

  const LocationInputContainer({
    super.key,
    required this.screenWidth,
    required this.responsivePadding,
    required this.iconSize,
    required this.isRouteSelected,
    this.selectedPickUpLocation,
    this.selectedDropOffLocation,
    required this.currentFare,
    required this.originalFare,
    this.selectedPaymentMethod,
    required this.selectedDiscountSpecification,
    required this.seatingPreference,
    required this.selectedIdImagePath,
    required this.onNavigateToLocationSearch,
    required this.onShowSeatingPreferenceDialog,
    required this.onShowDiscountSelectionDialog,
    required this.onConfirmBooking,
    this.onFareUpdated,
  });

  /// Shows the LocationInputContainer as a modal bottom sheet
  static Future<void> showBottomSheet({
    required BuildContext context,
    required bool isRouteSelected,
    SelectedLocation? selectedPickUpLocation,
    SelectedLocation? selectedDropOffLocation,
    required double currentFare,
    required double originalFare,
    String? selectedPaymentMethod,
    required ValueNotifier<String> selectedDiscountSpecification,
    required ValueNotifier<String> seatingPreference,
    required ValueNotifier<String?> selectedIdImagePath,
    required Function(bool) onNavigateToLocationSearch,
    required VoidCallback onShowSeatingPreferenceDialog,
    required VoidCallback onShowDiscountSelectionDialog,
    required VoidCallback onConfirmBooking,
    VoidCallback? onFareUpdated,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final responsivePadding = screenWidth * 0.04;
    final iconSize = screenWidth * 0.06;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return LocationInputContainer(
          screenWidth: screenWidth,
          responsivePadding: responsivePadding,
          iconSize: iconSize,
          isRouteSelected: isRouteSelected,
          selectedPickUpLocation: selectedPickUpLocation,
          selectedDropOffLocation: selectedDropOffLocation,
          currentFare: currentFare,
          originalFare: originalFare,
          selectedPaymentMethod: selectedPaymentMethod,
          selectedDiscountSpecification: selectedDiscountSpecification,
          seatingPreference: seatingPreference,
          selectedIdImagePath: selectedIdImagePath,
          onNavigateToLocationSearch: onNavigateToLocationSearch,
          onShowSeatingPreferenceDialog: onShowSeatingPreferenceDialog,
          onShowDiscountSelectionDialog: onShowDiscountSelectionDialog,
          onConfirmBooking: onConfirmBooking,
          onFareUpdated: onFareUpdated,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String svgAssetPickup = 'assets/svg/pinpickup.svg';
    String svgAssetDropOff = 'assets/svg/pindropoff.svg';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bottom sheet drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Main content with padding
          Padding(
            padding: EdgeInsets.all(responsivePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LocationRowWidget(
                  svgAsset: svgAssetPickup,
                  location: selectedPickUpLocation,
                  isPickup: true,
                  iconSize: iconSize,
                  enabled: isRouteSelected,
                  screenWidth: screenWidth,
                  currentFare: currentFare,
                  originalFare: originalFare,
                  selectedDiscountSpecification: selectedDiscountSpecification,
                  onNavigateToLocationSearch: onNavigateToLocationSearch,
                ),
                const Divider(),
                LocationRowWidget(
                  svgAsset: svgAssetDropOff,
                  location: selectedDropOffLocation,
                  isPickup: false,
                  iconSize: iconSize,
                  enabled: isRouteSelected,
                  screenWidth: screenWidth,
                  currentFare: currentFare,
                  originalFare: originalFare,
                  selectedDiscountSpecification: selectedDiscountSpecification,
                  onNavigateToLocationSearch: onNavigateToLocationSearch,
                ),
                SizedBox(height: 27),
                if (isRouteSelected)
                  DiscountSelectionButton(
                    selectedDiscountSpecification:
                        selectedDiscountSpecification,
                    selectedIdImagePath: selectedIdImagePath,
                    isRouteSelected: isRouteSelected,
                    selectedPickUpLocation: selectedPickUpLocation,
                    selectedDropOffLocation: selectedDropOffLocation,
                    currentFare: currentFare,
                    originalFare: originalFare,
                    selectedPaymentMethod: selectedPaymentMethod,
                    seatingPreference: seatingPreference,
                    onNavigateToLocationSearch: onNavigateToLocationSearch,
                    onShowSeatingPreferenceDialog:
                        onShowSeatingPreferenceDialog,
                    onShowDiscountSelectionDialog:
                        onShowDiscountSelectionDialog,
                    onConfirmBooking: onConfirmBooking,
                    onFareUpdated: onFareUpdated,
                    isDarkMode: isDarkMode,
                  ),
                // ID Image Display Container
                ValueListenableBuilder<String?>(
                  valueListenable: selectedIdImagePath,
                  builder: (context, imagePath, _) {
                    if (imagePath != null && imagePath.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IdImageContainer(
                          imagePath: imagePath,
                          selectedDiscountSpecification:
                              selectedDiscountSpecification,
                          selectedIdImagePath: selectedIdImagePath,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                if (isRouteSelected)
                  SeatingPreferenceButton(
                    seatingPreference: seatingPreference,
                    onShowSeatingPreferenceDialog:
                        onShowSeatingPreferenceDialog,
                    isRouteSelected: isRouteSelected,
                    isDarkMode: isDarkMode,
                  ),
                // Payment method is always Cash, no need for selection button
                SizedBox(height: screenWidth * 0.05),
                ConfirmBookingButton(
                  selectedPickUpLocation: selectedPickUpLocation,
                  selectedDropOffLocation: selectedDropOffLocation,
                  selectedPaymentMethod: selectedPaymentMethod,
                  isRouteSelected: isRouteSelected,
                  onConfirmBooking: onConfirmBooking,
                ),
                // Add some bottom padding for the bottom sheet
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DiscountSelectionButton extends StatelessWidget {
  final ValueNotifier<String> selectedDiscountSpecification;
  final ValueNotifier<String?> selectedIdImagePath;
  final bool isRouteSelected;
  final SelectedLocation? selectedPickUpLocation;
  final SelectedLocation? selectedDropOffLocation;
  final double currentFare;
  final double originalFare;
  final String? selectedPaymentMethod;
  final ValueNotifier<String> seatingPreference;
  final Function(bool) onNavigateToLocationSearch;
  final VoidCallback onShowSeatingPreferenceDialog;
  final VoidCallback onShowDiscountSelectionDialog;
  final VoidCallback onConfirmBooking;
  final VoidCallback? onFareUpdated;
  final bool isDarkMode;

  const DiscountSelectionButton({
    super.key,
    required this.selectedDiscountSpecification,
    required this.selectedIdImagePath,
    required this.isRouteSelected,
    required this.selectedPickUpLocation,
    required this.selectedDropOffLocation,
    required this.currentFare,
    required this.originalFare,
    required this.selectedPaymentMethod,
    required this.seatingPreference,
    required this.onNavigateToLocationSearch,
    required this.onShowSeatingPreferenceDialog,
    required this.onShowDiscountSelectionDialog,
    required this.onConfirmBooking,
    this.onFareUpdated,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          await DiscountSelectionDialog.show(
            context: context,
            selectedDiscountSpecification: selectedDiscountSpecification,
            selectedIdImagePath: selectedIdImagePath,
            onFareUpdated: onFareUpdated,
            onReopenMainBottomSheet: () {
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
                selectedIdImagePath: selectedIdImagePath,
                onNavigateToLocationSearch: onNavigateToLocationSearch,
                onShowSeatingPreferenceDialog: onShowSeatingPreferenceDialog,
                onShowDiscountSelectionDialog: onShowDiscountSelectionDialog,
                onConfirmBooking: onConfirmBooking,
              );
            },
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_offer,
                  size: 24,
                  color: const Color(0xFF00CC58),
                ),
                const SizedBox(width: 12),
                Text(
                  'Discount:',
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
                  valueListenable: selectedDiscountSpecification,
                  builder: (context, discount, _) => Text(
                    discount.isEmpty ? 'None' : discount,
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
    );
  }
}

class SeatingPreferenceButton extends StatelessWidget {
  final ValueNotifier<String> seatingPreference;
  final VoidCallback onShowSeatingPreferenceDialog;
  final bool isRouteSelected;
  final bool isDarkMode;

  const SeatingPreferenceButton({
    super.key,
    required this.seatingPreference,
    required this.onShowSeatingPreferenceDialog,
    required this.isRouteSelected,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}

class ConfirmBookingButton extends StatelessWidget {
  final SelectedLocation? selectedPickUpLocation;
  final SelectedLocation? selectedDropOffLocation;
  final String? selectedPaymentMethod;
  final bool isRouteSelected;
  final VoidCallback onConfirmBooking;

  const ConfirmBookingButton({
    super.key,
    required this.selectedPickUpLocation,
    required this.selectedDropOffLocation,
    required this.selectedPaymentMethod,
    required this.isRouteSelected,
    required this.onConfirmBooking,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (selectedPickUpLocation != null &&
                selectedDropOffLocation != null &&
                selectedPaymentMethod != null &&
                isRouteSelected)
            ? () {
                // Close the bottom sheet first
                Navigator.of(context).pop();
                // Then trigger the booking
                onConfirmBooking();
              }
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
    );
  }
}
