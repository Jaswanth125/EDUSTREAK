import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ─── PREMIUM DARK PALETTE ────────────────────────────────────────────────
  static const Color darkBackground     = Color(0xFF080C1A); // Deep midnight
  static const Color darkSurface        = Color(0xFF0E1525); // Elevated surface
  static const Color darkSurfaceVariant = Color(0xFF151E35); // Card base
  static const Color darkGlass          = Color(0xFF1A2340); // Glassmorphism base
  static const Color darkBorder         = Color(0xFF232D4A); // Border
  static const Color darkBorderGlow     = Color(0xFF2E3D6A); // Glowing border

  // ─── BRAND ACCENT SYSTEM ─────────────────────────────────────────────────
  static const Color primaryColor   = Color(0xFF7C6FFF); // Electric violet
  static const Color primaryLight   = Color(0xFFA599FF); // Lighter violet
  static const Color primaryDark    = Color(0xFF5A4FBF); // Deeper violet
  static const Color secondaryColor = Color(0xFF00D4AA); // Neon teal/mint
  static const Color secondaryLight = Color(0xFF33FFCC); // Bright mint
  static const Color accentColor    = Color(0xFFFF6B6B); // Coral/streak
  static const Color accentLight    = Color(0xFFFF9999); // Light coral
  static const Color goldColor      = Color(0xFFFFD700); // Gold
  static const Color goldLight      = Color(0xFFFFE85A); // Bright gold
  static const Color roseColor      = Color(0xFFFF4E8A); // Hot pink
  static const Color cyanColor      = Color(0xFF00C9E8); // Electric cyan
  static const Color streakColor    = Color(0xFFFF7043); // Fire orange
  static const Color streakLight    = Color(0xFFFF9A77); // Light fire
  static const Color successColor   = Color(0xFF00E096); // Emerald green
  static const Color successLight   = Color(0xFF66FFBF); // Light emerald
  static const Color warningColor   = Color(0xFFFFB800); // Amber
  static const Color errorColor     = Color(0xFFFF4466); // Error red

  // ─── TEXT ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF0F3FF); // Almost white, slightly blue
  static const Color textSecondary = Color(0xFFADB8D9); // Muted blue-white
  static const Color textTertiary  = Color(0xFF5E6D8A); // Dimmed
  static const Color textAccent    = Color(0xFF7C6FFF); // Violet for highlights

  // ─── LIGHT PALETTE ───────────────────────────────────────────────────────
  static const Color lightBackground     = Color(0xFFF2F4FC);
  static const Color lightSurface        = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEEF1FA);
  static const Color lightBorder         = Color(0xFFDDE3F5);
  static const Color lightTextPrimary    = Color(0xFF0E1534);
  static const Color lightTextSecondary  = Color(0xFF445377);
  static const Color lightTextTertiary   = Color(0xFF8B9EC5);

  // ─── GRADIENTS ───────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C6FFF), Color(0xFFAB6FFF), Color(0xFF6FC5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF00A8E6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient streakGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF4E8A), Color(0xFFFF7043)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF9800), Color(0xFFFFD700)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00E096), Color(0xFF00C9E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFFF4E8A), Color(0xFFFF7043)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBaseGradient = LinearGradient(
    colors: [Color(0xFF0A0F20), Color(0xFF0E1525), Color(0xFF080C1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x1AFFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF151E35), Color(0xFF0E1525)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color primaryGlow = Color(0xFFA599FF);
  static const Color secondaryGlow = Color(0xFF33FFCC);
  static const Color accentGlow = Color(0xFFFF9999);
  static const Color streakGlow = Color(0xFFFF9A77);

  static List<BoxShadow> get cardGlowShadow => elevatedCardShadow;

  // ─── BOX SHADOWS ─────────────────────────────────────────────────────────
  static List<BoxShadow> primaryGlowShadow = [
    BoxShadow(color: primaryColor.withOpacity(0.5), blurRadius: 24, spreadRadius: -4, offset: const Offset(0, 8)),
    BoxShadow(color: primaryColor.withOpacity(0.25), blurRadius: 50, spreadRadius: -10, offset: const Offset(0, 18)),
  ];

  static List<BoxShadow> secondaryGlowShadow = [
    BoxShadow(color: secondaryColor.withOpacity(0.5), blurRadius: 24, spreadRadius: -4, offset: const Offset(0, 8)),
    BoxShadow(color: secondaryColor.withOpacity(0.2), blurRadius: 50, spreadRadius: -10, offset: const Offset(0, 18)),
  ];

  static List<BoxShadow> streakGlowShadow = [
    BoxShadow(color: streakColor.withOpacity(0.6), blurRadius: 28, spreadRadius: -4, offset: const Offset(0, 8)),
    BoxShadow(color: streakColor.withOpacity(0.3), blurRadius: 60, spreadRadius: -12, offset: const Offset(0, 20)),
  ];

  static List<BoxShadow> goldGlowShadow = [
    BoxShadow(color: goldColor.withOpacity(0.5), blurRadius: 24, spreadRadius: -4, offset: const Offset(0, 8)),
    BoxShadow(color: goldColor.withOpacity(0.2), blurRadius: 50, spreadRadius: -10, offset: const Offset(0, 18)),
  ];

  static List<BoxShadow> successGlowShadow = [
    BoxShadow(color: successColor.withOpacity(0.45), blurRadius: 24, spreadRadius: -4, offset: const Offset(0, 8)),
    BoxShadow(color: successColor.withOpacity(0.2), blurRadius: 50, spreadRadius: -10, offset: const Offset(0, 18)),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 20, spreadRadius: -4, offset: const Offset(0, 8)),
    BoxShadow(color: primaryColor.withOpacity(0.06), blurRadius: 40, spreadRadius: -8, offset: const Offset(0, 16)),
  ];

  static List<BoxShadow> elevatedCardShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 30, spreadRadius: -6, offset: const Offset(0, 12)),
    BoxShadow(color: primaryColor.withOpacity(0.12), blurRadius: 60, spreadRadius: -15, offset: const Offset(0, 25)),
  ];

  // ─── BORDER RADIUS ───────────────────────────────────────────────────────
  static const BorderRadius radiusXS  = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusSM  = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusMD  = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusLG  = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusXL  = BorderRadius.all(Radius.circular(32));
  static const BorderRadius radiusXXL = BorderRadius.all(Radius.circular(48));

  // ─── HELPER: Glass Card Decoration ───────────────────────────────────────
  static BoxDecoration glassCard({Color? borderColor, List<BoxShadow>? shadows}) {
    return BoxDecoration(
      gradient: glassGradient,
      borderRadius: radiusLG,
      border: Border.all(
        color: (borderColor ?? primaryColor).withOpacity(0.15),
        width: 1.2,
      ),
      boxShadow: shadows ?? cardShadow,
    );
  }

  static BoxDecoration premiumCard({LinearGradient? gradient, Color? glowColor}) {
    return BoxDecoration(
      gradient: gradient ?? LinearGradient(
        colors: [darkGlass, darkSurfaceVariant],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: radiusLG,
      border: Border.all(
        color: (glowColor ?? primaryColor).withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, spreadRadius: -4, offset: const Offset(0, 8)),
        BoxShadow(color: (glowColor ?? primaryColor).withOpacity(0.08), blurRadius: 35, spreadRadius: -8, offset: const Offset(0, 14)),
      ],
    );
  }

  // ─── DARK THEME ──────────────────────────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    fontFamily: 'SF Pro Display',
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: darkGlass,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radiusLG,
        side: BorderSide(color: darkBorder.withOpacity(0.5), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: radiusMD),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3),
        shadowColor: Colors.transparent,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLight,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkGlass,
      border: OutlineInputBorder(
        borderRadius: radiusMD,
        borderSide: BorderSide(color: darkBorder.withOpacity(0.6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusMD,
        borderSide: BorderSide(color: darkBorder.withOpacity(0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusMD,
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radiusMD,
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
      hintStyle: const TextStyle(color: textTertiary, fontSize: 14),
      prefixIconColor: primaryColor,
    ),
    textTheme: const TextTheme(
      displayLarge:  TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.0, color: textPrimary, height: 1.1),
      displayMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: textPrimary, height: 1.1),
      displaySmall:  TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: textPrimary, height: 1.2),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: textPrimary, height: 1.2),
      headlineMedium:TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: textPrimary, height: 1.3),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.1, color: textPrimary, height: 1.3),
      titleLarge:    TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary,   height: 1.4),
      titleMedium:   TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textSecondary, height: 1.4),
      titleSmall:    TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary, height: 1.4, letterSpacing: 0.1),
      bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textSecondary, height: 1.6),
      bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary, height: 1.5),
      bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textTertiary,  height: 1.5),
      labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary,   letterSpacing: 0.5),
      labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary, letterSpacing: 0.4),
      labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textTertiary,  letterSpacing: 0.5),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: primaryColor,
      unselectedItemColor: textTertiary,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.2),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
    dividerTheme: DividerThemeData(
      color: darkBorder.withOpacity(0.5),
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkGlass,
      labelStyle: const TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
      side: BorderSide(color: darkBorder.withOpacity(0.5)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: const StadiumBorder(),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: radiusXL,
        side: BorderSide(color: darkBorderGlow.withOpacity(0.5)),
      ),
      elevation: 24,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkGlass,
      contentTextStyle: const TextStyle(color: textPrimary, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: radiusMD),
      behavior: SnackBarBehavior.floating,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return textTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor.withOpacity(0.3);
        return darkGlass;
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      linearTrackColor: darkGlass,
    ),
  );

  // ─── LIGHT THEME ─────────────────────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    fontFamily: 'SF Pro Display',
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      surface: lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: lightTextPrimary,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        color: lightTextPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: lightSurface,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radiusLG,
        side: const BorderSide(color: lightBorder, width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: radiusMD),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: radiusMD,
        borderSide: const BorderSide(color: lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusMD,
        borderSide: const BorderSide(color: lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusMD,
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: const TextStyle(color: lightTextSecondary, fontSize: 14),
      hintStyle: const TextStyle(color: lightTextTertiary, fontSize: 14),
      prefixIconColor: primaryColor,
    ),
    textTheme: const TextTheme(
      displayLarge:  TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.0, color: lightTextPrimary),
      displayMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: lightTextPrimary),
      displaySmall:  TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: lightTextPrimary),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: lightTextPrimary),
      headlineMedium:TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: lightTextPrimary),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.1, color: lightTextPrimary),
      titleLarge:    TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: lightTextPrimary),
      titleMedium:   TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: lightTextSecondary),
      bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: lightTextSecondary),
      bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: lightTextSecondary),
      bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: lightTextTertiary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightSurface,
      selectedItemColor: primaryColor,
      unselectedItemColor: lightTextTertiary,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
    ),
    dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: lightSurface,
      shape: RoundedRectangleBorder(borderRadius: radiusXL),
      elevation: 8,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightTextPrimary,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: radiusMD),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
