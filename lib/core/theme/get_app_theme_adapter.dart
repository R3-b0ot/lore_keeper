import 'package:flutter/material.dart';

import 'package:lore_keeper/core/theme/theme_bootstrap.dart';
import 'accessibility_rating.dart';

/// Adapter to keep legacy call sites stable while we migrate.
class LegacyAppThemeAdapter {
  static ThemeData getLightTheme(AccessibilityRating rating) {
    // For now minimal pack delegates to legacy `lib/theme/app_theme.dart`.
    final controller = ThemeBootstrap.createDefaultController();

    // We intentionally ignore controller's ThemeMode here and directly build
    // light/dark variants.
    return controller.buildThemeData(
      isDark: false,
      accessibilityRating: rating,
    );
  }

  static ThemeData getDarkTheme(AccessibilityRating rating) {
    final controller = ThemeBootstrap.createDefaultController();
    return controller.buildThemeData(isDark: true, accessibilityRating: rating);
  }
}
