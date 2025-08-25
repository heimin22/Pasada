import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Service to handle offline/online connection checking and monitoring
class OfflineConnectionCheckService {
  static final OfflineConnectionCheckService _instance = OfflineConnectionCheckService._internal();
  factory OfflineConnectionCheckService() => _instance;
  OfflineConnectionCheckService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Stream controller to notify listeners about connectivity changes
  final StreamController<bool> _connectionStreamController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionStreamController.stream;
  
    bool _isConnected = true;
  bool get isConnected => _isConnected;
  
  // Track if offline bottom sheet is currently being shown
  bool _isOfflineBottomSheetShown = false;
  bool get isOfflineBottomSheetShown => _isOfflineBottomSheetShown;
  
  /// Mark that the offline bottom sheet is being shown
  void setOfflineBottomSheetShown(bool isShown) {
    _isOfflineBottomSheetShown = isShown;
  }
 
  /// Initialize the connectivity service
  Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        await _checkConnectivity();
      },
    );
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    await _checkConnectivity();
    return _isConnected;
  }

  /// Private method to check connectivity and notify listeners
  Future<void> _checkConnectivity() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    
    // Check if device has network connectivity
    bool hasConnection = connectivityResults.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );

    // If device shows connectivity, perform actual internet check
    if (hasConnection) {
      hasConnection = await _hasInternetAccess();
    }

    // Only notify if connection state changed
    if (_isConnected != hasConnection) {
      _isConnected = hasConnection;
      _connectionStreamController.add(_isConnected);
      
      debugPrint('Connection status changed: ${_isConnected ? "Online" : "Offline"}');
    }
  }

  /// Test actual internet access by attempting to reach a reliable server
  Future<bool> _hasInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      debugPrint('Internet access check error: $e');
      return false;
    }
  }

  /// Retry connection check - useful for manual retry attempts
  Future<bool> retryConnection() async {
    debugPrint('Retrying connection...');
    await Future.delayed(const Duration(seconds: 1)); // Brief delay for user feedback
    return await checkConnectivity();
  }

  /// Show connection status for debugging
  void logConnectionStatus() {
    debugPrint('Current connection status: ${_isConnected ? "Online" : "Offline"}');
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionStreamController.close();
  }
}

/// Mixin to easily add connectivity checking to widgets
mixin ConnectivityMixin {
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  /// Initialize connectivity monitoring for the widget
  void initConnectivityMonitoring() {
    _connectivitySubscription = OfflineConnectionCheckService()
        .connectionStream
        .listen((isConnected) {
      _isConnected = isConnected;
      onConnectivityChanged(isConnected);
    });
  }

  /// Override this method to handle connectivity changes
  void onConnectivityChanged(bool isConnected) {
    // Override in implementing classes
  }

  /// Dispose connectivity monitoring
  void disposeConnectivityMonitoring() {
    _connectivitySubscription?.cancel();
  }
}
