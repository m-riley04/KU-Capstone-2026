import 'package:flutter/material.dart';
import 'package:weather_animation/weather_animation.dart';

import 'base_app.dart';
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

  WeatherScene _sceneForCondition(String condition) {
    final normalized = condition.toLowerCase();

    if (normalized.contains('storm') ||
        normalized.contains('thunder') ||
        normalized.contains('lightning') ||
        normalized.contains('squall')) {
      return WeatherScene.stormy;
    }

    if (normalized.contains('sleet') || normalized.contains('wintry mix')) {
      return WeatherScene.showerSleet;
    }

    if (normalized.contains('snow') ||
        normalized.contains('blizzard') ||
        normalized.contains('flurr')) {
      return WeatherScene.snowfall;
    }

    if (normalized.contains('frost') ||
        normalized.contains('freeze') ||
        normalized.contains('icy')) {
      return WeatherScene.frosty;
    }

    if (normalized.contains('rain') ||
        normalized.contains('drizzle') ||
        normalized.contains('shower') ||
        normalized.contains('overcast') ||
        normalized.contains('cloud') ||
        normalized.contains('mist') ||
        normalized.contains('fog') ||
        normalized.contains('haze')) {
      return WeatherScene.rainyOvercast;
    }

    if (normalized.contains('sunset') ||
        normalized.contains('dusk') ||
        normalized.contains('evening') ||
        normalized.contains('wind')) {
      return WeatherScene.sunset;
    }

    if (normalized.contains('sun') ||
        normalized.contains('clear') ||
        normalized.contains('fair') ||
        normalized.contains('hot')) {
      return WeatherScene.scorchingSun;
    }

    return WeatherScene.weatherEvery;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _weatherStore,
      builder: (context, _) {
        final weather = _weatherStore.snapshot;
        final scene = _sceneForCondition(weather.condition);

        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                WrapperScene.weather(
                  scene: scene,
                  sizeCanvas: Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  ),
                ),
                Container(color: Colors.black.withValues(alpha: 0.28)),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (weather.iconUrl.isNotEmpty)
                        Image.network(
                          weather.iconUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.wb_sunny_rounded,
                            size: 100,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.wb_sunny_rounded,
                          size: 100,
                          color: Colors.white,
                        ),
                      const SizedBox(height: 20),
                      Text(
                        weather.temperature,
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        weather.condition,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        weather.location,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFFE6EAF0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
