import 'package:flutter/material.dart';
import 'base_app.dart';
import '../config/theme_config.dart';

class WeatherApp extends BaseApp {
  const WeatherApp({super.key});

  @override
  String get appName => 'Weather';

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: EarthyTheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wb_sunny_rounded,
              size: 100,
              color: EarthyTheme.sandstone,
            ),
            const SizedBox(height: 20),
            Text(
              '72°F',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: EarthyTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Partly Cloudy',
              style: TextStyle(
                fontSize: 20,
                color: EarthyTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
