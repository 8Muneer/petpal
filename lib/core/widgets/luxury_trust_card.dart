import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/community/domain/entities/community_post.dart';
import 'package:petpal/core/widgets/luxury_utility_chip.dart';

class LuxuryTrustCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onTreat;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onBookService;
  final VoidCallback? onKarmaInfo;
  final VoidCallback? onProfileTap;

  const LuxuryTrustCard({
    super.key,
    required this.post,
    this.onTreat,
    this.onComment,
    this.onShare,
    this.onBookService,
    this.onKarmaInfo,
    this.onProfileTap,
  });

  String get _timeAgo {
    final diff = DateTime.now().difference(post.createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} דקות';
    if (diff.inHours < 24) return '${diff.inHours} שעות';
    return '${diff.inDays} ימים';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // User Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onProfileTap,
                  child: Hero(
                    tag: 'avatar_${post.id}',
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(post.authorPhotoUrl),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(post.authorName, style: AppTextStyles.h3.copyWith(fontSize: 16)),
                          if (post.isAuthorVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Colors.blue, size: 14),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onKarmaInfo,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                'קארמה ${post.authorKarma}',
                                style: AppTextStyles.labelSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('• $_timeAgo', style: AppTextStyles.labelSm),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Post Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              post.content,
              style: AppTextStyles.bodyMd.copyWith(height: 1.5, color: AppColors.onSurface),
              textAlign: TextAlign.start,
            ),
          ),

          // Image Content (if any)
          if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.organic),
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrls!.first,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (post.isUrgent)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'דחוף',
                          style: AppTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Utility Chip (if recommendation and essential data exists)
          if (post.associatedServiceId != null &&
              post.associatedServiceName != null &&
              post.associatedServiceRating != null) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: LuxuryUtilityChip(
                name: post.associatedServiceName!,
                rating: post.associatedServiceRating!,
                onBook: onBookService,
              ),
            ),
          ],

          // Engagement Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _ActionButton(
                      icon: post.isLikedByMe ? Icons.pets : Icons.pets_outlined,
                      label: '${post.likes}',
                      onTap: onTreat,
                      iconColor: post.isLikedByMe ? AppColors.primary : null,
                    ),
                    const SizedBox(width: 20),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: '${post.commentsCount}',
                      onTap: onComment,
                    ),
                  ],
                ),
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'שתף',
                  onTap: onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final Color? iconColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isPrimary = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isPrimary ? 16 : 4, vertical: 8),
        decoration: isPrimary ? BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ) : null,
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? (isPrimary ? AppColors.primary : AppColors.textMuted)),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.labelMd.copyWith(
              color: iconColor ?? (isPrimary ? AppColors.primary : AppColors.textMuted),
              fontWeight: (iconColor != null || isPrimary) ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }
}
