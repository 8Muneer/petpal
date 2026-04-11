import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

enum AppCardVariant { solid, outline, tinted }

/// Unified card widget.
///
/// - [solid]   — white card with soft shadow (default)
/// - [outline] — white card with border, no shadow (for dense lists)
/// - [tinted]  — lightly tinted card, no border, no shadow (for info blocks)
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
    this.variant = AppCardVariant.solid,
    this.borderRadius,
    this.onTap,
    this.color,
  });

  /// Convenience — outline card
  const AppCard.outline({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.color,
  }) : variant = AppCardVariant.outline;

  /// Convenience — tinted card
  const AppCard.tinted({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.color,
  }) : variant = AppCardVariant.tinted;

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

      case AppCardVariant.tinted:
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? AppColors.surfaceBase,
            borderRadius: radius,
          ),
          child: child,
        );
    }
  }
}
