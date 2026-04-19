import 'package:flutter/material.dart';
import 'base_app.dart';
import '../config/theme_config.dart';
import '../services/weather_data_store.dart';

class WeatherApp extends BaseApp {
  const WeatherApp({super.key});

  @override
  String get appName => 'Weather';

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  final WeatherDataStore _weatherStore = WeatherDataStore.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _weatherStore,
      builder: (context, _) {
        final weather = _weatherStore.snapshot;

        return Container(
          color: EarthyTheme.surface,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (weather.iconUrl.isNotEmpty)
                  Image.network(
                    weather.iconUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.wb_sunny_rounded,
                      size: 100,
                      color: EarthyTheme.sandstone,
                    ),
                  )
                else
                  Icon(
                    Icons.wb_sunny_rounded,
                    size: 100,
                    color: EarthyTheme.sandstone,
                  ),
                const SizedBox(height: 20),
                Text(
                  weather.temperature,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: EarthyTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  weather.condition,
                  style: TextStyle(
                    fontSize: 20,
                    color: EarthyTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  weather.location,
                  style: TextStyle(
                    fontSize: 16,
                    color: EarthyTheme.bark,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
