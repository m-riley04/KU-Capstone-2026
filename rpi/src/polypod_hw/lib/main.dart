import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'controllers/notification_controller.dart';

import 'multi_window/multi_window.dart';
import 'config/display_manager.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await DisplayManager.init();

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
    final String appTitle = switch (windowKind) {
      PolypodWindowKind.top => 'Polypod_Top_Screen',
      PolypodWindowKind.bottom => 'Polypod_Bottom_Screen',
      PolypodWindowKind.single => 'Polypod Hardware Control',
    };

    return MaterialApp(
      title: appTitle,
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
  BaseApp _currentApp = const IdleApp();
  String _currentAppKey = 'Home';

  late final Map<String, BaseApp> _apps;

  final PolypodMultiWindow _multiWindow = createMultiWindow();
  PolypodWindowController? _topWindowController;
  PolypodWindowController? _bottomWindowController;

  /// Completer that the child (bottom) window signals when it has finished
  /// setting its title and is ready to be shown.  On Wayland, showing the
  /// window before the title is set would prevent the compositor's
  /// window-rule from matching, so the parent waits for this signal.
  Completer<void>? _childReadyCompleter;

  @override
  void initState() {
    super.initState();
    _idleController = IdleStateController();
    _idleController.setIdleCallback(_returnToIdle);
    _timerController = ClockTimerController();
    _notificationController = NotificationController();
    _apps = {
      'Home': const HomeApp(),
      'Timer': ClockApp(controller: _timerController),
      'Weather': const WeatherApp(),
      'Media': const MediaApp(),
      'Notes': const NotesApp(),
      'Settings': const SettingsApp(),
    };

    _initWindowing();
  }

  Future<void> _initWindowing() async {
    if (!_multiWindow.isSupported) return;
    _topWindowController = await _multiWindow.fromCurrentEngine();

    SystemChrome.setApplicationSwitcherDescription(
      const ApplicationSwitcherDescription(
        label: 'Polypod_Top_Screen',
        primaryColor: 0xFF000000,
      ),
    );

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
        case 'polypod/childReady':
          // The child window has set its title and is ready to be shown.
          if (_childReadyCompleter != null &&
              !_childReadyCompleter!.isCompleted) {
            _childReadyCompleter!.complete();
          }
          return null;
      }
      return null;
    });

    // Set the native window title so the compositor (labwc on Wayland) can
    // match it against its window rules and place it on the correct output.
    await DisplayManager.setWindowTitle('Polypod_Top_Screen');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureBottomWindow();
    });

    // Fullscreen this window on the first display.
    await DisplayManager.setFullscreenOnDisplay(0);
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

    // On Wayland, the child window's title must be set before it is shown so
    // that the compositor's window rule fires on the correct title.  We create
    // the child hidden, wait for it to signal readiness (title set), and then
    // show it.
    _childReadyCompleter = Completer<void>();

    _bottomWindowController = await _multiWindow.create(
      arguments: PolypodWindowArgs.encodeBottomArgs(mainWindowId: topId),
      hiddenAtLaunch: true,
    );

    if (DisplayManager.isWayland) {
      // Wait for the child engine to set its title (with a timeout fallback).
      await _childReadyCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint(
            'DisplayManager: child window did not signal readiness in time - '
            'showing anyway.',
          );
        },
      );
    }

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
    super.dispose();
  }

  void _returnToIdle() {
    setState(() {
      _currentApp = const IdleApp();
      _currentAppKey = 'Home';
    });
    _notifyBottomAppChanged();
  }

  void _returnToHome() {
    _idleController.resetIdleTimer();
    setState(() {
      _currentApp = const IdleApp();
      _currentAppKey = 'Home';
    });
    _notifyBottomAppChanged();
  }

  void _openApp(String appName) {
    _idleController.resetIdleTimer();
    setState(() {
      _currentAppKey = appName;
      _currentApp = _apps[appName] ?? const HomeApp();
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
    'Notes',
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

    SystemChrome.setApplicationSwitcherDescription(
      const ApplicationSwitcherDescription(
        label: 'Polypod_Bottom_Screen',
        primaryColor: 0xFF000000,
      ),
    );

    if (widget.mainWindowId != null) {
      _mainWindowController = await _multiWindow.fromWindowId(widget.mainWindowId!);
    }

    // Set the native window title BEFORE the window is shown.  On Wayland the
    // compositor (labwc) uses this title to match a window rule that places
    // the window on the correct output (SPI-1).
    await DisplayManager.setWindowTitle('Polypod_Bottom_Screen');

    // Signal the parent window that our title is set and we are ready to be
    // shown.  The parent waits for this before calling show() so the
    // compositor sees the correct title on first map.
    await _mainWindowController?.invokeMethod('polypod/childReady');

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

    // Fullscreen this window on the second display.
    await DisplayManager.setFullscreenOnDisplay(1);
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
  });

  final String currentAppKey;
  final void Function(Duration duration) onTimerSelectionChanged;
  final VoidCallback onTimerStart;
  final VoidCallback onTimerPause;
  final VoidCallback onTimerReset;

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
  BaseApp _currentApp = const IdleApp();

  late final Map<String, BaseApp> _apps;

  @override
  void initState() {
    super.initState();
    _idleController = IdleStateController();
    _idleController.setIdleCallback(_returnToIdle);
    _timerController = ClockTimerController();
    _notificationController = NotificationController();
    _apps = {
      'Home': const HomeApp(),
      'Timer': ClockApp(controller: _timerController),
      'Weather': const WeatherApp(),
      'Media': const MediaApp(),
      'Notes': const NotesApp(),
      'Settings': const SettingsApp(),
    };

    // Fullscreen on the primary display in single-window mode.
    _initDisplay();
  }

  Future<void> _initDisplay() async {
    await DisplayManager.setFullscreenOnDisplay(0);
  }

  @override
  void dispose() {
    _idleController.dispose();
    _timerController.dispose();
    _notificationController.dispose();
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
