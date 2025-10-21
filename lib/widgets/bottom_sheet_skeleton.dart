import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/widgets/skeleton.dart';

/// Skeleton loading widget for the bottom sheet content
class BottomSheetSkeleton extends StatelessWidget {
  final double screenWidth;
  final double responsivePadding;
  final double iconSize;

  const BottomSheetSkeleton({
    super.key,
    required this.screenWidth,
    required this.responsivePadding,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Skeleton content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsivePadding,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route selection skeleton
                Row(
                  children: [
                    SkeletonCircle(size: iconSize),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: screenWidth * 0.6, height: 16),
                          const SizedBox(height: 4),
                          SkeletonLine(width: screenWidth * 0.4, height: 14),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Pickup location skeleton
                Row(
                  children: [
                    SkeletonCircle(size: iconSize),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: screenWidth * 0.5, height: 16),
                          const SizedBox(height: 4),
                          SkeletonLine(width: screenWidth * 0.7, height: 14),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Dropoff location skeleton
                Row(
                  children: [
                    SkeletonCircle(size: iconSize),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: screenWidth * 0.5, height: 16),
                          const SizedBox(height: 4),
                          SkeletonLine(width: screenWidth * 0.7, height: 14),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Fare and payment skeleton
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(width: screenWidth * 0.3, height: 14),
                        const SizedBox(height: 8),
                        SkeletonLine(width: screenWidth * 0.2, height: 16),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SkeletonLine(width: screenWidth * 0.4, height: 14),
                        const SizedBox(height: 8),
                        SkeletonLine(width: screenWidth * 0.3, height: 16),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Action buttons skeleton
                Row(
                  children: [
                    Expanded(
                      child: SkeletonBlock(
                        width: double.infinity,
                        height: 48,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SkeletonBlock(
                        width: double.infinity,
                        height: 48,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
