import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

class AppNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const AppNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Unified bottom nav replacing [GlassNavBar].
///
/// Improvements:
/// - Animated pill indicator slides under active tab
/// - Active icon/label use token colors
/// - Item colors from AppColors — no hardcoded hex
/// - Intrinsic sizing adapts to item count
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<AppNavItem> items;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: AppRadius.xxlRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xCCFFFFFF),
              borderRadius: AppRadius.xxlRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.60),
              ),
              boxShadow: AppShadows.nav,
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                return Expanded(
                  child: _NavItem(
                    item: items[i],
                    isSelected: i == currentIndex,
                    onTap: () => onChanged(i),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AppNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated pill behind icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: AppRadius.fullRadius,
              ),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                size: 22,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: AppTextStyles.navLabel.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
