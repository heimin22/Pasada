import 'package:flutter/material.dart';

class BoundsFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final Color borderColor;
  final double elevation;
  final double iconSize;
  final double buttonSize;
  final Object? heroTag;

  const BoundsFAB({
    super.key,
    required this.onPressed,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.iconColor = const Color(0xFF00CC58),
    this.borderColor = const Color(0xFF00CC58),
    this.elevation = 3.0,
    this.iconSize = 28,
    this.buttonSize = 56,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ElevatedButton.styleFrom(
      elevation: elevation,
      padding: EdgeInsets.zero,
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: 2),
      ),
    );

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Hero(
        tag: heroTag ?? UniqueKey(),
        child: ElevatedButton(
          onPressed: onPressed,
          style: style,
          child: Icon(Icons.zoom_out_map, size: iconSize, color: iconColor),
        ),
      ),
    );
  }
}
