import 'package:flutter/material.dart';
import 'config/screen_config.dart';
import 'config/theme_config.dart';
import 'screens/top_screen.dart';
import 'screens/bottom_screen.dart';
import 'apps/base_app.dart';
import 'apps/idle_app.dart';
import 'apps/home_app.dart';
import 'apps/clock_app.dart';
import 'apps/weather_app.dart';
import 'apps/media_app.dart';
import 'apps/settings_app.dart';
import 'apps/notes_app.dart';
import 'controllers/clock_timer_controller.dart';
import 'controllers/idle_state_controller.dart';

void main() {
  runApp(const PolypodHWApp());
}

class PolypodHWApp extends StatelessWidget {
  const PolypodHWApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polypod Hardware Control',
      theme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(
        scaffoldBackgroundColor: EarthyTheme.background,
      ),
      home: const DualScreenHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}


/// Main home page that manages both top and bottom screens
class DualScreenHome extends StatefulWidget {
  const DualScreenHome({super.key});

  @override
  State<DualScreenHome> createState() => _DualScreenHomeState();
}

class _DualScreenHomeState extends State<DualScreenHome> {
  late IdleStateController _idleController;
  late ClockTimerController _timerController;
  BaseApp _currentApp = const IdleApp();

  late final Map<String, BaseApp> _apps;

  @override
  void initState() {
    super.initState();
    _idleController = IdleStateController();
    _idleController.setIdleCallback(_returnToIdle);
    _timerController = ClockTimerController();
    _apps = {
      'Home': const HomeApp(),
      'Timer': ClockApp(controller: _timerController),
      'Weather': const WeatherApp(),
      'Media': const MediaApp(),
      'Notes': const NotesApp(),
      'Settings': const SettingsApp(),
    };
  }

  @override
  void dispose() {
    _idleController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  void _returnToIdle() {
    setState(() {
      _currentApp = const IdleApp();
    });
  }

  void _returnToHome() {
    _idleController.resetIdleTimer();
    setState(() {
      _currentApp = const IdleApp();
    });
  }

  void _openApp(String appName) {
    _idleController.resetIdleTimer();
    setState(() {
      _currentApp = _apps[appName] ?? const HomeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EarthyTheme.background,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top Screen (640x480)
              TopScreen(
                currentApp: _currentApp,
                timerController: _timerController,
              ),
              // Bottom Screen (480x320)
              BottomScreen(
                onAppSelected: _openApp,
                onHomePressed: _returnToHome,
                availableApps: _apps.keys.where((name) => name != 'Home').toList(),
                currentApp: _currentApp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
