import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pasada_passenger_app/network/networkUtilities.dart';

/// Bottom sheet widget for displaying AI traffic insights
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
  Map<String, dynamic> _trafficReports = {};
  bool _isLoadingTraffic = false;
  String? _trafficError;

  @override
  void initState() {
    super.initState();
    _fetchTrafficReports();
  }

  Future<void> _fetchTrafficReports() async {
    try {
      final String? apiUrl = dotenv.env['API_URL'];
      if (apiUrl == null || apiUrl.isEmpty) {
        setState(() {
          _trafficError = 'API_URL not configured';
        });
        return;
      }

      if (widget.routes.isEmpty) {
        setState(() {
          _trafficReports = {};
          _trafficError = null;
        });
        return;
      }

      setState(() {
        _isLoadingTraffic = true;
        _trafficError = null;
      });

      final uri = Uri.parse('$apiUrl/api/analytics/summaries');
      final headers = {
        'Content-Type': 'application/json',
      };

      final response = await NetworkUtility.fetchUrl(uri, headers: headers);

      if (response == null) {
        if (mounted) {
          setState(() {
            _isLoadingTraffic = false;
            _trafficError = 'No response from traffic service';
          });
        }
        return;
      }

      final dynamic data = json.decode(response);

      Map<String, dynamic> reports = {};

      if (data is List) {
        for (final item in data) {
          final String routeName =
              item['routeName']?.toString() ?? 'Unknown Route';
          final String summary =
              item['summary']?.toString() ?? 'No traffic data available';
          final double density = (item['averageDensity'] ?? 0.0).toDouble();

          final densityPercentage = (density * 100).round();
          final densityText = densityPercentage > 70
              ? 'Heavy'
              : densityPercentage > 40
                  ? 'Moderate'
                  : 'Light';

          reports[routeName] =
              '$densityText traffic ($densityPercentage%). $summary';
        }
      }

      if (mounted) {
        setState(() {
          _trafficReports = reports;
          _isLoadingTraffic = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching AI traffic reports: $e');
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
        maxHeight: MediaQuery.of(context).size.height * 0.5,
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
                    Text(
                      'AI Traffic Insights',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
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

    if (_trafficReports.isEmpty) {
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
                'No traffic insights available yet.',
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

    return Expanded(
      child: ListView.separated(
        itemCount: widget.filteredRoutes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final String routeName =
              widget.filteredRoutes[index]['route_name']?.toString() ??
                  'Unknown Route';
          final dynamic reportValue = _trafficReports[routeName] ??
              _trafficReports[routeName.toLowerCase()] ??
              _trafficReports[routeName.toUpperCase()];
          final String reportText =
              reportValue?.toString() ?? 'No current traffic report.';

          return _buildTrafficCard(routeName, reportText, isDarkMode);
        },
      ),
    );
  }

  Widget _buildTrafficCard(
      String routeName, String reportText, bool isDarkMode) {
    // Extract traffic density for color coding
    String densityLevel = 'Light';
    Color statusColor = const Color(0xFF00CC58); // Green for light traffic

    if (reportText.toLowerCase().contains('heavy')) {
      densityLevel = 'Heavy';
      statusColor = const Color(0xFFFF5722); // Red for heavy traffic
    } else if (reportText.toLowerCase().contains('moderate')) {
      densityLevel = 'Moderate';
      statusColor = const Color(0xFFFF9800); // Orange for moderate traffic
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
                  routeName,
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
                  densityLevel,
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
            reportText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDarkMode ? Colors.grey[300]! : Colors.grey[700]!,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
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
