import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

/// Small label chip. Pass [color] for the text/border color;
/// fill is auto-derived as 12% opacity of that color.
class TinyChip extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? fill;
  final Color? textColor;
  final IconData? icon;

  const TinyChip({
    super.key,
    required this.text,
    this.color,
    this.fill,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor =
        textColor ?? color ?? AppColors.primary;
    final effectiveFill =
        fill ?? effectiveTextColor.withValues(alpha: 0.12);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: icon != null ? AppSpacing.sm : 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: effectiveFill,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: effectiveTextColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTextStyles.label.copyWith(
              color: effectiveTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
