import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/lost_and_found/domain/entities/lost_found_post.dart';
import 'package:petpal/features/lost_and_found/presentation/providers/lost_found_provider.dart';

class LostFoundBrowseScreen extends ConsumerWidget {
  final LostFoundPost anchorPost;

  const LostFoundBrowseScreen({super.key, required this.anchorPost});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLost = anchorPost.type == LostFoundType.lost;
    final oppositeType = isLost ? LostFoundType.found : LostFoundType.lost;
    final posts = ref
        .watch(isLost ? foundPostsProvider : lostPostsProvider)
        .asData
        ?.value
        .where((p) => p.id != anchorPost.id)
        .toList();

    final accent = isLost ? const Color(0xFFFB7185) : const Color(0xFF60A5FA);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            isLost ? 'בחר דיווח נמצא להשוואה' : 'בחר דיווח אבוד להשוואה',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Column(
          children: [
            _AnchorBanner(post: anchorPost, accent: accent),
            Expanded(
              child: posts == null
                  ? const Center(child: CircularProgressIndicator())
                  : posts.isEmpty
                      ? _EmptyState(oppositeType: oppositeType)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return _BrowseCard(
                              post: post,
                              onTap: () => context.push(
                                '/lost-found/compare',
                                extra: {'post1': anchorPost, 'post2': post},
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnchorBanner extends StatelessWidget {
  final LostFoundPost post;
  final Color accent;
  const _AnchorBanner({required this.post, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: post.imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                  color: const Color(0xFFF0F2F5),
                  child:
                      const Icon(Icons.pets_rounded, color: Colors.grey, size: 22)),
              errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFFF0F2F5),
                  child:
                      const Icon(Icons.pets_rounded, color: Colors.grey, size: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'השוואה מול: ${post.petName.isNotEmpty ? post.petName : post.species}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 2),
                const Text('בחר דיווח מהרשימה להפעלת השוואת AI',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 12, color: accent),
                const SizedBox(width: 4),
                Text('AI',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowseCard extends StatelessWidget {
  final LostFoundPost post;
  final VoidCallback onTap;
  const _BrowseCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLost = post.type == LostFoundType.lost;
    final accent = isLost ? const Color(0xFFFB7185) : const Color(0xFF60A5FA);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        color: const Color(0xFFF0F2F5),
                        child: const Icon(Icons.pets_rounded,
                            color: Colors.grey, size: 30)),
                    errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFF0F2F5),
                        child: const Icon(Icons.pets_rounded,
                            color: Colors.grey, size: 30)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              isLost ? 'אבוד' : 'נמצא',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: accent),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              post.petName.isNotEmpty
                                  ? post.petName
                                  : post.species,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Color(0xFF1A1A2E)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${post.species}${post.breed.isNotEmpty ? ' · ${post.breed}' : ''}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              post.area,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      size: 18, color: Color(0xFF8B5CF6)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final LostFoundType oppositeType;
  const _EmptyState({required this.oppositeType});

  @override
  Widget build(BuildContext context) {
    final label =
        oppositeType == LostFoundType.found ? 'דיווחי נמצא' : 'דיווחי אבוד';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'אין $label זמינים',
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 8),
            Text(
              'כרגע אין $label שאפשר להשוות אליהם.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
