import 'package:flutter/material.dart';

class LoreCardTheme extends ThemeExtension<LoreCardTheme> {
  final Color? backgroundColor;

  const LoreCardTheme({this.backgroundColor});

  @override
  ThemeExtension<LoreCardTheme> copyWith({Color? backgroundColor}) {
    return LoreCardTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  @override
  ThemeExtension<LoreCardTheme> lerp(
    ThemeExtension<LoreCardTheme>? other,
    double t,
  ) {
    if (other is! LoreCardTheme) return this;
    return LoreCardTheme(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
    );
  }
}

class FantasyBorderTheme extends ThemeExtension<FantasyBorderTheme> {
  final Color? borderColor;

  const FantasyBorderTheme({this.borderColor});

  @override
  ThemeExtension<FantasyBorderTheme> copyWith({Color? borderColor}) {
    return FantasyBorderTheme(borderColor: borderColor ?? this.borderColor);
  }

  @override
  ThemeExtension<FantasyBorderTheme> lerp(
    ThemeExtension<FantasyBorderTheme>? other,
    double t,
  ) {
    if (other is! FantasyBorderTheme) return this;
    return FantasyBorderTheme(
      borderColor: Color.lerp(borderColor, other.borderColor, t),
    );
  }
}
