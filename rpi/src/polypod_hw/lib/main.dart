import 'dart:convert';
import 'dart:io' show Platform, Process, ProcessStartMode;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/theme_config.dart';
import 'config/ipc_config.dart';
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
import 'ipc/ipc.dart';
import 'package:window_manager/window_manager.dart';

import 'multi_window/multi_window.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Window mode is determined by (in priority order):
  //   1. --dart-define=POLYPOD_WINDOW=top|bottom|single  (works with flutter run)
  //   2. CLI args: --top, --bottom, --single              (works with compiled binary)
  //   3. desktop_multi_window sub-window detection
  //   4. Default: top window
  const envWindow = String.fromEnvironment('POLYPOD_WINDOW');

  PolypodWindowKind? resolvedKind;

  // 1. Check --dart-define and CLI args
  if (envWindow == 'single' || args.contains('--single')) {
    resolvedKind = PolypodWindowKind.single;
  } else if (envWindow == 'bottom' || args.contains('--bottom')) {
    resolvedKind = PolypodWindowKind.bottom;
  } else if (envWindow == 'both' || args.contains('--both')) {
    // Launch a second process for the bottom window, then continue as top.
    _spawnBottomProcess();
    resolvedKind = PolypodWindowKind.top;
  } else if (envWindow == 'top' || args.contains('--top')) {
    resolvedKind = PolypodWindowKind.top;
  }

  // 2. If no explicit flag, check desktop_multi_window sub-window args
  if (resolvedKind == null && _isDesktopPlatform) {
    final multiWindow = createMultiWindow();
    if (multiWindow.isSupported) {
      final current = await multiWindow.fromCurrentEngine();
      final parsed = PolypodWindowArgs.parse(current?.arguments);
      if (parsed.kind == PolypodWindowKind.bottom) {
        runApp(PolypodHWApp(
          windowKind: PolypodWindowKind.bottom,
          mainWindowId: parsed.mainWindowId,
        ));
        return;
      }
    }
  }

  // 3. Default to top window
  resolvedKind ??= PolypodWindowKind.top;

  // Set the OS window title bar text.
  if (_isDesktopPlatform) {
    await windowManager.ensureInitialized();
    final title = switch (resolvedKind) {
      PolypodWindowKind.top => 'Polypod_Top_Screen',
      PolypodWindowKind.bottom => 'Polypod_Bottom_Window',
      PolypodWindowKind.single => 'Polypod Hardware Control',
    };
    await windowManager.setTitle(title);
  }

  runApp(PolypodHWApp(windowKind: resolvedKind));
}

bool get _isDesktopPlatform {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows || TargetPlatform.linux || TargetPlatform.macOS => true,
    _ => false,
  };
}

/// Spawn a detached child process that runs as the bottom window.
/// Works with compiled binaries (uses the current executable path).
void _spawnBottomProcess() {
  final exe = Platform.resolvedExecutable;
  Process.start(exe, ['--bottom'], mode: ProcessStartMode.detached);
  if (kDebugMode) {
    print('[Polypod] Spawned bottom window process: $exe --bottom');
  }
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
      PolypodWindowKind.bottom => 'Polypod_Bottom_Window',
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

  // ── IPC ──────────────────────────────────────────────────────────────────
  late final IpcServer _ipcServer;

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

    _ipcServer = IpcServer(port: IpcConfig.port);
    _ipcServer.onMessage = _handleIpcMessage;

    _initWindowing();
  }

  /// Handle an incoming IPC message from the bottom window.
  void _handleIpcMessage(IpcMessage msg) {
    switch (msg.type) {
      case 'selectApp':
        final name = msg.payload?['appName'];
        if (name is String) _openApp(name);
      case 'home':
        _returnToHome();
      case 'timerSelection':
        final p = msg.payload;
        if (p != null) {
          _timerController.updateSelection(
            Duration(
              hours: _intFromDynamic(p['hours']),
              minutes: _intFromDynamic(p['minutes']),
              seconds: _intFromDynamic(p['seconds']),
            ),
          );
        }
      case 'timerStart':
        _timerController.start();
      case 'timerPause':
        _timerController.pause();
      case 'timerReset':
        _timerController.reset();
    }
  }

  Future<void> _initWindowing() async {
    // Start the IPC server so the bottom window can connect.
    await _ipcServer.start();

    SystemChrome.setApplicationSwitcherDescription(
      const ApplicationSwitcherDescription(
        label: 'Polypod_Top_Screen',
        primaryColor: 0xFF000000,
      ),
    );
  }

  int _intFromDynamic(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Notify the bottom window of the current app via IPC.
  void _notifyBottomAppChanged() {
    _ipcServer.broadcast(IpcMessage.appChanged(_currentAppKey));
  }

  @override
  void dispose() {
    _ipcServer.dispose();
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

  String _currentAppKey = 'Home';

  // ── IPC ──────────────────────────────────────────────────────────────────
  late final IpcClient _ipcClient;

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
    _ipcClient = IpcClient(port: IpcConfig.port);
    _ipcClient.onMessage = _handleIpcMessage;
    _initWindowing();
  }

  /// Handle an incoming IPC message from the top window.
  void _handleIpcMessage(IpcMessage msg) {
    switch (msg.type) {
      case 'appChanged':
        final next = msg.payload?['currentAppKey']?.toString();
        if (next != null && mounted) {
          setState(() {
            _currentAppKey = next;
          });
        }
    }
  }

  Future<void> _initWindowing() async {
    // Connect to the top window's IPC server.
    await _ipcClient.connect();

    if (!_multiWindow.isSupported) return;

    SystemChrome.setApplicationSwitcherDescription(
      const ApplicationSwitcherDescription(
        label: 'Polypod_Bottom_Screen',
        primaryColor: 0xFF000000,
      ),
    );
  }

  /// Send an IPC message to the top window.
  void _sendToMain(IpcMessage message) {
    _ipcClient.send(message);
  }

  @override
  void dispose() {
    _ipcClient.dispose();
    super.dispose();
  }

  BaseApp _bottomProxyApp() {
    return _BottomProxyApp(
      currentAppKey: _currentAppKey,
      onTimerSelectionChanged: (duration) {
        _sendToMain(IpcMessage.timerSelection(
          hours: duration.inHours,
          minutes: duration.inMinutes.remainder(60),
          seconds: duration.inSeconds.remainder(60),
        ));
      },
      onTimerStart: () => _sendToMain(IpcMessage.timerStart()),
      onTimerPause: () => _sendToMain(IpcMessage.timerPause()),
      onTimerReset: () => _sendToMain(IpcMessage.timerReset()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EarthyTheme.background,
      body: Center(
        child: BottomScreen(
          onAppSelected: (name) => _sendToMain(IpcMessage.selectApp(name)),
          onHomePressed: () => _sendToMain(IpcMessage.home()),
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
