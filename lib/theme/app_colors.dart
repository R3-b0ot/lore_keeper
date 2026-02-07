import 'package:flutter/material.dart';

class AppColors {
  // --- Dark Mode Palette (Purple Midnight) ---
  static const Color bgMain = Color(0xFF0F0A1E);
  static const Color bgPanel = Color(0xFF1A1231);
  static const Color bgPanelLighter = Color(
    0xFF251B45,
  ); // Lighter shade for panels
  static const Color bgHover = Color(0xFF251B45);

  // AAA Dark Mode
  static const Color bgMainAAA = Color(0xFF050209); // Nearly black
  static const Color bgPanelAAA = Color(0xFF0F0A1E); // Very dark purple
  static const Color textMainAAA = Color(0xFFFFFFFF); // Pure white
  static const Color textMutedAAA = Color(
    0xFFE9D5FF,
  ); // High contrast light purple

  static const Color textMain = Color(0xFFF4EBFF);
  static const Color textMuted = Color(0xFFD6BBFB);

  // --- Light Mode Palette (Lavender Mist) ---
  static const Color bgMainLight = Color(0xFFF9F5FF);
  static const Color bgPanelLight = Color(0xFFFFFFFF);
  static const Color bgPanelLighterLight = Color(
    0xFFF4EBFF,
  ); // Lighter shade for panels in light mode
  static const Color bgHoverLight = Color(0xFFF4EBFF);

  // AAA Light Mode
  static const Color bgMainLightAAA = Color(0xFFFFFFFF); // Pure white
  static const Color bgPanelLightAAA = Color(0xFFF8FAFC); // Very subtle grey
  static const Color textMainLightAAA = Color(0xFF000000); // Pure black
  static const Color textMutedLightAAA = Color(0xFF374151); // Dark gray

  static const Color textMainLight = Color(0xFF101828);
  static const Color textMutedLight = Color(0xFF667085);

  // --- Brand Colors (Core Purple) ---
  static const Color primary = Color(0xFF7F56D9); // Keep as shade of purple
  static const Color primaryLight = Color(0xFFB692F6);
  static const Color primaryDark = Color(0xFF6941C6);

  // AAA Compliant Variants
  static const Color primaryAAA = Color(
    0xFF4C1D95,
  ); // Deepest purple for AAA contrast
  static const Color onPrimaryAAA = Colors.white; // High contrast for AAA

  static const Color accentGlow = Color(0xFFD6BBFB);
  static const Color border = Color(0xFFD5D7DA);
  static const Color borderDark = Color(0xFF2E235C);

  // AAA Border Variants
  static const Color borderAAA = Color(
    0xFF4B5563,
  ); // Darker gray for light mode AAA
  static const Color borderDarkAAA = Color(
    0xFF6941C6,
  ); // Brighter purple/gray for dark mode AAA

  // --- Feedback Colors ---
  static const Color error = Color(0xFFF97066);
  static const Color warning = Color(0xFFFEC84B);
  static const Color success = Color(0xFF32D583);

  static const Color errorLight = Color(0xFF93000A);
  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color warningLight = Color(0xFF712200);
  static const Color warningDark = Color(
    0xFFFFCC00,
  ); // Brighter yellow for dark
  static const Color successLight = Color(0xFF004F2C);
  static const Color successDark = Color(0xFF32D583);

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

  static const BoxShadow shadow = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.4),
    offset: Offset(0, 12),
    blurRadius: 24,
    spreadRadius: -4,
  );

  static const BoxShadow shadowLight = BoxShadow(
    color: Color.fromRGBO(105, 65, 198, 0.1),
    offset: Offset(0, 8),
    blurRadius: 16,
    spreadRadius: -2,
  );

  // --- Gradients ---
  static const Gradient heroGradient = RadialGradient(
    center: Alignment.center,
    radius: 0.8,
    colors: [Color(0xFF251B45), Color(0xFF0F0A1E)],
  );

  static const Gradient heroGradientLight = RadialGradient(
    center: Alignment.center,
    radius: 0.8,
    colors: [Color(0xFFF9F5FF), Color(0xFFF4EBFF)],
  );

  static const LinearGradient primaryCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7F56D9), Color(0xFF6941C6)],
  );

  static const LinearGradient primaryCardGradientAAA = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4C1D95), Color(0xFF6941C6)],
  );

  // --- Panel Styling ---
  static const EdgeInsets panelTitlePadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 16,
  );

  static TextStyle panelTitleStyle(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontSize: 22, // Increased from 18
    fontWeight: FontWeight.bold, // Increased from w600
    color: Theme.of(context).brightness == Brightness.dark
        ? textMain
        : textMainLight,
  );

  static const LinearGradient actionCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1231), Color(0xFF251B45)],
  );

  static const LinearGradient actionCardGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF9F5FF)],
  );
}
