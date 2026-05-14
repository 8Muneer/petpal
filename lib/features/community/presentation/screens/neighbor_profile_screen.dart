import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/luxury_trust_card.dart';
import 'package:petpal/features/community/presentation/providers/community_provider.dart';

class NeighborProfileScreen extends ConsumerWidget {
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final int karma;
  final bool isVerified;

  const NeighborProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.karma,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(communityFeedProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient Background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.primary, AppColors.surface],
                      ),
                    ),
                  ),
                  // User Info
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Hero(
                        tag: 'avatar_$userId',
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(userPhotoUrl),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: AppShadows.premium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userName,
                            style:
                                AppTextStyles.h2.copyWith(color: Colors.white),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                color: Colors.blue, size: 20),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'קארמה $karma',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Stats Section
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _StatItem(label: 'תרומות', value: '12'),
                  _StatItem(label: 'חטיפים', value: '156'),
                  _StatItem(label: 'עוקבים', value: '42'),
                ],
              ),
            ),
          ),

          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('תרומות לקהילה', style: AppTextStyles.h3),
            ),
          ),

          // Contributions List
          postsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => const SliverToBoxAdapter(
              child: Center(child: Text('שגיאה בטעינה')),
            ),
            data: (posts) {
              final userPosts =
                  posts.where((p) => p.authorId == userId).toList();

              if (userPosts.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('אין עדיין תרומות')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = userPosts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: LuxuryTrustCard(
                          post: post,
                          onTreat: () => ref
                              .read(communityFeedProvider.notifier)
                              .giveTreat(post.id),
                        ),
                      );
                    },
                    childCount: userPosts.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
          Text(label, style: AppTextStyles.labelSm),
        ],
      ),
    );
  }
}
