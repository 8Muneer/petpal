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
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';
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
    _tabController = TabController(length: 5, vsync: this);
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Actions (Filter & Grid)
              Row(
                children: [
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
              // Right Title (Explore)
              Text(
                'גלה',
                style: AppTextStyles.h1.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ExploreSearchBar(
            onChanged: (value) {
              ref.read(marketplaceFiltersProvider.notifier).updateSearch(value);
            },
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
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.1)),
              boxShadow: AppShadows.subtle,
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
        // Owner sub-tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            dividerColor: Colors.transparent,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'שומרים'),
              Tab(text: 'גינות כלבים'),
              Tab(text: 'וטרינרים'),
              Tab(text: 'חנויות'),
              Tab(text: 'הבקשות שלי'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSittersList(),
              _buildPOIList(POIType.park),
              _buildPOIList(POIType.vet),
              _buildPOIList(POIType.store),
              _buildMyRequestsList(),
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

  Widget _buildSittersList() {
    final sittersAsync = ref.watch(filteredSittingServicesProvider);

    return sittersAsync.when(
      data: (sitters) {
        if (sitters.isEmpty) {
          return const EmptyStateWidget(
            title: 'לא נמצאו שומרים',
            subtitle: 'נסה לשנות את הפילטרים או לחפש באזור אחר',
            icon: Icons.search_off_rounded,
          );
        }
        return _buildScrollableList(
          count: sitters.length,
          itemBuilder: (context, index) {
            final sitter = sitters[index];
            return BoutiquePropertyCard(
              title: sitter.providerName,
              subtitle: sitter.petTypes.join(' • '),
              price: '₪${sitter.priceText}',
              rating: sitter.rating ?? 0.0,
              reviewCount: sitter.reviewCount ?? 0,
              imageUrl: sitter.providerPhotoUrl,
              onTap: () => context.push('/sitting/detail/${sitter.id}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildMyRequestsList() {
    final myRequestsAsync = ref.watch(sittingRequestsProvider);

    return myRequestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Stack(
            children: [
              const Center(
                child: EmptyStateWidget(
                  title: 'אין בקשות פעילות',
                  subtitle: 'עדיין לא פרסמת בקשה לטיפול בחיות המחמד שלך',
                  icon: Icons.assignment_outlined,
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () => context.push('/sitting/create'),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          );
        }
        return Stack(
          children: [
            _buildScrollableList(
              count: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return BoutiquePropertyCard(
                  title: '${req.petName} - ${req.area}',
                  subtitle:
                      '${req.petType.name} • ${req.startDate?.day}/${req.startDate?.month}',
                  price: req.budget ?? 'לפי הסכמה',
                  actionText: 'סטטוס: ${req.status.name}',
                  onTap: () => context.push('/sitting/detail', extra: req),
                );
              },
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () => context.push('/sitting/create'),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
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
