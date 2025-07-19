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
  return mainHeight + 20.0;
}

double calculateMapPadding({
  required bool isBookingConfirmed,
  required double bookingStatusContainerHeight,
  required double locationInputContainerHeight,
  required bool isNotificationVisible,
  required double notificationHeight,
}) {
  double offset = isBookingConfirmed
      ? bookingStatusContainerHeight
      : locationInputContainerHeight +
          (isNotificationVisible && locationInputContainerHeight == 0
              ? notificationHeight + 10.0
              : 0);
  return offset + 20.0;
}
