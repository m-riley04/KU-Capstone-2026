import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File, ProcessStartMode, Platform, Process, ProcessResult, ProcessSignal, SocketException, exit, pid;

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

  // Kill any leftover polypod_hw processes from a previous run that
  // flutter run failed to clean up.  Skip this when we ARE the bottom
  // window — otherwise we'd kill the top window that just spawned us.
  final isBottomWindow = args.contains('--bottom');
  if (!kIsWeb && !isBottomWindow && (Platform.isLinux || Platform.isMacOS)) {
    await _killStaleProcesses();
  }

  // Window mode is determined by (in priority order):
  //   1. --dart-define=POLYPOD_WINDOW=top|bottom|single  (works with flutter run)
  //   2. CLI args: --top, --bottom, --single              (works with compiled binary)
  //   3. desktop_multi_window sub-window detection
  //   4. Default: top window
  final envWindow = (
    Platform.environment['POLYPOD_WINDOW'] 
    ?? const String.fromEnvironment('POLYPOD_WINDOW', defaultValue: 'both')
  ).toLowerCase();

  PolypodWindowKind? resolvedKind;

  // 1. Check --dart-define and CLI args
  if (envWindow == 'single' || args.contains('--single')) {
    resolvedKind = PolypodWindowKind.single;
  } else if (envWindow == 'bottom' || args.contains('--bottom')) {
    resolvedKind = PolypodWindowKind.bottom;
    // If the parent passed its PID, start a watchdog that exits when it dies.
    for (final arg in args) {
      if (arg.startsWith('--parent-pid=')) {
        final ppid = int.tryParse(arg.substring('--parent-pid='.length));
        if (ppid != null) _startParentWatchdog(ppid);
      }
    }
  } else if (envWindow == 'both' || args.contains('--both')) {
    // The bottom window will be spawned later from _initWindowing(),
    // after the IPC server is up and flutter run has connected.
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

  // Kill the spawned bottom process when we receive SIGINT / SIGTERM.
  ProcessSignal.sigint.watch().listen((_) {
    _killBottomProcess();
    exit(0);
  });
  ProcessSignal.sigterm.watch().listen((_) {
    _killBottomProcess();
    exit(0);
  });

  runApp(PolypodHWApp(windowKind: resolvedKind));
}

bool get _isDesktopPlatform {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows || TargetPlatform.linux || TargetPlatform.macOS => true,
    _ => false,
  };
}

/// Path to the PID file used to track the bottom window process.
const _bottomPidFile = '/tmp/polypod_bottom.pid';

/// The PID of the child bottom-window process, if we spawned one.
int? _bottomProcessPid;

/// Kill any leftover polypod_hw binary processes from a previous crashed run.
///
/// `flutter run` sometimes fails to clean up the binary it launched
/// (especially on WSL).  We use `pgrep -x` to match only processes whose
/// *executable name* is literally "polypod_hw" — this avoids killing
/// flutter, dart, or any other tool that merely has "polypod_hw" in its
/// command-line arguments.
Future<void> _killStaleProcesses() async {
  try {
    // 1. Check the PID file first (most targeted).
    final pidFile = File(_bottomPidFile);
    if (pidFile.existsSync()) {
      final stalePid = int.tryParse(pidFile.readAsStringSync().trim());
      if (stalePid != null && stalePid != pid) {
        try {
          Process.killPid(stalePid, ProcessSignal.sigkill);
          if (kDebugMode) print('[Polypod] Killed stale bottom (pid=$stalePid)');
        } catch (_) {}
      }
      pidFile.deleteSync();
    }

    // 2. Sweep any remaining polypod_hw binaries (belt-and-suspenders).
    //    Timeout after 2s to prevent hanging if pgrep is slow.
    final result = await Process.run('pgrep', ['-x', 'polypod_hw'])
        .timeout(const Duration(seconds: 2), onTimeout: () {
      return ProcessResult(0, 1, '', ''); // treat as "nothing found"
    });
    if (result.exitCode != 0) return;
    for (final line in result.stdout.toString().trim().split('\n')) {
      final stalePid = int.tryParse(line.trim());
      if (stalePid != null && stalePid != pid) {
        try {
          Process.killPid(stalePid, ProcessSignal.sigkill);
          if (kDebugMode) print('[Polypod] Killed stale process $stalePid');
        } catch (_) {}
      }
    }
    await Future.delayed(const Duration(milliseconds: 300));
  } catch (_) {}
}

/// Spawn a child process that runs as the bottom window.
///
/// Uses detached mode so the child is fully independent of the parent's
/// stdio — this prevents `flutter run` from seeing the child's VM
/// service and getting confused.
Future<void> _spawnBottomProcess() async {
  final exe = Platform.resolvedExecutable;
  try {
    final proc = await Process.start(
      exe,
      ['--bottom', '--parent-pid=$pid'],
      mode: ProcessStartMode.detached,
    );
    _bottomProcessPid = proc.pid;
    // Write PID file so the wrapper script (and next run) can find it.
    try {
      File(_bottomPidFile).writeAsStringSync('${proc.pid}');
    } catch (_) {}
    if (kDebugMode) {
      print('[Polypod] Spawned bottom window (pid=${proc.pid})');
    }
  } catch (e) {
    if (kDebugMode) {
      print('[Polypod] Failed to spawn bottom window: $e');
    }
  }
}

/// Kill the bottom-window child process if it is still running.
void _killBottomProcess() {
  final childPid = _bottomProcessPid;
  if (childPid != null) {
    if (kDebugMode) {
      print('[Polypod] Killing bottom window (pid=$childPid)');
    }
    try {
      Process.killPid(childPid, ProcessSignal.sigkill);
    } catch (_) {}
    // Clean up PID file.
    try {
      File(_bottomPidFile).deleteSync();
    } catch (_) {}
    _bottomProcessPid = null;
  }
}

/// Periodically check whether the parent process is still alive.
/// If it's gone (crashed, killed, etc.) this child process exits.
void _startParentWatchdog(int parentPid) {
  if (kDebugMode) {
    print('[Polypod] Watching parent process (pid=$parentPid)');
  }
  Timer.periodic(const Duration(seconds: 2), (timer) {
    // On Linux, /proc/<pid> exists iff the process is alive.
    if (!Directory('/proc/$parentPid').existsSync()) {
      if (kDebugMode) {
        print('[Polypod] Parent ($parentPid) gone — exiting.');
      }
      timer.cancel();
      exit(0);
    }
  });
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

    // Spawn the bottom window after a short delay.  This gives
    // `flutter run` time to fully connect its debugger to us before
    // a second Flutter process appears.
    Future.delayed(const Duration(seconds: 2), () {
      _spawnBottomProcess();
    });

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
    _killBottomProcess();
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
