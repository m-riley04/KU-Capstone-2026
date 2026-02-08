import 'package:flutter/material.dart';
import 'base_app.dart';
import '../config/theme_config.dart';

class HomeApp extends BaseApp {
  const HomeApp({super.key});

  @override
  String get appName => 'Home';

  @override
  State<HomeApp> createState() => _HomeAppState();
}

class _HomeAppState extends State<HomeApp> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EarthyTheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_rounded,
              size: 80,
              color: EarthyTheme.sage,
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome Home',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: EarthyTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Select an app from the control panel',
              style: TextStyle(
                fontSize: 14,
                color: EarthyTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
