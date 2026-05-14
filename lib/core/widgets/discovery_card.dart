import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DiscoveryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? distance;
  final String? imageUrl;
  final IconData icon;
  final Color themeColor;
  final VoidCallback onTap;
  final bool isEmergency;

  const DiscoveryCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.distance,
    this.imageUrl,
    required this.icon,
    required this.themeColor,
    required this.onTap,
    this.isEmergency = false,
  });

  Widget _buildImage() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        color: themeColor.withValues(alpha: 0.1),
        child: Icon(icon, size: 48, color: themeColor),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppColors.surface,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: themeColor.withValues(alpha: 0.1),
        child: Icon(icon, size: 40, color: themeColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280, // Match LuxuryServiceCard width
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: AppRadius.organicRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.premium,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section (Larger height for luxury feel)
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: _buildImage(),
                ),
                // Overlay Badge
                if (isEmergency)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: const Text(
                        'חירום 24/7',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                
                // Icon Badge (Top Left) - Optional Luxury Touch
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.subtle,
                    ),
                    child: Icon(icon, color: themeColor, size: 16),
                  ),
                ),
              ],
            ),
            
            // Info Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headlineSm.copyWith(
                      color: AppColors.onSurface,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (distance != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      distance!,
                      style: AppTextStyles.labelSm.copyWith(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
