import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/features/auth/domain/enums/user_role.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';
import 'package:petpal/features/explore/presentation/widgets/explore_search_bar.dart';
import 'package:petpal/features/explore/presentation/widgets/filter_bottom_sheet.dart';
import 'package:petpal/features/sitting/presentation/providers/marketplace_provider.dart';
import 'package:petpal/core/widgets/boutique_property_card.dart';
import 'package:petpal/core/widgets/empty_state_card.dart';
import 'package:petpal/features/explore/domain/entities/poi_model.dart';
import 'package:petpal/features/explore/presentation/providers/poi_provider.dart';
import 'package:petpal/features/explore/presentation/widgets/poi_card.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    // Listen to tab index changes from other screens
    ref.listen(exploreTabIndexProvider, (previous, next) {
      if (next != _tabController.index) {
        _tabController.animateTo(next);
      }
    });

    return AppScaffold(
      body: ColoredBox(
        color: const Color(0xFFF8F9FA), // Off-white background
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Please log in'));
            }

            final isOwner = profile.role == UserRole.petOwner;

            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: isOwner
                      ? _buildOwnerView(context)
                      : _buildSitterView(context),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Centered Header Title with premium styling
          Center(
            child: Text(
              'גלה',
              style: AppTextStyles.h2.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Integrated search and filter row
          Row(
            children: [
              Expanded(
                child: ExploreSearchBar(
                  onChanged: (value) {
                    ref.read(marketplaceFiltersProvider.notifier).updateSearch(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              _buildSquareAction(
                Icons.tune,
                () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const FilterBottomSheet(),
                  );
                },
                hasBadge:
                    ref.watch(marketplaceFiltersProvider).hasActiveFilters,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSquareAction(IconData icon, VoidCallback onTap,
      {bool hasBadge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.onSurface, size: 20),
          ),
          if (hasBadge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOwnerView(BuildContext context) {
    return Column(
      children: [
        // Owner sub-tabs with pill indicator decoration
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(vertical: 4),
            indicator: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            dividerColor: Colors.transparent,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'גינות כלבים'),
              Tab(text: 'וטרינרים'),
              Tab(text: 'חנויות'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPOIList(POIType.park),
              _buildPOIList(POIType.vet),
              _buildPOIList(POIType.store),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPOIList(POIType type) {
    final poisAsync = ref.watch(nearbyPOIsProvider(type: type));

    return poisAsync.when(
      data: (pois) {
        if (pois.isEmpty) {
          return const EmptyStateWidget(
            title: 'לא נמצאו תוצאות',
            subtitle: 'נסה לחפש באזור אחר',
            icon: Icons.map_outlined,
          );
        }
        return _buildScrollableList(
          count: pois.length,
          itemBuilder: (context, index) {
            final poi = pois[index];
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: POICard(
                poi: poi,
                onTap: () => context.push('/explore/poi/${poi.id}'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildSitterView(BuildContext context) {
    return _buildJobsList();
  }

  Widget _buildJobsList() {
    final jobsAsync = ref.watch(filteredPublicJobsProvider);

    return jobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return const EmptyStateWidget(
            title: 'אין עבודות זמינות',
            subtitle: 'כרגע אין בקשות פומביות באזור שלך. בדוק שוב מאוחר יותר',
            icon: Icons.work_outline_rounded,
          );
        }
        return _buildScrollableList(
          count: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return BoutiquePropertyCard(
              title: job.ownerName,
              subtitle: '${job.petName} • ${job.petType.name}',
              price: job.budget ?? '₪100',
              onTap: () => context.push('/sitting/detail', extra: job),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildScrollableList({
    required int count,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    return AnimationLimiter(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildResultsHeader(count),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 600),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: itemBuilder(context, index),
                      ),
                    ),
                  );
                },
                childCount: count,
              ),
            ),
          ),
          const SliverToBoxAdapter(
              child: SizedBox(height: 120)), // Space for floating nav
        ],
      ),
    );
  }

  Widget _buildResultsHeader(int count) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Sort
            Row(
              children: [
                const Icon(Icons.expand_more,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'מיון: מומלץ',
                  style:
                      AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            // Right: Count
            Row(
              children: [
                Text(
                  '$count זמינים',
                  style: AppTextStyles.bodyMd
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.home_outlined,
                    size: 18, color: AppColors.onSurface),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
