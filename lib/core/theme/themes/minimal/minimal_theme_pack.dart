import 'package:flutter/material.dart';

import 'package:lore_keeper/core/theme/theme_registry.dart';
import 'package:lore_keeper/core/theme/accessibility_rating.dart';

import 'minimal_theme_light.dart';
import 'minimal_theme_dark.dart';

class MinimalThemePack implements ThemePack {
  const MinimalThemePack();

  @override
  ThemePackMetadata get metadata => const ThemePackMetadata(
    id: 'minimal',
    displayName: 'Minimal',
    description:
        'Default pack that reproduces Lore Keeper current AA/AAA styles.',
    author: 'Lore Keeper',
    version: '1.0.0',
  );

  @override
  ThemeData buildThemeData({
    required bool isDark,
    required AccessibilityRating accessibilityRating,
  }) {
    return isDark
        ? MinimalThemeDark().buildThemeData(accessibilityRating)
        : MinimalThemeLight().buildThemeData(accessibilityRating);
  }
}
