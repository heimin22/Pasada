import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/services/id_camera_service.dart';
import 'package:pasada_passenger_app/widgets/discount_loading_screen.dart';

class DiscountSelectionDialog {
  /// Shows the discount selection dialog as a modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required ValueNotifier<String> selectedDiscountSpecification,
    required ValueNotifier<String?> selectedIdImageUrl,
    // Optional parameters to automatically reopen main bottom sheet after discount is applied
    bool? isRouteSelected,
    SelectedLocation? selectedPickUpLocation,
    SelectedLocation? selectedDropOffLocation,
    double? currentFare,
    double? originalFare,
    String? selectedPaymentMethod,
    ValueNotifier<String>? seatingPreference,
    Function(bool)? onNavigateToLocationSearch,
    VoidCallback? onShowSeatingPreferenceDialog,
    VoidCallback? onShowDiscountSelectionDialog,
    VoidCallback? onConfirmBooking,
    Function? onReopenMainBottomSheet,
    VoidCallback? onFareUpdated, // New callback for fare update
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
                                selectedIdImageUrl.value = null;
                                // Immediately update fare when discount is cleared
                                onFareUpdated?.call();
                                Navigator.of(context).pop();
                                return;
                              }

                              // For other discounts, capture and upload ID image first
                              Navigator.of(context)
                                  .pop(); // Close current dialog

                              final uploadedImageUrl =
                                  await IdCameraService.captureAndUploadIdImage(
                                context: context,
                                passengerType: discountType,
                              );
                              if (uploadedImageUrl != null) {
                                // Update discount values
                                selectedDiscountSpecification.value =
                                    discountType;
                                selectedIdImageUrl.value = uploadedImageUrl;

                                // Immediately update fare after discount is applied
                                onFareUpdated?.call();

                                // Show loading screen as a dialog
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return DiscountLoadingScreen(
                                          discountType: discountType);
                                    },
                                  );
                                }

                                // Simulate processing time and then show the updated bottom sheet
                                if (onReopenMainBottomSheet != null) {
                                  // Show loading for 2 seconds
                                  await Future.delayed(
                                      const Duration(seconds: 2));

                                  // Close loading screen and reopen bottom sheet with discount
                                  if (context.mounted) {
                                    Navigator.of(context)
                                        .pop(); // Close loading dialog

                                    // Small delay to ensure smooth transition
                                    await Future.delayed(
                                        const Duration(milliseconds: 300));

                                    // Reopen the main bottom sheet with updated discount
                                    onReopenMainBottomSheet();
                                  }
                                }
                              }
                              // If image capture fails or is cancelled, don't update discount
                            },
                            child: DiscountOptionTile(
                              option: option,
                              isSelected: isSelected,
                              isDarkMode: isDarkMode,
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
}

class DiscountOptionTile extends StatelessWidget {
  final Map<String, String> option;
  final bool isSelected;
  final bool isDarkMode;

  const DiscountOptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF00CC58).withAlpha(10)
            : (isDarkMode ? const Color(0xFF2A2A2A) : Colors.white),
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
                : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                if (option['description']!.isNotEmpty) ...[
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
    );
  }
}
