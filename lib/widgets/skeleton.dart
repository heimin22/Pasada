import 'package:flutter/material.dart';

class SkeletonBlock extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBlock({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: .35, end: .65).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE6E6E6);

    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;
  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SkeletonBlock(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }
}

class SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  const SkeletonLine({super.key, required this.width, this.height = 14});

  @override
  Widget build(BuildContext context) {
    return SkeletonBlock(width: width, height: height);
  }
}

class ProfileHeaderSkeleton extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;

  const ProfileHeaderSkeleton({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final avatarSize =
        (screenWidth < screenHeight ? screenWidth : screenHeight) * 0.23;

    return Container(
      width: double.infinity,
      color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.06,
        vertical: screenHeight * 0.06,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SkeletonCircle(size: avatarSize),
          SizedBox(width: screenWidth * 0.08),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.008),
              SkeletonLine(width: screenWidth * 0.45, height: 24),
              SizedBox(height: screenHeight * 0.012),
              SkeletonLine(width: screenWidth * 0.25, height: 16),
            ],
          )
        ],
      ),
    );
  }
}

class ListItemSkeleton extends StatelessWidget {
  final double screenWidth;
  final double leadingSize;
  final double titleWidthFraction; // 0..1
  final double subtitleWidthFraction; // 0..1
  final EdgeInsets padding;

  const ListItemSkeleton({
    super.key,
    required this.screenWidth,
    this.leadingSize = 48,
    this.titleWidthFraction = 0.6,
    this.subtitleWidthFraction = 0.4,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SkeletonCircle(size: leadingSize),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(
                    width: screenWidth * titleWidthFraction, height: 16),
                const SizedBox(height: 8),
                SkeletonLine(
                    width: screenWidth * subtitleWidthFraction, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final double screenWidth;
  final EdgeInsets itemPadding;

  const ListSkeleton({
    super.key,
    required this.itemCount,
    required this.screenWidth,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => ListItemSkeleton(
        screenWidth: screenWidth,
        padding: itemPadding,
      ),
    );
  }
}
