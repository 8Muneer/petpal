import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

/// A compact tile for recently viewed services.
/// Dimensions: 140px width.
class LuxuryRecentTile extends StatelessWidget {
  final String title;
  final String category;
  final String imageUrl;
  final VoidCallback? onTap;

  const LuxuryRecentTile({
    super.key,
    required this.title,
    required this.category,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (140px square with 24px corners)
            Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.tile),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.tile - 1),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.surface,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.surface,
                    child: const Icon(Icons.error_outline),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Text Stack
            Text(
              title,
              style: AppTextStyles.bodySm,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              category,
              style: AppTextStyles.labelMd,
            ),
          ],
        ),
      ),
    );
  }
}

