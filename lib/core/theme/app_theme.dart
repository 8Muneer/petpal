import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  COLOR TOKENS
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFFC19A6B); // Desert Bronze
  static const Color surface =
      Color(0xFFF9F9F7); // Warm Alabaster (App Background)
  static const Color onSurface = Color(0xFF1A1A1A); // Onyx Text

  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF636366);
  static const Color textMuted = Color(0xFF8E8E93);

  // Semantic Colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);

  // Status Colors (Luxury style)
  static const Color statusOpen = Color(0xFF2E7D32);
  static const Color statusTaken = Color(0xFFF9A825);
  static const Color statusClosed = Color(0xFF8E8E93);

  // Border & Dividers
  static const Color border = Color(0xFFE0E0E0); // Architectural Border
  static const Color divider = Color(0xFFF2F2F2);

  // Compatibility Aliases for legacy screens
  static const Color textPrimary = onSurface;
  static const Color background = surface;
  static const Color surfaceBase = surface;
  static const Color surfaceCard = pureWhite;
  static const Color borderFaint = border;
  static const Color danger = error;
  static const Color feed = textMuted;
  static const Color walks = primary;
  static const Color sitting = Color(0xFFB4A08B);
  static const Color lostPets = error;

  static Color get walksLight => primary.withValues(alpha: 0.1);
  static Color get sittingLight => sitting.withValues(alpha: 0.1);
  static Color get lostPetsLight => error.withValues(alpha: 0.1);
  static Color get statusOpenLight => success.withValues(alpha: 0.1);
  static Color get successLight => success.withValues(alpha: 0.1);
  static Color get primaryFaint => primary.withValues(alpha: 0.1);
  static Color get surfaceDark => const Color(0xFFE5E5E5);

  static LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, primary.withValues(alpha: 0.8)],
      );

  // Glassmorphism
  static Color get glassOverlay => Colors.white.withValues(alpha: 0.9);
  static Color get glassBorder => Colors.white.withValues(alpha: 0.2);

  // Shadows
  static Color get shadowSubtle => primary.withValues(alpha: 0.08);
  static Color get shadowMedium => primary.withValues(alpha: 0.15);
  static Color get shadowMed => shadowMedium;
  static Color get shadowDeep => primary.withValues(alpha: 0.25);

  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 30,
          offset: const Offset(0, 8),
        ),
      ];
}

// ─────────────────────────────────────────────
//  SPACING TOKENS
// ─────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double marginPage = 24.0;
  static const double gutterGrid = 16.0;
  static const double stackSection = 32.0;
  static const double stackComponent = 12.0;

  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
}

// ─────────────────────────────────────────────
//  RADIUS TOKENS
// ─────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const double organic = 32.0; // Luxury Signature Corner
  static const double chip = 12.0;
  static const double tile = 24.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;

  static BorderRadius get organicRadius => BorderRadius.circular(organic);
  static BorderRadius get chipRadius => BorderRadius.circular(chip);
  static BorderRadius get tileRadius => BorderRadius.circular(tile);
  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get fullRadius => BorderRadius.circular(999);

  // Compatibility Aliases
  static BorderRadius get xlRadius => BorderRadius.circular(20);
  static BorderRadius get xxlRadius => BorderRadius.circular(24);
}

// ─────────────────────────────────────────────
//  TEXT STYLES
// ─────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  // Luxury Serif (Playfair Display)
  static TextStyle get headlineLg => GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineMd => GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineSm => GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.onSurface,
      );

  // Modern Sans (IBM Plex Sans Arabic)
  static TextStyle get bodyLg => GoogleFonts.ibmPlexSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyMd => GoogleFonts.ibmPlexSansArabic(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.onSurface,
      );

  static TextStyle get bodySm => GoogleFonts.ibmPlexSansArabic(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.onSurface,
      );

  static TextStyle get labelMd => GoogleFonts.ibmPlexSansArabic(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: AppColors.textMuted,
      );

  static TextStyle get labelSm => GoogleFonts.ibmPlexSansArabic(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: AppColors.textMuted,
      );

  static TextStyle get priceTag => GoogleFonts.ibmPlexSansArabic(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );

  // Compatibility Aliases
  static TextStyle get h1 => headlineLg;
  static TextStyle get h2 => headlineMd;
  static TextStyle get h3 => headlineSm;
  static TextStyle get body => bodyMd;
  static TextStyle get bodyBold => bodyMd.copyWith(fontWeight: FontWeight.w700);
  static TextStyle get caption => labelMd;
  static TextStyle get label => labelMd;
  static TextStyle get navLabel => labelMd.copyWith(fontSize: 10);
  static TextStyle get buttonText =>
      bodyMd.copyWith(fontWeight: FontWeight.w700);
}

// ─────────────────────────────────────────────
//  SHADOW PRESETS
// ─────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get card => AppColors.premiumShadow;
  static List<BoxShadow> get premium => AppColors.premiumShadow;
  static List<BoxShadow> get shadowMed => AppColors.premiumShadow;
  static List<BoxShadow> get shadowDeep => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 40,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get glass => subtle;
  static List<BoxShadow> get button => subtle;
}

// ─────────────────────────────────────────────
//  MATERIAL THEME
// ─────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.surface,

      // Default Text Theme
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(),

      cardTheme: CardThemeData(
        color: AppColors.pureWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.organicRadius),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
          textStyle: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.pureWhite,
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => light;
}

