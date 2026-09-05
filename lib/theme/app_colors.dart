import 'package:flutter/material.dart';

/// Lore Keeper Color Palette & Surface Tokens.
///
/// Designed for a calm, content-first worldbuilding and writing workspace.
/// Uses refined neutral slate surfaces with a single distinctive accent color used sparingly.
class AppColors {
  // --- Dark Mode Palette (Refined Slate / Charcoal) ---
  /// Main scaffold background for dark mode (Slate 900)
  static const Color bgMain = Color(0xFF0F172A);

  /// Panel & sidebar surface for dark mode (Slate 800)
  static const Color bgPanel = Color(0xFF1E293B);

  /// Elevated panel / card surface for dark mode (Slate 700)
  static const Color bgPanelLighter = Color(0xFF334155);

  /// Hover state background for dark mode
  static const Color bgHover = Color(0xFF243248);

  // AAA Dark Mode Palette
  static const Color bgMainAAA = Color(0xFF020617);
  static const Color bgPanelAAA = Color(0xFF0F172A);
  static const Color textMainAAA = Color(0xFFFFFFFF);
  static const Color textMutedAAA = Color(0xFFE2E8F0);

  /// Primary body text for dark mode (Slate 50)
  static const Color textMain = Color(0xFFF8FAFC);

  /// Muted / secondary text for dark mode (Slate 400)
  static const Color textMuted = Color(0xFF94A3B8);

  // --- Light Mode Palette (Calm Studio Slate Paper) ---
  /// Main scaffold background for light mode (Slate 50)
  static const Color bgMainLight = Color(0xFFF8FAFC);

  /// Panel & sidebar surface for light mode (Pure White)
  static const Color bgPanelLight = Color(0xFFFFFFFF);

  /// Elevated panel / card surface for light mode (Slate 100)
  static const Color bgPanelLighterLight = Color(0xFFF1F5F9);

  /// Hover state background for light mode
  static const Color bgHoverLight = Color(0xFFF1F5F9);

  // AAA Light Mode Palette
  static const Color bgMainLightAAA = Color(0xFFFFFFFF);
  static const Color bgPanelLightAAA = Color(0xFFF8FAFC);
  static const Color textMainLightAAA = Color(0xFF000000);
  static const Color textMutedLightAAA = Color(0xFF334155);

  /// Primary body text for light mode (Slate 900)
  static const Color textMainLight = Color(0xFF0F172A);

  /// Muted / secondary text for light mode (Slate 600)
  static const Color textMutedLight = Color(0xFF475569);

  // --- Brand Colors (Distinctive Slate Indigo Accent) ---
  /// Core primary accent used sparingly (Indigo 500)
  static const Color primary = Color(0xFF6366F1);

  /// Light accent variant for dark surfaces (Indigo 400)
  static const Color primaryLight = Color(0xFF818CF8);

  /// Dark accent variant for light surfaces (Indigo 600)
  static const Color primaryDark = Color(0xFF4F46E5);

  // AAA Compliant Accent Variants
  static const Color primaryAAA = Color(0xFF4338CA);
  static const Color onPrimaryAAA = Colors.white;

  /// Subtle accent glow for selected items
  static const Color accentGlow = Color(0xFF818CF8);

  // --- Borders ---
  /// Subtle border for light surfaces (Slate 200)
  static const Color border = Color(0xFFE2E8F0);

  /// Subtle border for dark surfaces (Slate 700)
  static const Color borderDark = Color(0xFF334155);

  // AAA Border Variants
  static const Color borderAAA = Color(0xFF94A3B8);
  static const Color borderDarkAAA = Color(0xFF64748B);

  // --- Feedback Colors ---
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);

  static const Color errorLight = Color(0xFFDC2626);
  static const Color errorDark = Color(0xFFF87171);
  static const Color warningLight = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color successLight = Color(0xFF059669);
  static const Color successDark = Color(0xFF34D399);

  static Color getError(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? errorDark : errorLight;

  static Color getWarning(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? warningDark
      : warningLight;

  static Color getSuccess(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? successDark
      : successLight;

  // --- Refined Shadows (Calm & Subtle) ---
  static const BoxShadow shadow = BoxShadow(
    color: Color.fromRGBO(15, 23, 42, 0.25),
    offset: Offset(0, 4),
    blurRadius: 16,
    spreadRadius: -2,
  );

  static const BoxShadow shadowLight = BoxShadow(
    color: Color.fromRGBO(15, 23, 42, 0.05),
    offset: Offset(0, 4),
    blurRadius: 12,
    spreadRadius: -2,
  );

  // --- Refined Gradients (Subtle Tonal Transitions) ---
  static const Gradient heroGradient = RadialGradient(
    center: Alignment.center,
    radius: 1.0,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  static const Gradient heroGradientLight = RadialGradient(
    center: Alignment.center,
    radius: 1.0,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
  );

  static const LinearGradient primaryCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
  );

  static const LinearGradient primaryCardGradientAAA = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4338CA), Color(0xFF3730A3)],
  );

  // --- Panel Styling ---
  static const EdgeInsets panelTitlePadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 16,
  );

  static TextStyle panelTitleStyle(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).brightness == Brightness.dark
        ? textMain
        : textMainLight,
  );

  static const LinearGradient actionCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF1E293B)],
  );

  static const LinearGradient actionCardGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
  );

  // --- Dracula Colors ---
  static const Color draculaBackground = Color(0xFF282A36);
  static const Color draculaForeground = Color(0xFFF8F8F2);
  static const Color draculaPrimary = Color(0xFFFF79C6);
  static const Color draculaSecondary = Color(0xFFBD93F9);
  static const Color draculaTertiary = Color(0xFF8BE9FD);
  static const Color draculaError = Color(0xFFFF5555);
  static const Color draculaWarning = Color(0xFFFFB86C);
  static const Color draculaSuccess = Color(0xFF50FA7B);
  static const Color draculaMuted = Color(0xFF6272A4);
  static const Color draculaSelection = Color(0xFF44475A);
  static const Color draculaUIBackground = Color(0xFF191A21);

  // --- Alucard Colors ---
  static const Color alucardBackground = Color(0xFFFFFBEB);
  static const Color alucardForeground = Color(0xFF1F1F1F);
  static const Color alucardPrimary = Color(0xFFA3144D);
  static const Color alucardSecondary = Color(0xFF644AC9);
  static const Color alucardTertiary = Color(0xFF036A96);
  static const Color alucardError = Color(0xFFCB3A2A);
  static const Color alucardWarning = Color(0xFFA34D14);
  static const Color alucardSuccess = Color(0xFF14710A);
  static const Color alucardMuted = Color(0xFF6C664B);
  static const Color alucardSelection = Color(0xFFCFCFDE);
  static const Color alucardUIBackground = Color(0xFFBCBAB3);
}
