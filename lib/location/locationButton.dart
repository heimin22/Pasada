import 'package:flutter/material.dart';

class LocationFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double elevation;
  final double iconSize;
  final double buttonSize;

  const LocationFAB({
    super.key,
    required this.onPressed,
    this.icon = Icons.gps_fixed,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.blue,
    this.elevation = 4.0,
    this.iconSize = 24,
    this.buttonSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      elevation: elevation,
      mini: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.gps_fixed, size: iconSize, color: iconColor),
    );
  }
}
