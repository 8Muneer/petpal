import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

/// A premium glass-morphism search bar with 90% alpha and high blur.
class GlassSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const GlassSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Find walkers, sitters...',
    this.onFilterTap,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: AppTextStyles.bodyLg,
                    textInputAction: TextInputAction.search,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: AppTextStyles.bodyLg.copyWith(color: AppColors.textMuted),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onFilterTap,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
