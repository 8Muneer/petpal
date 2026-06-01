import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';
import 'package:petpal/features/feed/presentation/providers/feed_provider.dart';


class GuestHomeTab extends ConsumerWidget {
  final VoidCallback onRequireLogin;

  const GuestHomeTab({
    super.key,
    required this.onRequireLogin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(feedPostsProvider);

    return postsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            const Text(
              'שגיאה בטעינת הפיד',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.feed_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text(
                  'אין פוסטים עדיין',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'הפיד ריק כרגע — התחבר/י כדי לפרסם!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'התחבר/י',
                  leadingIcon: Icons.login_rounded,
                  onTap: () => context.push('/login'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: posts.length + 1, // +1 for the create-post banner
          itemBuilder: (context, index) {
            // First item: locked "create post" prompt
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: onRequireLogin,
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.borderFaint,
                          ),
                          child: const Icon(Icons.person_outline_rounded,
                              color: AppColors.textMuted),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'התחבר/י כדי לשתף פוסט...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color:
                                  AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const Icon(Icons.lock_outline_rounded,
                            size: 18, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              );
            }

            final post = posts[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _GuestPostCard(
                post: post,
                onTap: () => context.push('/feed/${post.id}'),
                onRequireLogin: onRequireLogin,
              ),
            );
          },
        );
      },
    );
  }
}

class _GuestPostCard extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onTap;
  final VoidCallback onRequireLogin;

  const _GuestPostCard({
    required this.post,
    required this.onTap,
    required this.onRequireLogin,
  });

  String get _timeAgo {
    if (post.createdAt == null) return '';
    final diff = DateTime.now().difference(post.createdAt!);
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק׳';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
    if (diff.inDays < 7) return 'לפני ${diff.inDays} ימים';
    return '${post.createdAt!.day}/${post.createdAt!.month}/${post.createdAt!.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isTip = post.type == PostType.tip;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: post.authorPhotoUrl != null &&
                            post.authorPhotoUrl!.isNotEmpty
                        ? null
                        : const LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [AppColors.primary, AppColors.statusOpen],
                          ),
                    image: post.authorPhotoUrl != null &&
                            post.authorPhotoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                                post.authorPhotoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: post.authorPhotoUrl != null &&
                          post.authorPhotoUrl!.isNotEmpty
                      ? null
                      : Center(
                          child: Text(
                            post.authorName.isNotEmpty
                                ? post.authorName.characters.first.toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isTip)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded,
                            size: 13, color: AppColors.warning),
                        SizedBox(width: 3),
                        Text(
                          'טיפ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Content (truncated)
            Text(
              post.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),

            // Optional image
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 160,
                    color: AppColors.borderFaint,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 160,
                    color: AppColors.borderFaint,
                    child: const Icon(Icons.broken_image_rounded,
                        color: AppColors.textMuted),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Actions row (read-only for guests — tapping triggers login)
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onRequireLogin,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_border_rounded,
                            size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          '${post.likes.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onRequireLogin,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          '${post.commentCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
