import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

class BookingFilterBar extends StatelessWidget {
  final int selectedStatusIndex;
  final Function(int) onStatusChanged;
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const BookingFilterBar({
    super.key,
    required this.selectedStatusIndex,
    required this.onStatusChanged,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status Segmented Control (Glassy)
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  _buildStatusButton(0, 'קרובות'),
                  _buildStatusButton(1, 'הושלמו'),
                  _buildStatusButton(2, 'בוטלו'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Category Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip('All', 'הכל'),
              const SizedBox(width: 8),
              _buildCategoryChip('Walks', 'טיולים'),
              const SizedBox(width: 8),
              _buildCategoryChip('Sitting', 'שמירה'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButton(int index, String label) {
    final bool isSelected = selectedStatusIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onStatusChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            boxShadow: isSelected ? AppShadows.subtle : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelMd.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String id, String label) {
    final bool isSelected = selectedCategory == id;
    return GestureDetector(
      onTap: () => onCategoryChanged(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.onSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.onSurface
                : AppColors.border.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: isSelected ? Colors.white : AppColors.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
