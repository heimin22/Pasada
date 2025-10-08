import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/services/slow_internet_warning_service.dart';

/// A banner widget that shows a warning when the internet connection is slow
class SlowInternetWarningBanner extends StatefulWidget {
  final Widget child;
  final bool showBanner;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const SlowInternetWarningBanner({
    super.key,
    required this.child,
    this.showBanner = true,
    this.onRetry,
    this.onDismiss,
  });

  @override
  State<SlowInternetWarningBanner> createState() =>
      _SlowInternetWarningBannerState();
}

class _SlowInternetWarningBannerState extends State<SlowInternetWarningBanner>
    with TickerProviderStateMixin {
  final SlowInternetWarningService _warningService =
      SlowInternetWarningService();

  bool _isSlowConnection = false;
  bool _isOnline = true;
  ConnectionQuality _connectionQuality = ConnectionQuality.good;
  bool _isDismissed = false;

  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMonitoring();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeMonitoring() {
    // Listen to slow connection changes
    _warningService.isSlowConnectionStream.listen((isSlow) {
      if (mounted) {
        setState(() {
          _isSlowConnection = isSlow;
        });
        _updateBannerVisibility();
      }
    });

    // Listen to online status changes
    _warningService.isOnlineStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
        _updateBannerVisibility();
      }
    });

    // Listen to connection quality changes
    _warningService.connectionQualityStream.listen((quality) {
      if (mounted) {
        setState(() {
          _connectionQuality = quality;
        });
      }
    });
  }

  void _updateBannerVisibility() {
    if (!widget.showBanner || _isDismissed) return;

    if (_isSlowConnection && _isOnline) {
      _slideController.forward();
      _pulseController.repeat(reverse: true);
    } else {
      _slideController.reverse();
      _pulseController.stop();
    }
  }

  void _handleRetry() {
    _warningService.testConnection();
    widget.onRetry?.call();
  }

  void _handleDismiss() {
    setState(() {
      _isDismissed = true;
    });
    _slideController.reverse();
    _pulseController.stop();
    widget.onDismiss?.call();
  }

  Color _getBannerColor() {
    switch (_connectionQuality) {
      case ConnectionQuality.fair:
        return Colors.orange.shade600;
      case ConnectionQuality.poor:
        return Colors.red.shade600;
      case ConnectionQuality.veryPoor:
        return Colors.red.shade800;
      default:
        return Colors.orange.shade600;
    }
  }

  IconData _getBannerIcon() {
    switch (_connectionQuality) {
      case ConnectionQuality.fair:
        return Icons.signal_wifi_4_bar;
      case ConnectionQuality.poor:
        return Icons.signal_wifi_bad;
      case ConnectionQuality.veryPoor:
        return Icons.signal_wifi_off;
      default:
        return Icons.signal_wifi_4_bar;
    }
  }

  String _getBannerMessage() {
    switch (_connectionQuality) {
      case ConnectionQuality.fair:
        return 'Slow internet connection detected';
      case ConnectionQuality.poor:
        return 'Poor internet connection - some features may not work';
      case ConnectionQuality.veryPoor:
        return 'Very slow connection - please check your network';
      default:
        return 'Slow internet connection detected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showBanner &&
            _isSlowConnection &&
            _isOnline &&
            !_isDismissed)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: _buildBanner(),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getBannerColor(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              _getBannerIcon(),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getBannerMessage(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _warningService.getRecommendedAction(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _handleRetry,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  onPressed: _handleDismiss,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}

/// A simpler version of the banner that can be used as a standalone widget
class SimpleSlowInternetBanner extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const SimpleSlowInternetBanner({
    super.key,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: SlowInternetWarningService().isSlowConnectionStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.shade600,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.signal_wifi_4_bar,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Slow internet connection detected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              if (onRetry != null)
                IconButton(
                  onPressed: onRetry,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
