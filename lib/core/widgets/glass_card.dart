import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

/// A premium glassmorphic container with high-blur and soft borders.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Color? color;
  final bool? useBlur; // Backwards compatibility
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.blur = 12.0,
    this.opacity = 0.7,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.color,
    this.useBlur,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppRadius.xlRadius;

    return Container(
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: boxShadow ?? AppShadows.premium,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: effectiveRadius,
              child: Container(
                padding: padding ?? const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (color ?? Colors.white).withValues(alpha: opacity),
                  borderRadius: effectiveRadius,
                  border: border ??
                      Border.all(
                        color: AppColors.borderFaint.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                ),
                child: child,
              ),
            ),
          ),
        ),
    );
  }
}

