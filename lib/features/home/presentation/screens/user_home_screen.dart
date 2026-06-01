import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_bottom_nav.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/luxury_hero.dart';
import 'package:petpal/core/widgets/glass_search_bar.dart';
import 'package:petpal/core/widgets/discovery_chip.dart';
import 'package:petpal/core/widgets/luxury_service_card.dart';
import 'package:petpal/features/home/presentation/widgets/home_top_rated_section.dart';
import 'package:petpal/features/home/presentation/widgets/my_requests_tab.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart' show SittingStatus;
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';
import 'package:petpal/features/lost_and_found/presentation/screens/lost_found_feed_screen.dart';
import 'package:petpal/features/feed/presentation/screens/feed_screen.dart';
import 'package:petpal/features/explore/presentation/screens/explore_screen.dart';
import 'package:petpal/features/home/presentation/widgets/services_tab.dart';
import 'package:petpal/features/messaging/presentation/widgets/chat_tab.dart';
import 'package:petpal/features/explore/domain/entities/poi_model.dart';
import 'package:petpal/features/explore/presentation/providers/poi_provider.dart';
import 'package:petpal/features/explore/presentation/widgets/poi_card.dart';
import 'package:petpal/core/widgets/empty_state_card.dart';


enum ServiceType { dogWalk, petSitting, available }

class ServiceCardData {
  final ServiceType type;
  final String name;
  final double rating;
  final String city;
  final String priceText;
  final String timeText;

  const ServiceCardData({
    required this.type,
    required this.name,
    required this.rating,
    required this.city,
    required this.priceText,
    required this.timeText,
  });
}

class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      _HomeTab(
        onAction: _toast,
        onTabChange: (i) => setState(() => _currentIndex = i),
      ),
      const FeedScreen(),
      const ExploreScreen(),
      const LostFoundFeedScreen(),
      const ServicesTab(),
      const MyRequestsTab(),
      const ChatTab(),
    ];
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(msg),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _currentIndex,
          onChanged: (i) => setState(() => _currentIndex = i),
          items: const [
            AppNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'בית'),
            AppNavItem(icon: Icons.feed_outlined, activeIcon: Icons.feed_rounded, label: 'פיד'),
            AppNavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'גלה'),
            AppNavItem(icon: Icons.pets_outlined, activeIcon: Icons.pets_rounded, label: 'אבודים'),
            AppNavItem(icon: Icons.design_services_outlined, activeIcon: Icons.design_services_rounded, label: 'שירותים'),
            AppNavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'הזמנות'),
            AppNavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'צ׳אט'),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends ConsumerStatefulWidget {
  final void Function(String msg) onAction;
  final void Function(int index) onTabChange;

  const _HomeTab({
    required this.onAction,
    required this.onTabChange,
  });

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  final ScrollController _scrollController = ScrollController();
  bool _showStickySearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 460 && !_showStickySearch) {
      setState(() => _showStickySearch = true);
    } else if (_scrollController.offset <= 460 && _showStickySearch) {
      setState(() => _showStickySearch = false);
    }
  }

  Color _sittingStatusColor(SittingStatus status) {
    switch (status) {
      case SittingStatus.open: return AppColors.warning;
      case SittingStatus.taken: return AppColors.success;
      case SittingStatus.closed: return AppColors.primary;
      case SittingStatus.declined: return AppColors.error;
    }
  }

  String _sittingStatusLabel(SittingStatus status) {
    switch (status) {
      case SittingStatus.open: return 'ממתין';
      case SittingStatus.taken: return 'אושר';
      case SittingStatus.closed: return 'הושלם';
      case SittingStatus.declined: return 'נדחה';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sittingReqAsync = ref.watch(sittingRequestsProvider);
    final walkReqAsync = ref.watch(walkRequestsProvider);
    final sittersAsync = ref.watch(sittingServicesProvider);
    final walkersAsync = ref.watch(walkServicesProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final profile = profileAsync.valueOrNull;
    final parksAsync = ref.watch(topRatedPOIsProvider(type: POIType.park));
    final vetsAsync = ref.watch(topRatedPOIsProvider(type: POIType.vet));
    final storesAsync = ref.watch(topRatedPOIsProvider(type: POIType.store));


    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Parallax Hero
            LuxuryHero(
              imageUrl:
                  'https://images.unsplash.com/photo-1552053831-71594a27632d?q=80&w=2000&auto=format&fit=crop',
              scrollController: _scrollController,
              searchBar: const GlassSearchBar(hintText: 'חפש שירותים...'),
              profileImageUrl: profile?.photoUrl,
              userName: profile?.name,
              profileMenuItems: [
                ProfileMenuItem(
                  icon: Icons.person_rounded,
                  label: 'הפרופיל שלי',
                  subtitle: 'ניהול פרטים אישיים',
                  onTap: () => context.push('/profile'),
                ),
                ProfileMenuItem(
                  icon: Icons.pets_rounded,
                  iconColor: AppColors.sapphire,
                  label: 'החיות שלי',
                  subtitle: 'ניהול חיות המחמד שלך',
                  onTap: () => context.push('/my-pets'),
                ),
              ],
            ),

            // 2. Discovery Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.marginPage),
                  child: Row(
                    children: [
                      DiscoveryChip(
                        label: 'שמירה',
                        icon: Icons.home_work_outlined,
                        onTap: () => widget.onTabChange(4),
                      ),
                      const SizedBox(width: 12),
                      DiscoveryChip(
                        label: 'גינות כלבים',
                        icon: Icons.park_rounded,
                        onTap: () {
                          ref.read(exploreTabIndexProvider.notifier).state = 0;
                          widget.onTabChange(2);
                        },
                      ),
                      const SizedBox(width: 12),
                      DiscoveryChip(
                        label: 'וטרינרים',
                        icon: Icons.medical_services_rounded,
                        onTap: () {
                          ref.read(exploreTabIndexProvider.notifier).state = 1;
                          widget.onTabChange(2);
                        },
                      ),
                      const SizedBox(width: 12),
                      DiscoveryChip(
                        label: 'חנויות חיות',
                        icon: Icons.shopping_bag_rounded,
                        onTap: () {
                          ref.read(exploreTabIndexProvider.notifier).state = 2;
                          widget.onTabChange(2);
                        },
                      ),
                      const SizedBox(width: 12),
                      DiscoveryChip(
                        label: 'חיות אבודות',
                        icon: Icons.pets_outlined,
                        onTap: () => widget.onTabChange(3),
                      ),
                      const SizedBox(width: 12),
                      DiscoveryChip(
                        label: 'פיד',
                        icon: Icons.feed_outlined,
                        onTap: () => widget.onTabChange(1),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. My Sitting Requests
            SliverToBoxAdapter(
              child: sittingReqAsync.when(
                data: (requests) {
                  if (requests.isEmpty) return const SizedBox.shrink();
                  return HomeTopRatedSection(
                    title: 'בקשות השמירה שלי',
                    itemHeight: 180,
                    onMoreTap: () => widget.onTabChange(5),
                    itemCount: requests.take(10).length,
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      return SittingRequestHomeCard(
                        request: req,
                        statusColor: _sittingStatusColor(req.status),
                        statusLabel: _sittingStatusLabel(req.status),
                        onTap: () =>
                            context.push('/sitting/detail', extra: req),
                      );
                    },
                  );
                },
                loading: () => const SizedBox(
                    height: 180,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2))),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text('שגיאה בטעינה',
                          style: AppTextStyles.labelMd
                              .copyWith(color: AppColors.error)),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // 4. My Walk Requests
            SliverToBoxAdapter(
              child: walkReqAsync.when(
                data: (requests) {
                  if (requests.isEmpty) return const SizedBox.shrink();
                  return HomeTopRatedSection(
                    title: 'בקשות הטיול שלי',
                    itemHeight: 180,
                    onMoreTap: () => widget.onTabChange(5),
                    itemCount: requests.take(10).length,
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      return WalkRequestHomeCard(
                        request: req,
                        onTap: () =>
                            context.push('/walks/detail', extra: req),
                      );
                    },
                  );
                },
                loading: () => const SizedBox(
                    height: 180,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2))),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text('שגיאה בטעינה',
                          style: AppTextStyles.labelMd
                              .copyWith(color: AppColors.error)),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // 5. Available Sitters
            SliverToBoxAdapter(
              child: sittersAsync.when(
                data: (sitters) {
                  final top = (sitters.toList()
                        ..sort((a, b) =>
                            (b.rating ?? 0).compareTo(a.rating ?? 0)))
                      .take(10)
                      .toList();
                  if (top.isEmpty) return const SizedBox.shrink();
                  return HomeTopRatedSection(
                    title: 'שומרים זמינים',
                    itemHeight: 340,
                    onMoreTap: () => widget.onTabChange(4),
                    itemCount: top.length,
                    itemBuilder: (context, index) {
                      final s = top[index];
                      return LuxuryServiceCard(
                        title: s.providerName,
                        serviceType: s.petTypes.join(' • '),
                        price: '₪${s.priceText}',
                        rating: (s.rating ?? 0).toStringAsFixed(1),
                        location: s.area,
                        imageUrl: s.providerPhotoUrl ?? '',
                        onTap: () => context.push(
                            '/services/provider/sitting',
                            extra: s),
                      );
                    },
                  );
                },
                loading: () => const SizedBox(
                    height: 340,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2))),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text('שגיאה בטעינה',
                          style: AppTextStyles.labelMd
                              .copyWith(color: AppColors.error)),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // 6. Available Walkers
            SliverToBoxAdapter(
              child: walkersAsync.when(
                data: (walkers) {
                  final top = (walkers.toList()
                        ..sort((a, b) =>
                            (b.rating ?? 0).compareTo(a.rating ?? 0)))
                      .take(10)
                      .toList();
                  if (top.isEmpty) return const SizedBox.shrink();
                  return HomeTopRatedSection(
                    title: 'מטיילים זמינים',
                    itemHeight: 340,
                    onMoreTap: () => widget.onTabChange(4),
                    itemCount: top.length,
                    itemBuilder: (context, index) {
                      final w = top[index];
                      return LuxuryServiceCard(
                        title: w.providerName,
                        serviceType: w.petTypes.join(' • '),
                        price: '₪${w.priceText}',
                        rating: (w.rating ?? 0).toStringAsFixed(1),
                        location: w.area,
                        imageUrl: w.providerPhotoUrl ?? '',
                        onTap: () => context.push(
                            '/services/provider/walk',
                            extra: w),
                      );
                    },
                  );
                },
                loading: () => const SizedBox(
                    height: 340,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2))),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text('שגיאה בטעינה',
                          style: AppTextStyles.labelMd
                              .copyWith(color: AppColors.error)),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // 7. Dog Parks Section
            SliverToBoxAdapter(
              child: parksAsync.when(
                data: (parks) => HomeTopRatedSection(
                  title: 'גינות כלבים',
                  itemHeight: 300,
                  onMoreTap: () {
                    ref.read(exploreTabIndexProvider.notifier).state = 0;
                    widget.onTabChange(2);
                  },
                  itemCount: parks.length,
                  emptyState: const EmptyStateWidget(
                    title: 'אין גינות כלבים באזור',
                    subtitle: 'נסה לחפש באזור אחר',
                    icon: Icons.park_rounded,
                  ),
                  itemBuilder: (context, index) {
                    final poi = parks[index];
                    return Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: POICard(
                        poi: poi,
                        isCompact: true,
                        onTap: () => context.push('/explore/poi/${poi.id}'),
                      ),
                    );
                  },
                ),
                loading: () => const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // 8. Vets Section
            SliverToBoxAdapter(
              child: vetsAsync.when(
                data: (vets) => HomeTopRatedSection(
                  title: 'וטרינרים',
                  itemHeight: 300,
                  onMoreTap: () {
                    ref.read(exploreTabIndexProvider.notifier).state = 1;
                    widget.onTabChange(2);
                  },
                  itemCount: vets.length,
                  emptyState: const EmptyStateWidget(
                    title: 'אין וטרינרים באזור',
                    subtitle: 'נסה לחפש באזור אחר',
                    icon: Icons.medical_services_rounded,
                  ),
                  itemBuilder: (context, index) {
                    final poi = vets[index];
                    return Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: POICard(
                        poi: poi,
                        isCompact: true,
                        onTap: () => context.push('/explore/poi/${poi.id}'),
                      ),
                    );
                  },
                ),
                loading: () => const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // 9. Stores Section
            SliverToBoxAdapter(
              child: storesAsync.when(
                data: (stores) => HomeTopRatedSection(
                  title: 'חנויות חיות',
                  itemHeight: 300,
                  onMoreTap: () {
                    ref.read(exploreTabIndexProvider.notifier).state = 2;
                    widget.onTabChange(2);
                  },
                  itemCount: stores.length,
                  emptyState: const EmptyStateWidget(
                    title: 'אין חנויות באזור',
                    subtitle: 'נסה לחפש באזור אחר',
                    icon: Icons.shopping_bag_rounded,
                  ),
                  itemBuilder: (context, index) {
                    final poi = stores[index];
                    return Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: POICard(
                        poi: poi,
                        isCompact: true,
                        onTap: () => context.push('/explore/poi/${poi.id}'),
                      ),
                    );
                  },
                ),
                loading: () => const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 130)),
          ],
        ),

        // Sticky Search Bar Overlay
        if (_showStickySearch)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
                left: AppSpacing.marginPage,
                right: AppSpacing.marginPage,
              ),
              color: AppColors.surface.withValues(alpha: 0.95),
              child: const GlassSearchBar(hintText: 'חפש שירותים...'),
            ),
          ),
      ],
    );
  }
}
