import 'package:flutter/material.dart';

class DiscountLoadingScreen extends StatelessWidget {
  final String discountType;

  const DiscountLoadingScreen({
    super.key,
    required this.discountType,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: (isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5))
            .withAlpha(0.95.toInt()),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Loading animation
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(0.1.toInt()),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated loading indicator
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF00CC58)),
                        strokeWidth: 4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Success icon with discount type
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user,
                          color: const Color(0xFF00CC58),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$discountType ID Verified',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode
                                ? const Color(0xFFF5F5F5)
                                : const Color(0xFF121212),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Loading message
                    Text(
                      'Applying 20% discount...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF00CC58),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'Please wait while we update your fare',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? const Color(0xFFAAAAAA)
                            : const Color(0xFF666666),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Progress dots animation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 3; i++)
                    AnimatedProgressDot(
                      delay: Duration(milliseconds: i * 200),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedProgressDot extends StatefulWidget {
  final Duration delay;

  const AnimatedProgressDot({
    super.key,
    required this.delay,
  });

  @override
  State<AnimatedProgressDot> createState() => _AnimatedProgressDotState();
}

class _AnimatedProgressDotState extends State<AnimatedProgressDot>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF00CC58).withAlpha(_animation.value.toInt()),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}
