import 'package:flutter/material.dart';

class CheckPainter extends CustomPainter {
  final double progress;

  CheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF00CC58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.7);
    path.lineTo(size.width * 0.8, size.height * 0.3);

    final metrics = path.computeMetrics();
    final totalLength =
        metrics.fold(0.0, (double prev, metric) => prev + metric.length);
    final drawLength = totalLength * progress;

    double currentLength = 0.0;
    final Path extractPath = Path();
    for (final metric in metrics) {
      final nextLength = currentLength + metric.length;
      if (drawLength > currentLength) {
        final length = (drawLength < nextLength)
            ? drawLength - currentLength
            : metric.length;
        extractPath.addPath(metric.extractPath(0, length), Offset.zero);
      }
      currentLength = nextLength;
    }

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
