import 'package:flutter/material.dart';

class NotificationContainer extends StatefulWidget {
  final Animation<double> downwardAnimation;
  final double notificationHeight;
  final VoidCallback onClose;

  const NotificationContainer({
    super.key,
    required this.downwardAnimation,
    required this.notificationHeight,
    required this.onClose,
  });

  @override
  _NotificationContainerState createState() => _NotificationContainerState();
}

class _NotificationContainerState extends State<NotificationContainer> {
  double _dragOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: widget.downwardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              0, widget.downwardAnimation.value * widget.notificationHeight),
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              // Only allow downward drags (positive dy) and clamp offset
              if (details.delta.dy > 0) {
                setState(() {
                  _dragOffset = (_dragOffset + details.delta.dy)
                      .clamp(0.0, widget.notificationHeight);
                  if (_dragOffset >= widget.notificationHeight) {
                    _dragOffset = 0.0;
                    widget.onClose();
                  }
                });
              }
            },
            onVerticalDragEnd: (details) {
              if (_dragOffset < widget.notificationHeight / 2) {
                setState(() => _dragOffset = 0.0);
              }
            },
            child: Container(
              height: widget.notificationHeight - _dragOffset,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: MediaQuery.of(context).size.width * 0.03,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_outlined,
                            color: const Color(0xFF00CC58), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please select a route before choosing locations',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFF121212),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: Icon(Icons.close, color: const Color(0xFF00CC58)),
                        onPressed: widget.onClose,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
