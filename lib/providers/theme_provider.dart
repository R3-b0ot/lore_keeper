import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:lore_keeper/core/theme/accessibility_rating.dart';
import 'package:lore_keeper/core/theme/theme_registry.dart';

export 'package:lore_keeper/core/theme/accessibility_rating.dart';

/// Provider managing active theme pack, dark/light mode, and accessibility level.
class ThemeNotifier extends ChangeNotifier {
  late Box _settingsBox;
  static const String _themeKey = 'themeMode';
  static const String _themePackKey = 'themePack';
  static const String _accessibilityKey = 'accessibilityRating';

  String _themePack = 'minimal';

  /// Currently selected pack ID ('minimal', 'dracula', etc.).
  String get themePack => _themePack;

  ThemeMode _themeMode = ThemeMode.system;

  /// Active theme mode (system, light, or dark).
  ThemeMode get themeMode => _themeMode;

  AccessibilityRating _accessibilityRating = AccessibilityRating.aa;

  /// Active contrast compliance level (AA or AAA).
  AccessibilityRating get accessibilityRating => _accessibilityRating;

  /// Active [ThemePack] resolved from [ThemeRegistry].
  ThemePack get activePack => ThemeRegistry.instance.getPackById(_themePack);

  /// Computes [ThemeData] for light mode from active theme pack.
  ThemeData get lightTheme => activePack.buildThemeData(
        isDark: false,
        accessibilityRating: _accessibilityRating,
      );

  /// Computes [ThemeData] for dark mode from active theme pack.
  ThemeData get darkTheme => activePack.buildThemeData(
        isDark: true,
        accessibilityRating: _accessibilityRating,
      );

  ThemeNotifier() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _settingsBox = Hive.box('settings');

    // Load Theme Pack
    _themePack = _settingsBox.get(_themePackKey, defaultValue: 'minimal');

    // Load Theme Mode
    final themeString = _settingsBox.get(_themeKey, defaultValue: 'system');
    switch (themeString) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
        break;
    }

    // Load Accessibility Rating
    final ratingString = _settingsBox.get(
      _accessibilityKey,
      defaultValue: 'aa',
    );
    _accessibilityRating = ratingString == 'aaa'
        ? AccessibilityRating.aaa
        : AccessibilityRating.aa;

    notifyListeners();
  }

  /// Changes the theme pack ID and persists it.
  Future<void> setThemePack(String pack) async {
    _themePack = pack;
    await _settingsBox.put(_themePackKey, pack);
    notifyListeners();
  }

  /// Changes the theme mode (system, light, dark) and persists it.
  Future<void> setTheme(ThemeMode themeMode) async {
    _themeMode = themeMode;
    await _settingsBox.put(_themeKey, themeMode.name);
    notifyListeners();
  }

  /// Changes accessibility rating (AA or AAA) and persists it.
  Future<void> setAccessibilityRating(AccessibilityRating rating) async {
    _accessibilityRating = rating;
    await _settingsBox.put(_accessibilityKey, rating.name);
    notifyListeners();
  }
}
