import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/location/selectedLocation.dart';
import 'package:pasada_passenger_app/widgets/responsive_dialogs.dart';

class MapDialogManager {
  final BuildContext context;
  bool errorDialogVisible = false;

  MapDialogManager(this.context);

  /// Show a generic alert dialog
  void showAlertDialog(String title, String content,
      {VoidCallback? onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: title,
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  /// Show a generic error dialog
  void showError(String message) {
    showAlertDialog('Error', message);
  }

  /// Show location service error dialog
  void showLocationErrorDialog({VoidCallback? onRetry}) {
    if (errorDialogVisible) return;
    errorDialogVisible = true;

    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Location Error',
        content: const Text('Enable location services to continue.'),
        actions: [
          TextButton(
            onPressed: () {
              errorDialogVisible = false;
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              errorDialogVisible = false;
              Navigator.pop(context);
              onRetry?.call();
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  /// Show location permission dialog
  void showLocationPermissionDialog({VoidCallback? onOpenSettings}) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Permission Required',
        content: const Text(
            'Enable location permissions in device settings to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (onOpenSettings != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOpenSettings();
              },
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
  }

  /// App-styled pre-prompt BEFORE asking OS for location permission
  Future<bool> showPrePromptLocationPermission() async {
    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResponsiveDialog(
        title: 'Location Access',
        content: const Text(
            'We need location access to show nearby buses and calculate routes to your destination.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  /// App-styled pre-prompt BEFORE enabling device location services
  Future<bool> showPrePromptLocationService() async {
    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResponsiveDialog(
        title: 'Enable Location Services',
        content: const Text(
            'Turn on device location services to enable accurate pickup and route suggestions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  /// Show pickup distance warning dialog
  Future<bool> showPickupDistanceWarning(
    LatLng pickupLocation,
    LatLng currentLocation,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final selectedLoc = SelectedLocation("", pickupLocation);
    final distance = selectedLoc.distanceFrom(currentLocation);

    if (distance <= 1.0) return true; // No warning needed

    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => ResponsiveDialog(
        title: 'Distance warning',
        content: Text(
          'The selected pick-up location is quite far from your current location. Do you want to continue?',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            fontSize: 14,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF067837),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    return proceed ?? false;
  }

  /// Show network connection error dialog
  void showNetworkError({VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Connection Error',
        content: const Text(
            'No internet connection. Please check your network and try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Show confirmation dialog
  Future<bool> showConfirmationDialog({
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: title,
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show loading dialog
  void showLoadingDialog({String message = 'Loading...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResponsiveDialog(
        title: 'Please wait',
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
        actions: [], // No actions for loading dialog
      ),
    );
  }

  /// Hide any current dialog
  void hideDialog() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Show route generation error
  void showRouteGenerationError({VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Route Error',
        content: const Text(
            'Could not generate route between selected locations. Please try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Show location selection required dialog
  void showLocationSelectionRequired() {
    showError('Please select both pickup and dropoff locations first.');
  }

  /// Reset error dialog state
  void resetErrorDialogState() {
    errorDialogVisible = false;
  }
}
