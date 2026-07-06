import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/app_header_bar.dart';
import 'package:petpal/core/widgets/app_search_bar.dart';
import 'package:petpal/core/widgets/filter_button.dart';
import 'package:petpal/features/explore/presentation/providers/poi_filters_provider.dart';
import 'package:petpal/features/explore/presentation/widgets/filter_bottom_sheet.dart';
import 'package:petpal/features/sitting/presentation/providers/marketplace_provider.dart';
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
    // Listen to tab index changes from other screens
    ref.listen(exploreTabIndexProvider, (previous, next) {
      if (next != _tabController.index) {
        _tabController.animateTo(next);
      }
    });

    return AppScaffold(
      body: ColoredBox(
        color: AppColors.surface,
        child: Column(
          children: [
            const AppHeaderBar(title: 'גלה'),
            _buildHeader(context),
            Expanded(child: _buildOwnerView(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final filterActiveCount = ref.watch(poiFiltersProvider).activeCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FilterButton(
                activeCount: filterActiveCount,
                onTap: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const FilterBottomSheet(isOwner: true),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppSearchBar(
                  hint: 'חפש...',
                  onChanged: (value) {
                    ref
                        .read(marketplaceFiltersProvider.notifier)
                        .updateSearch(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerView(BuildContext context) {
    return Column(
      children: [
        // Owner sub-tabs with card container
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.border.withValues(alpha: 0.4),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                return Row(
                  children: [
                    Expanded(child: _buildTabButton(0, 'גינות כלבים')),
                    _buildTabSeparator(),
                    Expanded(child: _buildTabButton(1, 'וטרינרים')),
                    _buildTabSeparator(),
                    Expanded(child: _buildTabButton(2, 'חנויות')),
                  ],
                );
              },
            ),
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
    // nearbyPOIsProvider watches poiFiltersProvider internally and applies
    // minRating / hasReviewsOnly before returning — filtering in the provider
    // layer means it runs on the full fetched set, not after the 200-doc cap.
    final poisAsync = ref.watch(nearbyPOIsProvider(type: type));

    return poisAsync.when(
      data: (pois) {
        if (pois.isEmpty) {
          return const EmptyStateWidget(
            title: 'לא נמצאו תוצאות',
            subtitle: 'נסה לשנות את הסינון',
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

  Widget _buildTabButton(int index, String label) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTabSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        '|',
        style: TextStyle(
          color: AppColors.border,
          fontSize: 16,
          fontWeight: FontWeight.w300,
        ),
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
