import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/widgets/loading_dialog.dart';
import 'package:pasada_passenger_app/managers/booking_manager.dart';
import 'package:pasada_passenger_app/widgets/onboarding_dialog.dart';
import 'package:pasada_passenger_app/services/notificationService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to handle HomeScreen initialization, onboarding, and rush-hour dialogs
class HomeScreenInitService {
  static Future<void> runInitialization({
    required BuildContext context,
    required bool Function() getIsInitialized,
    required VoidCallback setIsInitialized,
    required bool Function() getHasOnboardingBeenCalled,
    required VoidCallback setHasOnboardingBeenCalled,
    required bool Function() getIsRushHourDialogShown,
    required VoidCallback setRushHourDialogShown,
    required BookingManager bookingManager,
    required bool Function() getIsBookingConfirmed,
    required VoidCallback measureContainers,
    required VoidCallback loadLocation,
    required VoidCallback loadPaymentMethod,
    required VoidCallback loadRoute,
  }) async {
    // Double-check authentication before proceeding with home screen initialization
    final supabaseAuth = Supabase.instance.client.auth;
    final session = supabaseAuth.currentSession;

    if (session == null) {
      debugPrint('User not authenticated, skipping home screen initialization');
      return;
    }

    final shouldReinitialize = PageStorage.of(context).readState(
          context,
          identifier: const ValueKey('homeInitialized'),
        ) ==
        false;

    if (!getIsInitialized() || shouldReinitialize) {
      LoadingDialog.show(context, message: 'Initializing resources...');
      try {
        await InitializationService.initialize(context);
        setIsInitialized();
        PageStorage.of(context).writeState(
          context,
          true,
          identifier: const ValueKey('homeInitialized'),
        );
      } catch (e) {
        debugPrint('Initialization error: $e');
        // Don't mark as initialized if there was an error
        return;
      } finally {
        if (context.mounted) {
          LoadingDialog.hide(context);
        }
      }
    }

    if (getHasOnboardingBeenCalled()) return;
    setHasOnboardingBeenCalled();

    await bookingManager.loadActiveBooking();

    if (getIsBookingConfirmed()) {
      measureContainers();
      return;
    }

    loadLocation();
    loadPaymentMethod();
    loadRoute();
    measureContainers();

    await showOnboardingDialog(context);
    NotificationService.showAvailabilityNotification();
  }

  // Rush hour dialog logic moved to HomeScreenPageState._initializeHomeScreen
}
