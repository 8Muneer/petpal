import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

class LostFoundToggleBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;

  const LostFoundToggleBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              _buildTabButton(0, 'אבדות'),
              _buildTabButton(1, 'מציאות'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final bool isSelected = selectedIndex == index;
    final activeColor =
        index == 0 ? const Color(0xFFBA1A1A) : AppColors.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelMd.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
