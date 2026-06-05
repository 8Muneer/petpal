import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

/// Unified filter button used across Explore, Lost & Found, and Services screens.
///
/// Active state (activeCount > 0): primary background, white icon, red count badge.
/// Inactive state: white background, border, muted icon.
class FilterButton extends StatelessWidget {
  final VoidCallback onTap;
  final int activeCount;

  const FilterButton({
    super.key,
    required this.onTap,
    this.activeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = activeCount > 0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.pureWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.border,
              ),
              boxShadow: AppShadows.subtle,
            ),
            child: Icon(
              Icons.tune_rounded,
              color: isActive ? Colors.white : AppColors.textSecondary,
              size: 22,
            ),
          ),
          if (isActive)
            Positioned(
              top: -6,
              left: -6,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
