import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  COLOR TOKENS
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF52B788);
  static const Color primaryFaint = Color(0xFFD8F3DC);

  // Surface
  static const Color surfaceBase = Color(0xFFF8FAF8);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceGlass = Color(0xB8FFFFFF); // 72% white
  static const Color surfaceOverlay = Color(0x8CFFFFFF); // 55% white

  // Text
  static const Color textPrimary = Color(0xFF1A2E1A);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textLink = Color(0xFF2D6A4F);

  // Feature colors
  static const Color walks = Color(0xFF2D6A4F);
  static const Color walksLight = Color(0xFFD8F3DC);
  static const Color sitting = Color(0xFF6B48FF);
  static const Color sittingLight = Color(0xFFEDE9FE);
  static const Color feed = Color(0xFFF59E0B);
  static const Color feedLight = Color(0xFFFEF3C7);
  static const Color lostPets = Color(0xFFEF4444);
  static const Color lostPetsLight = Color(0xFFFEE2E2);

  // Status
  static const Color statusOpen = Color(0xFF10B981);
  static const Color statusOpenLight = Color(0xFFD1FAE5);
  static const Color statusTaken = Color(0xFFF59E0B);
  static const Color statusTakenLight = Color(0xFFFEF3C7);
  static const Color statusClosed = Color(0xFF94A3B8);
  static const Color statusClosedLight = Color(0xFFF1F5F9);

  // Semantic
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);

  // UI Chrome
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFaint = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE8EDF0);
  static const Color shadow = Color(0x14000000);
  static const Color shadowDeep = Color(0x20000000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
  );

  static const LinearGradient walksGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D6A4F), Color(0xFF40916C)],
  );

  static const LinearGradient sittingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6B48FF), Color(0xFF9B7FFF)],
  );

  static const LinearGradient feedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFFECFDF5), Color(0xFFF6F7FB), Color(0xFFFAFAFA)],
  );
}

// ─────────────────────────────────────────────
//  SPACING TOKENS  (8pt grid)
// ─────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Page insets
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingTight = EdgeInsets.all(12);
}

// ─────────────────────────────────────────────
//  RADIUS TOKENS
// ─────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double full = 999;

  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
  static BorderRadius get xxlRadius => BorderRadius.circular(xxl);
  static BorderRadius get fullRadius => BorderRadius.circular(full);
}

// ─────────────────────────────────────────────
//  TEXT STYLES
// ─────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.ibmPlexSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.ibmPlexSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyBold => GoogleFonts.ibmPlexSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.6,
        color: AppColors.textPrimary,
      );

  static TextStyle get caption => GoogleFonts.ibmPlexSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get label => GoogleFonts.ibmPlexSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.3,
        color: AppColors.textMuted,
      );

  static TextStyle get buttonText => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.textInverse,
      );

  static TextStyle get navLabel => GoogleFonts.ibmPlexSans(
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
          color: AppColors.shadow,
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get cardElevated => [
        BoxShadow(
          color: AppColors.shadowDeep,
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get button => [
        const BoxShadow(
          color: Color(0x472D6A4F),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get nav => [
        const BoxShadow(
          color: Color(0x14000000),
          blurRadius: 24,
          offset: Offset(0, -4),
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
      textTheme: GoogleFonts.ibmPlexSansTextTheme(),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlRadius,
        ),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  // Kept for backward compat — remove once all usages replaced
  static ThemeData get lightTheme => light;
  static const double superCurveRadius = 28.0;
  static const double cardRadius = 20.0;
}
