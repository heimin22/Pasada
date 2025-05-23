import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/location/locationButton.dart'; // Corrected import path

class HomeScreenFAB extends StatelessWidget {
  final GlobalKey<State<StatefulWidget>>
      mapScreenKey; // To interact with MapScreenState
  final Animation<double> downwardAnimation;
  final Animation<double> bookingAnimationControllerValue;
  final double responsivePadding;
  final double fabVerticalSpacing;
  final double iconSize;
  final VoidCallback onPressed;
  final double bottomOffset; // New property to control bottom positioning

  const HomeScreenFAB({
    super.key,
    required this.mapScreenKey,
    required this.downwardAnimation,
    required this.bookingAnimationControllerValue,
    required this.responsivePadding,
    required this.fabVerticalSpacing,
    required this.iconSize,
    required this.onPressed,
    required this.bottomOffset, // Initialize in constructor
  });

  @override
  Widget build(BuildContext context) {
    // Access MapScreenState - specific to your implementation
    // dynamic mapState = mapScreenKey.currentState;

    return Positioned(
      right: responsivePadding,
      bottom:
          bottomOffset + fabVerticalSpacing, // Use bottomOffset for positioning
      child: AnimatedBuilder(
        animation:
            downwardAnimation, // Listen to the specific animation for this FAB
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, downwardAnimation.value),
            child: Opacity(
              opacity: 1 - bookingAnimationControllerValue.value,
              child: LocationFAB(
                heroTag: "homeLocationFAB",
                onPressed: onPressed,
                iconSize: iconSize,
                buttonSize: MediaQuery.of(context).size.width * 0.12,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFF5F5F5),
                iconColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF00E865)
                    : const Color(0xFF00CC58),
              ),
            ),
          );
        },
      ),
    );
  }
}
