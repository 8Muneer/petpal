import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

/// A specialized glass-morphism pill for ratings, badges, and small overlays.
/// Follows the Luxury design spec: White (90% alpha), Backdrop blur (10).
class GlassPill extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final EdgeInsets padding;

  const GlassPill({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.9,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.fullRadius,
      child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withValues(alpha: opacity),
            borderRadius: AppRadius.fullRadius,
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1.0,
            ),
          ),
          child: child,
        ),
    );
  }
}
