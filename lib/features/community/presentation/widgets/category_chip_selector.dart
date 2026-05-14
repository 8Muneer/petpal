import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/community/domain/entities/community_post.dart';
import 'package:petpal/features/community/presentation/providers/create_post_provider.dart';

class CategoryChipSelector extends ConsumerWidget {
  const CategoryChipSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(createPostProvider.select((s) => s.category));

    final categories = [
      {'id': TrustPostType.update, 'label': 'עדכון'},
      {'id': TrustPostType.recommendation, 'label': 'המלצה'},
      {'id': TrustPostType.tip, 'label': 'טיפ'},
      {'id': TrustPostType.playdate, 'label': 'מפגש'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'על מה הפוסט?',
          style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final type = cat['id'] as TrustPostType;
              final label = cat['label'] as String;
              final isSelected = type == selectedCategory;

              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) ref.read(createPostProvider.notifier).setCategory(type);
                  },
                  backgroundColor: AppColors.pureWhite,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
