import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pasada_passenger_app/providers/weather_provider.dart';
import 'package:pasada_passenger_app/services/location_weather_service.dart';
import 'package:pasada_passenger_app/widgets/optimized_cached_image.dart';

/// Weather display widget for the home screen
class HomeWeatherWidget extends StatelessWidget {
  final double size;

  const HomeWeatherWidget({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProv, _) {
        if (weatherProv.isLoading) {
          return SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF00CC58),
            ),
          );
        } else if (weatherProv.hasError) {
          return GestureDetector(
            onTap: weatherProv.canRetry ? () async {
              await weatherProv.retryFetch();
            } : null,
            child: Tooltip(
              message: weatherProv.canRetry 
                ? 'Tap to retry weather loading' 
                : weatherProv.error ?? 'Weather unavailable',
              child: Icon(
                Icons.refresh,
                size: size,
                color: weatherProv.canRetry 
                  ? Color(0xFF00CC58) 
                  : Colors.grey,
              ),
            ),
          );
        } else if (weatherProv.weather != null) {
          return GestureDetector(
            onTap: () async {
              await weatherProv.refreshWeather();
            },
            child: Tooltip(
              message: 'Tap to refresh weather\n${weatherProv.weather!.condition}',
              child: OptimizedCachedImage.thumbnail(
                imageUrl: weatherProv.weather!.iconUrl,
                size: size,
                placeholder: SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00CC58),
                  ),
                ),
                errorWidget: Icon(
                  Icons.cloud_off,
                  size: size,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        } else {
          return GestureDetector(
            onTap: () async {
              // Try the weather provider's built-in initialization first
              final initialized = await weatherProv.initializeWeatherService();
              if (!initialized) {
                // Fallback to the location weather service
                await LocationWeatherService.refreshWeatherNow(weatherProv);
              }
            },
            child: Tooltip(
              message: 'Tap to load weather',
              child: Icon(
                Icons.cloud_queue,
                size: size,
                color: Colors.grey,
              ),
            ),
          );
        }
      },
    );
  }
}
