import 'package:flutter/material.dart';
import 'package:lore_keeper/core/theme/theme_color_tokens.dart';
import 'package:lore_keeper/theme/app_colors.dart';

/// Slate Minimal theme palette color tokens.
abstract class MinimalColors {
  /// Pre-built [ThemeColorTokens] for Minimal Dark mode.
  static const ThemeColorTokens darkTokens = ThemeColorTokens(
    background: AppColors.bgMain,
    backgroundDarker: AppColors.bgMainAAA,
    backgroundDark: AppColors.bgPanel,
    backgroundLight: AppColors.bgPanelLighter,
    backgroundLighter: Color(0xFF475569),
    floating: AppColors.bgPanelLighter,
    selection: Color(0xFF334155),
    currentLine: Color(0xFF243248),
    lineHighlightFallback: Color(0xFF243248),
    foreground: AppColors.textMain,
    comment: AppColors.textMuted,
    pink: Color(0xFFEC4899),
    purple: Color(0xFFA855F7),
    cyan: Color(0xFF06B6D4),
    green: Color(0xFF10B981),
    orange: Color(0xFFF97316),
    yellow: Color(0xFFEAB308),
    red: AppColors.error,
    functionalRed: AppColors.error,
    functionalOrange: AppColors.warning,
    functionalGreen: AppColors.success,
    functionalCyan: Color(0xFF0284C7),
    functionalPurple: Color(0xFF7C3AED),
  );

  /// Pre-built [ThemeColorTokens] for Minimal Light mode.
  static const ThemeColorTokens lightTokens = ThemeColorTokens(
    background: AppColors.bgMainLight,
    backgroundDarker: Color(0xFFE2E8F0),
    backgroundDark: Color(0xFFF1F5F9),
    backgroundLight: AppColors.bgPanelLight,
    backgroundLighter: Color(0xFFF8FAFC),
    floating: Color(0xFFF1F5F9),
    selection: Color(0xFFE2E8F0),
    currentLine: Color(0xFFF1F5F9),
    lineHighlightFallback: Color(0xFFE2E8F0),
    foreground: AppColors.textMainLight,
    comment: AppColors.textMutedLight,
    pink: Color(0xFFDB2777),
    purple: Color(0xFF9333EA),
    cyan: Color(0xFF0891B2),
    green: Color(0xFF059669),
    orange: Color(0xFFEA580C),
    yellow: Color(0xFFCA8A04),
    red: AppColors.errorLight,
    functionalRed: AppColors.errorLight,
    functionalOrange: AppColors.warningLight,
    functionalGreen: AppColors.successLight,
    functionalCyan: Color(0xFF0284C7),
    functionalPurple: Color(0xFF6D28D9),
  );
}
