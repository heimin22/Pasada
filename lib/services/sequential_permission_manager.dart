import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:location/location.dart' as location;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/location_permission_manager.dart';
import '../services/notificationService.dart';

/// Centralized manager for requesting permissions sequentially to prevent system overload
/// and provide a better user experience with explanations for each permission.
class SequentialPermissionManager {
  static SequentialPermissionManager? _instance;
  static SequentialPermissionManager get instance =>
      _instance ??= SequentialPermissionManager._();

  SequentialPermissionManager._();

  // Track permission request state to prevent multiple simultaneous flows
  bool _isRequestingPermissions = false;
  final Map<Permission, DateTime> _lastRequestTime = {};

  // Minimum delay between permission requests to prevent overwhelming the system
  static const Duration _requestDelay = Duration(milliseconds: 800);
  static const Duration _cooldownPeriod = Duration(seconds: 30);

  /// Main method to request all required permissions sequentially for onboarding
  Future<PermissionFlowResult> requestOnboardingPermissions({
    required BuildContext context,
    bool showExplanations = true,
  }) async {
    if (_isRequestingPermissions) {
      debugPrint(
          'Permission flow already in progress, ignoring duplicate request');
      return PermissionFlowResult(
          success: false, message: 'Permission flow already in progress');
    }

    _isRequestingPermissions = true;

    try {
      final result = await _executeSequentialPermissionFlow(
        context: context,
        showExplanations: showExplanations,
      );

      return result;
    } finally {
      _isRequestingPermissions = false;
    }
  }

  /// Execute the sequential permission flow
  Future<PermissionFlowResult> _executeSequentialPermissionFlow({
    required BuildContext context,
    required bool showExplanations,
  }) async {
    final List<PermissionRequestInfo> permissionFlow = [
      PermissionRequestInfo(
        permission: Permission.location,
        title: 'Location Access',
        description:
            'We need location access to show nearby buses and calculate routes to your destination.',
        icon: Icons.location_on,
        isEssential: true,
        customHandler: _handleLocationPermission,
      ),
      PermissionRequestInfo(
        permission: Permission.locationAlways,
        title: 'Background Location',
        description:
            'This allows us to provide real-time updates about your ride even when the app is in the background.',
        icon: Icons.location_searching,
        isEssential: false,
        dependsOn: Permission.location,
        customHandler: _handleBackgroundLocationPermission,
      ),
      PermissionRequestInfo(
        permission: Permission.notification,
        title: 'Notifications',
        description:
            'Stay updated with ride confirmations, driver location, and arrival notifications.',
        icon: Icons.notifications,
        isEssential: true,
        customHandler: _handleNotificationPermission,
      ),
    ];

    // Add SMS permission for Android only
    if (Platform.isAndroid) {
      permissionFlow.add(
        PermissionRequestInfo(
          permission: Permission.sms,
          title: 'SMS Access',
          description:
              'This helps us automatically verify your phone number with SMS codes.',
          icon: Icons.sms,
          isEssential: false,
        ),
      );
    }

    final results = <Permission, PermissionStatus>{};
    final failedEssential = <PermissionRequestInfo>[];

    for (final permissionInfo in permissionFlow) {
      // Check if permission depends on another permission
      if (permissionInfo.dependsOn != null) {
        final dependentStatus = results[permissionInfo.dependsOn];
        if (dependentStatus != PermissionStatus.granted) {
          debugPrint(
              'Skipping ${permissionInfo.permission} as dependency ${permissionInfo.dependsOn} not granted');
          results[permissionInfo.permission] = PermissionStatus.denied;
          continue;
        }
      }

      // Show explanation dialog if needed
      if (showExplanations && context.mounted) {
        final shouldProceed = await _showPermissionExplanation(
          context: context,
          permissionInfo: permissionInfo,
        );

        if (!shouldProceed) {
          results[permissionInfo.permission] = PermissionStatus.denied;
          if (permissionInfo.isEssential) {
            failedEssential.add(permissionInfo);
          }
          continue;
        }
      }

      // Add delay between permission requests
      if (_lastRequestTime.isNotEmpty) {
        await Future.delayed(_requestDelay);
      }

      // Request the permission
      final status = await _requestSinglePermission(permissionInfo);
      results[permissionInfo.permission] = status;
      _lastRequestTime[permissionInfo.permission] = DateTime.now();

      // If essential permission was denied, track it
      if (permissionInfo.isEssential && status != PermissionStatus.granted) {
        failedEssential.add(permissionInfo);
      }

      debugPrint('Permission ${permissionInfo.permission}: $status');
    }

    // Save results to preferences for future reference
    await _savePermissionResults(results);

    // Determine overall success
    final hasFailedEssential = failedEssential.isNotEmpty;
    final successMessage = _buildResultMessage(results, failedEssential);

    return PermissionFlowResult(
      success: !hasFailedEssential,
      message: successMessage,
      permissionResults: results,
      failedEssentialPermissions: failedEssential,
    );
  }

  /// Request a single permission with custom handling if available
  Future<PermissionStatus> _requestSinglePermission(
      PermissionRequestInfo info) async {
    try {
      // Check for cooldown period
      final lastRequest = _lastRequestTime[info.permission];
      if (lastRequest != null &&
          DateTime.now().difference(lastRequest) < _cooldownPeriod) {
        // Return current status without requesting again
        return await info.permission.status;
      }

      // Use custom handler if available
      if (info.customHandler != null) {
        return await info.customHandler!(info);
      }

      // Standard permission request
      final currentStatus = await info.permission.status;
      if (currentStatus == PermissionStatus.granted) {
        return currentStatus;
      }

      return await info.permission.request();
    } catch (e) {
      debugPrint('Error requesting permission ${info.permission}: $e');
      return PermissionStatus.denied;
    }
  }

  /// Custom handler for location permission (integrates with existing LocationPermissionManager)
  Future<PermissionStatus> _handleLocationPermission(
      PermissionRequestInfo info) async {
    try {
      final locationStatus = await LocationPermissionManager.instance
          .ensureLocationPermissionGranted();

      // Convert location package status to permission_handler status
      switch (locationStatus) {
        case location.PermissionStatus.granted:
        case location.PermissionStatus.grantedLimited:
          return PermissionStatus.granted;
        case location.PermissionStatus.denied:
          return PermissionStatus.denied;
        case location.PermissionStatus.deniedForever:
          return PermissionStatus.permanentlyDenied;
      }
    } catch (e) {
      debugPrint('Error in custom location permission handler: $e');
      // Fallback to standard permission request
      return await info.permission.request();
    }
  }

  /// Custom handler for background location permission
  Future<PermissionStatus> _handleBackgroundLocationPermission(
      PermissionRequestInfo info) async {
    try {
      // Only request if foreground location is granted
      final foregroundStatus = await Permission.location.status;
      if (foregroundStatus != PermissionStatus.granted) {
        return PermissionStatus.denied;
      }

      return await info.permission.request();
    } catch (e) {
      debugPrint('Error in background location permission handler: $e');
      return PermissionStatus.denied;
    }
  }

  /// Custom handler for notification permission (integrates with NotificationService)
  Future<PermissionStatus> _handleNotificationPermission(
      PermissionRequestInfo info) async {
    try {
      // Use existing notification service logic
      await NotificationService.initialize();

      // Check if notifications are enabled
      final areEnabled = await NotificationService.checkPermissions();
      return areEnabled ? PermissionStatus.granted : PermissionStatus.denied;
    } catch (e) {
      debugPrint('Error in notification permission handler: $e');
      // Fallback to standard permission request
      return await info.permission.request();
    }
  }

  /// Show explanation dialog before requesting permission
  Future<bool> _showPermissionExplanation({
    required BuildContext context,
    required PermissionRequestInfo permissionInfo,
  }) async {
    if (!context.mounted) return false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  permissionInfo.icon,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    permissionInfo.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permissionInfo.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                if (permissionInfo.isEssential)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withAlpha(30)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This permission is required for the app to function properly.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              if (!permissionInfo.isEssential)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFFD7481D),
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Allow',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF00CC58),
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Save permission results to shared preferences
  Future<void> _savePermissionResults(
      Map<Permission, PermissionStatus> results) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await prefs.setInt('permission_flow_timestamp', timestamp);

      for (final entry in results.entries) {
        final key = 'permission_${entry.key.toString()}';
        final value = entry.value.toString();
        await prefs.setString(key, value);
      }
    } catch (e) {
      debugPrint('Error saving permission results: $e');
    }
  }

  /// Build result message based on permission outcomes
  String _buildResultMessage(
    Map<Permission, PermissionStatus> results,
    List<PermissionRequestInfo> failedEssential,
  ) {
    if (failedEssential.isNotEmpty) {
      return 'Some essential permissions were not granted. The app may not function properly.';
    }

    final grantedCount = results.values
        .where((status) => status == PermissionStatus.granted)
        .length;
    final totalCount = results.length;

    if (grantedCount == totalCount) {
      return 'All permissions granted successfully!';
    } else {
      return 'Permissions setup completed. Some optional permissions were skipped.';
    }
  }

  /// Check if we should request permissions again (for retry scenarios)
  Future<bool> shouldRetryPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFlowTimestamp = prefs.getInt('permission_flow_timestamp');

      if (lastFlowTimestamp == null) return true;

      final lastFlow = DateTime.fromMillisecondsSinceEpoch(lastFlowTimestamp);
      final hoursSinceLastFlow = DateTime.now().difference(lastFlow).inHours;

      // Allow retry after 24 hours
      return hoursSinceLastFlow >= 24;
    } catch (e) {
      debugPrint('Error checking retry permissions: $e');
      return true;
    }
  }

  /// Get current status of all managed permissions
  Future<Map<Permission, PermissionStatus>> getCurrentPermissionStatus() async {
    final permissions = [
      Permission.location,
      Permission.locationAlways,
      Permission.notification,
      if (Platform.isAndroid) Permission.sms,
    ];

    final results = <Permission, PermissionStatus>{};
    for (final permission in permissions) {
      try {
        results[permission] = await permission.status;
      } catch (e) {
        results[permission] = PermissionStatus.denied;
      }
    }

    return results;
  }
}

/// Information about a permission request
class PermissionRequestInfo {
  final Permission permission;
  final String title;
  final String description;
  final IconData icon;
  final bool isEssential;
  final Permission? dependsOn;
  final Future<PermissionStatus> Function(PermissionRequestInfo)? customHandler;

  PermissionRequestInfo({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
    this.isEssential = false,
    this.dependsOn,
    this.customHandler,
  });
}

/// Result of permission flow execution
class PermissionFlowResult {
  final bool success;
  final String message;
  final Map<Permission, PermissionStatus>? permissionResults;
  final List<PermissionRequestInfo>? failedEssentialPermissions;

  PermissionFlowResult({
    required this.success,
    required this.message,
    this.permissionResults,
    this.failedEssentialPermissions,
  });
}
