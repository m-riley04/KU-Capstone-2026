import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'config/theme_config.dart';
import 'screens/top_screen.dart';
import 'screens/bottom_screen.dart';
import 'apps/base_app.dart';
import 'apps/idle_app.dart';
import 'apps/clock_app.dart';
import 'apps/weather_app.dart';
import 'apps/media_app.dart';
import 'apps/settings_app.dart';
import 'apps/polypod_app.dart';
import 'controllers/clock_timer_controller.dart';
import 'controllers/idle_state_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/polypod_animation_controller.dart';
import 'controllers/polypod_maintenance_controller.dart';

import 'multi_window/multi_window.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!_isDesktopPlatform) {
    runApp(const PolypodHWApp(windowKind: PolypodWindowKind.single));
    return;
  }

  final multiWindow = createMultiWindow();
  if (!multiWindow.isSupported) {
    runApp(const PolypodHWApp(windowKind: PolypodWindowKind.single));
    return;
  }

  final current = await multiWindow.fromCurrentEngine();
  final parsed = PolypodWindowArgs.parse(current?.arguments);
  runApp(
    PolypodHWApp(
      windowKind: parsed.kind,
      mainWindowId: parsed.mainWindowId,
    ),
  );
}

bool get _isDesktopPlatform {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows || TargetPlatform.linux || TargetPlatform.macOS => true,
    _ => false,
  };
}

enum PolypodWindowKind { single, top, bottom }

class PolypodWindowArgs {
  const PolypodWindowArgs({
    required this.kind,
    this.mainWindowId,
  });

  final PolypodWindowKind kind;
  final String? mainWindowId;

  static PolypodWindowArgs parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const PolypodWindowArgs(kind: PolypodWindowKind.top);
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const PolypodWindowArgs(kind: PolypodWindowKind.top);
      }

      final type = decoded['type']?.toString();
      final mainId = decoded['mainWindowId']?.toString();

      if (type == 'bottom') {
        return PolypodWindowArgs(
          kind: PolypodWindowKind.bottom,
          mainWindowId: mainId,
        );
      }

      if (type == 'single') {
        return const PolypodWindowArgs(kind: PolypodWindowKind.single);
      }

      return const PolypodWindowArgs(kind: PolypodWindowKind.top);
    } catch (_) {
      return const PolypodWindowArgs(kind: PolypodWindowKind.top);
    }
  }

  static String encodeBottomArgs({required String mainWindowId}) {
    return jsonEncode({
      'type': 'bottom',
      'mainWindowId': mainWindowId,
    });
  }
}

class PolypodHWApp extends StatelessWidget {
  const PolypodHWApp({
    super.key,
    required this.windowKind,
    this.mainWindowId,
  });

  final PolypodWindowKind windowKind;
  final String? mainWindowId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polypod Hardware Control',
      theme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(
        scaffoldBackgroundColor: EarthyTheme.background,
      ),
      home: switch (windowKind) {
        PolypodWindowKind.bottom => BottomControlWindow(mainWindowId: mainWindowId),
        PolypodWindowKind.top => const TopOnlyWindow(),
        PolypodWindowKind.single => const DualScreenHome(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class TopOnlyWindow extends StatefulWidget {
  const TopOnlyWindow({super.key});

  @override
  State<TopOnlyWindow> createState() => _TopOnlyWindowState();
}

class _TopOnlyWindowState extends State<TopOnlyWindow> {
  late IdleStateController _idleController;
  late ClockTimerController _timerController;
  late NotificationController _notificationController;
  late PolypodAnimationController _polypodController;
  late PolypodMaintenanceController _maintenanceController;
  late BaseApp _currentApp;
  String _currentAppKey = 'Home';

  late final Map<String, BaseApp> _apps;

  final PolypodMultiWindow _multiWindow = createMultiWindow();
  PolypodWindowController? _topWindowController;
  PolypodWindowController? _bottomWindowController;

  @override
  void initState() {
    super.initState();
    _idleController = IdleStateController();
    _idleController.setIdleCallback(_returnToIdle);
    _timerController = ClockTimerController();
    _notificationController = NotificationController();
    _polypodController = PolypodAnimationController();
    _maintenanceController = PolypodMaintenanceController();
    _apps = {
      'Home': IdleApp(maintenanceController: _maintenanceController),
      'Timer': ClockApp(controller: _timerController),
      'Weather': const WeatherApp(),
      'Media': const MediaApp(),
      'Polypod': PolypodApp(
        controller: _polypodController,
        onFeed: _maintenanceController.feed,
        onWater: _maintenanceController.water,
        onPet: _maintenanceController.pet,
      ),
      'Settings': const SettingsApp(),
    };
    _currentApp = IdleApp(maintenanceController: _maintenanceController);

    _initWindowing();
  }

  Future<void> _initWindowing() async {
    if (!_multiWindow.isSupported) return;
    _topWindowController = await _multiWindow.fromCurrentEngine();

    await _topWindowController?.setMethodHandler((method, arguments) async {
      switch (method) {
        case 'polypod/selectApp':
          if (arguments is String) _openApp(arguments);
          return null;
        case 'polypod/home':
          _returnToHome();
          return null;
        case 'polypod/timerSelection':
          if (arguments is Map) {
            final hours = _intFromDynamic(arguments['hours']);
            final minutes = _intFromDynamic(arguments['minutes']);
            final seconds = _intFromDynamic(arguments['seconds']);
            _timerController.updateSelection(
              Duration(hours: hours, minutes: minutes, seconds: seconds),
            );
          }
          return null;
        case 'polypod/timerStart':
          _timerController.start();
          return null;
        case 'polypod/timerPause':
          _timerController.pause();
          return null;
        case 'polypod/timerReset':
          _timerController.reset();
          return null;
        case 'polypod/feed':
          _polypodController.triggerFeed();
          _maintenanceController.feed();
          return null;
        case 'polypod/water':
          _polypodController.triggerWater();
          _maintenanceController.water();
          return null;
        case 'polypod/pet':
          _polypodController.triggerPet();
          _maintenanceController.pet();
          return null;
      }
      return null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureBottomWindow();
    });
  }

  int _intFromDynamic(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _ensureBottomWindow() async {
    if (!_multiWindow.isSupported) return;
    final topId = _topWindowController?.windowId;
    if (topId == null) return;

    final existing = await _multiWindow.getAll();
    for (final controller in existing) {
      final args = PolypodWindowArgs.parse(controller.arguments);
      if (args.kind == PolypodWindowKind.bottom && args.mainWindowId == topId) {
        _bottomWindowController = controller;
        await _bottomWindowController?.show();
        await _notifyBottomAppChanged();
        return;
      }
    }

    _bottomWindowController = await _multiWindow.create(
      arguments: PolypodWindowArgs.encodeBottomArgs(mainWindowId: topId),
      hiddenAtLaunch: true,
    );
    await _bottomWindowController?.show();
    await _notifyBottomAppChanged();
  }

  Future<void> _notifyBottomAppChanged() async {
    await _bottomWindowController?.invokeMethod(
      'polypod/appChanged',
      {'currentAppKey': _currentAppKey},
    );
  }

  @override
  void dispose() {
    _idleController.dispose();
    _timerController.dispose();
    _notificationController.dispose();
    _polypodController.dispose();
    _maintenanceController.dispose();
    super.dispose();
  }

  void _returnToIdle() {
    setState(() {
      _currentApp = IdleApp(maintenanceController: _maintenanceController);
      _currentAppKey = 'Home';
    });
    _notifyBottomAppChanged();
  }

  void _returnToHome() {
    _idleController.resetIdleTimer();
    setState(() {
      _currentApp = IdleApp(maintenanceController: _maintenanceController);
      _currentAppKey = 'Home';
    });
    _notifyBottomAppChanged();
  }

  void _openApp(String appName) {
    _idleController.resetIdleTimer();
    setState(() {
      _currentAppKey = appName;
      _currentApp = _apps[appName] ?? IdleApp(maintenanceController: _maintenanceController);
    });
    _notifyBottomAppChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EarthyTheme.background,
      body: Center(
        child: TopScreen(
          currentApp: _currentApp,
          timerController: _timerController,
          notificationController: _notificationController,
        ),
      ),
    );
  }
}

class BottomControlWindow extends StatefulWidget {
  const BottomControlWindow({
    super.key,
    required this.mainWindowId,
  });

  final String? mainWindowId;

  @override
  State<BottomControlWindow> createState() => _BottomControlWindowState();
}

class _BottomControlWindowState extends State<BottomControlWindow> {
  final PolypodMultiWindow _multiWindow = createMultiWindow();
  PolypodWindowController? _bottomWindowController;
  PolypodWindowController? _mainWindowController;

  String _currentAppKey = 'Home';

  static const List<String> _availableApps = [
    'Timer',
    'Weather',
    'Media',
    'Polypod',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _initWindowing();
  }

  Future<void> _initWindowing() async {
    if (!_multiWindow.isSupported) return;
    _bottomWindowController = await _multiWindow.fromCurrentEngine();
    if (widget.mainWindowId != null) {
      _mainWindowController = await _multiWindow.fromWindowId(widget.mainWindowId!);
    }

    await _bottomWindowController?.setMethodHandler((method, arguments) async {
      switch (method) {
        case 'polypod/appChanged':
          if (arguments is Map) {
            final next = arguments['currentAppKey']?.toString();
            if (next != null && mounted) {
              setState(() {
                _currentAppKey = next;
              });
            }
          }
          return null;
      }
      return null;
    });
  }

  Future<void> _sendToMain(String method, [dynamic arguments]) async {
    await _mainWindowController?.invokeMethod(method, arguments);
  }

  BaseApp _bottomProxyApp() {
    return _BottomProxyApp(
      currentAppKey: _currentAppKey,
      onTimerSelectionChanged: (duration) {
        _sendToMain('polypod/timerSelection', {
          'hours': duration.inHours,
          'minutes': duration.inMinutes.remainder(60),
          'seconds': duration.inSeconds.remainder(60),
        });
      },
      onTimerStart: () => _sendToMain('polypod/timerStart'),
      onTimerPause: () => _sendToMain('polypod/timerPause'),
      onTimerReset: () => _sendToMain('polypod/timerReset'),
      onFeed: () => _sendToMain('polypod/feed'),
      onWater: () => _sendToMain('polypod/water'),
      onPet: () => _sendToMain('polypod/pet'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EarthyTheme.background,
      body: Center(
        child: BottomScreen(
          onAppSelected: (name) => _sendToMain('polypod/selectApp', name),
          onHomePressed: () => _sendToMain('polypod/home'),
          availableApps: _availableApps,
          currentApp: _bottomProxyApp(),
        ),
      ),
    );
  }
}

class _BottomProxyApp extends BaseApp {
  const _BottomProxyApp({
    required this.currentAppKey,
    required this.onTimerSelectionChanged,
    required this.onTimerStart,
    required this.onTimerPause,
    required this.onTimerReset,
    required this.onFeed,
    required this.onWater,
    required this.onPet,
  });

  final String currentAppKey;
  final void Function(Duration duration) onTimerSelectionChanged;
  final VoidCallback onTimerStart;
  final VoidCallback onTimerPause;
  final VoidCallback onTimerReset;
  final VoidCallback onFeed;
  final VoidCallback onWater;
  final VoidCallback onPet;

  @override
  String get appName => currentAppKey;

  @override
  Widget? buildBottomScreenContent(BuildContext context) {
    if (currentAppKey == 'Timer') {
      return HorizontalWheelList(
        onSelectionChanged: onTimerSelectionChanged,
        onStart: onTimerStart,
        onPause: onTimerPause,
        onReset: onTimerReset,
      );
    }
    if (currentAppKey == 'Polypod') {
      return PolypodCareControls(
        onFeedPressed: onFeed,
        onWaterPressed: onWater,
        onPetPressed: onPet,
      );
    }
    return null;
  }

  @override
  State<_BottomProxyApp> createState() => _BottomProxyAppState();
}

class _BottomProxyAppState extends State<_BottomProxyApp> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
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
  late NotificationController _notificationController;
  late PolypodAnimationController _polypodController;
  late PolypodMaintenanceController _maintenanceController;
  late BaseApp _currentApp;

  late final Map<String, BaseApp> _apps;

  @override
  void initState() {
    super.initState();
    _idleController = IdleStateController();
    _idleController.setIdleCallback(_returnToIdle);
    _timerController = ClockTimerController();
    _notificationController = NotificationController();
    _polypodController = PolypodAnimationController();
    _maintenanceController = PolypodMaintenanceController();
    _apps = {
      'Home': IdleApp(maintenanceController: _maintenanceController),
      'Timer': ClockApp(controller: _timerController),
      'Weather': const WeatherApp(),
      'Media': const MediaApp(),
      'Polypod': PolypodApp(
        controller: _polypodController,
        onFeed: _maintenanceController.feed,
        onWater: _maintenanceController.water,
        onPet: _maintenanceController.pet,
      ),
      'Settings': const SettingsApp(),
    };
    _currentApp = IdleApp(maintenanceController: _maintenanceController);
  }

  @override
  void dispose() {
    _idleController.dispose();
    _timerController.dispose();
    _notificationController.dispose();
    _polypodController.dispose();
    _maintenanceController.dispose();
    super.dispose();
  }

  void _returnToIdle() {
    setState(() {
      _currentApp = IdleApp(maintenanceController: _maintenanceController);
    });
  }

  void _returnToHome() {
    _idleController.resetIdleTimer();
    setState(() {
      _currentApp = IdleApp(maintenanceController: _maintenanceController);
    });
  }

  void _openApp(String appName) {
    _idleController.resetIdleTimer();
    setState(() {
      _currentApp = _apps[appName] ?? IdleApp(maintenanceController: _maintenanceController);
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
                notificationController: _notificationController,
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
