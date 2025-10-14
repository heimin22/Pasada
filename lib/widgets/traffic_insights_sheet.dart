import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/models/traffic_analytics.dart';
import 'package:pasada_passenger_app/services/traffic_analytics_service.dart';

/// Bottom sheet widget for displaying real-time traffic analytics
class TrafficInsightsSheet extends StatefulWidget {
  final List<Map<String, dynamic>> routes;
  final List<Map<String, dynamic>> filteredRoutes;

  const TrafficInsightsSheet({
    super.key,
    required this.routes,
    required this.filteredRoutes,
  });

  @override
  State<TrafficInsightsSheet> createState() => _TrafficInsightsSheetState();
}

class _TrafficInsightsSheetState extends State<TrafficInsightsSheet> {
  final TrafficAnalyticsService _analyticsService = TrafficAnalyticsService();
  TodayRouteTrafficResponse? _trafficData;
  bool _isLoadingTraffic = false;
  String? _trafficError;

  @override
  void initState() {
    super.initState();
    _fetchTrafficReports();
  }

  Future<void> _fetchTrafficReports({bool forceRefresh = false}) async {
    try {
      if (widget.routes.isEmpty) {
        setState(() {
          _trafficData = null;
          _trafficError = null;
        });
        return;
      }

      setState(() {
        _isLoadingTraffic = true;
        _trafficError = null;
      });

      // Use the traffic analytics service to fetch data
      // forceRefresh bypasses cache if set to true
      final trafficResponse = await _analyticsService.getTodayTrafficAnalytics(
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _trafficData = trafficResponse;
          _isLoadingTraffic = false;
          if (trafficResponse == null) {
            _trafficError = 'Unable to load traffic data';
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching traffic analytics: $e');
      if (mounted) {
        setState(() {
          _isLoadingTraffic = false;
          _trafficError = 'Failed to load traffic insights: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grab handle
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 20),
                // Title with info button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Traffic Analytics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (_trafficData != null) ...[
                          Text(
                            'Today, ${_trafficData!.date.day}/${_trafficData!.date.month}/${_trafficData!.date.year}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Inter',
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          if (_trafficData!.mode != null)
                            Text(
                              'Source: ${_trafficData!.mode}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          if (_analyticsService.hasCachedData())
                            Text(
                              _getCacheStatusText(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Inter',
                                color: isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[500],
                              ),
                            ),
                        ],
                      ],
                    ),
                    IconButton(
                      onPressed: () => _showInfoDialog(context, isDarkMode),
                      icon: Icon(
                        Icons.info_outline,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 24,
                      ),
                      tooltip: 'How it works',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Content
                Flexible(child: _buildTrafficInsightsContent(isDarkMode)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: const Color(0xFF00CC58),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'How Traffic Analytics Work',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoSection(
                  'Real-time Data Collection',
                  'Our system continuously monitors passenger density, vehicle speeds, and route patterns to provide accurate traffic insights.',
                  Icons.sensors,
                  isDarkMode,
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  'Traffic Density Analysis',
                  'Traffic levels are calculated based on passenger count and vehicle capacity:\n• Light: 0-40% capacity\n• Moderate: 40-70% capacity\n• Heavy: 70%+ capacity',
                  Icons.traffic,
                  isDarkMode,
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  'AI-Powered Insights',
                  'AI analyzes historical patterns and current conditions to predict traffic trends and provide actionable recommendations.',
                  Icons.psychology,
                  isDarkMode,
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  'Live Updates',
                  'Traffic insights are refreshed automatically to ensure you have the most current information for your journey planning.',
                  Icons.update,
                  isDarkMode,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00CC58),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoSection(
      String title, String description, IconData icon, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00CC58).withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF00CC58),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrafficInsightsContent(bool isDarkMode) {
    final Color textSecondary =
        isDarkMode ? Colors.grey[300]! : Colors.grey[700]!;

    if (_isLoadingTraffic) {
      return Expanded(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode
                      ? const Color(0xFF00CC58)
                      : const Color(0xFF00CC58),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Fetching live traffic insights...',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_trafficError != null) {
      return Expanded(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                _trafficError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _fetchTrafficReports,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00CC58),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_trafficData == null || _trafficData!.routes.isEmpty) {
      return Expanded(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No traffic analytics available yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => _fetchTrafficReports(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00CC58),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Build list of routes that have traffic data using normalized name matching
    final routesWithData = widget.filteredRoutes.where((route) {
      final routeName = route['route_name']?.toString() ?? '';
      return _findAnalyticsRouteByName(routeName) != null;
    }).toList();

    if (routesWithData.isEmpty) {
      // Fallback: show all analytics routes to verify data flow
      final analyticsRoutes = _trafficData!.routes;
      return Expanded(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: analyticsRoutes.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 48,
                      color: textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No analytics data for displayed routes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Data is being collected.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: textSecondary,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  itemCount: analyticsRoutes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildTrafficCard(
                        analyticsRoutes[index], isDarkMode);
                  },
                ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: () => _fetchTrafficReports(forceRefresh: true),
        color: const Color(0xFF00CC58),
        child: ListView.separated(
          itemCount: routesWithData.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final String routeName =
                routesWithData[index]['route_name']?.toString() ??
                    'Unknown Route';
            final RouteTrafficToday? trafficData =
                _findAnalyticsRouteByName(routeName);

            if (trafficData == null) {
              return const SizedBox.shrink();
            }

            return _buildTrafficCard(trafficData, isDarkMode);
          },
        ),
      ),
    );
  }

  // Normalize strings for looser matching between DB route names and analytics route names
  String _normalizeName(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[-_/]'), '')
        .trim();
  }

  RouteTrafficToday? _findAnalyticsRouteByName(String name) {
    if (_trafficData == null) return null;
    final normalized = _normalizeName(name);
    try {
      return _trafficData!.routes.firstWhere((r) =>
          _normalizeName(r.routeName) == normalized ||
          _normalizeName(r.routeName).contains(normalized) ||
          normalized.contains(_normalizeName(r.routeName)));
    } catch (_) {
      return _trafficData!.getRouteByName(name);
    }
  }

  Widget _buildTrafficCard(RouteTrafficToday trafficData, bool isDarkMode) {
    // Map traffic status to color
    Color statusColor;
    switch (trafficData.currentStatus) {
      case TrafficStatus.low:
        statusColor = const Color(0xFF00CC58); // Green
        break;
      case TrafficStatus.moderate:
        statusColor = const Color(0xFFFF9800); // Orange
        break;
      case TrafficStatus.high:
        statusColor = const Color(0xFFFF5722); // Red
        break;
      case TrafficStatus.severe:
        statusColor = const Color(0xFFD32F2F); // Dark Red
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800]! : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDarkMode ? 20 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.route,
                size: 20,
                color: const Color(0xFF00CC58),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trafficData.routeName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withAlpha(30)),
                ),
                child: Text(
                  trafficData.currentStatus.displayName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            trafficData.summary,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDarkMode ? Colors.grey[300]! : Colors.grey[700]!,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // Additional metrics row
          Row(
            children: [
              _buildMetricChip(
                icon: Icons.speed,
                label: '${trafficData.avgSpeedKmh.toStringAsFixed(1)} km/h',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(width: 8),
              _buildMetricChip(
                icon: Icons.insert_chart,
                label: '${trafficData.densityPercentage}% density',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(width: 8),
              _buildMetricChip(
                icon: Icons.access_time,
                label: 'Peak: ${trafficData.peakTrafficTime}',
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey[700]!.withAlpha(50)
            : Colors.grey[200]!.withAlpha(100),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Get cache status text for display
  String _getCacheStatusText() {
    final cacheTime = _analyticsService.getCacheTimeRemaining();
    if (cacheTime == null) return '';

    final minutes = cacheTime.inMinutes;
    final seconds = cacheTime.inSeconds % 60;

    if (minutes > 0) {
      return 'Cached • Updates in ${minutes}m';
    } else if (seconds > 0) {
      return 'Cached • Updates in ${seconds}s';
    } else {
      return 'Updating...';
    }
  }
}

/// Helper function to show the traffic insights bottom sheet
Future<void> showTrafficInsightsSheet(
  BuildContext context,
  List<Map<String, dynamic>> routes,
  List<Map<String, dynamic>> filteredRoutes,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => TrafficInsightsSheet(
      routes: routes,
      filteredRoutes: filteredRoutes,
    ),
  );
}
