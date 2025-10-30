import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn, error, none }

class AppLogger {
  static LogLevel level = kDebugMode ? LogLevel.info : LogLevel.warn;
  static bool verbose = false; // enable to print very detailed structures

  static final Map<int, DateTime> _lastSeenByHash = {};
  static Duration throttleWindow = const Duration(seconds: 3);

  static void setLevel(LogLevel newLevel) {
    level = newLevel;
  }

  static void setVerbose(bool isVerbose) {
    verbose = isVerbose;
  }

  static void debug(String message, {String? tag, bool throttle = true}) {
    _log(LogLevel.debug, message, tag: tag, throttle: throttle);
  }

  static void info(String message, {String? tag, bool throttle = true}) {
    _log(LogLevel.info, message, tag: tag, throttle: throttle);
  }

  static void warn(String message, {String? tag, bool throttle = true}) {
    _log(LogLevel.warn, message, tag: tag, throttle: throttle);
  }

  static void error(String message, {String? tag, bool throttle = false}) {
    _log(LogLevel.error, message, tag: tag, throttle: throttle);
  }

  static void _log(LogLevel msgLevel, String message,
      {String? tag, bool throttle = true}) {
    if (level.index > msgLevel.index) return;
    if (!kDebugMode && msgLevel == LogLevel.debug)
      return; // no debug in release

    final formatted = tag != null ? '[$tag] $message' : message;
    final hash = formatted.hashCode;

    if (throttle) {
      final now = DateTime.now();
      final last = _lastSeenByHash[hash];
      if (last != null && now.difference(last) < throttleWindow) {
        return; // drop duplicate within window
      }
      _lastSeenByHash[hash] = now;
    }

    // Use debugPrint to avoid long line truncation issues in Flutter
    debugPrint(formatted);
  }
}
