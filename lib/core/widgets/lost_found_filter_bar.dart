import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/lost_and_found/presentation/providers/lost_found_controller.dart';

class LostFoundFilterBar extends StatelessWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;
  final LostFoundViewType viewType;
  final Function(LostFoundViewType) onViewTypeChanged;

  const LostFoundFilterBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.viewType,
    required this.onViewTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  onChanged: onSearchChanged,
                  style: AppTextStyles.bodySm,
                  decoration: const InputDecoration(
                    hintText: 'חפש לפי אזור, גזע או תיאור...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w400),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildViewToggleButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggleButton() {
    final isMap = viewType == LostFoundViewType.map;
    return GestureDetector(
      onTap: () {
        onViewTypeChanged(isMap ? LostFoundViewType.grid : LostFoundViewType.map);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMap ? AppColors.onSurface : AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isMap ? Icons.grid_view_rounded : Icons.map_outlined,
          size: 18,
          color: isMap ? Colors.white : AppColors.onSurface,
        ),
      ),
    );
  }
}
