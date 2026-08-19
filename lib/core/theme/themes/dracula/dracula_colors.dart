import 'package:flutter/material.dart';
import 'package:lore_keeper/core/theme/theme_color_tokens.dart';

/// Official Dracula Theme Spec color tokens.
///
/// Contains exact hex palette values for Dracula Classic (dark) and
/// Alucard Classic (light), along with standard functional colors.
abstract class DraculaColors {
  // --- Dracula Classic (Dark) ---
  static const Color darkBackground = Color(0xFF282A36);
  static const Color darkBackgroundDarker = Color(0xFF191A21);
  static const Color darkBackgroundDark = Color(0xFF21222C);
  static const Color darkBackgroundLight = Color(0xFF343746);
  static const Color darkBackgroundLighter = Color(0xFF424450);
  static const Color darkFloating = Color(0xFF343746);
  static const Color darkCurrentLine = Color(0xFF6272A4);
  static const Color darkSelection = Color(0xFF44475A);
  static const Color darkForeground = Color(0xFFF8F8F2);
  static const Color darkComment = Color(0xFF6272A4);
  static const Color darkPink = Color(0xFFFF79C6);
  static const Color darkPurple = Color(0xFFBD93F9);
  static const Color darkCyan = Color(0xFF8BE9FD);
  static const Color darkGreen = Color(0xFF50FA7B);
  static const Color darkOrange = Color(0xFFFFB86C);
  static const Color darkYellow = Color(0xFFF1FA8C);
  static const Color darkRed = Color(0xFFFF5555);
  static const Color darkLineHighlightFallback = Color(0xFF353747);

  // --- Alucard Classic (Light) ---
  static const Color lightBackground = Color(0xFFFFFBEB);
  static const Color lightBackgroundDarker = Color(0xFFBCBAB3);
  static const Color lightBackgroundDark = Color(0xFFCECCC0);
  static const Color lightBackgroundLight = Color(0xFFDEDCCF);
  static const Color lightBackgroundLighter = Color(0xFFECE9DF);
  static const Color lightFloating = Color(0xFFEFEDDC);
  static const Color lightCurrentLine = Color(0xFF6C664B);
  static const Color lightSelection = Color(0xFFCFCFDE);
  static const Color lightForeground = Color(0xFF1F1F1F);
  static const Color lightComment = Color(0xFF6C664B);
  static const Color lightPink = Color(0xFFA3144D);
  static const Color lightPurple = Color(0xFF644AC9);
  static const Color lightCyan = Color(0xFF036A96);
  static const Color lightGreen = Color(0xFF14710A);
  static const Color lightOrange = Color(0xFFA34D14);
  static const Color lightYellow = Color(0xFF846E15);
  static const Color lightRed = Color(0xFFCB3A2A);
  static const Color lightLineHighlightFallback = Color(0xFFE2DECA);

  // --- Shared Functional Colors ---
  static const Color functionalRed = Color(0xFFDE5735);
  static const Color functionalOrange = Color(0xFFA39514);
  static const Color functionalGreen = Color(0xFF089108);
  static const Color functionalCyan = Color(0xFF0081D6);
  static const Color functionalPurple = Color(0xFF815CD6);

  /// Pre-built [ThemeColorTokens] for Dracula Classic (Dark).
  static const ThemeColorTokens darkTokens = ThemeColorTokens(
    background: darkBackground,
    backgroundDarker: darkBackgroundDarker,
    backgroundDark: darkBackgroundDark,
    backgroundLight: darkBackgroundLight,
    backgroundLighter: darkBackgroundLighter,
    floating: darkFloating,
    selection: darkSelection,
    currentLine: darkCurrentLine,
    lineHighlightFallback: darkLineHighlightFallback,
    foreground: darkForeground,
    comment: darkComment,
    pink: darkPink,
    purple: darkPurple,
    cyan: darkCyan,
    green: darkGreen,
    orange: darkOrange,
    yellow: darkYellow,
    red: darkRed,
    functionalRed: functionalRed,
    functionalOrange: functionalOrange,
    functionalGreen: functionalGreen,
    functionalCyan: functionalCyan,
    functionalPurple: functionalPurple,
  );

  /// Pre-built [ThemeColorTokens] for Alucard Classic (Light).
  static const ThemeColorTokens lightTokens = ThemeColorTokens(
    background: lightBackground,
    backgroundDarker: lightBackgroundDarker,
    backgroundDark: lightBackgroundDark,
    backgroundLight: lightBackgroundLight,
    backgroundLighter: lightBackgroundLighter,
    floating: lightFloating,
    selection: lightSelection,
    currentLine: lightCurrentLine,
    lineHighlightFallback: lightLineHighlightFallback,
    foreground: lightForeground,
    comment: lightComment,
    pink: lightPink,
    purple: lightPurple,
    cyan: lightCyan,
    green: lightGreen,
    orange: lightOrange,
    yellow: lightYellow,
    red: lightRed,
    functionalRed: functionalRed,
    functionalOrange: functionalOrange,
    functionalGreen: functionalGreen,
    functionalCyan: functionalCyan,
    functionalPurple: functionalPurple,
  );
}
