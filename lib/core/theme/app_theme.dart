import 'package:flutter/material.dart';

import 'accessibility_rating.dart';

import 'theme_controller.dart';

/// Central ThemeData factory.
///
/// This file intentionally stays small: all theme composition lives in
/// [ThemeController] and theme packs under `lib/core/theme/themes/*`.
import 'get_app_theme_adapter.dart';

class AppTheme {
  static ThemeData getLightTheme(AccessibilityRating rating) {
    return LegacyAppThemeAdapter.getLightTheme(rating);
  }

  static ThemeData getDarkTheme(AccessibilityRating rating) {
    return LegacyAppThemeAdapter.getDarkTheme(rating);
  }

  static ThemeData themeFromController({
    required ThemeController controller,
    required AccessibilityRating accessibilityRating,
    required bool isDark,
  }) {
    return controller.buildThemeData(
      isDark: isDark,
      accessibilityRating: accessibilityRating,
    );
  }
}
