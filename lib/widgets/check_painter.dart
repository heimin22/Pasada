import 'package:flutter/material.dart';

class CheckPainter extends CustomPainter {
  final double progress;

  CheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final Paint paint = Paint()
      ..color = const Color(0xFF00CC58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Center the checkmark in the canvas
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.width / 120; // Scale based on canvas size

    // Simple animated checkmark - draw strokes based on progress
    if (progress >= 0.3) {
      // First stroke (left part of check)
      final firstStrokeProgress = ((progress - 0.3) / 0.35).clamp(0.0, 1.0);
      final startX = centerX - 15 * scale;
      final startY = centerY;
      final midX = centerX - 5 * scale;
      final midY = centerY + 10 * scale;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(
          startX + (midX - startX) * firstStrokeProgress,
          startY + (midY - startY) * firstStrokeProgress,
        ),
        paint,
      );
    }

    if (progress >= 0.65) {
      // Second stroke (right part of check)
      final secondStrokeProgress = ((progress - 0.65) / 0.35).clamp(0.0, 1.0);
      final midX = centerX - 5 * scale;
      final midY = centerY + 10 * scale;
      final endX = centerX + 20 * scale;
      final endY = centerY - 15 * scale;

      canvas.drawLine(
        Offset(midX, midY),
        Offset(
          midX + (endX - midX) * secondStrokeProgress,
          midY + (endY - midY) * secondStrokeProgress,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
