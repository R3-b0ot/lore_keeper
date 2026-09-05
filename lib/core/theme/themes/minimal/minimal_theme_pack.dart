import 'package:flutter/material.dart';

import 'package:lore_keeper/core/theme/accessibility_rating.dart';
import 'package:lore_keeper/core/theme/theme_color_tokens.dart';
import 'package:lore_keeper/core/theme/theme_font_tokens.dart';
import 'package:lore_keeper/core/theme/theme_registry.dart';

import 'minimal_colors.dart';
import 'minimal_theme_dark.dart';
import 'minimal_theme_light.dart';

/// Default pack reproducing Lore Keeper's Slate visuals for dark and light modes.
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
  ThemeColorTokens get darkColors => MinimalColors.darkTokens;

  @override
  ThemeColorTokens get lightColors => MinimalColors.lightTokens;

  @override
  ThemeFontTokens get fonts => const ThemeFontTokens(
    displayFamily: 'Inter',
    bodyFamily: 'Inter',
    monoFamily: 'monospace',
  );

  @override
  ThemeData buildThemeData({
    required bool isDark,
    required AccessibilityRating accessibilityRating,
  }) {
    final baseTheme = isDark
        ? MinimalThemeDark().buildThemeData(accessibilityRating)
        : MinimalThemeLight().buildThemeData(accessibilityRating);

    final colors = isDark ? darkColors : lightColors;

    return baseTheme.copyWith(
      extensions: [...baseTheme.extensions.values, colors, fonts],
    );
  }
}
