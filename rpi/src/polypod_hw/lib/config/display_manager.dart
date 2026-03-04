import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart';
import 'package:screen_retriever/screen_retriever.dart' as screen;
import 'package:window_manager/window_manager.dart';

/// Utility for managing window display placement and fullscreen mode.
///
/// Call [init] once in `main()` after [WidgetsFlutterBinding.ensureInitialized].
/// Then use [setFullscreenOnDisplay] from each window to position itself on the
/// correct monitor and enter fullscreen.
class DisplayManager {
  DisplayManager._();

  /// Initialise the underlying [WindowManager].
  static Future<void> init() async {
    if (!_isDesktop) return;
    await windowManager.ensureInitialized();
  }

  /// Move the current window onto the monitor at [displayIndex] and enter
  /// fullscreen.
  ///
  /// If [displayIndex] is out of range the primary (first) display is used.
  static Future<void> setFullscreenOnDisplay(int displayIndex) async {
    if (!_isDesktop) return;

    final displays = await screen.screenRetriever.getAllDisplays();
    if (displays.isEmpty) {
      // Last resort – just fullscreen wherever the OS placed us.
      await windowManager.setFullScreen(true);
      return;
    }

    final target = displayIndex < displays.length
        ? displays[displayIndex]
        : displays[0];

    // Use visiblePosition / visibleSize so we stay inside the work-area
    // when repositioning.  The fullscreen call that follows will cover the
    // entire monitor (including any taskbar area).
    final pos = target.visiblePosition ?? Offset.zero;
    final size = target.visibleSize ?? target.size;

    // Place the window in the centre of the target display (half-size) so the
    // OS's "which monitor is this window on?" heuristic picks the right one.
    await windowManager.setBounds(
      Rect.fromLTWH(
        pos.dx + size.width * 0.25,
        pos.dy + size.height * 0.25,
        size.width * 0.5,
        size.height * 0.5,
      ),
    );

    // Give the windowing system a moment to process the move.
    await Future.delayed(const Duration(milliseconds: 150));

    // Now go fullscreen on whichever monitor the window is associated with.
    await windowManager.setFullScreen(true);
  }

  static bool get _isDesktop {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS =>
        true,
      _ => false,
    };
  }
}
