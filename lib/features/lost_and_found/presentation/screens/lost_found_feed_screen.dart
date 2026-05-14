import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/luxury_lost_found_card.dart';
import 'package:petpal/core/widgets/lost_found_filter_bar.dart';
import 'package:petpal/core/widgets/lost_found_toggle_bar.dart';
import 'package:petpal/features/lost_and_found/domain/entities/lost_found_post.dart';
import 'package:petpal/features/lost_and_found/presentation/providers/lost_found_controller.dart';

class LostFoundFeedScreen extends ConsumerStatefulWidget {
  const LostFoundFeedScreen({super.key});

  @override
  ConsumerState<LostFoundFeedScreen> createState() =>
      _LostFoundFeedScreenState();
}

class _LostFoundFeedScreenState extends ConsumerState<LostFoundFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lostFoundControllerProvider);
    final postsAsync = ref.watch(filteredLostFoundPostsProvider);
    final userPhotoUrl =
        ref.watch(authStateChangesProvider).asData?.value?.photoURL;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Luxury Top App Bar
            _buildSliverAppBar(userPhotoUrl),

            // 2. Navigation & Filters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  children: [
                    LostFoundToggleBar(
                      selectedIndex: state.selectedTabIndex,
                      onTabChanged: (index) => ref
                          .read(lostFoundControllerProvider.notifier)
                          .setTab(index),
                    ),
                    const SizedBox(height: 16),
                    LostFoundFilterBar(
                      searchQuery: state.searchQuery,
                      onSearchChanged: (val) => ref
                          .read(lostFoundControllerProvider.notifier)
                          .setSearch(val),
                      viewType: state.viewType,
                      onViewTypeChanged: (type) => ref
                          .read(lostFoundControllerProvider.notifier)
                          .setViewType(type),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Main Feed Grid
            if (state.viewType == LostFoundViewType.grid)
              _buildGridFeed(postsAsync)
            else
              _buildMapViewPlaceholder(),
          ],
        ),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  Widget _buildSliverAppBar(String? photoUrl) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.background.withValues(alpha: 0.9),
      surfaceTintColor: Colors.transparent,
      leadingWidth: 70,
      leading: Center(
        child: IconButton(
          onPressed: () {}, // Open drawer or menu
          icon: const Icon(Icons.menu_rounded, color: AppColors.primary),
        ),
      ),
      centerTitle: true,
      title: Text(
        'Lost & Found',
        style: AppTextStyles.headlineMd.copyWith(
          fontFamily: 'Playfair Display',
          fontStyle: FontStyle.italic,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              image: photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(photoUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: photoUrl == null
                ? const Icon(Icons.person_outline_rounded,
                    color: AppColors.textMuted)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildGridFeed(AsyncValue<List<LostFoundPost>> postsAsync) {
    return postsAsync.when(
      loading: () => const SliverFillRemaining(
        child:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(child: Text('שגיאה בטעינה: $e')),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return const SliverFillRemaining(child: _EmptyState());
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: LuxuryLostFoundCard(
                    post: posts[index],
                    onTap: () =>
                        context.push('/lost-found/detail', extra: posts[index]),
                  ),
                );
              },
              childCount: posts.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapViewPlaceholder() {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: AppRadius.organicRadius,
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.subtle,
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.organicRadius,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.1,
                          child: Image.network(
                            'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=1000',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_outlined,
                                size: 48, color: AppColors.primary),
                            SizedBox(height: 12),
                            Text(
                              'SOON',
                              style: TextStyle(
                                letterSpacing: 4,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text('מפת אבדות ומציאות', style: AppTextStyles.headlineSm),
              const SizedBox(height: 8),
              const Text(
                'תצוגת המפה בגרסת  תהיה זמינה בעדכון הקרוב',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => context.push('/lost-found/create'),
      backgroundColor: AppColors.onSurface,
      foregroundColor: Colors.white,
      shape: const CircleBorder(),
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(
              File(
                  'C:\\Users\\NumanSh\\.gemini\\antigravity\\brain\\e323afa0-d6c2-4ef9-a738-e95d80e5b61a\\lost_found_empty_state_1777124150071.png'),
              height: 200,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.pets_rounded,
                size: 64,
                color: AppColors.border,
              ),
            ),
            const SizedBox(height: 32),
            Text('לא נמצאו דיווחים', style: AppTextStyles.headlineSm),
            const SizedBox(height: 12),
            const Text(
              'הקהילה שלנו עדיין לא דיווחה על מקרים באזור זה. נסה לשנות את החיפוש.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
