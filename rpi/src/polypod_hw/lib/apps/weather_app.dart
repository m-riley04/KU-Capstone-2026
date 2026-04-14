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
  static const String _indoorTemp = '70°F';
  static const String _indoorHumidity = '46%';
  static const String _indoorPressure = '.998 atm';

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
            const SizedBox(height: 28),
            Container(
              width: 420,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: EarthyTheme.bark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interior Environment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: EarthyTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _MetricItem(
                        icon: Icons.thermostat_rounded,
                        label: 'Temp',
                        value: _indoorTemp,
                      ),
                      _MetricItem(
                        icon: Icons.water_drop_rounded,
                        label: 'Humidity',
                        value: _indoorHumidity,
                      ),
                      _MetricItem(
                        icon: Icons.speed_rounded,
                        label: 'Pressure',
                        value: _indoorPressure,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: EarthyTheme.wheat),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: EarthyTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: EarthyTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
