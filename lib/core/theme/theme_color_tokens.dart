import 'package:flutter/material.dart';

/// Immutable design color tokens for a [ThemePack].
///
/// Encapsulates all surface, text, syntax accent, and functional colors used by
/// Lore Keeper components. Extends [ThemeExtension] so widgets can consume tokens
/// via `Theme.of(context).extension<ThemeColorTokens>()`.
@immutable
class ThemeColorTokens extends ThemeExtension<ThemeColorTokens> {
  // --- Surfaces ---
  final Color background;
  final Color backgroundDarker;
  final Color backgroundDark;
  final Color backgroundLight;
  final Color backgroundLighter;
  final Color floating;
  final Color selection;
  final Color currentLine;
  final Color lineHighlightFallback;

  // --- Text ---
  final Color foreground;
  final Color comment;

  // --- Accents ---
  final Color pink;
  final Color purple;
  final Color cyan;
  final Color green;
  final Color orange;
  final Color yellow;
  final Color red;

  // --- Functional ---
  final Color functionalRed;
  final Color functionalOrange;
  final Color functionalGreen;
  final Color functionalCyan;
  final Color functionalPurple;

  const ThemeColorTokens({
    required this.background,
    required this.backgroundDarker,
    required this.backgroundDark,
    required this.backgroundLight,
    required this.backgroundLighter,
    required this.floating,
    required this.selection,
    required this.currentLine,
    required this.lineHighlightFallback,
    required this.foreground,
    required this.comment,
    required this.pink,
    required this.purple,
    required this.cyan,
    required this.green,
    required this.orange,
    required this.yellow,
    required this.red,
    required this.functionalRed,
    required this.functionalOrange,
    required this.functionalGreen,
    required this.functionalCyan,
    required this.functionalPurple,
  });

  @override
  ThemeColorTokens copyWith({
    Color? background,
    Color? backgroundDarker,
    Color? backgroundDark,
    Color? backgroundLight,
    Color? backgroundLighter,
    Color? floating,
    Color? selection,
    Color? currentLine,
    Color? lineHighlightFallback,
    Color? foreground,
    Color? comment,
    Color? pink,
    Color? purple,
    Color? cyan,
    Color? green,
    Color? orange,
    Color? yellow,
    Color? red,
    Color? functionalRed,
    Color? functionalOrange,
    Color? functionalGreen,
    Color? functionalCyan,
    Color? functionalPurple,
  }) {
    return ThemeColorTokens(
      background: background ?? this.background,
      backgroundDarker: backgroundDarker ?? this.backgroundDarker,
      backgroundDark: backgroundDark ?? this.backgroundDark,
      backgroundLight: backgroundLight ?? this.backgroundLight,
      backgroundLighter: backgroundLighter ?? this.backgroundLighter,
      floating: floating ?? this.floating,
      selection: selection ?? this.selection,
      currentLine: currentLine ?? this.currentLine,
      lineHighlightFallback:
          lineHighlightFallback ?? this.lineHighlightFallback,
      foreground: foreground ?? this.foreground,
      comment: comment ?? this.comment,
      pink: pink ?? this.pink,
      purple: purple ?? this.purple,
      cyan: cyan ?? this.cyan,
      green: green ?? this.green,
      orange: orange ?? this.orange,
      yellow: yellow ?? this.yellow,
      red: red ?? this.red,
      functionalRed: functionalRed ?? this.functionalRed,
      functionalOrange: functionalOrange ?? this.functionalOrange,
      functionalGreen: functionalGreen ?? this.functionalGreen,
      functionalCyan: functionalCyan ?? this.functionalCyan,
      functionalPurple: functionalPurple ?? this.functionalPurple,
    );
  }

  @override
  ThemeColorTokens lerp(
    covariant ThemeExtension<ThemeColorTokens>? other,
    double t,
  ) {
    if (other is! ThemeColorTokens) return this;
    return ThemeColorTokens(
      background: Color.lerp(background, other.background, t)!,
      backgroundDarker: Color.lerp(
        backgroundDarker,
        other.backgroundDarker,
        t,
      )!,
      backgroundDark: Color.lerp(backgroundDark, other.backgroundDark, t)!,
      backgroundLight: Color.lerp(backgroundLight, other.backgroundLight, t)!,
      backgroundLighter: Color.lerp(
        backgroundLighter,
        other.backgroundLighter,
        t,
      )!,
      floating: Color.lerp(floating, other.floating, t)!,
      selection: Color.lerp(selection, other.selection, t)!,
      currentLine: Color.lerp(currentLine, other.currentLine, t)!,
      lineHighlightFallback: Color.lerp(
        lineHighlightFallback,
        other.lineHighlightFallback,
        t,
      )!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      comment: Color.lerp(comment, other.comment, t)!,
      pink: Color.lerp(pink, other.pink, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      green: Color.lerp(green, other.green, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
      red: Color.lerp(red, other.red, t)!,
      functionalRed: Color.lerp(functionalRed, other.functionalRed, t)!,
      functionalOrange: Color.lerp(
        functionalOrange,
        other.functionalOrange,
        t,
      )!,
      functionalGreen: Color.lerp(functionalGreen, other.functionalGreen, t)!,
      functionalCyan: Color.lerp(functionalCyan, other.functionalCyan, t)!,
      functionalPurple: Color.lerp(
        functionalPurple,
        other.functionalPurple,
        t,
      )!,
    );
  }
}
