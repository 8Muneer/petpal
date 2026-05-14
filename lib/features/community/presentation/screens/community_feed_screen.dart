import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/luxury_trust_card.dart';
import 'package:petpal/core/widgets/neighborhood_pulse_bar.dart';
import 'package:petpal/features/community/presentation/providers/community_provider.dart';
import 'package:petpal/features/community/presentation/screens/create_trust_post_screen.dart';
import 'package:petpal/features/community/presentation/screens/neighbor_profile_screen.dart';
import 'package:petpal/features/community/presentation/widgets/community_comments_sheet.dart';
import 'package:petpal/features/community/presentation/widgets/community_empty_state.dart';
import 'package:petpal/features/community/presentation/providers/alerts_provider.dart';
import 'package:petpal/features/community/domain/entities/community_alert.dart';

import 'package:petpal/core/widgets/lottie_animation_overlay.dart';
import 'package:petpal/features/community/presentation/widgets/hero_pet_section.dart';

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  bool _showTreatAnimation = false;
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(communityFeedProvider.notifier).loadMorePosts();
    }
  }

  void _triggerTreatAnimation() {
    setState(() => _showTreatAnimation = true);
  }

  void _showComments(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommunityCommentsSheet(postId: postId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(communityFeedProvider);
    final selectedFilter = ref.watch(communityFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () => ref.read(communityFeedProvider.notifier).refreshPosts(),
        color: AppColors.primary,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Header
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                centerTitle: false,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'רשת האמון',
                      style: AppTextStyles.h2.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'קהילה גלובלית',
                      style: AppTextStyles.labelSm.copyWith(
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: AppColors.primary),
                    onPressed: () => _showKarmaInfo(context),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Neighborhood Alert Banner
              const SliverToBoxAdapter(
                child: _NeighborhoodAlertBanner(),
              ),

              // Picture of the Day Hero
              const SliverToBoxAdapter(
                child: HeroPetSection(),
              ),

              // Pulse Bar (Sticky-ish)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverPulseBarDelegate(
                  child: Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: NeighborhoodPulseBar(
                      selectedFilter: selectedFilter,
                      onFilterChanged: (filter) => ref.read(communityFilterProvider.notifier).state = filter,
                    ),
                  ),
                ),
              ),

              // Create Post Bar (Facebook Style)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateTrustPostScreen()),
                      );
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
                          const CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=current_user'),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'על מה אתה חושב?',
                            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                          ),
                          const Spacer(),
                          Icon(Icons.photo_library_outlined, color: Colors.green.withValues(alpha: 0.8), size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Feed
              postsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                error: (e, st) => SliverFillRemaining(
                  child: Center(child: Text('שגיאה בטעינת הפיד: $e')),
                ),
                data: (posts) {
                  // Improved filtering logic
                  final filteredPosts = selectedFilter == 'All' 
                    ? posts 
                    : posts.where((p) {
                        final typeStr = p.type.toString().split('.').last.toLowerCase();
                        final topicStr = (p.topic ?? '').toLowerCase();
                        final filterLower = selectedFilter.toLowerCase();
                        
                        return typeStr == filterLower || topicStr == filterLower;
                      }).toList();

                  if (filteredPosts.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: CommunityEmptyState(
                        onAction: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreateTrustPostScreen()),
                          );
                        },
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = filteredPosts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: LuxuryTrustCard(
                              post: post,
                              onTreat: () async {
                                await ref.read(communityFeedProvider.notifier).giveTreat(post.id);
                                _triggerTreatAnimation();
                              },
                              onKarmaInfo: () => _showKarmaInfo(context),
                              onProfileTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NeighborProfileScreen(
                                      userId: post.authorId,
                                      userName: post.authorName,
                                      userPhotoUrl: post.authorPhotoUrl,
                                      karma: post.authorKarma,
                                      isVerified: post.isAuthorVerified,
                                    ),
                                  ),
                                );
                              },
                              onBookService: () => _showBookingDialog(
                                context,
                                post.associatedServiceName ?? 'השירות',
                              ),
                              onComment: () => _showComments(post.id),
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
            
            // Lottie Animation Overlay
            LottieAnimationOverlay(
              isVisible: _showTreatAnimation,
              lottieAsset: 'https://lottie.host/801a6b0c-99f5-4556-9964-b003a3d5b272/R1q389Oq3h.json', // Reliable heart burst
              onComplete: () => setState(() => _showTreatAnimation = false),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context, String serviceName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.confirmation_number_outlined, color: Colors.green, size: 32),
            ),
            const SizedBox(height: 16),
            Text('הזמנת שירות', style: AppTextStyles.h3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'אתה עומד להזמין את השירות:',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Text(serviceName, style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('מפעיל תהליך הזמנה עבור $serviceName...'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('המשך להזמנה'),
          ),
        ],
      ),
    );
  }

  void _showKarmaInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.primary),
            const SizedBox(width: 12),
            Text('מה זה קארמה?', style: AppTextStyles.h3),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('קארמה היא הדרך של הקהילה להכיר תודה לאלו שעוזרים.'),
            SizedBox(height: 16),
            _KarmaRuleRow(icon: Icons.favorite_border, text: 'חטיף מהשכנים', points: '1 נקודה'),
            SizedBox(height: 8),
            _KarmaRuleRow(icon: Icons.star_border, text: 'פרסום המלצה', points: '3 נקודות'),
            SizedBox(height: 16),
            Text(
              'ככל שיש לך יותר קארמה, הפוסטים שלך יהיו בולטים יותר והאמון בך יגדל!',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('הבנתי, תודה!'),
          ),
        ],
      ),
    );
  }
}

class _NeighborhoodAlertBanner extends ConsumerWidget {
  const _NeighborhoodAlertBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For demo, we use a fixed neighborhood, but in production this comes from user profile
    final alertsAsync = ref.watch(communityAlertsProvider('Brooklyn Heights'));

    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) return const SizedBox.shrink();
        final latest = alerts.first;
        final isUrgent = latest.type == AlertType.urgent;
        final color = isUrgent ? const Color(0xFFFF4B4B) : Colors.orange;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 1),
            builder: (context, value, child) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: color.withValues(alpha: isUrgent ? 0.2 + (value * 0.3) : 0.2),
                    width: isUrgent ? 1 + (value * 2) : 1,
                  ),
                  boxShadow: isUrgent 
                    ? [BoxShadow(color: color.withValues(alpha: 0.1 * value), blurRadius: 10 * value, spreadRadius: 2 * value)]
                    : null,
                ),
                child: child,
              );
            },
            onEnd: () {
              // Loop animation if urgent
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isUrgent ? Icons.emergency_share : Icons.warning_amber_rounded, 
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latest.title,
                        style: TextStyle(fontWeight: FontWeight.bold, color: color),
                      ),
                      Text(
                        latest.content,
                        style: TextStyle(fontSize: 12, color: color),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: color),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _KarmaRuleRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String points;

  const _KarmaRuleRow({required this.icon, required this.text, required this.points});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
        Text(points, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
      ],
    );
  }
}

class _SliverPulseBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverPulseBarDelegate({required this.child});

  @override
  double get minExtent => 72;
  @override
  double get maxExtent => 72;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SliverPulseBarDelegate oldDelegate) {
    return false;
  }
}
