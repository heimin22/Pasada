import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_passenger_app/location/recentSearch.dart';
import 'package:pasada_passenger_app/models/stop.dart';

import 'distance_helper.dart';

/// Helper class for building UI components
class UIComponentsHelper {
  final DistanceHelper _distanceHelper = DistanceHelper();

  /// Build recent search tile
  Widget buildRecentSearchTile(
    RecentSearch search,
    bool isDarkMode,
    LatLng? currentLocation,
    VoidCallback onTap, {
    double? precomputedDistance,
  }) {
    // Use pre-computed distance if provided, otherwise calculate (fallback)
    final distance = precomputedDistance ??
        (currentLocation != null
            ? _distanceHelper.getCachedDistance(
                currentLocation, search.coordinates)
            : null);

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isDarkMode ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // History icon container - aligned to center
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00CC58).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.history,
                    size: 16,
                    color: Color(0xFF00CC58),
                  ),
                ),
                const SizedBox(width: 12),
                // Address and distance section - expandable
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        search.address,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode
                              ? const Color(0xFFF5F5F5)
                              : const Color(0xFF121212),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (distance != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: const Color(0xFF00CC58),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(distance / 1000).toStringAsFixed(1)} km away',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: Color(0xFF00CC58),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Chevron icon - aligned to center
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: isDarkMode
                      ? const Color(0xFFAAAAAA)
                      : const Color(0xFF666666),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build stop tile
  Widget buildStopTile(
    Stop stop,
    bool isDarkMode,
    LatLng? currentLocation,
    VoidCallback onTap, {
    double? precomputedDistance,
  }) {
    // Use pre-computed distance if provided, otherwise calculate (fallback)
    final distance = precomputedDistance ??
        (currentLocation != null
            ? _distanceHelper.getCachedDistance(
                currentLocation, stop.coordinates)
            : null);

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDarkMode ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Stop number container - aligned to center
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00CC58).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${stop.order}',
                      style: const TextStyle(
                        color: Color(0xFF00CC58),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Title and subtitle section - expandable
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stop.name,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? const Color(0xFFF5F5F5)
                              : const Color(0xFF121212),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stop.address,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: isDarkMode
                              ? const Color(0xFFAAAAAA)
                              : const Color(0xFF666666),
                        ),
                      ),
                      if (distance != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: const Color(0xFF00CC58),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(distance / 1000).toStringAsFixed(1)} km away',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Color(0xFF00CC58),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Chevron icon - aligned to center
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDarkMode
                      ? const Color(0xFFAAAAAA)
                      : const Color(0xFF666666),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build lazy loading list for performance with large datasets
  Widget buildLazyStopList(
    List<Stop> stops,
    bool isDarkMode,
    LatLng? currentLocation,
    Function(Stop) onStopSelected,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      cacheExtent: 300.0, // Pre-render stops above/below viewport
      // Removed fixed itemExtent to allow dynamic height based on content
      itemCount: stops.length,
      itemBuilder: (context, index) {
        return buildStopTile(
          stops[index],
          isDarkMode,
          currentLocation,
          () => onStopSelected(stops[index]),
        );
      },
    );
  }

  /// Build sort menu items
  List<PopupMenuEntry<String>> buildSortMenuItems(String currentSortOption) {
    return [
      PopupMenuItem<String>(
        value: 'order',
        child: Row(
          children: [
            Icon(
              Icons.route,
              size: 16,
              color:
                  currentSortOption == 'order' ? const Color(0xFF00CC58) : null,
            ),
            const SizedBox(width: 8),
            Text(
              'Sort by Route Order',
              style: TextStyle(
                color: currentSortOption == 'order'
                    ? const Color(0xFF00CC58)
                    : null,
                fontWeight: currentSortOption == 'order'
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'name',
        child: Row(
          children: [
            Icon(
              Icons.sort_by_alpha,
              size: 16,
              color:
                  currentSortOption == 'name' ? const Color(0xFF00CC58) : null,
            ),
            const SizedBox(width: 8),
            Text(
              'Sort by Name',
              style: TextStyle(
                color: currentSortOption == 'name'
                    ? const Color(0xFF00CC58)
                    : null,
                fontWeight: currentSortOption == 'name'
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'distance',
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: currentSortOption == 'distance'
                  ? const Color(0xFF00CC58)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              'Sort by Distance',
              style: TextStyle(
                color: currentSortOption == 'distance'
                    ? const Color(0xFF00CC58)
                    : null,
                fontWeight: currentSortOption == 'distance'
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
