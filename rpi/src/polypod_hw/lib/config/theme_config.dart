import 'package:flutter/material.dart';

/// Earthy theme configuration
class EarthyTheme {
  // earthy color palette
  static const Color forestGreen = Color(0xFF4A5D23);
  static const Color sage = Color(0xFF87A96B);
  static const Color terracotta = Color(0xFFB85C38);
  static const Color sandstone = Color(0xFFD4A574);
  static const Color clay = Color(0xFFA0522D);
  static const Color moss = Color(0xFF6B7C3A);
  static const Color bark = Color(0xFF5C4033);
  static const Color wheat = Color(0xFFC9A961);

  static const Color background = Color(0xFF2B2520);
  static const Color surface = Color(0xFF3A3128);
  static const Color textPrimary = Color(0xFFE8DCC4);
  static const Color textSecondary = Color(0xFFC4B5A0);

  static List<Color> get buttonColors => [
        forestGreen,
        terracotta,
        sage,
        clay,
        moss,
        sandstone,
      ];
}
