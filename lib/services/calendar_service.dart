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
  final Map<DateTime, String?> _holidayNameCache = {};

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
        _holidayNameCache[localDate] = null;
        return false;
      }
      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      final List<dynamic> items =
          (data['items'] as List<dynamic>? ?? <dynamic>[]);

      // Consider it a holiday if any all-day event exists on this date
      String? matchedHolidayName;
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
          final bool matches = !d0.isBefore(DateTime(
                  endDateTime.year, endDateTime.month, endDateTime.day)) &&
              !DateTime(startDateTime.year, startDateTime.month,
                      startDateTime.day)
                  .isAfter(d0);
          if (matches) {
            matchedHolidayName ??= (e['summary'] as String?)?.trim();
          }
          return matches;
        }
        final DateTime eventDate = DateTime.parse(startDateString);
        final bool matches = eventDate.year == localDate.year &&
            eventDate.month == localDate.month &&
            eventDate.day == localDate.day;
        if (matches) {
          matchedHolidayName ??= (e['summary'] as String?)?.trim();
        }
        return matches;
      });

      _isHolidayCache[localDate] = isHoliday;
      _holidayNameCache[localDate] = isHoliday ? matchedHolidayName : null;
      return isHoliday;
    } catch (_) {
      _isHolidayCache[localDate] = false;
      _holidayNameCache[localDate] = null;
      return false;
    }
  }

  /// Returns the specific holiday name for the provided [date], if any.
  /// Uses cached value when available; may perform a fetch if needed.
  Future<String?> getHolidayName(DateTime date) async {
    final DateTime localDate = DateTime(date.year, date.month, date.day);
    if (_holidayNameCache.containsKey(localDate)) {
      return _holidayNameCache[localDate];
    }

    // Ensure holiday status is computed and caches filled
    final bool isHoliday = await isPhilippineHoliday(localDate);
    if (!isHoliday) {
      _holidayNameCache[localDate] = null;
      return null;
    }
    return _holidayNameCache[localDate];
  }

  /// Fetches holidays within an inclusive [start]..[end] range (local dates),
  /// returning a map of local DateTime (Y-M-D) to holiday name.
  /// Populates internal caches for faster subsequent lookups.
  Future<Map<DateTime, String>> getHolidaysInRange(
      DateTime start, DateTime end) async {
    final DateTime startLocal = DateTime(start.year, start.month, start.day);
    final DateTime endLocal = DateTime(end.year, end.month, end.day);

    final String? apiKey = dotenv.env['GOOGLE_CALENDAR_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return <DateTime, String>{};
    }

    final DateTime timeMin = DateTime(
      startLocal.year,
      startLocal.month,
      startLocal.day,
      0,
      0,
      0,
    ).toUtc();
    final DateTime timeMax = DateTime(
      endLocal.year,
      endLocal.month,
      endLocal.day,
      23,
      59,
      59,
      999,
    ).toUtc();

    final Uri url = Uri.https(
      'www.googleapis.com',
      '/calendar/v3/calendars/$_calendarId/events',
      <String, String>{
        'key': apiKey,
        'timeMin': timeMin.toIso8601String(),
        'timeMax': timeMax.toIso8601String(),
        'singleEvents': 'true',
        'orderBy': 'startTime',
        'maxResults': '250',
      },
    );

    final Map<DateTime, String> result = <DateTime, String>{};
    try {
      final http.Response response =
          await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return result;
      }
      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      final List<dynamic> items =
          (data['items'] as List<dynamic>? ?? <dynamic>[]);

      for (final dynamic item in items) {
        final Map<String, dynamic> e = item as Map<String, dynamic>;
        final String? summary = (e['summary'] as String?)?.trim();
        if (summary == null || summary.isEmpty) continue;

        final Map<String, dynamic>? startObj =
            e['start'] as Map<String, dynamic>?;
        final Map<String, dynamic>? endObj = e['end'] as Map<String, dynamic>?;
        if (startObj == null) continue;

        if (startObj['date'] != null) {
          // All-day event
          final DateTime eventDate =
              DateTime.parse(startObj['date'] as String).toLocal();
          final DateTime key =
              DateTime(eventDate.year, eventDate.month, eventDate.day);
          if (!key.isBefore(startLocal) && !key.isAfter(endLocal)) {
            result[key] = summary;
            _isHolidayCache[key] = true;
            _holidayNameCache[key] = summary;
          }
        } else if (startObj['dateTime'] != null) {
          // Timed event – fill all matching days in range
          final DateTime startDt =
              DateTime.parse(startObj['dateTime'] as String).toLocal();
          final DateTime endDt = endObj != null && endObj['dateTime'] != null
              ? DateTime.parse(endObj['dateTime'] as String).toLocal()
              : startDt;
          DateTime cursor = DateTime(startDt.year, startDt.month, startDt.day);
          final DateTime endDay = DateTime(endDt.year, endDt.month, endDt.day);
          while (!cursor.isAfter(endDay)) {
            if (!cursor.isBefore(startLocal) && !cursor.isAfter(endLocal)) {
              result[cursor] = summary;
              _isHolidayCache[cursor] = true;
              _holidayNameCache[cursor] = summary;
            }
            cursor = cursor.add(const Duration(days: 1));
          }
        }
      }

      return result;
    } catch (_) {
      return result;
    }
  }
}
