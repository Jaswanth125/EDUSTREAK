import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens and theme definitions extracted directly from the
/// EduStreak Multi-Portal Reference Image.
class EduStreakTheme {
  // ─── BRAND CORE COLORS (MASTER USER SPECIFICATION) ───────────────────────
  static const Color primaryViolet     = Color(0xFF7950F2); // Primary vibrant purple
  static const Color primaryPurple     = Color(0xFF7950F2); // Alias
  static const Color deepPurple        = Color(0xFF43218B); // Deep purple for cards
  static const Color darkViolet        = Color(0xFF24104F); // Dark violet
  static const Color lavender          = Color(0xFFEEE7FF); // Light lavender
  static const Color softLavender      = Color(0xFFF6F1FF); // Ultra soft lavender
  static const Color purpleHighlight   = Color(0xFFA66BFF); // Purple glow/accent
  static const Color textNavy          = Color(0xFF19133D); // Deep midnight navy text
  static const Color cyanAccent        = Color(0xFF35C9FF); // Electric cyan accent
  static const Color primaryVioletDark = Color(0xFF5F3DC4);
  static const Color primaryVioletLight= Color(0xFFA66BFF);
  static const Color neonCyan          = Color(0xFF35C9FF);
  static const Color emeraldGreen      = Color(0xFF10B981);
  static const Color amberGold         = Color(0xFFFBBF24);
  static const Color streakOrange      = Color(0xFFFF6B35);
  static const Color rosePink          = Color(0xFFEC4899);
  static const Color magentaPink       = Color(0xFFEC4899);

  // ─── STUDENT & PARENT LIGHT LAVENDER PALETTE ───────────────────────────
  static const Color studentBg         = Color(0xFFF5F1FD); // Soft luminous lavender canvas
  static const Color studentSurface    = Color(0xFFFFFFFF); // Crisp white card
  static const Color studentSurfaceSub = Color(0xFFF6F1FF); // Tinted subsection
  static const Color studentBorder     = Color(0xFFEADBFC); // Delicate lavender card border
  static const Color studentText       = Color(0xFF19133D); // Rich midnight navy text
  static const Color studentTextMuted  = Color(0xFF7B7599); // Soft purple-gray muted
  static const Color studentTextViolet = Color(0xFF7950F2); // Purple accent text

  // ─── STUDENT PORTAL COMPLETE DARK PALETTE (MASTER SPECIFICATION) ────────
  static const Color studentDarkBg        = Color(0xFF0B0920); // Deep midnight navy canvas
  static const Color studentDarkSidebar   = Color(0xFF11102B); // Dark indigo sidebar
  static const Color studentDarkHeader    = Color(0xFF171333); // Dark purple header
  static const Color studentDarkCard      = Color(0xFF201A42); // Layered dark purple card
  static const Color studentDarkCardSub   = Color(0xFF292254); // Elevated inner container
  static const Color studentDarkBorder    = Color(0xFF49347D); // Subtle violet card border
  static const Color studentDarkText      = Color(0xFFFFFFFF); // Pure white heading
  static const Color studentDarkTextMuted = Color(0xFFA5A0C8); // Muted lavender secondary
  static const Color studentDarkHighlight = Color(0xFFC4B5FD); // Bright lavender highlight
  static const Color primaryBrand         = Color(0xFF7950FF); // Vibrant violet brand
  static const Color secondaryAccent      = Color(0xFFA855F7); // Electric purple accent
  static const Color secondaryPurple      = Color(0xFFA855F7); // Electric purple accent

  // Dynamic Theme Helpers
  static Color studentCanvasBg(bool isDark) => isDark ? studentDarkBg : studentBg;
  static Color studentSidebarBg(bool isDark) => isDark ? studentDarkSidebar : Colors.white;
  static Color studentHeaderBg(bool isDark) => isDark ? studentDarkHeader : Colors.white;
  static Color studentCardBg(bool isDark) => isDark ? studentDarkCard : Colors.white;
  static Color studentCardSubBg(bool isDark) => isDark ? studentDarkCardSub : studentSurfaceSub;
  static Color studentBorderColor(bool isDark) => isDark ? studentDarkBorder : studentBorder;
  static Color studentTitleColor(bool isDark) => isDark ? studentDarkText : textNavy;
  static Color studentSubtitleColor(bool isDark) => isDark ? studentDarkTextMuted : studentTextMuted;

  // ─── TEACHER & CENTRAL ADMIN DARK NAVY PALETTE ─────────────────────────
  static const Color darkNavyBg        = Color(0xFF080C21); // Deep cosmic navy
  static const Color darkNavySurface   = Color(0xFF101538); // Elevated glass card base
  static const Color darkNavyCard      = Color(0xFF141A42); // Solid card background
  static const Color darkNavyBorder    = Color(0xFF283168); // Subtle container border
  static const Color darkGlowBorder    = Color(0xFF7950F2); // Glowing border line
  static const Color darkTextWhite     = Color(0xFFFFFFFF); // Pure white header
  static const Color darkTextMuted     = Color(0xFF9CA3AF); // Muted lavender gray
  static const Color darkTextSub       = Color(0xFFA5B4FC); // Soft violet secondary text
  static const Color cardBorder        = darkNavyBorder;    // Convenient alias for card borders
  static const Color textMuted         = darkTextMuted;     // Convenient alias for muted text

  // ─── SUBJECT COLOR SYSTEM ──────────────────────────────────────────────
  static const Color subjectMaths      = Color(0xFF0284C7); // Cyan/blue
  static const Color subjectScience    = Color(0xFF10B981); // Emerald green
  static const Color subjectEnglish    = Color(0xFFEC4899); // Rose/pink
  static const Color subjectSocial     = Color(0xFF8B5CF6); // Purple

  // ─── GRADIENTS ─────────────────────────────────────────────────────────
  static const LinearGradient activePillGradient = LinearGradient(
    colors: [Color(0xFF8A57F7), Color(0xFF6C3EE8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient questCardGradient = LinearGradient(
    colors: [Color(0xFF43218B), Color(0xFF31156E), Color(0xFF24104F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cosmicNavGradient = LinearGradient(
    colors: [Color(0xFF0D1236), Color(0xFF090C22)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient teacherHubGradient = LinearGradient(
    colors: [Color(0xFF231C63), Color(0xFF3B2788), Color(0xFF201353)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient logo3dGradient = LinearGradient(
    colors: [Color(0xFF9885FF), Color(0xFF6E56FF), Color(0xFF4527A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── SHADOWS & GLOWS ───────────────────────────────────────────────────
  static List<BoxShadow> get violetGlow => [
    BoxShadow(
      color: primaryViolet.withValues(alpha: 0.35),
      blurRadius: 18,
      spreadRadius: 1,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get softCardShadow => [
    BoxShadow(
      color: const Color(0xFF6366F1).withValues(alpha: 0.07),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get darkCardGlow => [
    BoxShadow(
      color: const Color(0xFF7C6FFF).withValues(alpha: 0.12),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  // ─── TYPOGRAPHY (PLUS JAKARTA SANS) ───────────────────────────────────
  static TextStyle fontHeading1({Color color = studentText, FontWeight weight = FontWeight.w800}) {
    return GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: weight, color: color, letterSpacing: -0.3);
  }

  static TextStyle fontHeading2({Color color = studentText, FontWeight weight = FontWeight.w700}) {
    return GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: weight, color: color, letterSpacing: -0.2);
  }

  static TextStyle fontHeading3({Color color = studentText, FontWeight weight = FontWeight.w700}) {
    return GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: weight, color: color);
  }

  static TextStyle fontBody({Color color = studentText, FontWeight weight = FontWeight.w500}) {
    return GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: weight, color: color, height: 1.4);
  }

  static TextStyle fontCaption({Color color = studentTextMuted, FontWeight weight = FontWeight.w500}) {
    return GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: weight, color: color);
  }

  static TextStyle fontLabel({Color color = studentText, FontWeight weight = FontWeight.w600}) {
    return GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: weight, color: color);
  }

  static TextStyle fontBodySmall({Color color = studentText, FontWeight weight = FontWeight.w500}) {
    return GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: weight, color: color, height: 1.35);
  }

  static TextStyle fontSmall({Color color = studentTextMuted, FontWeight weight = FontWeight.w500}) {
    return GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: weight, color: color);
  }

  // ─── CARD DECORATIONS ─────────────────────────────────────────────────
  static BoxDecoration lightCardDecoration({double radius = 18, Color? bgColor, Border? border}) {
    return BoxDecoration(
      color: bgColor ?? studentSurface,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: studentBorder, width: 1.2),
      boxShadow: softCardShadow,
    );
  }

  static BoxDecoration darkCardDecoration({double radius = 18, Color? borderColor, double glowOpacity = 0.25}) {
    return BoxDecoration(
      color: darkNavySurface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? darkGlowBorder.withValues(alpha: glowOpacity),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: (borderColor ?? darkGlowBorder).withValues(alpha: glowOpacity * 0.4),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration studentDarkCardDecoration({double radius = 18, Color? bgColor, Color? borderColor}) {
    return BoxDecoration(
      color: bgColor ?? studentDarkCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? studentDarkBorder, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.25),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
