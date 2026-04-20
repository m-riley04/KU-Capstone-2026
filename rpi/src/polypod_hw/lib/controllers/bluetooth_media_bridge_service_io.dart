import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

class BluetoothMediaBridgeService {
  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;

  Future<void> start() async {
    if (_process != null) {
      return;
    }

    final scriptPath = _resolveBridgeScriptPath();
    if (!await File(scriptPath).exists()) {
      debugPrint('Bluetooth media bridge script not found at: $scriptPath');
      return;
    }

    final candidates = <String>['python3', 'python'];
    for (final executable in candidates) {
      try {
        final process = await Process.start(
          executable,
          [scriptPath],
          mode: ProcessStartMode.normal,
        );

        _process = process;
        _stdoutSub = process.stdout
            .transform(SystemEncoding().decoder)
            .listen((line) {
              debugPrint('bluetooth_media_bridge: ${line.trimRight()}');
            });
        _stderrSub = process.stderr
            .transform(SystemEncoding().decoder)
            .listen((line) {
              debugPrint('bluetooth_media_bridge_error: ${line.trimRight()}');
            });

        unawaited(
          process.exitCode.then((code) {
            debugPrint('Bluetooth media bridge exited with code $code');
            _cleanupProcessRefs();
          }),
        );

        debugPrint('Started bluetooth media bridge using: $executable');
        return;
      } catch (_) {
        // Try next executable candidate.
      }
    }

    debugPrint('Failed to start bluetooth media bridge: python3/python not available.');
  }

  Future<void> stop() async {
    final process = _process;
    if (process == null) return;

    process.kill(ProcessSignal.sigterm);
    _cleanupProcessRefs();
  }

  String _resolveBridgeScriptPath() {
    final currentDir = Directory.current.path;
    final scriptPath =
        '$currentDir${Platform.pathSeparator}..${Platform.pathSeparator}media${Platform.pathSeparator}bluetooth_media_bridge.py';
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
