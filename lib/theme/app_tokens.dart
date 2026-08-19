import 'package:flutter/material.dart';

/// Design Tokens for Lore Keeper's Visual Design System.
///
/// Provides centralized, immutable values for spacing, typography, radii,
/// icon sizes, and elevation to ensure visual consistency throughout the UI.

abstract class AppSpacing {
  /// 4.0 - Micro spacing (gap between inline icon & label)
  static const double xs = 4.0;

  /// 8.0 - Compact spacing (internal padding for chips, small buttons)
  static const double s = 8.0;

  /// 12.0 - Standard element spacing (gap between items in lists/grids)
  static const double m = 12.0;

  /// 16.0 - Standard container padding
  static const double l = 16.0;

  /// 24.0 - Section padding / structural gaps
  static const double xl = 24.0;

  /// 32.0 - Large section spacing
  static const double xxl = 32.0;

  /// 48.0 - Hero / major area spacing
  static const double xxxl = 48.0;
}

abstract class AppRadii {
  /// 4.0 - Subtle rounding for badges, tooltips
  static const double xs = 4.0;

  /// 8.0 - Standard control radius (buttons, text inputs, chips)
  static const double s = 8.0;

  /// 12.0 - Card & panel container radius
  static const double m = 12.0;

  /// 16.0 - Dialog & overlay container radius
  static const double l = 16.0;

  /// 999.0 - Fully rounded pill style
  static const double full = 999.0;

  // BorderRadius helpers
  static final BorderRadius borderXs = BorderRadius.circular(xs);
  static final BorderRadius borderS = BorderRadius.circular(s);
  static final BorderRadius borderM = BorderRadius.circular(m);
  static final BorderRadius borderL = BorderRadius.circular(l);
  static final BorderRadius borderFull = BorderRadius.circular(full);
}

abstract class AppIconSizes {
  /// 14.0 - Small inline indicators
  static const double xs = 14.0;

  /// 16.0 - Small UI controls
  static const double s = 16.0;

  /// 20.0 - Standard icon size (buttons, list items)
  static const double m = 20.0;

  /// 24.0 - Action icons (topbars, primary actions)
  static const double l = 24.0;

  /// 32.0 - Hero / feature icons
  static const double xl = 32.0;
}

abstract class AppElevation {
  /// 0.0 - Flat surface with subtle border (default for content-first UI)
  static const double flat = 0.0;

  /// 2.0 - Subtle floating control or card on scroll
  static const double low = 2.0;

  /// 8.0 - Popover menus, tooltips, dropdown overlays
  static const double medium = 8.0;

  /// 16.0 - Modal dialogs
  static const double high = 16.0;
}

abstract class AppTypography {
  static const String fontFamily = 'Inter';

  /// Display Large - 32px / 1.2 height / SemiBold (-0.5 tracking)
  static const TextStyle displayLarge = TextStyle(
    inherit: false,
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.2,
    textBaseline: TextBaseline.alphabetic,
    letterSpacing: -0.5,
  );

  /// Display Medium - 24px / 1.25 height / SemiBold (-0.3 tracking)
  static const TextStyle displayMedium = TextStyle(
    inherit: false,
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
    textBaseline: TextBaseline.alphabetic,
    letterSpacing: -0.3,
  );

  /// Title Large (H1) - 20px / 1.3 height / SemiBold (-0.2 tracking)
  static const TextStyle titleLarge = TextStyle(
    inherit: false,
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    textBaseline: TextBaseline.alphabetic,
    letterSpacing: -0.2,
  );

  /// Title Medium (H2) - 16px / 1.35 height / Medium (-0.1 tracking)
  static const TextStyle titleMedium = TextStyle(
    inherit: false,
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.35,
    textBaseline: TextBaseline.alphabetic,
    letterSpacing: -0.1,
  );

  /// Title Small (H3) - 14px / 1.4 height / Medium
  static const TextStyle titleSmall = TextStyle(
    inherit: false,
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    textBaseline: TextBaseline.alphabetic,
  );

  /// Body Large - 16px / 1.5 height / Regular
  static const TextStyle bodyLarge = TextStyle(
    inherit: false,
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    textBaseline: TextBaseline.alphabetic,
  );

  /// Body Medium - 14px / 1.4 height / Regular
  static const TextStyle bodyMedium = TextStyle(
    inherit: false,
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    textBaseline: TextBaseline.alphabetic,
  );

  /// Body Small - 12px / 1.35 height / Regular
  static const TextStyle bodySmall = TextStyle(
    inherit: false,
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    textBaseline: TextBaseline.alphabetic,
  );

  /// Label Large - 14px / 1.4 height / Medium
  static const TextStyle labelLarge = TextStyle(
    inherit: false,
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    textBaseline: TextBaseline.alphabetic,
  );

  /// Label Medium - 12px / 1.35 height / Medium
  static const TextStyle labelMedium = TextStyle(
    inherit: false,
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
    textBaseline: TextBaseline.alphabetic,
  );

  /// Label Small - 10px / 1.3 height / SemiBold (Tracking 0.5)
  static const TextStyle labelSmall = TextStyle(
    inherit: false,
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.3,
    textBaseline: TextBaseline.alphabetic,
    letterSpacing: 0.5,
  );
}
