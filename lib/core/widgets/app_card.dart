import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

enum AppCardVariant { glass, solid, outline }

/// Unified card widget replacing [GlassCard].
///
/// - [glass]   — frosted glass look (default), good over gradient backgrounds
/// - [solid]   — white card with shadow, good over plain backgrounds
/// - [outline] — white card with border, no shadow (for dense lists)
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final AppCardVariant variant;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.variant = AppCardVariant.glass,
    this.borderRadius,
    this.onTap,
    this.color,
  });

  /// Convenience — solid white card
  const AppCard.solid({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.color,
  }) : variant = AppCardVariant.solid;

  /// Convenience — outline card
  const AppCard.outline({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.color,
  }) : variant = AppCardVariant.outline;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.xlRadius;
    final effectivePadding = padding ?? AppSpacing.cardPadding;

    Widget card = _buildCard(radius, effectivePadding);

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: AppColors.primary.withValues(alpha: 0.06),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: card,
        ),
      );
    }

    return card;
  }

  Widget _buildCard(BorderRadius radius, EdgeInsets padding) {
    switch (variant) {
      case AppCardVariant.glass:
        return ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: color ?? const Color(0xB8FFFFFF),
                borderRadius: radius,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                ),
                boxShadow: AppShadows.card,
              ),
              child: child,
            ),
          ),
        );

      case AppCardVariant.solid:
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? AppColors.surfaceCard,
            borderRadius: radius,
            boxShadow: AppShadows.card,
          ),
          child: child,
        );

      case AppCardVariant.outline:
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? AppColors.surfaceCard,
            borderRadius: radius,
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        );
    }
  }
}
