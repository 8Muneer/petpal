import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

/// Back-office palette for the admin console. Deliberately cooler and more
/// neutral than the consumer app surfaces, signalling "tool" over "product"
/// while staying within the Nautical Depths family.
class AdminColors {
  AdminColors._();

  /// App background — cool neutral grey (vs the consumer blue-white).
  static const Color bg = Color(0xFFF2F5F8);

  /// Panels, cards, table rows.
  static const Color panel = Colors.white;

  /// Hairlines and card borders.
  static const Color border = Color(0xFFE3E8EF);

  /// Primary text.
  static const Color ink = AppColors.prussianBlue3;

  /// Secondary / muted text.
  static const Color inkMuted = Color(0xFF64748B);

  /// Dark navigation rail background.
  static const Color rail = AppColors.prussianBlue3;

  /// Accent (selection, links, primary actions).
  static const Color accent = AppColors.smartBlue;
}

/// Compact admin text scale (denser than the consumer scale).
class AdminText {
  AdminText._();

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AdminColors.ink,
    height: 1.2,
  );

  static const TextStyle section = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: AdminColors.inkMuted,
    letterSpacing: 0.2,
  );

  static const TextStyle rowTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AdminColors.ink,
  );

  static const TextStyle rowSub = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AdminColors.inkMuted,
  );

  static const TextStyle metric = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: AdminColors.ink,
    height: 1.0,
  );
}
