import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';
import 'package:petpal/features/feed/presentation/providers/feed_provider.dart';

final feedFilterProvider = StateProvider<String>((ref) => 'all');

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Reserved for future pagination
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(feedPostsProvider);
    final selectedFilter = ref.watch(feedFilterProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: RefreshIndicator(
          onRefresh: () async => ref.invalidate(feedPostsProvider),
          color: AppColors.primary,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Floating header
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                centerTitle: false,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'פיד חדשות',
                      style: AppTextStyles.h2.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'קהילת PetPal',
                      style: AppTextStyles.labelSm.copyWith(
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              // Sticky filter bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverFeedFilterDelegate(
                  child: Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _FeedFilterBar(
                      selectedFilter: selectedFilter,
                      onFilterChanged: (f) =>
                          ref.read(feedFilterProvider.notifier).state = f,
                    ),
                  ),
                ),
              ),

              // Facebook-style create post CTA
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: InkWell(
                    onTap: () {
                      if (uid.isEmpty) {
                        _showLoginDialog(context);
                        return;
                      }
                      context.push('/feed/create');
                    },
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: Row(
                        children: [
                          LiveUserAvatar(
                            uid: uid,
                            fallbackName: '',
                            size: 36,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'מה את/ה חושב/ת?',
                            style: AppTextStyles.bodyMd
                                .copyWith(color: AppColors.textMuted),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.photo_library_outlined,
                            color: Colors.green.withValues(alpha: 0.8),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Posts
              postsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: Center(child: Text('שגיאה בטעינת הפיד: $e')),
                ),
                data: (posts) {
                  final filteredPosts = selectedFilter == 'all'
                      ? posts
                      : posts
                          .where((p) => p.type.name == selectedFilter)
                          .toList();

                  if (filteredPosts.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyFeedState(
                        onTap: () {
                          if (uid.isEmpty) {
                            _showLoginDialog(context);
                            return;
                          }
                          context.push('/feed/create');
                        },
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = filteredPosts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _PostCard(
                              post: post,
                              currentUid: uid,
                              onTap: () => context.push('/feed/${post.id}'),
                              onLike: () {
                                if (uid.isEmpty) {
                                  _showLoginDialog(context);
                                  return;
                                }
                                ref
                                    .read(feedRepositoryProvider)
                                    .toggleLike(post.id, uid);
                              },
                            ),
                          );
                        },
                        childCount: filteredPosts.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sliver delegate ──────────────────────────────────────────────────────────

class _SliverFeedFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _SliverFeedFilterDelegate({required this.child});

  @override
  double get minExtent => 72;
  @override
  double get maxExtent => 72;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SliverFeedFilterDelegate oldDelegate) => false;
}

// ─── Filter bar ───────────────────────────────────────────────────────────────

class _FeedFilterBar extends StatelessWidget {
  final String selectedFilter;
  final void Function(String) onFilterChanged;

  const _FeedFilterBar({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('all', 'הכל'),
      ('post', 'פוסטים'),
      ('tip', 'טיפים'),
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final (filterId, filterLabel) = filters[index];
          final isSelected = filterId == selectedFilter;

          return Padding(
            padding: const EdgeInsets.only(left: 10),
            child: ChoiceChip(
              label: Text(filterLabel),
              selected: isSelected,
              onSelected: (_) => onFilterChanged(filterId),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              showCheckmark: false,
              elevation: isSelected ? 4 : 0,
              shadowColor: isSelected
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          );
        },
      ),
    );
  }
}

// ─── Login dialog ─────────────────────────────────────────────────────────────

void _showLoginDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'צריך להתחבר כדי להמשיך',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'התחבר/י כדי לתת לייק, להגיב ולפרסם פוסטים.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('התחבר/י',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ),
  );
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyFeedState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyFeedState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.feed_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
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
            'היה/י הראשון/ה לפרסם!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.primary, AppColors.statusOpen],
                ),
              ),
              child: const Text(
                'פרסם פוסט',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Post card ────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final FeedPost post;
  final String currentUid;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const _PostCard({
    required this.post,
    required this.currentUid,
    required this.onTap,
    required this.onLike,
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
    final isLiked = post.isLikedBy(currentUid);
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
                LiveUserAvatar(
                  uid: post.authorUid,
                  fallbackName: post.authorName,
                  fallbackPhotoUrl: post.authorPhotoUrl,
                  size: 40,
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
                          fontSize: 14,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded,
                            size: 14, color: AppColors.warning),
                        SizedBox(width: 4),
                        Text(
                          'טיפ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Content
            Text(
              post.content,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),

            // Optional image
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: AppColors.borderFaint,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: AppColors.borderFaint,
                    child: const Icon(Icons.broken_image_rounded,
                        color: AppColors.textMuted),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Actions row
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onLike,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pets_rounded,
                          size: 20,
                          color: isLiked
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likes.length}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isLiked
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.commentCount}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
