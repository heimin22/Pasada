import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/widgets/bottom_sheet_skeleton.dart';
import 'package:pasada_passenger_app/widgets/location_input_container.dart';

/// A wrapper widget that can show loading state in the bottom sheet
class LoadingBottomSheet extends StatefulWidget {
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
  final ValueNotifier<String?> selectedIdImageUrl;
  final Function(bool) onNavigateToLocationSearch;
  final VoidCallback onShowSeatingPreferenceDialog;
  final VoidCallback onShowDiscountSelectionDialog;
  final VoidCallback onConfirmBooking;
  final VoidCallback? onFareUpdated;

  const LoadingBottomSheet({
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
    required this.selectedIdImageUrl,
    required this.onNavigateToLocationSearch,
    required this.onShowSeatingPreferenceDialog,
    required this.onShowDiscountSelectionDialog,
    required this.onConfirmBooking,
    this.onFareUpdated,
  });

  /// Show the loading bottom sheet with ability to toggle loading state
  static Future<LoadingBottomSheetState?> showLoadingBottomSheet({
    required BuildContext context,
    required bool isRouteSelected,
    SelectedLocation? selectedPickUpLocation,
    SelectedLocation? selectedDropOffLocation,
    required double currentFare,
    required double originalFare,
    String? selectedPaymentMethod,
    required ValueNotifier<String> selectedDiscountSpecification,
    required ValueNotifier<String> seatingPreference,
    required ValueNotifier<String?> selectedIdImageUrl,
    required Function(bool) onNavigateToLocationSearch,
    required VoidCallback onShowSeatingPreferenceDialog,
    required VoidCallback onShowDiscountSelectionDialog,
    required VoidCallback onConfirmBooking,
    VoidCallback? onFareUpdated,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final responsivePadding = screenWidth * 0.04;
    final iconSize = screenWidth * 0.06;

    return showModalBottomSheet<LoadingBottomSheetState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return LoadingBottomSheet(
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
          selectedIdImageUrl: selectedIdImageUrl,
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
  State<LoadingBottomSheet> createState() => LoadingBottomSheetState();
}

class LoadingBottomSheetState extends State<LoadingBottomSheet> {
  bool _isLoading = false;

  /// Show skeleton loading state
  void showLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  /// Hide skeleton loading state
  void hideLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return BottomSheetSkeleton(
        screenWidth: widget.screenWidth,
        responsivePadding: widget.responsivePadding,
        iconSize: widget.iconSize,
      );
    }

    return LocationInputContainer(
      screenWidth: widget.screenWidth,
      responsivePadding: widget.responsivePadding,
      iconSize: widget.iconSize,
      isRouteSelected: widget.isRouteSelected,
      selectedPickUpLocation: widget.selectedPickUpLocation,
      selectedDropOffLocation: widget.selectedDropOffLocation,
      currentFare: widget.currentFare,
      originalFare: widget.originalFare,
      selectedPaymentMethod: widget.selectedPaymentMethod,
      selectedDiscountSpecification: widget.selectedDiscountSpecification,
      seatingPreference: widget.seatingPreference,
      selectedIdImageUrl: widget.selectedIdImageUrl,
      onNavigateToLocationSearch: widget.onNavigateToLocationSearch,
      onShowSeatingPreferenceDialog: widget.onShowSeatingPreferenceDialog,
      onShowDiscountSelectionDialog: widget.onShowDiscountSelectionDialog,
      onConfirmBooking: widget.onConfirmBooking,
      onFareUpdated: widget.onFareUpdated,
    );
  }
}
