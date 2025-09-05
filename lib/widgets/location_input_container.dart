import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/screens/paymentMethodScreen.dart';
import 'package:pasada_passenger_app/services/id_camera_service.dart';

class LocationInputContainer extends StatelessWidget {
  final double screenWidth;
  final double responsivePadding;
  final double iconSize;
  final bool isRouteSelected;
  final SelectedLocation? selectedPickUpLocation;
  final SelectedLocation? selectedDropOffLocation;
  final double currentFare;
  final String? selectedPaymentMethod;
  final ValueNotifier<String> selectedDiscountSpecification;
  final ValueNotifier<String> seatingPreference;
  final ValueNotifier<String?> selectedIdImagePath;
  final Function(bool) onNavigateToLocationSearch;
  final VoidCallback onShowSeatingPreferenceDialog;
  final VoidCallback onShowDiscountSelectionDialog;
  final VoidCallback onConfirmBooking;
  // Callback to update payment method in parent
  final Function(String) onPaymentMethodSelected;

  const LocationInputContainer({
    super.key,
    required this.screenWidth,
    required this.responsivePadding,
    required this.iconSize,
    required this.isRouteSelected,
    this.selectedPickUpLocation,
    this.selectedDropOffLocation,
    required this.currentFare,
    this.selectedPaymentMethod,
    required this.selectedDiscountSpecification,
    required this.seatingPreference,
    required this.selectedIdImagePath,
    required this.onNavigateToLocationSearch,
    required this.onShowSeatingPreferenceDialog,
    required this.onShowDiscountSelectionDialog,
    required this.onConfirmBooking,
    required this.onPaymentMethodSelected,
  });

  /// Shows the LocationInputContainer as a modal bottom sheet
  static Future<void> showBottomSheet({
    required BuildContext context,
    required bool isRouteSelected,
    SelectedLocation? selectedPickUpLocation,
    SelectedLocation? selectedDropOffLocation,
    required double currentFare,
    String? selectedPaymentMethod,
    required ValueNotifier<String> selectedDiscountSpecification,
    required ValueNotifier<String> seatingPreference,
    required ValueNotifier<String?> selectedIdImagePath,
    required Function(bool) onNavigateToLocationSearch,
    required VoidCallback onShowSeatingPreferenceDialog,
    required VoidCallback onShowDiscountSelectionDialog,
    required VoidCallback onConfirmBooking,
    required Function(String) onPaymentMethodSelected,
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
          selectedPaymentMethod: selectedPaymentMethod,
          selectedDiscountSpecification: selectedDiscountSpecification,
          seatingPreference: seatingPreference,
          selectedIdImagePath: selectedIdImagePath,
          onNavigateToLocationSearch: onNavigateToLocationSearch,
          onShowSeatingPreferenceDialog: onShowSeatingPreferenceDialog,
          onShowDiscountSelectionDialog: onShowDiscountSelectionDialog,
          onConfirmBooking: onConfirmBooking,
          onPaymentMethodSelected: onPaymentMethodSelected,
        );
      },
    );
  }

  /// Shows the discount selection dialog as a modal bottom sheet
  static Future<void> showDiscountSelectionDialog({
    required BuildContext context,
    required ValueNotifier<String> selectedDiscountSpecification,
    required ValueNotifier<String?> selectedIdImagePath,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final discountOptions = [
      {'value': '', 'label': 'None', 'description': 'No discount'},
      {'value': 'Student', 'label': 'Student', 'description': '20% discount'},
      {
        'value': 'Senior Citizen',
        'label': 'Senior Citizen',
        'description': '20% discount'
      },
      {'value': 'PWD', 'label': 'PWD', 'description': '20% discount'},
    ];

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color:
                isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
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
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Select Discount Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF121212),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Discount options
                    ...discountOptions.map((option) {
                      return ValueListenableBuilder<String>(
                        valueListenable: selectedDiscountSpecification,
                        builder: (context, currentValue, _) {
                          final isSelected = currentValue == option['value'];
                          return InkWell(
                            onTap: () async {
                              final discountType = option['value']!;

                              // If selecting "None", clear both discount and image
                              if (discountType.isEmpty) {
                                selectedDiscountSpecification.value = '';
                                selectedIdImagePath.value = null;
                                Navigator.of(context).pop();
                                return;
                              }

                              // For other discounts, capture ID image first
                              Navigator.of(context)
                                  .pop(); // Close current dialog

                              final capturedImage =
                                  await IdCameraService.captureIdImage(context);
                              if (capturedImage != null) {
                                selectedDiscountSpecification.value =
                                    discountType;
                                selectedIdImagePath.value = capturedImage.path;
                              }
                              // If image capture fails or is cancelled, don't update discount
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF00CC58).withAlpha(10)
                                    : (isDarkMode
                                        ? const Color(0xFF2A2A2A)
                                        : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF00CC58)
                                      : (isDarkMode
                                          ? const Color(0xFF3A3A3A)
                                          : const Color(0xFFE0E0E0)),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? const Color(0xFF00CC58)
                                        : (isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600]),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option['label']!,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode
                                                ? const Color(0xFFF5F5F5)
                                                : const Color(0xFF121212),
                                          ),
                                        ),
                                        if (option['description']!
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            option['description']!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDarkMode
                                                  ? const Color(0xFFAAAAAA)
                                                  : const Color(0xFF666666),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
              // Add some bottom padding
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  /// Builds the ID image display container
  Widget _buildIdImageContainer(
    BuildContext context,
    String imagePath,
    ValueNotifier<String> selectedDiscountSpecification,
    ValueNotifier<String?> selectedIdImagePath,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00CC58).withAlpha(50),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user,
                color: const Color(0xFF00CC58),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'ID Verification',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: isDarkMode
                      ? const Color(0xFFAAAAAA)
                      : const Color(0xFF666666),
                ),
                onSelected: (value) async {
                  if (value == 'retake') {
                    final newImage =
                        await IdCameraService.captureIdImage(context);
                    if (newImage != null) {
                      selectedIdImagePath.value = newImage.path;
                    }
                  } else if (value == 'remove') {
                    selectedIdImagePath.value = null;
                    selectedDiscountSpecification.value = '';
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'retake',
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt, size: 18),
                        SizedBox(width: 8),
                        Text('Retake Photo'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF3A3A3A)
                    : const Color(0xFFF0F0F0),
              ),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load image',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? const Color(0xFFAAAAAA)
                                : const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: const Color(0xFF00CC58),
                size: 16,
              ),
              const SizedBox(width: 6),
              ValueListenableBuilder<String>(
                valueListenable: selectedDiscountSpecification,
                builder: (context, discount, _) => Text(
                  '$discount ID verified',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF00CC58),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
            SizedBox(height: screenWidth * 0.08),
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
                      onTap: onShowDiscountSelectionDialog,
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
                  ),
                // ID Image Display Container
                ValueListenableBuilder<String?>(
                  valueListenable: selectedIdImagePath,
                  builder: (context, imagePath, _) {
                    if (imagePath != null && imagePath.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildIdImageContainer(
                          context,
                          imagePath,
                          selectedDiscountSpecification,
                          selectedIdImagePath,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
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
                            context, // Use current context for navigation
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
