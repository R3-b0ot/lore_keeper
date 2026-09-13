import 'package:flutter/material.dart';

import 'global_setting_key.dart';

/// Multiplier ranges used by the scaling system.
abstract class ScaleRange {
  static const double minInterface = 0.8; // 80%
  static const double maxInterface = 1.4; // 140%
  static const double minText = 0.8; // 80%
  static const double maxText = 1.6; // 160%
}

/// A single resolved scale (interface or text) expressed as a multiplier.
///
/// Converts a percentage UI value (80–160) into a normalized factor and clamps
/// it to the supported range so out-of-range persisted values never corrupt
/// the layout.
@immutable
class ScaleFactor {
  /// Normalized multiplier (1.0 == 100%).
  final double factor;

  const ScaleFactor._(this.factor);

  /// Builds a [ScaleFactor] from a percentage value (e.g. 100 == 100%).
  factory ScaleFactor.percent(double percent, {required bool isText}) {
    final min = isText ? ScaleRange.minText : ScaleRange.minInterface;
    final max = isText ? ScaleRange.maxText : ScaleRange.maxInterface;
    final clamped = (percent / 100.0).clamp(min, max);
    return ScaleFactor._(clamped);
  }

  /// The unclamped percentage this factor was derived from (for display).
  double resolvePercent(double basePercent) =>
      (basePercent * factor).roundToDouble();

  double scale(double value) => value * factor;
}

/// Centralized scaling hub for interface and typography.
///
/// Provides normalized factors derived from persisted global settings and is
/// exposed to the widget tree through [ScaleTokens] (a [ThemeExtension]) so
/// components can consume consistent, live-updating scale values without each
/// widget re-implementing the conversion.
@immutable
class ScaleTokens extends ThemeExtension<ScaleTokens> {
  /// Effective interface scale (affects spacing, icons, control heights).
  final double interfaceScale;

  /// Effective text scale (affects typography via MediaQuery textScaler).
  final double textScale;

  /// Selected density label.
  final AppDensity density;

  const ScaleTokens({
    this.interfaceScale = 1.0,
    this.textScale = 1.0,
    this.density = AppDensity.comfortable,
  });

  /// Scales a spacing/dimension value by the interface factor.
  double sp(double value) => value * interfaceScale;

  /// Scales an icon size.
  double icon(double value) => value * interfaceScale;

  /// Horizontal & vertical padding modifier from density.
  double get densityPadding {
    switch (density) {
      case AppDensity.compact:
        return -2.0;
      case AppDensity.comfortable:
        return 0.0;
      case AppDensity.spacious:
        return 3.0;
    }
  }

  /// Vertical padding modifier used by list/control heights.
  double get densityControl {
    switch (density) {
      case AppDensity.compact:
        return -4.0;
      case AppDensity.comfortable:
        return 0.0;
      case AppDensity.spacious:
        return 6.0;
    }
  }

  @override
  ScaleTokens copyWith({
    double? interfaceScale,
    double? textScale,
    AppDensity? density,
  }) {
    return ScaleTokens(
      interfaceScale: interfaceScale ?? this.interfaceScale,
      textScale: textScale ?? this.textScale,
      density: density ?? this.density,
    );
  }

  @override
  ScaleTokens lerp(ThemeExtension<ScaleTokens>? other, double t) {
    if (other is! ScaleTokens) return this;
    return ScaleTokens(
      interfaceScale: lerpDoubleSafe(interfaceScale, other.interfaceScale, t),
      textScale: lerpDoubleSafe(textScale, other.textScale, t),
      density: t < 0.5 ? density : other.density,
    );
  }

  static double lerpDoubleSafe(double a, double b, double t) => a + (b - a) * t;
}

/// Convenience accessor: `context.scale.sp(...)`.
extension ScaleContext on BuildContext {
  /// Resolves [ScaleTokens] (defaults to 1.0 when theme not yet wired).
  ScaleTokens get scale =>
      Theme.of(this).extension<ScaleTokens>() ?? const ScaleTokens();
}
