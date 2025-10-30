import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
// Removed unused material import
import 'package:pasada_passenger_app/utils/app_logger.dart';

/// Service to monitor internet connection speed and show warnings for slow connections
class SlowInternetWarningService {
  static final SlowInternetWarningService _instance =
      SlowInternetWarningService._internal();
  factory SlowInternetWarningService() => _instance;
  SlowInternetWarningService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Stream controllers for different connection states
  final StreamController<bool> _isOnlineController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _isSlowConnectionController =
      StreamController<bool>.broadcast();
  final StreamController<ConnectionQuality> _connectionQualityController =
      StreamController<ConnectionQuality>.broadcast();

  // Public streams
  Stream<bool> get isOnlineStream => _isOnlineController.stream;
  Stream<bool> get isSlowConnectionStream => _isSlowConnectionController.stream;
  Stream<ConnectionQuality> get connectionQualityStream =>
      _connectionQualityController.stream;

  // Current state
  bool _isOnline = true;
  bool _isSlowConnection = false;
  ConnectionQuality _connectionQuality = ConnectionQuality.good;

  // Getters
  bool get isOnline => _isOnline;
  bool get isSlowConnection => _isSlowConnection;
  ConnectionQuality get connectionQuality => _connectionQuality;

  // Configuration
  static const Duration _speedTestTimeout = Duration(seconds: 5);
  static const String _testUrl = 'https://www.google.com';

  /// Initialize the service
  Future<void> initialize() async {
    await _checkInitialConnection();

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        await _handleConnectivityChange(results);
      },
    );
  }

  /// Check initial connection status
  Future<void> _checkInitialConnection() async {
    final results = await _connectivity.checkConnectivity();
    await _handleConnectivityChange(results);
  }

  /// Handle connectivity changes
  Future<void> _handleConnectivityChange(
      List<ConnectivityResult> results) async {
    final hasConnection = results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);

    if (!hasConnection) {
      _updateConnectionState(false, false, ConnectionQuality.none);
      return;
    }

    // Test actual internet access and speed
    final hasInternet = await _testInternetAccess();
    if (!hasInternet) {
      _updateConnectionState(false, false, ConnectionQuality.none);
      return;
    }

    // Test connection speed
    final speedTestResult = await _testConnectionSpeed();
    _updateConnectionState(
        true, speedTestResult.isSlow, speedTestResult.quality);
  }

  /// Test if internet access is available
  Future<bool> _testInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      AppLogger.warn('Internet access test failed: $e', tag: 'Net');
      return false;
    }
  }

  /// Test connection speed and determine if it's slow
  Future<SpeedTestResult> _testConnectionSpeed() async {
    try {
      final stopwatch = Stopwatch()..start();

      final client = HttpClient();
      client.connectionTimeout = _speedTestTimeout;

      final request = await client.getUrl(Uri.parse(_testUrl));
      await request.close();

      stopwatch.stop();
      final responseTime = stopwatch.elapsed;

      client.close();

      // Determine connection quality based on response time
      ConnectionQuality quality;
      bool isSlow = false;

      if (responseTime <= const Duration(milliseconds: 500)) {
        quality = ConnectionQuality.excellent;
      } else if (responseTime <= const Duration(milliseconds: 1000)) {
        quality = ConnectionQuality.good;
      } else if (responseTime <= const Duration(milliseconds: 2000)) {
        quality = ConnectionQuality.fair;
        isSlow = true;
      } else if (responseTime <= const Duration(seconds: 3)) {
        quality = ConnectionQuality.poor;
        isSlow = true;
      } else {
        quality = ConnectionQuality.veryPoor;
        isSlow = true;
      }

      AppLogger.debug('Connection ${responseTime.inMilliseconds}ms - $quality',
          tag: 'Net', throttle: true);

      return SpeedTestResult(
        responseTime: responseTime,
        quality: quality,
        isSlow: isSlow,
      );
    } catch (e) {
      AppLogger.warn('Speed test failed: $e', tag: 'Net');
      return SpeedTestResult(
        responseTime: const Duration(seconds: 10),
        quality: ConnectionQuality.veryPoor,
        isSlow: true,
      );
    }
  }

  /// Update connection state and notify listeners
  void _updateConnectionState(
      bool isOnline, bool isSlowConnection, ConnectionQuality quality) {
    bool stateChanged = false;

    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _isOnlineController.add(_isOnline);
      stateChanged = true;
    }

    if (_isSlowConnection != isSlowConnection) {
      _isSlowConnection = isSlowConnection;
      _isSlowConnectionController.add(_isSlowConnection);
      stateChanged = true;
    }

    if (_connectionQuality != quality) {
      _connectionQuality = quality;
      _connectionQualityController.add(_connectionQuality);
      stateChanged = true;
    }

    if (stateChanged) {
      AppLogger.debug(
          'Conn updated online:$isOnline slow:$isSlowConnection q:$quality',
          tag: 'Net',
          throttle: true);
    }
  }

  /// Manually trigger a connection test
  Future<void> testConnection() async {
    final results = await _connectivity.checkConnectivity();
    await _handleConnectivityChange(results);
  }

  /// Get connection quality description
  String getConnectionQualityDescription() {
    switch (_connectionQuality) {
      case ConnectionQuality.excellent:
        return 'Excellent connection';
      case ConnectionQuality.good:
        return 'Good connection';
      case ConnectionQuality.fair:
        return 'Fair connection';
      case ConnectionQuality.poor:
        return 'Poor connection';
      case ConnectionQuality.veryPoor:
        return 'Very poor connection';
      case ConnectionQuality.none:
        return 'No connection';
    }
  }

  /// Get recommended action based on connection quality
  String getRecommendedAction() {
    switch (_connectionQuality) {
      case ConnectionQuality.excellent:
      case ConnectionQuality.good:
        return 'Connection is working well';
      case ConnectionQuality.fair:
        return 'Consider switching to a better network if available';
      case ConnectionQuality.poor:
        return 'Connection is slow. Some features may not work properly';
      case ConnectionQuality.veryPoor:
        return 'Connection is very slow. Please check your network or try again later';
      case ConnectionQuality.none:
        return 'No internet connection. Please check your network settings';
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _isOnlineController.close();
    _isSlowConnectionController.close();
    _connectionQualityController.close();
  }
}

/// Connection quality levels
enum ConnectionQuality {
  excellent,
  good,
  fair,
  poor,
  veryPoor,
  none,
}

/// Result of a speed test
class SpeedTestResult {
  final Duration responseTime;
  final ConnectionQuality quality;
  final bool isSlow;

  const SpeedTestResult({
    required this.responseTime,
    required this.quality,
    required this.isSlow,
  });
}

/// Mixin to easily add slow internet monitoring to widgets
mixin SlowInternetMonitoringMixin {
  StreamSubscription<bool>? _slowConnectionSubscription;
  bool _isSlowConnection = false;
  bool get isSlowConnection => _isSlowConnection;

  /// Initialize slow internet monitoring for the widget
  void initSlowInternetMonitoring() {
    _slowConnectionSubscription =
        SlowInternetWarningService().isSlowConnectionStream.listen((isSlow) {
      _isSlowConnection = isSlow;
      onSlowConnectionChanged(isSlow);
    });
  }

  /// Override this method to handle slow connection changes
  void onSlowConnectionChanged(bool isSlowConnection) {
    // Override in implementing classes
  }

  /// Dispose slow internet monitoring
  void disposeSlowInternetMonitoring() {
    _slowConnectionSubscription?.cancel();
  }
}
