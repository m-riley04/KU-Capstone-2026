import 'dart:io';

/// Flutter-side API for controlling the RGB LED via the Python GPIO code.
/// Spawns a one-shot Python script (`led_set_color.py`) each time the color
/// changes. GPIO pins hold their state after the process exits, so no
/// persistent daemon is needed — matching the notification system's approach
/// of keeping the bridge stateless.

/// Available colors - must stay in sync with the Python `LEDColor` enum.
enum LEDColor { off, white, red, green, blue, yellow, cyan, magenta }

class LEDController {
  LEDController({String? scriptPath}) : _scriptPath = scriptPath;

  final String? _scriptPath;

  /// Resolve the path to `led_api/led_set_color.py` relative to the working
  /// directory, the same way `NotificationController` resolves its paths.
  String _resolveScriptPath() {
    if (_scriptPath != null) return _scriptPath;

    final cwd = Directory.current.path;
    // From polypod_hw → ../led_api/led_set_color.py
    final path =
        '$cwd${Platform.pathSeparator}..${Platform.pathSeparator}led_api${Platform.pathSeparator}led_set_color.py';
    return File(path).absolute.path;
  }

  Future<void> setColor(LEDColor color) async {
    final colorName = color.name.toUpperCase();
    try {
      final result = await Process.run(
        'python3',
        [_resolveScriptPath(), colorName],
      );
      if (result.exitCode == 0) {
        print('LED color set to $colorName');
      } else {
        print('LED script error (exit ${result.exitCode}): ${result.stderr}');
      }
    } catch (e) {
      print('LED setColor failed: $e');
    }
  }

  /// Turn the LED off. Call this when the app is shutting down to
  /// reset the GPIO pins to a clean state.
  Future<void> turnOff() => setColor(LEDColor.off);
}

