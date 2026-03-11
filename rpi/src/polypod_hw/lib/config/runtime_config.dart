class RuntimeConfig {
  const RuntimeConfig({
    required this.fullscreen,
    required this.topDisplayIndex,
    required this.bottomDisplayIndex,
  });

  /// Whether windows should be fullscreened on their target display.
  final bool fullscreen;

  /// Display index used by the top window.
  final int topDisplayIndex;

  /// Display index used by the bottom window.
  final int bottomDisplayIndex;

  /// Parses simple CLI flags from [args]. Intended for desktop/embedded builds.
  ///
  /// Supported flags:
  /// - `--fullscreen` / `--no-fullscreen`
  /// - `--top-display=<int>`
  /// - `--bottom-display=<int>`
  RuntimeConfig applyArgs(List<String> args) {
    bool? fullscreen;
    int? top;
    int? bottom;

    for (final raw in args) {
      final arg = raw.trim();
      if (arg.isEmpty) continue;

      if (arg == '--fullscreen') {
        fullscreen = true;
        continue;
      }
      if (arg == '--no-fullscreen') {
        fullscreen = false;
        continue;
      }

      if (arg.startsWith('--top-display=')) {
        top = int.tryParse(arg.substring('--top-display='.length));
        continue;
      }
      if (arg.startsWith('--bottom-display=')) {
        bottom = int.tryParse(arg.substring('--bottom-display='.length));
        continue;
      }
    }

    return RuntimeConfig(
      fullscreen: fullscreen ?? this.fullscreen,
      topDisplayIndex: top ?? topDisplayIndex,
      bottomDisplayIndex: bottom ?? bottomDisplayIndex,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'fullscreen': fullscreen,
      'topDisplayIndex': topDisplayIndex,
      'bottomDisplayIndex': bottomDisplayIndex,
    };
  }

  static RuntimeConfig? fromJson(dynamic raw) {
    if (raw is! Map) return null;

    bool? fullscreen;
    int? top;
    int? bottom;

    final fullscreenRaw = raw['fullscreen'];
    if (fullscreenRaw is bool) fullscreen = fullscreenRaw;
    if (fullscreenRaw is String) {
      final normalized = fullscreenRaw.toLowerCase();
      if (normalized == 'true') fullscreen = true;
      if (normalized == 'false') fullscreen = false;
    }

    final topRaw = raw['topDisplayIndex'];
    if (topRaw is int) top = topRaw;
    if (topRaw is num) top = topRaw.toInt();
    if (topRaw is String) top = int.tryParse(topRaw);

    final bottomRaw = raw['bottomDisplayIndex'];
    if (bottomRaw is int) bottom = bottomRaw;
    if (bottomRaw is num) bottom = bottomRaw.toInt();
    if (bottomRaw is String) bottom = int.tryParse(bottomRaw);

    if (fullscreen == null || top == null || bottom == null) return null;

    return RuntimeConfig(
      fullscreen: fullscreen,
      topDisplayIndex: top,
      bottomDisplayIndex: bottom,
    );
  }
}
