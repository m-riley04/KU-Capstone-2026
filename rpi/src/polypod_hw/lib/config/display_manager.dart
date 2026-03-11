import 'dart:io' show Platform;
import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart';
import 'package:screen_retriever/screen_retriever.dart' as screen;
import 'package:window_manager/window_manager.dart';

/// Utility for managing window display placement and fullscreen mode.
///
/// Call [init] once in `main()` after [WidgetsFlutterBinding.ensureInitialized].
/// Then use [setFullscreenOnDisplay] from each window to position itself on the
/// correct monitor and enter fullscreen.
///
/// On Linux running under a Wayland compositor (e.g. labwc on Raspberry Pi),
/// client-side window positioning (`gtk_window_move`) is a no-op.  Instead the
/// compositor's **window rules** (configured in `labwc/rc.xml`) are responsible
/// for moving each window to the correct output.  [setFullscreenOnDisplay] will
/// detect this and only set the window title so the compositor rules can match
/// it; fullscreen is also applied by the compositor rule via `ToggleFullscreen`.
class DisplayManager {
  DisplayManager._();

  static bool? _waylandCached;

  /// Initialise the underlying [WindowManager].
  static Future<void> init() async {
    if (!_isDesktop) return;
    await windowManager.ensureInitialized();
  }

  /// Whether the current session is running under Wayland.
  static bool get isWayland {
    if (_waylandCached != null) return _waylandCached!;
    if (kIsWeb || !Platform.isLinux) {
      _waylandCached = false;
      return false;
    }
    final sessionType = Platform.environment['XDG_SESSION_TYPE'] ?? '';
    final waylandDisplay = Platform.environment['WAYLAND_DISPLAY'] ?? '';
    _waylandCached =
        sessionType.toLowerCase() == 'wayland' || waylandDisplay.isNotEmpty;
    return _waylandCached!;
  }

  /// Move the current window onto the monitor at [displayIndex] and enter
  /// fullscreen.
  ///
  /// If [displayIndex] is out of range the primary (first) display is used.
  ///
  /// On Wayland/Linux the compositor handles both placement and fullscreen via
  /// window rules keyed on the window title.  The caller is responsible for
  /// setting the title *before* the window is shown (see [setWindowTitle]).
  static Future<void> setFullscreenOnDisplay(int displayIndex) async {
    if (!_isDesktop) return;

    // ── Wayland path ─────────────────────────────────────────────────────
    // On Wayland, client-side move/resize is not supported.  The labwc
    // compositor window rules (rc.xml) will:
    //   1. match on the window title,
    //   2. MoveToOutput to the correct display, and
    //   3. ToggleFullscreen.
    // We therefore do NOT call setBounds or setFullScreen ourselves; that
    // would race with the compositor's own actions.
    if (isWayland) {
      debugPrint(
        'DisplayManager: Wayland detected - compositor handles placement '
        'for display index $displayIndex.',
      );
      return;
    }

    // ── X11 / Windows / macOS path ───────────────────────────────────────
    final displays = await screen.screenRetriever.getAllDisplays();
    if (displays.isEmpty) {
      // Last resort - just fullscreen wherever the OS placed us.
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

  /// Helper to set the native window title.
  ///
  /// On Wayland this is critical: the compositor uses the title to match
  /// window rules that determine output placement and fullscreen.
  static Future<void> setWindowTitle(String title) async {
    if (!_isDesktop) return;
    await windowManager.setTitle(title);
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
