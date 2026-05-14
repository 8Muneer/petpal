import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/community/presentation/providers/community_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';

class HeroPetSection extends ConsumerWidget {
  const HeroPetSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final podPost = ref.watch(pictureOfTheDayProvider);

    if (podPost == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4E6), Color(0xFFFFE8CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppShadows.premium,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Animation
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.1,
              child: Lottie.network(
                'https://lottie.host/6477e682-353d-495a-939e-d71d374e2d31/Z4C3eZ4S9u.json', // Paw animation
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Pet Photo
                Hero(
                  tag: 'pod_${podPost.id}',
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: AppShadows.subtle,
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(podPost.imageUrls!.first),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '⭐ תמונת היום',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        podPost.authorName, // Assuming the post content or author name is the "Pet" name
                        style: AppTextStyles.h3.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.favorite, size: 14, color: Color(0xFFFF4B4B)),
                          const SizedBox(width: 4),
                          Text(
                            '${podPost.treats} פינוקים מהקהילה',
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
