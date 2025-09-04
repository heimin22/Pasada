import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/widgets/route_selection_widget.dart';
import 'package:pasada_passenger_app/widgets/home_weather_widget.dart';

/// Header section containing route selection and weather display
class HomeHeaderSection extends StatelessWidget {
  final AnimationController bookingAnimationController;
  final Animation<double> downwardAnimation;
  final String routeName;
  final VoidCallback onRouteSelectionTap;
  final double weatherIconSize;

  const HomeHeaderSection({
    super.key,
    required this.bookingAnimationController,
    required this.downwardAnimation,
    required this.routeName,
    required this.onRouteSelectionTap,
    required this.weatherIconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: bookingAnimationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -downwardAnimation.value),
              child: Opacity(
                opacity: 1 - bookingAnimationController.value,
                child: RouteSelectionWidget(
                  routeName: routeName,
                  onTap: onRouteSelectionTap,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        HomeWeatherWidget(size: weatherIconSize),
      ],
    );
  }
}
