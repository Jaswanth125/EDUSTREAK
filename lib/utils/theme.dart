import 'package:flutter/material.dart';

class AppTheme {
  // Premium Dark Theme Color Palette - Futuristic & Luxurious
  static const Color darkBackground = Color(0xFF0A0E27); // Deep space blue-black
  static const Color darkSurface = Color(0xFF141B2D); // Elevated surface
  static const Color darkSurfaceVariant = Color(0xFF1E2742); // Card surface
  static const Color darkBorder = Color(0xFF2A3455); // Subtle borders
  
  // Neon Accent Colors with Glow
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color primaryGlow = Color(0xFF818CF8); // Lighter indigo for glow
  static const Color secondaryColor = Color(0xFF8B5CF6); // Purple
  static const Color secondaryGlow = Color(0xFFA78BFA); // Lighter purple for glow
  static const Color accentColor = Color(0xFF06B6D4); // Cyan
  static const Color accentGlow = Color(0xFF22D3EE); // Lighter cyan for glow
  static const Color streakColor = Color(0xFFFF6B35); // Orange-Red
  static const Color streakGlow = Color(0xFFFF8C65); // Lighter orange for glow
  static const Color successColor = Color(0xFF10B981); // Emerald
  static const Color successGlow = Color(0xFF34D399); // Lighter emerald for glow
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color warningGlow = Color(0xFFFBBF24); // Lighter amber for glow
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB4B9C7);
  static const Color textTertiary = Color(0xFF6B7280);
  
  // Premium Deep Gradients with Glow Effect
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient primaryGlowGradient = LinearGradient(
    colors: [Color(0xFF818CF8), Color(0xFFA78BFA), Color(0xFFC4B5FD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399), Color(0xFF6EE7B7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient streakGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8C65), Color(0xFFFFA88C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF22D3EE), Color(0xFF67E8F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E2742), Color(0xFF141B2D), Color(0xFF0F1625)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Glow Box Shadow
  static List<BoxShadow> primaryGlowShadow = [
    BoxShadow(
      color: primaryColor.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: primaryColor.withOpacity(0.2),
      blurRadius: 40,
      spreadRadius: -10,
      offset: const Offset(0, 16),
    ),
  ];
  
  static List<BoxShadow> streakGlowShadow = [
    BoxShadow(
      color: streakColor.withOpacity(0.5),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: streakColor.withOpacity(0.3),
      blurRadius: 48,
      spreadRadius: -10,
      offset: const Offset(0, 16),
    ),
  ];
  
  static List<BoxShadow> successGlowShadow = [
    BoxShadow(
      color: successColor.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: successColor.withOpacity(0.2),
      blurRadius: 40,
      spreadRadius: -10,
      offset: const Offset(0, 16),
    ),
  ];
  
  static List<BoxShadow> cardGlowShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: primaryColor.withOpacity(0.1),
      blurRadius: 30,
      spreadRadius: -5,
      offset: const Offset(0, 12),
    ),
  ];

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      surface: darkSurface,
      onPrimary: textPrimary,
      onSecondary: textPrimary,
      onSurface: textPrimary,
      onBackground: textPrimary,
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      titleTextStyle: const TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: darkSurfaceVariant,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceVariant.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: darkBorder.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: darkBorder.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textTertiary),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: textPrimary,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.2,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: textSecondary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: textTertiary,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primaryColor,
      unselectedItemColor: textTertiary,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: darkBorder.withOpacity(0.3),
      thickness: 1,
    ),
  );
}

