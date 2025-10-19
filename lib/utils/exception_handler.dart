import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/utils/toast_utils.dart';

/// Centralized exception handling utility for the app
class ExceptionHandler {
  /// Handle exceptions with logging and user feedback
  static void handleException(
    dynamic exception,
    String context, {
    String? userMessage,
    bool showToast = true,
    bool logToConsole = true,
  }) {
    // Log the exception
    if (logToConsole) {
      developer.log(
        'Exception in $context: $exception',
        name: 'ExceptionHandler',
        error: exception,
        stackTrace: StackTrace.current,
      );
    }

    // Show user-friendly message
    if (showToast && userMessage != null) {
      ToastUtils.showError(userMessage);
    }
  }

  /// Handle network-related exceptions
  static void handleNetworkException(
    dynamic exception,
    String context, {
    String? userMessage,
    bool showToast = true,
  }) {
    final networkMessage =
        userMessage ?? 'Network error. Please check your connection.';

    handleException(
      exception,
      context,
      userMessage: networkMessage,
      showToast: showToast,
    );
  }

  /// Handle location-related exceptions
  static void handleLocationException(
    dynamic exception,
    String context, {
    String? userMessage,
    bool showToast = true,
  }) {
    final locationMessage =
        userMessage ?? 'Location error. Please check your location settings.';

    handleException(
      exception,
      context,
      userMessage: locationMessage,
      showToast: showToast,
    );
  }

  /// Handle authentication-related exceptions
  static void handleAuthException(
    dynamic exception,
    String context, {
    String? userMessage,
    bool showToast = true,
  }) {
    final authMessage =
        userMessage ?? 'Authentication error. Please try again.';

    handleException(
      exception,
      context,
      userMessage: authMessage,
      showToast: showToast,
    );
  }

  /// Handle database-related exceptions
  static void handleDatabaseException(
    dynamic exception,
    String context, {
    String? userMessage,
    bool showToast = true,
  }) {
    final dbMessage = userMessage ?? 'Data error. Please try again.';

    handleException(
      exception,
      context,
      userMessage: dbMessage,
      showToast: showToast,
    );
  }

  /// Handle permission-related exceptions
  static void handlePermissionException(
    dynamic exception,
    String context, {
    String? userMessage,
    bool showToast = true,
  }) {
    final permissionMessage =
        userMessage ?? 'Permission error. Please check your app permissions.';

    handleException(
      exception,
      context,
      userMessage: permissionMessage,
      showToast: showToast,
    );
  }

  /// Handle generic exceptions with custom error message
  static void handleGenericException(
    dynamic exception,
    String context, {
    String? userMessage,
    bool showToast = true,
  }) {
    final genericMessage =
        userMessage ?? 'An unexpected error occurred. Please try again.';

    handleException(
      exception,
      context,
      userMessage: genericMessage,
      showToast: showToast,
    );
  }

  /// Handle exceptions silently (only log, no user feedback)
  static void handleSilentException(
    dynamic exception,
    String context,
  ) {
    handleException(
      exception,
      context,
      showToast: false,
    );
  }

  /// Handle exceptions with custom error handling
  static void handleCustomException(
    dynamic exception,
    String context,
    VoidCallback? onError,
  ) {
    // Log the exception
    developer.log(
      'Exception in $context: $exception',
      name: 'ExceptionHandler',
      error: exception,
      stackTrace: StackTrace.current,
    );

    // Execute custom error handling
    if (onError != null) {
      onError();
    }
  }

  /// Get user-friendly error message based on exception type
  static String getUserFriendlyMessage(dynamic exception) {
    if (exception.toString().contains('network') ||
        exception.toString().contains('connection')) {
      return 'Network error. Please check your connection.';
    }

    if (exception.toString().contains('location') ||
        exception.toString().contains('permission')) {
      return 'Location error. Please check your location settings.';
    }

    if (exception.toString().contains('auth') ||
        exception.toString().contains('login')) {
      return 'Authentication error. Please try again.';
    }

    if (exception.toString().contains('database') ||
        exception.toString().contains('query')) {
      return 'Data error. Please try again.';
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
