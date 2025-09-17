import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service to determine if a given date is a Philippine public holiday
/// using Google Calendar API (Philippines Holidays calendar).
class CalendarService {
  CalendarService._();

  static final CalendarService instance = CalendarService._();

  // Google public calendar for Philippines holidays
  // See: https://developers.google.com/calendar/api/v3/reference/events/list
  static const String _calendarId =
      'en.philippines#holiday@group.v.calendar.google.com';

  // Simple in-memory cache for day lookups to reduce API calls
  final Map<DateTime, bool> _isHolidayCache = {};

  /// Returns true if the provided [date] is a holiday in the Philippines.
  /// Results are cached per local date (year-month-day).
  Future<bool> isPhilippineHoliday(DateTime date) async {
    final DateTime localDate = DateTime(date.year, date.month, date.day);
    if (_isHolidayCache.containsKey(localDate)) {
      return _isHolidayCache[localDate]!;
    }

    final String? apiKey = dotenv.env['GOOGLE_CALENDAR_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      // If no API key is configured, assume not a holiday to avoid blocking discounts
      _isHolidayCache[localDate] = false;
      return false;
    }

    // Define timeMin/timeMax to cover the entire local day in ISO8601
    final DateTime timeMin =
        DateTime(localDate.year, localDate.month, localDate.day, 0, 0, 0)
            .toUtc();
    final DateTime timeMax = timeMin.add(const Duration(days: 1));

    final Uri url = Uri.https(
      'www.googleapis.com',
      '/calendar/v3/calendars/$_calendarId/events',
      <String, String>{
        'key': apiKey,
        'timeMin': timeMin.toIso8601String(),
        'timeMax': timeMax.toIso8601String(),
        'singleEvents': 'true',
        'orderBy': 'startTime',
        'maxResults': '5',
      },
    );

    try {
      final http.Response response =
          await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        _isHolidayCache[localDate] = false;
        return false;
      }
      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      final List<dynamic> items =
          (data['items'] as List<dynamic>? ?? <dynamic>[]);

      // Consider it a holiday if any all-day event exists on this date
      final bool isHoliday = items.any((dynamic item) {
        final Map<String, dynamic> e = item as Map<String, dynamic>;
        final Map<String, dynamic>? start = e['start'] as Map<String, dynamic>?;
        final Map<String, dynamic>? end = e['end'] as Map<String, dynamic>?;
        if (start == null) return false;
        // All-day holiday events usually use 'date' (no time)
        final String? startDateString = start['date'] as String?;
        if (startDateString == null) {
          // Timed event: compare date range
          final String? startDateTimeString = start['dateTime'] as String?;
          if (startDateTimeString == null) return false;
          final DateTime startDateTime =
              DateTime.parse(startDateTimeString).toLocal();
          final DateTime endDateTime = end != null && end['dateTime'] != null
              ? DateTime.parse(end['dateTime'] as String).toLocal()
              : startDateTime;
          final DateTime d0 =
              DateTime(localDate.year, localDate.month, localDate.day);
          return !d0.isBefore(DateTime(
                  endDateTime.year, endDateTime.month, endDateTime.day)) &&
              !DateTime(startDateTime.year, startDateTime.month,
                      startDateTime.day)
                  .isAfter(d0);
        }
        final DateTime eventDate = DateTime.parse(startDateString);
        return eventDate.year == localDate.year &&
            eventDate.month == localDate.month &&
            eventDate.day == localDate.day;
      });

      _isHolidayCache[localDate] = isHoliday;
      return isHoliday;
    } catch (_) {
      _isHolidayCache[localDate] = false;
      return false;
    }
  }
}
