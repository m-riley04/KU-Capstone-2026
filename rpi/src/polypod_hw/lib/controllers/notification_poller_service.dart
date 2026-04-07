import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Starts/stops the Python notification API poller process.
class NotificationPollerService {
  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;

  bool get isRunning => _process != null;

  Future<void> start({double intervalSeconds = 5.0}) async {
    if (_process != null) {
      return;
    }

    final scriptPath = _resolvePollerScriptPath();
    if (!await File(scriptPath).exists()) {
      debugPrint('Notification poller script not found at: $scriptPath');
      return;
    }

    // Prefer python3 on Linux, but support python on environments where
    // python3 is not available.
    final candidates = <String>['python3', 'python'];

    for (final executable in candidates) {
      try {
        final process = await Process.start(
          executable,
          [scriptPath, '--interval', intervalSeconds.toString()],
          mode: ProcessStartMode.normal,
        );

        _process = process;
        _stdoutSub = process.stdout
            .transform(SystemEncoding().decoder)
            .listen((line) {
              debugPrint('notification_poller: ${line.trimRight()}');
            });
        _stderrSub = process.stderr
            .transform(SystemEncoding().decoder)
            .listen((line) {
              debugPrint('notification_poller_error: ${line.trimRight()}');
            });

        unawaited(
          process.exitCode.then((code) {
            debugPrint('Notification poller exited with code $code');
            _cleanupProcessRefs();
          }),
        );

        debugPrint('Started notification poller using: $executable');
        return;
      } catch (_) {
        // Try next candidate executable.
      }
    }

    debugPrint('Failed to start notification poller: python3/python not available.');
  }

  Future<void> stop() async {
    final process = _process;
    if (process == null) return;

    process.kill(ProcessSignal.sigterm);
    _cleanupProcessRefs();
  }

  String _resolvePollerScriptPath() {
    final currentDir = Directory.current.path;
    final scriptPath =
        '$currentDir${Platform.pathSeparator}..${Platform.pathSeparator}notif${Platform.pathSeparator}notification_api_poller.py';
    return File(scriptPath).absolute.path;
  }

  void _cleanupProcessRefs() {
    _process = null;
    _stdoutSub?.cancel();
    _stdoutSub = null;
    _stderrSub?.cancel();
    _stderrSub = null;
  }
}
