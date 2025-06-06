import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pasada_passenger_app/screens/selectionScreen.dart';
import 'package:pasada_passenger_app/screens/viewRideDetailsScreen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/widgets/circle_painter.dart';
import 'package:pasada_passenger_app/widgets/check_painter.dart';

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
      duration: const Duration(seconds: 2),
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
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
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
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      Fluttertoast.showToast(
        msg: 'Could not launch email',
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

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor:
              isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
          foregroundColor:
              isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          elevation: 1.0,
          leadingWidth: 60,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios,
                  color: isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212)),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const selectionScreen()),
                );
              },
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: TextButton(
                onPressed: _launchEmail,
                child: Text(
                  'Contact Support',
                  style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      color: isDarkMode
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFF121212),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          painter:
                              CirclePainter(progress: _circleAnimation.value),
                          size: const Size(120, 120),
                        ),
                        CustomPaint(
                          painter:
                              CheckPainter(progress: _checkAnimation.value),
                          size: const Size(120, 120),
                        ),
                        Opacity(
                          opacity: _checkAnimation.value,
                          child: Transform.scale(
                            scale: _checkAnimation.value,
                            child: const Icon(
                              Icons.check,
                              size: 60,
                              color: Color(0xFF00CC58),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Arrived\nSuccessfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 30,
                    color: isDarkMode
                        ? const Color(0xFFF5F5F5)
                        : const Color(0xFF121212)),
              ),
              const SizedBox(height: 12),
              Text(
                'Arrived at $formattedTime',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ViewRideDetailsScreen(bookingId: widget.bookingId)),
                  );
                },
                child: Text(
                  'View Ride Receipt',
                  style: TextStyle(
                      decoration: TextDecoration.underline,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDarkMode
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFF121212)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const selectionScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F5F5),
                  foregroundColor: const Color(0xFF00CC58),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
