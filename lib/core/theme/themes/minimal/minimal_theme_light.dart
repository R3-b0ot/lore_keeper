import 'package:flutter/material.dart';

import 'package:lore_keeper/providers/theme_provider.dart';
import 'package:lore_keeper/theme/app_theme.dart' as legacy;

/// Temporary bridge: delegates to the legacy ThemeData implementation.
///
/// Goal: guarantee visual parity while we migrate styling into tokens.
class MinimalThemeLight {
  ThemeData buildThemeData(AccessibilityRating rating) {
    return legacy.AppTheme.getLightTheme(rating);
  }
}
