import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/widgets/home_location_display.dart';
import 'package:pasada_passenger_app/widgets/notification_container.dart';

/// Bottom section containing notification and location display
class HomeBottomSection extends StatelessWidget {
  final AnimationController bookingAnimationController;
  final Animation<double> downwardAnimation;
  final bool isNotificationVisible;
  final double notificationHeight;
  final VoidCallback onNotificationClose;
  final VoidCallback onMeasureContainers;
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

  const HomeBottomSection({
    super.key,
    required this.bookingAnimationController,
    required this.downwardAnimation,
    required this.isNotificationVisible,
    required this.notificationHeight,
    required this.onNotificationClose,
    required this.onMeasureContainers,
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bookingAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, downwardAnimation.value),
          child: Opacity(
            opacity: 1 - bookingAnimationController.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNotificationVisible)
                  NotificationContainer(
                    downwardAnimation: downwardAnimation,
                    notificationHeight: notificationHeight,
                    onClose: () {
                      onNotificationClose();
                      onMeasureContainers();
                    },
                  ),
                const SizedBox(height: 10),
                HomeLocationDisplay(
                  isRouteSelected: isRouteSelected,
                  selectedPickUpLocation: selectedPickUpLocation,
                  selectedDropOffLocation: selectedDropOffLocation,
                  currentFare: currentFare,
                  originalFare: originalFare,
                  selectedPaymentMethod: selectedPaymentMethod,
                  selectedDiscountSpecification: selectedDiscountSpecification,
                  seatingPreference: seatingPreference,
                  selectedIdImageUrl: selectedIdImageUrl,
                  screenWidth: screenWidth,
                  responsivePadding: responsivePadding,
                  onNavigateToLocationSearch: onNavigateToLocationSearch,
                  onShowSeatingPreferenceDialog: onShowSeatingPreferenceDialog,
                  onShowDiscountSelectionDialog: onShowDiscountSelectionDialog,
                  onConfirmBooking: onConfirmBooking,
                  onFareUpdated: onFareUpdated,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
