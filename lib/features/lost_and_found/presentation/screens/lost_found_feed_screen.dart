import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/lost_and_found/domain/entities/lost_found_post.dart';
import 'package:petpal/features/lost_and_found/presentation/providers/lost_found_provider.dart';

class LostFoundFeedScreen extends ConsumerStatefulWidget {
  const LostFoundFeedScreen({super.key});

  @override
  ConsumerState<LostFoundFeedScreen> createState() =>
      _LostFoundFeedScreenState();
}

class _LostFoundFeedScreenState extends ConsumerState<LostFoundFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    _PostsList(type: LostFoundType.lost),
                    _PostsList(type: LostFoundType.found),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/lost-found/create'),
          backgroundColor: const Color(0xFFFB7185),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('דיווח חדש',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFB7185).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pets_rounded,
                color: Color(0xFFFB7185), size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('חיות אבודות ונמצאות',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A2E))),
              Text('התאמה חכמה עם AI',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFFFB7185),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'אבודים'),
          Tab(text: 'נמצאו'),
        ],
      ),
    );
  }
}

class _PostsList extends ConsumerWidget {
  final LostFoundType type;
  const _PostsList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = type == LostFoundType.lost
        ? ref.watch(lostPostsProvider)
        : ref.watch(foundPostsProvider);

    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('שגיאה: $e')),
      data: (posts) {
        if (posts.isEmpty) {
          return _EmptyState(type: type);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _LostFoundCard(post: posts[index]);
          },
        );
      },
    );
  }
}

class _LostFoundCard extends StatelessWidget {
  final LostFoundPost post;
  const _LostFoundCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final isLost = post.type == LostFoundType.lost;
    final accent = isLost ? const Color(0xFFFB7185) : const Color(0xFF60A5FA);
    final hasMatches = post.matches.isNotEmpty;

    return GestureDetector(
      onTap: () => context.push('/lost-found/detail', extra: post),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: CachedNetworkImage(
                imageUrl: post.imageUrl,
                width: 100,
                height: 110,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: const Color(0xFFF0F2F5),
                  child: const Icon(Icons.pets_rounded,
                      color: Colors.grey, size: 36),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFFF0F2F5),
                  child: const Icon(Icons.pets_rounded,
                      color: Colors.grey, size: 36),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isLost ? 'אבוד' : 'נמצא',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: accent),
                          ),
                        ),
                        if (hasMatches) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome_rounded,
                                    size: 11, color: Color(0xFF10B981)),
                                const SizedBox(width: 3),
                                Text(
                                  '${post.matches.length} התאמה',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF10B981)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.petName.isNotEmpty ? post.petName : post.species,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 3),
                    if (post.breed.isNotEmpty)
                      Text(
                        '${post.species} · ${post.breed}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            post.area,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(Icons.chevron_left_rounded,
                  color: AppColors.textMuted, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final LostFoundType type;
  const _EmptyState({required this.type});

  @override
  Widget build(BuildContext context) {
    final isLost = type == LostFoundType.lost;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pets_rounded,
              size: 64,
              color: isLost
                  ? const Color(0xFFFB7185).withValues(alpha: 0.4)
                  : const Color(0xFF60A5FA).withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            isLost ? 'אין דיווחים על חיות אבודות' : 'אין דיווחים על חיות שנמצאו',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          const Text(
            'לחץ על הכפתור למטה כדי לדווח',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
