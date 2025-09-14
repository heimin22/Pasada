import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/screens/selectionScreen.dart';
import 'package:pasada_passenger_app/screens/viewRideDetailsScreen.dart';
import 'package:pasada_passenger_app/widgets/check_painter.dart';
import 'package:pasada_passenger_app/widgets/circle_painter.dart';
import 'package:url_launcher/url_launcher.dart';

class CompletedRideScreen extends StatefulWidget {
  final DateTime arrivedTime;
  final int bookingId;
  const CompletedRideScreen(
      {super.key, required this.arrivedTime, required this.bookingId});

  @override
  State<CompletedRideScreen> createState() => _CompletedRideScreenState();
}

class _CompletedRideScreenState extends State<CompletedRideScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _circleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'contact.pasada@gmail.com',
      queryParameters: {
        'subject': 'Trip Feedback',
      },
    );
    final bool launched = await launchUrl(
      emailUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      Fluttertoast.showToast(
        msg: 'Could not launch email client.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xFF121212),
        textColor: const Color(0xFFF5F5F5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(widget.arrivedTime);
    final formattedTime = time.format(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF121212),
                  ]
                : [
                    const Color(0xFFF8F9FA),
                    const Color(0xFFE9ECEF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color:
                            isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 20),
                        color:
                            isDarkMode ? Color(0xFFF5F5F5) : Color(0xFF121212),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const selectionScreen()),
                          );
                        },
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color:
                            isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton.icon(
                        onPressed: _launchEmail,
                        icon: const Icon(Icons.support_agent, size: 18),
                        label: const Text(
                          'Support',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: isDarkMode
                              ? Color(0xFFF5F5F5)
                              : Color(0xFF121212),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Animation Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          // Animated Success Icon
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF00CC58).withAlpha(10),
                                  const Color(0xFF00CC58).withAlpha(5),
                                ],
                              ),
                            ),
                            child: AnimatedBuilder(
                              animation: _controller,
                              builder: (_, __) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer glow effect
                                    AnimatedScale(
                                      scale:
                                          0.8 + (_circleAnimation.value * 0.2),
                                      duration:
                                          const Duration(milliseconds: 100),
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF00CC58)
                                              .withAlpha(20),
                                        ),
                                      ),
                                    ),
                                    // Circle and check
                                    SizedBox(
                                      width: 120,
                                      height: 120,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CustomPaint(
                                            painter: CirclePainter(
                                                progress:
                                                    _circleAnimation.value),
                                            size: const Size(120, 120),
                                          ),
                                          CustomPaint(
                                            painter: CheckPainter(
                                                progress:
                                                    _checkAnimation.value),
                                            size: const Size(120, 120),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Success Text
                          AnimatedBuilder(
                            animation: _circleAnimation,
                            builder: (context, child) {
                              return AnimatedOpacity(
                                opacity:
                                    _circleAnimation.value >= 0.8 ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 500),
                                child: Column(
                                  children: [
                                    Text(
                                      'Arrived Successfully!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 32,
                                        color: isDarkMode
                                            ? Color(0xFFF5F5F5)
                                            : Color(0xFF121212),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'You have safely arrived at your destination',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 16,
                                        color: isDarkMode
                                            ? Color(0xFFF5F5F5)
                                            : Color(0xFF121212),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Trip Info
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF00CC58).withAlpha(20),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule,
                            color: const Color(0xFF00CC58),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Arrived at $formattedTime',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: isDarkMode
                                  ? Color(0xFFF5F5F5)
                                  : Color(0xFF121212),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          // View Receipt Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF00CC58),
                                width: 2,
                              ),
                            ),
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ViewRideDetailsScreen(
                                        bookingId: widget.bookingId),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.receipt_long, size: 20),
                              label: const Text(
                                'View Trip Receipt',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF00CC58),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Home Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00CC58), Color(0xFF00A047)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const selectionScreen()),
                                );
                              },
                              icon: const Icon(Icons.home, size: 20),
                              label: const Text(
                                'Back to Home',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Color(0xFFF5F5F5),
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
