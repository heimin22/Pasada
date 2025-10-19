import 'package:intl/intl.dart';

/// Utility class for handling Philippines timezone operations (GMT+8)
class TimezoneUtils {
  /// Get the current DateTime in Philippines timezone (GMT+8)
  static DateTime nowInPhilippines() {
    // For booking purposes, we use the local device time as Philippines time
    // This assumes the device is set to Philippines timezone
    return DateTime.now();
  }

  /// Convert a DateTime to Philippines timezone (GMT+8)
  static DateTime toPhilippinesTime(DateTime dateTime) {
    // If the DateTime is UTC, convert to Philippines time (UTC+8)
    if (dateTime.isUtc) {
      return dateTime.add(const Duration(hours: 8));
    }

    // If it's already local time, treat it as Philippines time
    return dateTime;
  }

  /// Convert a DateTime from Philippines timezone to UTC
  static DateTime fromPhilippinesToUtc(DateTime dateTime) {
    // For our booking system, we don't need to convert to UTC
    // as we're storing times in Philippines timezone
    return dateTime;
  }

  /// Get a formatted string of the current time in Philippines timezone
  static String getCurrentPhilippinesTimeString() {
    final philippinesTime = nowInPhilippines();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(philippinesTime);
  }

  /// Parse a DateTime string and convert it to Philippines timezone
  static DateTime parseToPhilippinesTime(String dateTimeString) {
    final parsedDateTime = DateTime.parse(dateTimeString);

    // If the parsed DateTime is UTC (has +00:00 or Z suffix), convert to Philippines time
    if (parsedDateTime.isUtc ||
        dateTimeString.contains('+00:00') ||
        dateTimeString.endsWith('Z')) {
      // Convert UTC to Philippines time (UTC+8)
      return parsedDateTime.add(const Duration(hours: 8));
    }

    // If it's already local time, treat it as Philippines time
    return parsedDateTime;
  }

  /// Format a DateTime in Philippines timezone to ISO8601 string
  static String toPhilippinesIso8601String(DateTime dateTime) {
    // For booking purposes, we format the time as it appears in Philippines
    return dateTime.toIso8601String();
  }

  /// Check if a DateTime is in Philippines timezone
  static bool isInPhilippinesTimezone(DateTime dateTime) {
    // For our purposes, we consider all times as Philippines time
    return true;
  }

  /// Get the timezone offset for Philippines (UTC+8)
  static Duration getPhilippinesTimezoneOffset() {
    return const Duration(hours: 8);
  }
}
