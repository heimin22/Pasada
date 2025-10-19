import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

/// Service for logging and tracking errors in the app
class ErrorLoggingService {
  static const String _errorLogKey = 'error_logs';
  static const int _maxLogEntries = 100; // Keep only last 100 errors

  /// Log an error with context information
  static Future<void> logError({
    required String error,
    required String context,
    String? userId,
    Map<String, dynamic>? additionalData,
    StackTrace? stackTrace,
  }) async {
    try {
      final errorEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'error': error,
        'context': context,
        'userId': userId,
        'additionalData': additionalData,
        'stackTrace': stackTrace?.toString(),
      };

      // Log to console for development
      developer.log(
        'Error logged: $error',
        name: 'ErrorLoggingService',
        error: error,
        stackTrace: stackTrace,
      );

      // Store in SharedPreferences for persistence
      await _storeErrorLog(errorEntry);
    } catch (e) {
      // If error logging fails, at least log to console
      developer.log('Failed to log error: $e');
    }
  }

  /// Store error log in SharedPreferences
  static Future<void> _storeErrorLog(Map<String, dynamic> errorEntry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingLogs = prefs.getStringList(_errorLogKey) ?? [];

      // Add new error entry
      existingLogs.add(errorEntry.toString());

      // Keep only the last N entries
      if (existingLogs.length > _maxLogEntries) {
        existingLogs.removeRange(0, existingLogs.length - _maxLogEntries);
      }

      await prefs.setStringList(_errorLogKey, existingLogs);
    } catch (e) {
      developer.log('Failed to store error log: $e');
    }
  }

  /// Get stored error logs
  static Future<List<Map<String, dynamic>>> getErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList(_errorLogKey) ?? [];

      return logs.map((log) {
        try {
          // Parse the stored log entry
          return Map<String, dynamic>.from(log as Map);
        } catch (e) {
          return <String, dynamic>{'error': 'Failed to parse log entry'};
        }
      }).toList();
    } catch (e) {
      developer.log('Failed to get error logs: $e');
      return [];
    }
  }

  /// Clear all error logs
  static Future<void> clearErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_errorLogKey);
    } catch (e) {
      developer.log('Failed to clear error logs: $e');
    }
  }

  /// Log critical errors that need immediate attention
  static Future<void> logCriticalError({
    required String error,
    required String context,
    String? userId,
    Map<String, dynamic>? additionalData,
    StackTrace? stackTrace,
  }) async {
    // Log with higher priority
    developer.log(
      'CRITICAL ERROR: $error',
      name: 'ErrorLoggingService',
      error: error,
      stackTrace: stackTrace,
      level: 1000, // High priority
    );

    // Store with critical flag
    await logError(
      error: 'CRITICAL: $error',
      context: context,
      userId: userId,
      additionalData: {
        ...?additionalData,
        'critical': true,
      },
      stackTrace: stackTrace,
    );
  }

  /// Log network-related errors
  static Future<void> logNetworkError({
    required String error,
    required String context,
    String? userId,
    String? endpoint,
    int? statusCode,
  }) async {
    await logError(
      error: error,
      context: context,
      userId: userId,
      additionalData: {
        'type': 'network',
        'endpoint': endpoint,
        'statusCode': statusCode,
      },
    );
  }

  /// Log location-related errors
  static Future<void> logLocationError({
    required String error,
    required String context,
    String? userId,
    double? latitude,
    double? longitude,
  }) async {
    await logError(
      error: error,
      context: context,
      userId: userId,
      additionalData: {
        'type': 'location',
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  /// Log authentication errors
  static Future<void> logAuthError({
    required String error,
    required String context,
    String? userId,
    String? authMethod,
  }) async {
    await logError(
      error: error,
      context: context,
      userId: userId,
      additionalData: {
        'type': 'authentication',
        'authMethod': authMethod,
      },
    );
  }
}
