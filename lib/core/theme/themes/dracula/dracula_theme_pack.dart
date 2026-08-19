import 'package:flutter/material.dart';

import 'package:lore_keeper/core/theme/accessibility_rating.dart';
import 'package:lore_keeper/core/theme/theme_color_tokens.dart';
import 'package:lore_keeper/core/theme/theme_font_tokens.dart';
import 'package:lore_keeper/core/theme/theme_registry.dart';
import 'package:lore_keeper/theme/app_tokens.dart';
import 'dracula_colors.dart';

/// Official Dracula Theme Spec dual pack (Dracula Classic dark + Alucard Classic light).
class DraculaThemePack implements ThemePack {
  const DraculaThemePack();

  @override
  ThemePackMetadata get metadata => const ThemePackMetadata(
    id: 'dracula',
    displayName: 'Dracula',
    description: 'Dracula Classic (dark) & Alucard Classic (light) theme spec.',
    author: 'R3',
    version: '1.0.0',
  );

  @override
  ThemeColorTokens get darkColors => DraculaColors.darkTokens;

  @override
  ThemeColorTokens get lightColors => DraculaColors.lightTokens;

  @override
  ThemeFontTokens get fonts => const ThemeFontTokens(
    displayFamily: 'Inter',
    bodyFamily: 'Inter',
    monoFamily: 'Fira Code',
  );

  @override
  ThemeData buildThemeData({
    required bool isDark,
    required AccessibilityRating accessibilityRating,
  }) {
    final colors = isDark ? darkColors : lightColors;

    final colorScheme = isDark
        ? _darkColorScheme(colors)
        : _lightColorScheme(colors);

    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.pink,
      colorScheme: colorScheme,
      textTheme: _textTheme(colors),
      extensions: [colors, fonts],
      cardTheme: CardThemeData(
        color: colors.backgroundDark,
        elevation: AppElevation.flat,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderM,
          side: BorderSide(color: colors.currentLine),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.backgroundDark,
        elevation: AppElevation.flat,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderL,
          side: BorderSide(color: colors.currentLine),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: colors.foreground,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: colors.foreground,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.backgroundLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.m,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: colors.comment),
        labelStyle: AppTypography.bodyMedium.copyWith(color: colors.foreground),
        border: OutlineInputBorder(
          borderRadius: AppRadii.borderS,
          borderSide: BorderSide(color: colors.currentLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderS,
          borderSide: BorderSide(color: colors.currentLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderS,
          borderSide: BorderSide(color: colors.pink, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.currentLine,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ColorScheme _darkColorScheme(ThemeColorTokens c) {
    return ColorScheme.dark(
      primary: c.pink,
      onPrimary: Colors.black,
      primaryContainer: c.backgroundLight,
      onPrimaryContainer: c.foreground,
      secondary: c.purple,
      onSecondary: Colors.black,
      secondaryContainer: c.selection,
      onSecondaryContainer: c.foreground,
      tertiary: c.cyan,
      onTertiary: Colors.black,
      surface: c.backgroundDark,
      onSurface: c.foreground,
      onSurfaceVariant: c.comment,
      error: c.red,
      onError: Colors.black,
      outline: c.currentLine,
      outlineVariant: c.backgroundLight,
      surfaceContainerHighest: c.backgroundLight,
      surfaceContainerLowest: c.backgroundDarker,
    );
  }

  static ColorScheme _lightColorScheme(ThemeColorTokens c) {
    return ColorScheme.light(
      primary: c.pink,
      onPrimary: Colors.white,
      primaryContainer: c.backgroundLight,
      onPrimaryContainer: c.foreground,
      secondary: c.purple,
      onSecondary: Colors.white,
      secondaryContainer: c.selection,
      onSecondaryContainer: c.foreground,
      tertiary: c.cyan,
      onTertiary: Colors.white,
      surface: c.backgroundLight,
      onSurface: c.foreground,
      onSurfaceVariant: c.comment,
      error: c.red,
      onError: Colors.white,
      outline: c.currentLine,
      outlineVariant: c.backgroundDark,
      surfaceContainerHighest: c.backgroundLighter,
      surfaceContainerLowest: c.backgroundDarker,
    );
  }

  static TextTheme _textTheme(ThemeColorTokens c) {
    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(
        color: c.foreground,
        inherit: false,
      ),
      displayMedium: AppTypography.displayMedium.copyWith(
        color: c.foreground,
        inherit: false,
      ),
      displaySmall: AppTypography.displayMedium.copyWith(
        color: c.foreground,
        inherit: false,
      ),
      headlineLarge: AppTypography.displayLarge.copyWith(
        color: c.foreground,
        inherit: false,
      ),
      headlineMedium: AppTypography.displayMedium.copyWith(
        color: c.foreground,
        inherit: false,
      ),
      headlineSmall: AppTypography.titleLarge.copyWith(
        color: c.foreground,
        inherit: false,
      ),
      titleLarge: AppTypography.titleLarge.copyWith(
        color: c.foreground,
        inherit: false,
      ),
      titleMedium: AppTypography.titleMedium.copyWith(
        color: c.foreground,
        inherit: false,
      ),
      titleSmall: AppTypography.titleSmall.copyWith(
        color: c.foreground,
        inherit: false,
      ),
      bodyLarge: AppTypography.bodyLarge.copyWith(
        color: c.foreground,
        inherit: false,
      ),
      bodyMedium: AppTypography.bodyMedium.copyWith(
        color: c.foreground,
        inherit: false,
      ),
      bodySmall: AppTypography.bodySmall.copyWith(
        color: c.comment,
        inherit: false,
      ),
      labelLarge: AppTypography.labelLarge.copyWith(
        color: c.foreground,
        inherit: false,
      ),
      labelMedium: AppTypography.labelMedium.copyWith(
        color: c.comment,
        inherit: false,
      ),
      labelSmall: AppTypography.labelSmall.copyWith(
        color: c.comment,
        inherit: false,
      ),
    );
  }
}
