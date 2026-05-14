import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

class NeighborhoodPulseBar extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const NeighborhoodPulseBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'id': 'All', 'label': 'הכל'},
      {'id': 'Recommendations', 'label': 'המלצות'},
      {'id': 'Playdates', 'label': 'מפגשים'},
      {'id': 'Gallery', 'label': 'גלריה'},
      {'id': 'Alerts', 'label': 'התראות'},
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final filterId = filter['id'] as String;
          final filterLabel = filter['label'] as String;
          final isSelected = filterId == selectedFilter;

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ChoiceChip(
              label: Text(filterLabel),
              selected: isSelected,
              onSelected: (_) => onFilterChanged(filterId),
              backgroundColor: AppColors.pureWhite,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderStatus.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              showCheckmark: false,
              elevation: isSelected ? 4 : 0,
            ),
          );
        },
      ),
    );
  }
}

// Helper to fix the missing BorderStatus in some Flutter versions
extension BorderStatus on Border {
  static BorderSide all({required Color color}) => BorderSide(color: color);
}
