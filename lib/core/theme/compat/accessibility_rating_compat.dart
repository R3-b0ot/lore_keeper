import 'package:lore_keeper/core/theme/accessibility_rating.dart';
import 'package:lore_keeper/providers/theme_provider.dart' as legacy;

/// Converts legacy AA/AAA ratings to the theme-layer enum.
AccessibilityRating toTheme(legacy.AccessibilityRating rating) {
  switch (rating) {
    case legacy.AccessibilityRating.aaa:
      return AccessibilityRating.aaa;
    case legacy.AccessibilityRating.aa:
      return AccessibilityRating.aa;
  }
}

/// Converts theme-layer AA/AAA ratings to the legacy provider enum.
legacy.AccessibilityRating toLegacy(AccessibilityRating rating) {
  switch (rating) {
    case AccessibilityRating.aaa:
      return legacy.AccessibilityRating.aaa;
    case AccessibilityRating.aa:
      return legacy.AccessibilityRating.aa;
  }
}
