List<String> splitLocation(String location) {
  final parts = location.split(',');
  if (parts.length < 2) {
    return [location, ''];
  }
  return [parts[0], parts.sublist(1).join(', ')];
}

double calculateBottomPadding({
  required bool isBookingConfirmed,
  required double bookingStatusContainerHeight,
  required double locationInputContainerHeight,
  required bool isNotificationVisible,
  required double notificationHeight,
}) {
  double mainHeight = isBookingConfirmed
      ? bookingStatusContainerHeight
      : locationInputContainerHeight +
          (isNotificationVisible && locationInputContainerHeight == 0
              ? notificationHeight + 10.0
              : 0);

  // Responsive spacing: only add extra padding when dialog exists
  // When dialog is empty (height == 0), use minimal padding for Google Maps logo only
  final double googleMapsUIPadding = locationInputContainerHeight > 0
      ? 60.0 // Extra spacing when dialog is visible (for logo + FAB clearance)
      : 50.0; // Minimal spacing when dialog is empty (for logo only)

  return mainHeight + 10.0 + googleMapsUIPadding;
}

double calculateMapPadding({
  required bool isBookingConfirmed,
  required double bookingStatusContainerHeight,
  required double locationInputContainerHeight,
  required bool isNotificationVisible,
  required double notificationHeight,
}) {
  // Calculate base offset for location dialog
  double offset = isBookingConfirmed
      ? bookingStatusContainerHeight
      : locationInputContainerHeight +
          (isNotificationVisible && locationInputContainerHeight == 0
              ? notificationHeight + 10.0
              : 0);

  // Responsive padding: only add extra padding when dialog exists
  // When dialog is empty (height == 0), use minimal padding for Google Maps logo only
  // Google Maps logo is ~48px, so we add padding to keep it visible
  final double googleMapsUIPadding = locationInputContainerHeight > 0
      ? 70.0 // Extra spacing when dialog is visible (for logo + FAB clearance)
      : 50.0; // Minimal spacing when dialog is empty (for logo only)

  return offset + 10.0 + googleMapsUIPadding;
}
