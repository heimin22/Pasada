import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pasada_passenger_app/screens/selectionScreen.dart';
import 'package:pasada_passenger_app/screens/viewRideDetailsScreen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pasada_passenger_app/widgets/circle_painter.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CompletedRideScreen(arrivedTime: DateTime.now()),
  ));
}

class CompletedRideScreen extends StatefulWidget {
  final DateTime arrivedTime;
  const CompletedRideScreen({super.key, required this.arrivedTime});

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
      Navigator.pop(context);
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      Fluttertoast.showToast(
        msg: 'Could not launch email',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
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
                  builder: (_, child) {
                    return CustomPaint(
                      painter: CirclePainter(progress: _circleAnimation.value),
                      child: Center(
                        child: Opacity(
                          opacity: _checkAnimation.value,
                          child: Transform.scale(
                            scale: _checkAnimation.value,
                            child: const Icon(Icons.check,
                                size: 60, color: Colors.green),
                          ),
                        ),
                      ),
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
                        builder: (_) => const ViewRideDetailsScreen()),
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
            ],
          ),
        ),
      ),
    );
  }
}
