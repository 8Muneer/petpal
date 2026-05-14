import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

class SitterSentimentBar extends StatelessWidget {
  final Map<String, int> tagFrequencies;
  final int totalReviews;

  const SitterSentimentBar({
    super.key,
    required this.tagFrequencies,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    if (tagFrequencies.isEmpty || totalReviews == 0) {
      return const SizedBox.shrink();
    }

    // Sort tags by frequency and take top 3
    final sortedTags = tagFrequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topTags = sortedTags.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'מה השכנים אומרים',
          style: AppTextStyles.bodyBold,
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 12),
        ...topTags.map((entry) {
          final percentage = entry.value / totalReviews;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(percentage * 100).toInt()}%', style: AppTextStyles.labelSm),
                    Text(entry.key, style: AppTextStyles.labelMd),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: AppColors.borderFaint.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
