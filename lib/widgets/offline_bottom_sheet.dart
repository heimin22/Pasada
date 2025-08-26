import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/screens/offflineConnectionCheckService.dart';
import 'package:pasada_passenger_app/theme/theme_controller.dart';

/// Bottom sheet widget displayed when the app is offline
class OfflineBottomSheet extends StatefulWidget {
  /// Callback function called when connection is restored
  final VoidCallback? onConnectionRestored;
  
  /// Whether to show the bottom sheet as persistent (non-dismissible)
  final bool isPersistent;

  const OfflineBottomSheet({
    super.key,
    this.onConnectionRestored,
    this.isPersistent = true,
  });

  /// Show the offline bottom sheet
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onConnectionRestored,
    bool isPersistent = true,
  }) {
    return showModalBottomSheet(
      context: context,
      isDismissible: !isPersistent,
      enableDrag: !isPersistent,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OfflineBottomSheet(
        onConnectionRestored: onConnectionRestored,
        isPersistent: isPersistent,
      ),
    );
  }

  @override
  State<OfflineBottomSheet> createState() => _OfflineBottomSheetState();
}

class _OfflineBottomSheetState extends State<OfflineBottomSheet>
    with TickerProviderStateMixin {
  bool _isRetrying = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    _themeController.initialize();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    // Reset the bottom sheet shown flag when widget is disposed
    OfflineConnectionCheckService().setOfflineBottomSheetShown(false);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
    });

    try {
      final connectivityService = OfflineConnectionCheckService();
      final isConnected = await connectivityService.retryConnection();
      
      if (isConnected) {
        // Connection restored
        connectivityService.setOfflineBottomSheetShown(false);
        widget.onConnectionRestored?.call();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Still offline, show feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Still no internet connection. Please check your network settings.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Retry connection error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to check connection. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeController.isDarkMode;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212);
    final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600];
    final handleBarColor = isDarkMode ? Colors.grey[600] : Colors.grey[300];
    final iconBackgroundColor = isDarkMode ? Colors.red[900]?.withValues(alpha: 0.3) : Colors.red[50];
    final iconColor = isDarkMode ? Colors.red[300] : Colors.red[400];
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: handleBarColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Offline icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'No Internet Connection',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              'Please check your internet connection and try again. Make sure you have a stable WiFi or mobile data connection.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: subtitleColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // Retry button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRetrying ? null : _handleRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isRetrying
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Checking...',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Try Again',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            // Tips section
            const SizedBox(height: 24),
                          Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.blue[900]?.withValues(alpha: 0.3) : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.blue[400]! : Colors.blue[200]!,
                  ),
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: isDarkMode ? Colors.blue[300] : Colors.blue[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tips',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDarkMode ? Colors.blue[200] : Colors.blue[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Check if WiFi or mobile data is enabled\n'
                    '• Try moving to an area with better signal\n'
                    '• Restart your device\'s network settings',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom padding for safe area
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
