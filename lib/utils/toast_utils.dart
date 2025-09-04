import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastUtils {
  // Standard toast colors
  static const Color _successBg = Color(0xFF00A347);
  static const Color _errorBg = Color(0xFFC82909);
  static const Color _warningBg = Color(0xFFE8A917);
  static const Color _infoBg = Color(0xFFF5F5F5);
  static const Color _lightText = Color(0xFFF5F5F5);
  static const Color _darkText = Color(0xFF121212);

  /// Shows a success toast message
  static void showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: _successBg,
      textColor: _lightText,
      fontSize: 16.0,
    );
  }

  /// Shows an error toast message
  static void showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: _errorBg,
      textColor: _lightText,
      fontSize: 16.0,
    );
  }

  /// Shows a warning toast message
  static void showWarning(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: _warningBg,
      textColor: _lightText,
      fontSize: 16.0,
    );
  }

  /// Shows an info toast message
  static void showInfo(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: _infoBg,
      textColor: _darkText,
      fontSize: 16.0,
    );
  }

  /// Shows a loading toast message that can be canceled
  static void showLoading(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: _infoBg,
      textColor: _darkText,
      fontSize: 16.0,
    );
  }

  /// Parse authentication errors and return user-friendly messages
  static String parseAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('internet') || errorString.contains('connection')) {
      return 'Network connection error. Please check your internet connection and try again.';
    }
    
    if (errorString.contains('invalid_credentials') || errorString.contains('invalid login')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }
    
    if (errorString.contains('email_not_confirmed') || errorString.contains('email not confirmed')) {
      return 'Please verify your email address before logging in.';
    }
    
    if (errorString.contains('too_many_requests') || errorString.contains('rate limit')) {
      return 'Too many login attempts. Please wait a moment before trying again.';
    }
    
    if (errorString.contains('user_not_found') || errorString.contains('user not found')) {
      return 'No account found with this email address.';
    }
    
    if (errorString.contains('email_already_registered') || errorString.contains('user_already_registered')) {
      return 'An account with this email already exists. Please try logging in instead.';
    }
    
    if (errorString.contains('phone number already registered')) {
      return 'This phone number is already registered with another account.';
    }
    
    if (errorString.contains('weak_password') || errorString.contains('password')) {
      return 'Password is too weak. Please use a stronger password with at least 8 characters.';
    }
    
    if (errorString.contains('invalid_email') || errorString.contains('email')) {
      return 'Please enter a valid email address.';
    }
    
    if (errorString.contains('signup_disabled')) {
      return 'Account registration is currently disabled. Please try again later.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timeout. Please check your connection and try again.';
    }
    
    // Default error message for unrecognized errors
    return 'An unexpected error occurred. Please try again later.';
  }

  /// Parse network/connectivity errors
  static String parseNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('socket') || errorString.contains('handshake')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    if (errorString.contains('no internet') || errorString.contains('no connection')) {
      return 'No internet connection detected. Please check your network settings.';
    }
    
    return 'Network error occurred. Please check your connection and try again.';
  }
}
