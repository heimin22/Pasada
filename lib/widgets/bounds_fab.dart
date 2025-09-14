import 'package:flutter/material.dart';

class BoundsFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final double elevation;
  final double iconSize;
  final double buttonSize;
  final Object? heroTag;

  const BoundsFAB({
    super.key,
    required this.onPressed,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.iconColor = const Color(0xFF00CC58),
    this.elevation = 4.0,
    this.iconSize = 24,
    this.buttonSize = 48,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag ?? UniqueKey(),
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      elevation: elevation,
      mini: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.zoom_out_map, size: iconSize, color: iconColor),
    );
  }
}
