import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  COLOR TOKENS
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Brand — vibrant fresh teal
  static const Color primary      = Color(0xFF1DB185);
  static const Color primaryDark  = Color(0xFF0F8F68);
  static const Color primaryLight = Color(0xFF4EC99B);
  static const Color primaryFaint = Color(0xFFE8FFF5);

  // Surface
  static const Color surfaceBase    = Color(0xFFF5F7FA);
  static const Color surfaceCard    = Color(0xFFFFFFFF);
  static const Color surfaceGlass   = Color(0xCCFFFFFF);
  static const Color surfaceOverlay = Color(0x99FFFFFF);

  // Text
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted     = Color(0xFF94A3B8);
  static const Color textInverse   = Color(0xFFFFFFFF);
  static const Color textLink      = Color(0xFF1DB185);

  // Feature colors
  static const Color walks        = Color(0xFF1DB185);
  static const Color walksLight   = Color(0xFFE8FFF5);
  static const Color walksAccent  = Color(0xFF0F8F68);
  static const Color sitting      = Color(0xFF7C3AED);
  static const Color sittingLight = Color(0xFFF3EEFF);
  static const Color feed         = Color(0xFFF59E0B);
  static const Color feedLight    = Color(0xFFFFF8E6);
  static const Color lostPets     = Color(0xFFEF4444);
  static const Color lostPetsLight = Color(0xFFFFEEEE);

  // Status
  static const Color statusOpen       = Color(0xFF10B981);
  static const Color statusOpenLight  = Color(0xFFDCFCE7);
  static const Color statusTaken      = Color(0xFFF59E0B);
  static const Color statusTakenLight = Color(0xFFFFF8E6);
  static const Color statusClosed     = Color(0xFF94A3B8);
  static const Color statusClosedLight = Color(0xFFF1F5F9);

  // Semantic
  static const Color danger       = Color(0xFFEF4444);
  static const Color dangerLight  = Color(0xFFFFEEEE);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color success      = Color(0xFF10B981);
  static const Color successLight = Color(0xFFDCFCE7);

  // UI Chrome
  static const Color border      = Color(0xFFE2E8F0);
  static const Color borderFaint = Color(0xFFF1F5F9);
  static const Color divider     = Color(0xFFF1F5F9);
  static const Color shadow      = Color(0x0D000000); // 5%
  static const Color shadowMed   = Color(0x14000000); // 8%
  static const Color shadowDeep  = Color(0x1F000000); // 12%

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1DB185), Color(0xFF0F8F68)],
  );

  static const LinearGradient walksGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1DB185), Color(0xFF0D9268)],
  );

  static const LinearGradient sittingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF9F67FF)],
  );

  static const LinearGradient feedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFFBA35)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF5F7FA), Color(0xFFF5F7FA)],
  );
}

// ─────────────────────────────────────────────
//  SPACING TOKENS  (8pt grid)
// ─────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;

  static const EdgeInsets pagePadding      = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const EdgeInsets cardPadding      = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingTight = EdgeInsets.all(12);
}

// ─────────────────────────────────────────────
//  RADIUS TOKENS
// ─────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 24;
  static const double full = 999;

  static BorderRadius get smRadius   => BorderRadius.circular(sm);
  static BorderRadius get mdRadius   => BorderRadius.circular(md);
  static BorderRadius get lgRadius   => BorderRadius.circular(lg);
  static BorderRadius get xlRadius   => BorderRadius.circular(xl);
  static BorderRadius get xxlRadius  => BorderRadius.circular(xxl);
  static BorderRadius get fullRadius => BorderRadius.circular(full);
}

// ─────────────────────────────────────────────
//  TEXT STYLES
// ─────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => GoogleFonts.plusJakartaSans(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textPrimary,
  );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyBold => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.6,
    color: AppColors.textPrimary,
  );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static TextStyle get label => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.2,
    color: AppColors.textMuted,
  );

  static TextStyle get buttonText => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textInverse,
  );

  static TextStyle get navLabel => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}

// ─────────────────────────────────────────────
//  SHADOW PRESETS
// ─────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.shadowMed,
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get cardElevated => [
    BoxShadow(
      color: AppColors.shadowDeep,
      blurRadius: 28,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get button => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.35),
      blurRadius: 14,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> get nav => [
    BoxShadow(
      color: AppColors.shadowDeep,
      blurRadius: 20,
      offset: const Offset(0, -2),
    ),
  ];

  static List<BoxShadow> get subtle => [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
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
        secondary: AppColors.primaryLight,
        error: AppColors.danger,
        surface: AppColors.surfaceBase,
        onPrimary: AppColors.textInverse,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.surfaceBase,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textInverse,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: AppRadius.lgRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgRadius,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgRadius,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
        ),
        labelStyle: AppTextStyles.caption,
        hintStyle: AppTextStyles.caption,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xxlRadius),
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
      ),
    );
  }

  static ThemeData get lightTheme => light;
  static const double superCurveRadius = 24.0;
  static const double cardRadius = 20.0;
}
