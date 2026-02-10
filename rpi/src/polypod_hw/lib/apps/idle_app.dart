import 'package:flutter/material.dart';
import 'base_app.dart';
import '../config/theme_config.dart';

/// Idle screen that displays when no app is active
class IdleApp extends BaseApp {
  const IdleApp({super.key});

  @override
  String get appName => 'Idle';

  @override
  State<IdleApp> createState() => _IdleAppState();
}

class _IdleAppState extends State<IdleApp> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: EarthyTheme.surface,
      child: Center(
        child: ClipOval(
          child: Image.asset(
            'web/icons/loader.gif',
            fit: BoxFit.cover,
            width: 240,
            height: 240,
          ),
        ),
      ),
    );
  }
}
