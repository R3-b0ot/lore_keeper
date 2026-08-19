import 'package:flutter/material.dart';
import 'package:lore_keeper/providers/theme_provider.dart';
import 'app_colors.dart';
import 'app_tokens.dart';
import 'theme_extensions.dart';

class AppTheme {
  static ThemeData getDarkTheme(AccessibilityRating rating) {
    final isAAA = rating == AccessibilityRating.aaa;

    final primaryColor = isAAA ? AppColors.primaryLight : AppColors.primary;
    final surfaceColor = isAAA ? AppColors.bgPanelAAA : AppColors.bgPanel;
    final scaffoldBg = isAAA ? AppColors.bgMainAAA : AppColors.bgMain;
    final textColor = isAAA ? AppColors.textMainAAA : AppColors.textMain;
    final textMutedColor = isAAA ? AppColors.textMutedAAA : AppColors.textMuted;
    final borderColor = isAAA ? AppColors.borderDarkAAA : AppColors.borderDark;

    final colorScheme = ColorScheme.dark(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: isAAA ? const Color(0xFF2E3B52) : const Color(0xFF1E293B),
      onPrimaryContainer: Colors.white,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.bgMain,
      secondaryContainer: const Color(0xFF243248),
      onSecondaryContainer: textColor,
      tertiaryContainer: const Color(0xFF2D3748),
      onTertiaryContainer: textColor,
      surface: surfaceColor,
      onSurface: textColor,
      onSurfaceVariant: textMutedColor,
      error: AppColors.errorDark,
      onError: Colors.black,
      outline: borderColor,
      outlineVariant: const Color(0xFF1E293B),
      surfaceContainerHighest: const Color(0xFF334155),
      surfaceContainerLowest: scaffoldBg,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primaryColor,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(textColor, textMutedColor),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: AppElevation.flat,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderM,
          side: BorderSide(color: borderColor),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: AppElevation.flat,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderL,
          side: BorderSide(color: borderColor),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(color: textColor, inherit: false),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: textColor),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceColor,
        elevation: AppElevation.medium,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderM,
          side: BorderSide(color: borderColor),
        ),
      ),
      elevatedButtonTheme: _elevatedButtonTheme(primaryColor, Colors.white),
      filledButtonTheme: _filledButtonTheme(primaryColor, Colors.white),
      textButtonTheme: _textButtonTheme(primaryColor),
      outlinedButtonTheme: _outlinedButtonTheme(primaryColor, borderColor, textColor),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: colorScheme.surfaceContainerHighest,
        borderColor: borderColor,
        focusedColor: primaryColor,
        textColor: textColor,
        mutedColor: textMutedColor,
      ),
      tabBarTheme: _tabBarTheme(primaryColor, textMutedColor),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(
        color: textColor,
        size: AppIconSizes.m,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: AppRadii.borderS,
          border: Border.all(color: borderColor),
        ),
        textStyle: AppTypography.bodySmall.copyWith(color: textColor),
      ),
      extensions: <ThemeExtension<dynamic>>[
        LoreCardTheme(backgroundColor: surfaceColor),
        FantasyBorderTheme(borderColor: borderColor),
      ],
      useMaterial3: true,
    );
  }

  static ThemeData getLightTheme(AccessibilityRating rating) {
    final isAAA = rating == AccessibilityRating.aaa;

    final primaryColor = isAAA ? AppColors.primaryAAA : AppColors.primaryDark;
    final surfaceColor = isAAA ? AppColors.bgPanelLightAAA : AppColors.bgPanelLight;
    final scaffoldBg = isAAA ? AppColors.bgMainLightAAA : AppColors.bgMainLight;
    final textColor = isAAA ? AppColors.textMainLightAAA : AppColors.textMainLight;
    final textMutedColor = isAAA ? AppColors.textMutedLightAAA : AppColors.textMutedLight;
    final borderColor = isAAA ? AppColors.borderAAA : AppColors.border;

    final colorScheme = ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFEEF2FF),
      onPrimaryContainer: primaryColor,
      secondary: AppColors.primary,
      onSecondary: Colors.white,
      surface: surfaceColor,
      onSurface: textColor,
      onSurfaceVariant: textMutedColor,
      error: AppColors.error,
      onError: Colors.white,
      outline: borderColor,
      outlineVariant: const Color(0xFFF1F5F9),
      surfaceContainerHighest: const Color(0xFFF1F5F9),
      surfaceContainerLowest: Colors.white,
    );

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primaryColor,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(textColor, textMutedColor),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: AppElevation.flat,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderM,
          side: BorderSide(color: borderColor),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: AppElevation.flat,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderL,
          side: BorderSide(color: borderColor),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(color: textColor, inherit: false),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: textColor),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceColor,
        elevation: AppElevation.medium,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderM,
          side: BorderSide(color: borderColor),
        ),
      ),
      elevatedButtonTheme: _elevatedButtonTheme(primaryColor, Colors.white),
      filledButtonTheme: _filledButtonTheme(primaryColor, Colors.white),
      textButtonTheme: _textButtonTheme(primaryColor),
      outlinedButtonTheme: _outlinedButtonTheme(primaryColor, borderColor, textColor),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: colorScheme.surfaceContainerHighest,
        borderColor: borderColor,
        focusedColor: primaryColor,
        textColor: textColor,
        mutedColor: textMutedColor,
      ),
      tabBarTheme: _tabBarTheme(primaryColor, textMutedColor),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(
        color: textColor,
        size: AppIconSizes.m,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: AppRadii.borderS,
        ),
        textStyle: AppTypography.bodySmall.copyWith(color: Colors.white),
      ),
      extensions: <ThemeExtension<dynamic>>[
        LoreCardTheme(backgroundColor: surfaceColor),
        FantasyBorderTheme(borderColor: borderColor),
      ],
      useMaterial3: true,
    );
  }

  static TextTheme _buildTextTheme(Color textMain, Color textMuted) {
    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: textMain, inherit: false),
      displayMedium: AppTypography.displayMedium.copyWith(color: textMain, inherit: false),
      displaySmall: AppTypography.displayMedium.copyWith(color: textMain, inherit: false),
      headlineLarge: AppTypography.displayLarge.copyWith(color: textMain, inherit: false),
      headlineMedium: AppTypography.displayMedium.copyWith(color: textMain, inherit: false),
      headlineSmall: AppTypography.titleLarge.copyWith(color: textMain, inherit: false),
      titleLarge: AppTypography.titleLarge.copyWith(color: textMain, inherit: false),
      titleMedium: AppTypography.titleMedium.copyWith(color: textMain, inherit: false),
      titleSmall: AppTypography.titleSmall.copyWith(color: textMain, inherit: false),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: textMain, inherit: false),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: textMain, inherit: false),
      bodySmall: AppTypography.bodySmall.copyWith(color: textMuted, inherit: false),
      labelLarge: AppTypography.labelLarge.copyWith(color: textMain, inherit: false),
      labelMedium: AppTypography.labelMedium.copyWith(color: textMuted, inherit: false),
      labelSmall: AppTypography.labelSmall.copyWith(color: textMuted, inherit: false),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(Color bg, Color fg) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderS,
        ),
        textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme(Color bg, Color fg) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderS,
        ),
        textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(Color fg) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderS,
        ),
        textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(
    Color fg,
    Color borderColor,
    Color textColor,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderS,
        ),
        textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }





  static InputDecorationTheme _inputDecorationTheme({
    required Color fillColor,
    required Color borderColor,
    required Color focusedColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.m,
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(color: mutedColor, inherit: false),
      labelStyle: AppTypography.bodyMedium.copyWith(color: textColor, inherit: false),
      border: OutlineInputBorder(
        borderRadius: AppRadii.borderS,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.borderS,
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.borderS,
        borderSide: BorderSide(color: focusedColor, width: 2),
      ),
    );
  }

  static TabBarThemeData _tabBarTheme(Color labelColor, Color unselectedLabelColor) {
    return TabBarThemeData(
      labelColor: labelColor,
      unselectedLabelColor: unselectedLabelColor,
      indicatorColor: labelColor,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: AppTypography.labelLarge,
    );
  }

  static ThemeData get draculaTheme => getDarkTheme(AccessibilityRating.aa);
  static ThemeData get alucardTheme => getLightTheme(AccessibilityRating.aa);
}
