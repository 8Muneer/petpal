import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

/// A reusable Home screen section that displays a horizontal list of items
/// with a header row (title + "More" link) and entrance animation.
///
/// Used by each category (Sitters, Parks, Vets, Stores, My Requests)
/// on the Home screen to show top-rated items with a consistent layout.
class HomeTopRatedSection extends StatelessWidget {
  final String title;
  final VoidCallback onMoreTap;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final double itemHeight;
  final Widget? emptyState;

  const HomeTopRatedSection({
    super.key,
    required this.title,
    required this.onMoreTap,
    required this.itemCount,
    required this.itemBuilder,
    this.itemHeight = 280,
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section header row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginPage,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.headlineMd,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: onMoreTap,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'עוד',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Content: horizontal list or empty state
          if (itemCount == 0 && emptyState != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginPage,
              ),
              child: emptyState!,
            )
          else
            SizedBox(
              height: itemHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginPage,
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 16,
                    ),
                    child: itemBuilder(context, index),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
