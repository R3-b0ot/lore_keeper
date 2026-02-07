import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

enum AccessibilityRating { aa, aaa }

class ThemeNotifier extends ChangeNotifier {
  late Box _settingsBox;
  static const String _themeKey = 'themeMode';
  static const String _accessibilityKey = 'accessibilityRating';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  AccessibilityRating _accessibilityRating = AccessibilityRating.aa;
  AccessibilityRating get accessibilityRating => _accessibilityRating;

  ThemeNotifier() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _settingsBox = await Hive.openBox('settings');

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

  Future<void> setTheme(ThemeMode themeMode) async {
    _themeMode = themeMode;
    await _settingsBox.put(_themeKey, themeMode.name);
    notifyListeners();
  }

  Future<void> setAccessibilityRating(AccessibilityRating rating) async {
    _accessibilityRating = rating;
    await _settingsBox.put(_accessibilityKey, rating.name);
    notifyListeners();
  }
}
