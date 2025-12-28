import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Sage & Slate Palette
  static const Color primarySage = Color(0xFF9CAF88);
  static const Color secondarySlate = Color(0xFF4A5568);
  static const Color alertCoral = Color(0xFFF08080);
  static const Color surfaceAlabaster = Color(0xFFF9F9F7);

  // UI Blueprints (Sage Serenity)
  static const Color sageSerenity = Color(0xFF7DAF9C);
  static const Color sunsetAmber = Color(0xFFFFB347);
  static const Color softBone = Color(0xFFF9F8F6);
  static const Color warmMist = Color(0xFFF0EEE9);

  static const Color white = Colors.white;
}

class AppTheme {
  static const double superCurveRadius = 32.0;
  static const double cardRadius = 24.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primarySage,
        primary: AppColors.primarySage,
        secondary: AppColors.secondarySlate,
        error: AppColors.alertCoral,
        surface: AppColors.surfaceAlabaster,
        onPrimary: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.surfaceAlabaster,
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme().merge(
        GoogleFonts.ibmPlexSansTextTheme(),
      ),
      cardTheme: CardThemeData(
        color: AppColors.warmMist,
        elevation: 2,
        shadowColor: const Color(0x0D2D2D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(superCurveRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primarySage,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(superCurveRadius),
          ),
        ),
      ),
    );
  }
}
