import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/location/locationButton.dart'; // Corrected import path
import 'package:pasada_passenger_app/widgets/bounds_fab.dart';

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
  final String bookingStatus; // Booking status to show bounds button
  final bool isBookingConfirmed; // Check if booking is confirmed

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
    required this.bookingStatus,
    required this.isBookingConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    // Check if bounds button should be shown
    final shouldShowBoundsButton = isBookingConfirmed &&
        (bookingStatus == 'accepted' || bookingStatus == 'ongoing');

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
              child: shouldShowBoundsButton
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bounds button
                        BoundsFAB(
                          heroTag: "homeBoundsFAB",
                          onPressed: () {
                            (mapScreenKey.currentState as dynamic)
                                ?.showDriverFocusBounds(bookingStatus);
                          },
                          iconSize: iconSize,
                          buttonSize: MediaQuery.of(context).size.width * 0.12,
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF1E1E1E)
                                  : const Color(0xFFF5F5F5),
                          iconColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF00E865)
                                  : const Color(0xFF00CC58),
                        ),
                        SizedBox(height: fabVerticalSpacing * 0.5),
                        // Location button
                        LocationFAB(
                          heroTag: "homeLocationFAB",
                          onPressed: onPressed,
                          iconSize: iconSize,
                          buttonSize: MediaQuery.of(context).size.width * 0.12,
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF1E1E1E)
                                  : const Color(0xFFF5F5F5),
                          iconColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF00E865)
                                  : const Color(0xFF00CC58),
                        ),
                      ],
                    )
                  : LocationFAB(
                      heroTag: "homeLocationFAB",
                      onPressed: onPressed,
                      iconSize: iconSize,
                      buttonSize: MediaQuery.of(context).size.width * 0.12,
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
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
