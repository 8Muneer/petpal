import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  PETPAL DEEP TEAL PALETTE
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Raw Palette ───────────────────────────────────────────────────────────
  static const Color prussianBlue3  = Color(0xFF001233); // deepest navy-black
  static const Color prussianBlue2  = Color(0xFF001845); // very dark navy
  static const Color prussianBlue   = Color(0xFF002855); // prussian blue
  static const Color regalNavy      = Color(0xFF023E7D); // rich regal navy
  static const Color sapphire       = Color(0xFF0353A4); // deep sapphire
  static const Color smartBlue      = Color(0xFF1B6E8C); // deep teal-blue ← primary
  static const Color twilightIndigo = Color(0xFF33415C); // muted slate-indigo
  static const Color blueSlate      = Color(0xFF5C677D); // desaturated slate
  static const Color slateGrey      = Color(0xFF7D8597); // neutral grey-blue
  static const Color lavenderGrey   = Color(0xFF979DAC); // soft cool grey

  // ── Semantic Roles ────────────────────────────────────────────────────────
  static const Color primary    = smartBlue;             // #1B6E8C
  static const Color accent     = Color(0xFF2596BE);     // bright teal accent (gradients, highlights)
  static const Color surface    = Color(0xFFEBF5F9);     // ultra-light teal tint
  static const Color onSurface  = prussianBlue3;         // #001233 deep text
  static const Color pureWhite  = Color(0xFFFFFFFF);

  static const Color textSecondary = regalNavy;          // #023E7D
  static const Color textMuted     = slateGrey;          // #7D8597

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color error   = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF1B6B45);
  static const Color warning = Color(0xFFD48F1A);

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color statusOpen   = Color(0xFF1B6B45);
  static const Color statusTaken  = Color(0xFFD48F1A);
  static const Color statusClosed = blueSlate;

  // ── Borders & Dividers ────────────────────────────────────────────────────
  static const Color border  = Color(0xFFAACCDE); // teal-blue border
  static const Color divider = Color(0xFFCCE6F0); // very light teal

  // ── Compatibility Aliases (semantic) ─────────────────────────────────────
  static const Color textPrimary = onSurface;
  static const Color background  = surface;
  static const Color surfaceBase = surface;
  static const Color surfaceCard = pureWhite;
  static const Color borderFaint = border;
  static const Color danger      = error;
  static const Color feed        = textMuted;
  static const Color walks       = sapphire;
  static const Color sitting     = regalNavy;
  static const Color lostPets    = prussianBlue3;

  // ── Dynamic Helpers ───────────────────────────────────────────────────────
  static Color get walksLight      => sapphire.withValues(alpha: 0.13);
  static Color get sittingLight    => regalNavy.withValues(alpha: 0.13);
  static Color get lostPetsLight   => prussianBlue3.withValues(alpha: 0.10);
  static Color get statusOpenLight => success.withValues(alpha: 0.12);
  static Color get successLight    => success.withValues(alpha: 0.12);
  static Color get primaryFaint    => primary.withValues(alpha: 0.10);
  static Color get surfaceDark     => const Color(0xFFCFE2F5);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D4560), smartBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [prussianBlue3, prussianBlue2, prussianBlue],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient velvetGradient = LinearGradient(
    colors: [regalNavy, sapphire, smartBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient deepGradient = LinearGradient(
    colors: [prussianBlue3, regalNavy],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Glassmorphism ─────────────────────────────────────────────────────────
  static Color get glassOverlay => Colors.white.withValues(alpha: 0.88);
  static Color get glassBorder  => Colors.white.withValues(alpha: 0.30);

  // ── Shadows (navy-tinted) ─────────────────────────────────────────────────
  static Color get shadowSubtle => prussianBlue3.withValues(alpha: 0.08);
  static Color get shadowMedium => prussianBlue3.withValues(alpha: 0.15);
  static Color get shadowMed    => shadowMedium;
  static Color get shadowDeep   => prussianBlue3.withValues(alpha: 0.26);

  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: prussianBlue3.withValues(alpha: 0.12),
          blurRadius: 28,
          offset: const Offset(0, 8),
        ),
      ];
}

// ─────────────────────────────────────────────
//  SPACING TOKENS
// ─────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;

  static const double marginPage     = 24.0;
  static const double gutterGrid     = 16.0;
  static const double stackSection   = 32.0;
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

  static const double organic = 32.0;
  static const double chip    = 12.0;
  static const double tile    = 24.0;
  static const double sm      = 8.0;
  static const double md      = 12.0;
  static const double lg      = 16.0;

  static BorderRadius get organicRadius => BorderRadius.circular(organic);
  static BorderRadius get chipRadius    => BorderRadius.circular(chip);
  static BorderRadius get tileRadius    => BorderRadius.circular(tile);
  static BorderRadius get smRadius      => BorderRadius.circular(sm);
  static BorderRadius get mdRadius      => BorderRadius.circular(md);
  static BorderRadius get lgRadius      => BorderRadius.circular(lg);
  static BorderRadius get fullRadius    => BorderRadius.circular(999);

  static BorderRadius get xlRadius  => BorderRadius.circular(20);
  static BorderRadius get xxlRadius => BorderRadius.circular(24);
}

// ─────────────────────────────────────────────
//  TEXT STYLES
// ─────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get headlineLg => GoogleFonts.frankRuhlLibre(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineMd => GoogleFonts.frankRuhlLibre(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineSm => GoogleFonts.frankRuhlLibre(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyLg => GoogleFonts.heebo(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyMd => GoogleFonts.heebo(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.onSurface,
      );

  static TextStyle get bodySm => GoogleFonts.heebo(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.onSurface,
      );

  static TextStyle get labelMd => GoogleFonts.heebo(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: AppColors.textMuted,
      );

  static TextStyle get labelSm => GoogleFonts.heebo(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: AppColors.textMuted,
      );

  static TextStyle get priceTag => GoogleFonts.heebo(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );

  static TextStyle get h1       => headlineLg;
  static TextStyle get h2       => headlineMd;
  static TextStyle get h3       => headlineSm;
  static TextStyle get body     => bodyMd;
  static TextStyle get bodyBold => bodyMd.copyWith(fontWeight: FontWeight.w700);
  static TextStyle get caption  => labelMd;
  static TextStyle get label    => labelMd;
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
          color: AppColors.prussianBlue3.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get card    => AppColors.premiumShadow;
  static List<BoxShadow> get premium => AppColors.premiumShadow;
  static List<BoxShadow> get shadowMed  => AppColors.premiumShadow;
  static List<BoxShadow> get shadowDeep => [
        BoxShadow(
          color: AppColors.prussianBlue3.withValues(alpha: 0.20),
          blurRadius: 40,
          offset: const Offset(0, 14),
        ),
      ];

  static List<BoxShadow> get glass  => subtle;
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
        secondary: AppColors.sapphire,
        tertiary: AppColors.regalNavy,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: GoogleFonts.heeboTextTheme(),

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
        hintStyle: const TextStyle(color: AppColors.textMuted),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.border),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        labelStyle: AppTextStyles.labelMd,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
      ),
    );
  }

  static ThemeData get lightTheme => light;
}
