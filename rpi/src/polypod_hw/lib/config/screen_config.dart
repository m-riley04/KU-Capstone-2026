/// Screen configuration for the dual-screen embedded device
class ScreenConfig {
  /// Top screen dimensions (landscape)
  static const double topScreenWidth = 640.0;
  static const double topScreenHeight = 480.0;

  /// Bottom screen dimensions (landscape)
  static const double bottomScreenWidth = 480.0;
  static const double bottomScreenHeight = 320.0;

  /// Total device width (maximum of both screens)
  static double get totalWidth => topScreenWidth;

  /// Total device height (sum of both screens)
  static double get totalHeight => topScreenHeight + bottomScreenHeight;

  /// Aspect ratio calculations
  static double get topScreenAspectRatio =>
      topScreenWidth / topScreenHeight; // ~1.33:1
  static double get bottomScreenAspectRatio =>
      bottomScreenWidth / bottomScreenHeight; // ~0.67:1
}
