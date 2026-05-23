import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/glass_pill.dart';

/// A premium service card designed for the Luxury Home Screen.
/// Includes 220px image header, glass rating pill, and luxury typography.
class LuxuryServiceCard extends StatelessWidget {
  final String title;
  final String serviceType;
  final String price;
  final String rating;
  final String location;
  final String imageUrl;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const LuxuryServiceCard({
    super.key,
    required this.title,
    required this.serviceType,
    required this.price,
    required this.rating,
    required this.location,
    required this.imageUrl,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: AppRadius.organicRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header (220px)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.organic),
                  ),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 220,
                            color: AppColors.surface,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 220,
                            color: AppColors.surface,
                            child: const Icon(Icons.error_outline),
                          ),
                        )
                      : Container(
                          height: 220,
                          color: AppColors.surface,
                          child: const Icon(Icons.pets,
                              color: AppColors.border, size: 48),
                        ),
                ),
                
                // Glass Rating Pill (Top-Left)
                Positioned(
                  top: 16,
                  right: 16, // Assuming RTL or just a clean placement
                  child: GlassPill(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: AppTextStyles.bodySm,
                        ),
                      ],
                    ),
                  ),
                ),

                // Favorite Button (Bottom-Right)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.pureWhite,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content Area
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.headlineSm,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        price,
                        style: AppTextStyles.priceTag,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    serviceType,
                    style: AppTextStyles.labelMd,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: AppTextStyles.labelMd,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

