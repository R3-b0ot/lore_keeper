import 'package:flutter/material.dart';

import 'accessibility_rating.dart';

/// Controller responsible for producing the active [ThemeData] based on:
/// - selected theme pack
/// - light/dark mode
/// - accessibility rating
///
/// This is intentionally UI-framework-agnostic beyond ChangeNotifier so it can
/// integrate with Provider, Bloc, or Riverpod.
class ThemeController extends ChangeNotifier {
  final ThemeRegistryAdapter registry;

  String _selectedThemePackId = 'minimal';
  ThemeMode _themeMode = ThemeMode.system;
  AccessibilityRating _accessibilityRating = AccessibilityRating.aa;

  ThemeController({required this.registry});

  String get selectedThemePackId => _selectedThemePackId;
  ThemeMode get themeMode => _themeMode;
  AccessibilityRating get accessibilityRating => _accessibilityRating;

  void setThemePackId(String id) {
    if (_selectedThemePackId == id) return;
    _selectedThemePackId = id;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void setAccessibilityRating(AccessibilityRating rating) {
    if (_accessibilityRating == rating) return;
    _accessibilityRating = rating;
    notifyListeners();
  }

  /// Computes whether we should build light or dark ThemeData.
  bool _resolveIsDark(Brightness systemBrightness) {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return systemBrightness == Brightness.dark;
    }
  }

  /// Returns ThemeData for the resolved brightness.
  ThemeData getThemeData({required Brightness systemBrightness}) {
    final isDark = _resolveIsDark(systemBrightness);

    final pack =
        registry.getPackById(_selectedThemePackId) ??
        registry.getPackById('minimal');

    return pack.buildThemeData(
      isDark: isDark,
      accessibilityRating: _accessibilityRating,
    );
  }

  /// Helper for stateless call sites where isDark is known.
  ThemeData getThemeDataForVariant({required bool isDark}) {
    final pack =
        registry.getPackById(_selectedThemePackId) ??
        registry.getPackById('minimal');

    return pack.buildThemeData(
      isDark: isDark,
      accessibilityRating: _accessibilityRating,
    );
  }

  /// ThemeData factory.
  ///
  /// Used by [lib/core/theme/app_theme.dart].
  ThemeData buildThemeData({
    required bool isDark,
    required AccessibilityRating accessibilityRating,
  }) {
    final pack =
        registry.getPackById(_selectedThemePackId) ??
        registry.getPackById('minimal');

    return pack.buildThemeData(
      isDark: isDark,
      accessibilityRating: accessibilityRating,
    );
  }
}

/// Small adapter interface to avoid importing theme_registry in every file
/// while still keeping strong typing.
abstract class ThemeRegistryAdapter {
  dynamic getPackById(String id);
}
