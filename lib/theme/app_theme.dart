import 'package:flutter/material.dart';
import 'package:lore_keeper/providers/theme_provider.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData getDarkTheme(AccessibilityRating rating) {
    final isAAA = rating == AccessibilityRating.aaa;

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: isAAA ? AppColors.bgMainAAA : AppColors.bgMain,
      primaryColor: isAAA ? AppColors.primaryAAA : AppColors.primary,
      colorScheme: ColorScheme.dark(
        primary: isAAA ? AppColors.primaryAAA : AppColors.primaryAAA,
        secondary: AppColors.primaryLight,
        surface: isAAA ? AppColors.bgPanelAAA : AppColors.bgPanel,
        error: AppColors.errorDark,
        onPrimary: AppColors.onPrimaryAAA,
        onSecondary: AppColors.bgMain,
        onSurface: isAAA ? AppColors.textMainAAA : AppColors.textMain,
        onSurfaceVariant: isAAA ? AppColors.textMutedAAA : AppColors.textMuted,
        onError: Colors.black,
        outline: isAAA ? AppColors.borderDarkAAA : AppColors.borderDark,
        primaryContainer: isAAA ? AppColors.primaryAAA : AppColors.primaryDark,
        onPrimaryContainer: Colors.white,
        secondaryContainer: const Color(0xFF2E235C),
        onSecondaryContainer: isAAA
            ? AppColors.textMainAAA
            : AppColors.textMain,
        tertiaryContainer: const Color(0xFF472D1B),
        onTertiaryContainer: isAAA ? AppColors.textMainAAA : AppColors.textMain,
        surfaceContainerHighest: const Color(0xFF251B45),
        surfaceContainerLowest: isAAA ? AppColors.bgMainAAA : AppColors.bgMain,
      ),
      textTheme: _buildTextTheme(isAAA, true),
      elevatedButtonTheme: _elevatedButtonTheme(true),
      filledButtonTheme: _filledButtonTheme(true),
      textButtonTheme: _textButtonTheme(true),
      outlinedButtonTheme: _outlinedButtonTheme(true, isAAA),
      inputDecorationTheme: _inputDecorationTheme(true, isAAA),
      tabBarTheme: _tabBarTheme(true, isAAA),
      useMaterial3: true,
    );
  }

  static ThemeData getLightTheme(AccessibilityRating rating) {
    final isAAA = rating == AccessibilityRating.aaa;

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: isAAA
          ? AppColors.bgMainLightAAA
          : AppColors.bgMainLight,
      primaryColor: AppColors.primaryDark,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryAAA,
        onPrimary: AppColors.onPrimaryAAA,
        secondary: AppColors.primary,
        onSecondary: Colors.white,
        surface: isAAA ? AppColors.bgPanelLightAAA : AppColors.bgPanelLight,
        onSurface: isAAA ? AppColors.textMainLightAAA : AppColors.textMainLight,
        error: AppColors.error,
        onError: Colors.white,
        outline: isAAA ? AppColors.borderAAA : AppColors.border,
        primaryContainer: const Color(0xFFF4EBFF),
        onPrimaryContainer: AppColors.primaryDark,
        surfaceContainerHighest: const Color(0xFFF4EBFF),
        surfaceContainerLowest: const Color(0xFFFFFFFF),
      ),
      textTheme: _buildTextTheme(isAAA, false),
      elevatedButtonTheme: _elevatedButtonTheme(false),
      filledButtonTheme: _filledButtonTheme(false),
      textButtonTheme: _textButtonTheme(false),
      outlinedButtonTheme: _outlinedButtonTheme(false, isAAA),
      inputDecorationTheme: _inputDecorationTheme(false, isAAA),
      tabBarTheme: _tabBarTheme(false, isAAA),
      useMaterial3: true,
    );
  }

  static TextTheme _buildTextTheme(bool isAAA, bool isDark) {
    final mainColor = isDark
        ? (isAAA ? AppColors.textMainAAA : AppColors.textMain)
        : (isAAA ? AppColors.textMainLightAAA : AppColors.textMainLight);

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w300,
        fontSize: 57,
        color: mainColor,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 45,
        color: mainColor,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 36,
        color: mainColor,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 32,
        color: mainColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 28,
        color: mainColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 24,
        color: mainColor,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 22,
        color: mainColor,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: mainColor,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: mainColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: mainColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: mainColor,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 12,
        color: mainColor,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: mainColor,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 12,
        color: mainColor,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 11,
        color: mainColor,
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(bool isDark) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppColors.primaryAAA : AppColors.primaryDark,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme(bool isDark) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: isDark ? AppColors.primaryAAA : AppColors.primaryDark,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(bool isDark) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isDark
            ? AppColors.primaryLight
            : AppColors.primaryDark,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(bool isDark, bool isAAA) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark
            ? (isAAA ? AppColors.textMainAAA : AppColors.textMain)
            : (isAAA ? AppColors.textMainLightAAA : AppColors.textMainLight),
        side: BorderSide(
          color: isDark
              ? (isAAA ? AppColors.borderDarkAAA : AppColors.borderDark)
              : (isAAA ? AppColors.borderAAA : AppColors.border),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(bool isDark, bool isAAA) {
    final borderColor = isDark
        ? (isAAA ? AppColors.borderDarkAAA : AppColors.borderDark)
        : (isAAA ? AppColors.borderAAA : AppColors.border);

    return InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? (isAAA ? AppColors.bgMainAAA : AppColors.bgMain)
          : (isAAA ? AppColors.bgPanelLightAAA : AppColors.bgPanelLight),
      hintStyle: TextStyle(
        fontSize: 12,
        color:
            (isDark
                    ? (isAAA ? AppColors.textMutedAAA : AppColors.textMuted)
                    : (isAAA
                          ? AppColors.textMutedLightAAA
                          : AppColors.textMutedLight))
                .withValues(alpha: 0.4),
      ),
      labelStyle: TextStyle(
        color: isDark
            ? (isAAA ? AppColors.textMainAAA : AppColors.textMain)
            : (isAAA ? AppColors.textMainLightAAA : AppColors.textMainLight),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.primaryAAA,
          width: 2,
        ), // AAA Primary for focus
      ),
    );
  }

  static TabBarThemeData _tabBarTheme(bool isDark, bool isAAA) {
    return TabBarThemeData(
      labelColor: isDark
          ? (isAAA ? Colors.white : AppColors.primaryLight)
          : AppColors.primaryDark,
      unselectedLabelColor: isDark
          ? (isAAA ? AppColors.textMutedAAA : AppColors.textMuted)
          : AppColors.textMutedLight,
      indicatorColor: isDark
          ? (isAAA ? Colors.white : AppColors.primaryLight)
          : AppColors.primaryDark,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.normal,
        fontSize: 13,
      ),
    );
  }
}
