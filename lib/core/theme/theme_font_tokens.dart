import 'package:flutter/material.dart';

/// Immutable font family tokens for a [ThemePack].
///
/// Exposes typography families for headers/display, body reading/writing,
/// and monospaced code/shortcuts. Extends [ThemeExtension] so widgets can access
/// font families via `Theme.of(context).extension<ThemeFontTokens>()`.
@immutable
class ThemeFontTokens extends ThemeExtension<ThemeFontTokens> {
  /// Font family used for headings, brand, and section labels.
  final String displayFamily;

  /// Font family used for long-form reading and manuscript writing.
  final String bodyFamily;

  /// Font family used for metadata, shortcuts, counts, and code blocks.
  final String monoFamily;

  const ThemeFontTokens({
    required this.displayFamily,
    required this.bodyFamily,
    required this.monoFamily,
  });

  @override
  ThemeFontTokens copyWith({
    String? displayFamily,
    String? bodyFamily,
    String? monoFamily,
  }) {
    return ThemeFontTokens(
      displayFamily: displayFamily ?? this.displayFamily,
      bodyFamily: bodyFamily ?? this.bodyFamily,
      monoFamily: monoFamily ?? this.monoFamily,
    );
  }

  @override
  ThemeFontTokens lerp(
    covariant ThemeExtension<ThemeFontTokens>? other,
    double t,
  ) {
    if (other is! ThemeFontTokens) return this;
    // Font families do not interpolate continuously; switch at midpoint.
    return t < 0.5 ? this : other;
  }
}
