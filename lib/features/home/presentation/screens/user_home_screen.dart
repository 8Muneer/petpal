import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/core/widgets/app_bottom_nav.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/section_header.dart';
import 'package:petpal/core/widgets/luxury_hero.dart';
import 'package:petpal/core/widgets/glass_search_bar.dart';
import 'package:petpal/core/widgets/discovery_chip.dart';
import 'package:petpal/core/widgets/luxury_service_card.dart';
import 'package:petpal/features/home/presentation/widgets/home_top_rated_section.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart'
    show SittingRequest, SittingStatus;
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';
import 'package:petpal/core/widgets/empty_state_card.dart';
import 'package:petpal/core/utils/price_formatter.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart';
import 'package:petpal/features/walks/domain/entities/walk_service.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/messaging/data/datasources/messaging_datasource.dart';
import 'package:petpal/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';
import 'package:petpal/features/lost_and_found/presentation/screens/lost_found_feed_screen.dart';
import 'package:petpal/features/booking/presentation/providers/booking_provider.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';
import 'package:petpal/features/feed/presentation/screens/feed_screen.dart';

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

class _UserHomeScreenState extends ConsumerState<UserHomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

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
    final tabs = <Widget>[
      _HomeTab(
        onAction: _toast,
        onTabChange: (i) => setState(() => _currentIndex = i),
      ),
      const FeedScreen(),
      const LostFoundFeedScreen(),
      const _ServicesTab(),
      const _MyRequestsTab(),
      const _ChatTab(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          child: KeyedSubtree(
            key: ValueKey(_currentIndex),
            child: tabs[_currentIndex],
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _currentIndex,
          onChanged: (i) => setState(() => _currentIndex = i),
          items: const [
            AppNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'בית'),
            AppNavItem(icon: Icons.feed_outlined, activeIcon: Icons.feed_rounded, label: 'פיד'),
            AppNavItem(icon: Icons.pets_outlined, activeIcon: Icons.pets_rounded, label: 'אבודים'),
            AppNavItem(icon: Icons.design_services_outlined, activeIcon: Icons.design_services_rounded, label: 'שירותים'),
            AppNavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'הבקשות'),
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
    }
  }

  String _sittingStatusLabel(SittingStatus status) {
    switch (status) {
      case SittingStatus.open: return 'ממתין';
      case SittingStatus.taken: return 'אושר';
      case SittingStatus.closed: return 'הושלם';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sittingReqAsync = ref.watch(sittingRequestsProvider);
    final walkReqAsync = ref.watch(walkRequestsProvider);
    final sittersAsync = ref.watch(sittingServicesProvider);
    final walkersAsync = ref.watch(walkServicesProvider);

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
              onProfileTap: () => context.push('/profile'),
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
                        onTap: () => widget.onTabChange(3),
                      ),
                      const SizedBox(width: 12),
                      DiscoveryChip(
                        label: 'טיולים',
                        icon: Icons.directions_walk_outlined,
                        onTap: () => widget.onTabChange(3),
                      ),
                      const SizedBox(width: 12),
                      DiscoveryChip(
                        label: 'חיות אבודות',
                        icon: Icons.pets_outlined,
                        onTap: () => widget.onTabChange(2),
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
                    onMoreTap: () => widget.onTabChange(3),
                    itemCount: requests.take(10).length,
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      return _SittingRequestHomeCard(
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
                error: (_, __) => const SizedBox.shrink(),
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
                    onMoreTap: () => widget.onTabChange(3),
                    itemCount: requests.take(10).length,
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      return _WalkRequestHomeCard(
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
                error: (_, __) => const SizedBox.shrink(),
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
                    onMoreTap: () => widget.onTabChange(3),
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
                        onTap: () => widget.onTabChange(3),
                      );
                    },
                  );
                },
                loading: () => const SizedBox(
                    height: 340,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2))),
                error: (_, __) => const SizedBox.shrink(),
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
                    onMoreTap: () => widget.onTabChange(3),
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
                        onTap: () => widget.onTabChange(3),
                      );
                    },
                  );
                },
                loading: () => const SizedBox(
                    height: 340,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2))),
                error: (_, __) => const SizedBox.shrink(),
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

class _SittingRequestHomeCard extends StatelessWidget {
  final SittingRequest request;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;

  const _SittingRequestHomeCard({
    required this.request,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: AppRadius.organicRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.premium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.home_work_outlined,
                      size: 18, color: AppColors.primary),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel,
                      style: AppTextStyles.labelSm.copyWith(
                          color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(request.petName, style: AppTextStyles.headlineSm),
            const SizedBox(height: 4),
            Text(request.area,
                style:
                    AppTextStyles.labelMd.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _WalkRequestHomeCard extends StatelessWidget {
  final WalkRequest request;
  final VoidCallback onTap;

  const _WalkRequestHomeCard({
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: AppRadius.organicRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.premium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_walk_outlined,
                      size: 18, color: AppColors.primary),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('טיול',
                      style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(request.petName, style: AppTextStyles.headlineSm),
            const SizedBox(height: 4),
            Text(request.area,
                style:
                    AppTextStyles.labelMd.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// הבקשות שלי Tab — combines walk requests + sitting requests
// ═══════════════════════════════════════════════════════════════════════════

class _MyRequestsTab extends ConsumerStatefulWidget {
  const _MyRequestsTab();

  @override
  ConsumerState<_MyRequestsTab> createState() => _MyRequestsTabState();
}

class _MyRequestsTabState extends ConsumerState<_MyRequestsTab> {
  int _selected = 0; // 0 = הכל, 1 = טיולים, 2 = שמירה

  static const _filters = ['הכל', 'בקשות טיולים', 'בקשות שמירה', 'הזמנות'];

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('צור בקשה חדשה', style: AppTextStyles.headlineSm),
              const SizedBox(height: 6),
              Text('בחר את סוג הבקשה שתרצה להגיש',
                  style: AppTextStyles.labelMd),
              const SizedBox(height: 20),
              // Walks option
              _CreateOptionTile(
                icon: Icons.directions_walk_rounded,
                color: AppColors.primary,
                title: 'בקשת טיולים',
                subtitle: 'חפש מטייל לכלב שלך',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/walks/create');
                },
              ),
              const SizedBox(height: 12),
              // Sitting option
              _CreateOptionTile(
                icon: Icons.house_rounded,
                color: AppColors.sitting,
                title: 'בקשת שמירה',
                subtitle: 'חפש שומר לחיית המחמד שלך',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/sitting/create');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Feed-style filter bar ────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_filters.length, (i) {
                  final selected = _selected == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected ? AppColors.primary : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Text(
                        _filters[i],
                        style: AppTextStyles.bodyMd.copyWith(
                          color: selected ? AppColors.primary : AppColors.textMuted,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // ── Create request CTA ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: InkWell(
              onTap: () => _showCreateSheet(context),
              borderRadius: BorderRadius.circular(32),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.subtle,
                ),
                child: Row(
                  children: [
                    Text(
                      'צור בקשה חדשה...',
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                    ),
                    const Spacer(),
                    Icon(Icons.add_circle_outline_rounded,
                        color: AppColors.primary.withValues(alpha: 0.8), size: 22),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: switch (_selected) {
                1 => const _WalkRequestsView(key: ValueKey('walk')),
                2 => const _SittingRequestsView(key: ValueKey('sitting')),
                3 => const _MyBookingsView(key: ValueKey('bookings')),
                _ => const _AllRequestsFeed(key: ValueKey('all')),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodyMd
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.labelMd),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Unified feed combining walk + sitting requests ───────────────────────────

class _AllRequestsFeed extends ConsumerWidget {
  const _AllRequestsFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walksAsync   = ref.watch(walkRequestsProvider);
    final sittingAsync = ref.watch(sittingRequestsProvider);

    if (walksAsync.isLoading || sittingAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final walks   = walksAsync.asData?.value   ?? <WalkRequest>[];
    final sittings = sittingAsync.asData?.value ?? <SittingRequest>[];

    if (walks.isEmpty && sittings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined,
                size: 56, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('אין בקשות עדיין', style: AppTextStyles.headlineSm.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text('צור בקשת טיול או שמירה מהדף הראשי', style: AppTextStyles.labelMd),
          ],
        ),
      );
    }

    // Interleave: pair walk + sitting cards side by side in a grid
    final walkCards   = walks.asMap().entries.map((e) => _WalkRequestCard(request: e.value, colorIndex: e.key)).toList();
    final sittingCards = sittings.asMap().entries.map((e) => _SittingRequestCard(request: e.value, colorIndex: e.key)).toList();

    // Merge into a flat list sorted by type label for display
    final List<Widget> allCards = [...walkCards, ...sittingCards];

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewPadding.bottom + 84),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.47,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: allCards.length,
      itemBuilder: (_, i) => allCards[i],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// שירותים Tab — Airbnb-style unified services with advanced filters
// ═══════════════════════════════════════════════════════════════════════════

class _ServiceEntry {
  final bool isWalk;
  final WalkService? walk;
  final SittingService? sitting;

  const _ServiceEntry.walk(this.walk)
      : isWalk = true,
        sitting = null;
  const _ServiceEntry.sitting(this.sitting)
      : isWalk = false,
        walk = null;

  String get providerName => isWalk ? walk!.providerName : sitting!.providerName;
  String get area         => isWalk ? walk!.area         : sitting!.area;
  List<String> get petTypes     => isWalk ? walk!.petTypes     : sitting!.petTypes;
  List<String> get availableDays => isWalk ? walk!.availableDays : sitting!.availableDays;
  bool get isActive       => isWalk ? walk!.isActive      : sitting!.isActive;
  double? get rating      => isWalk ? walk!.rating        : sitting!.rating;
  int? get reviewCount    => isWalk ? walk!.reviewCount   : sitting!.reviewCount;
  String get priceText    => isWalk ? walk!.priceText     : sitting!.priceText;
  String get priceType    => isWalk ? walk!.priceType     : sitting!.priceType;

  double get parsedPrice {
    final cleaned = priceText.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}

// ── Filter state (passed into the sheet so it can compute live counts) ──────
class _FilterState {
  String typeFilter;
  Set<String> petTypes;
  Set<String> selectedDays;
  double minRating;
  RangeValues priceRange;
  bool activeOnly;
  bool hasReviewsOnly;
  String sortBy;

  _FilterState({
    this.typeFilter = 'הכל',
    Set<String>? petTypes,
    Set<String>? selectedDays,
    this.minRating = 0,
    this.priceRange = const RangeValues(0, 500),
    this.activeOnly = false,
    this.hasReviewsOnly = false,
    this.sortBy = 'ברירת מחדל',
  })  : petTypes = petTypes ?? {},
        selectedDays = selectedDays ?? {};

  _FilterState copyWith({
    String? typeFilter,
    Set<String>? petTypes,
    Set<String>? selectedDays,
    double? minRating,
    RangeValues? priceRange,
    bool? activeOnly,
    bool? hasReviewsOnly,
    String? sortBy,
  }) =>
      _FilterState(
        typeFilter: typeFilter ?? this.typeFilter,
        petTypes: petTypes ?? Set.from(this.petTypes),
        selectedDays: selectedDays ?? Set.from(this.selectedDays),
        minRating: minRating ?? this.minRating,
        priceRange: priceRange ?? this.priceRange,
        activeOnly: activeOnly ?? this.activeOnly,
        hasReviewsOnly: hasReviewsOnly ?? this.hasReviewsOnly,
        sortBy: sortBy ?? this.sortBy,
      );

  bool get isDefault =>
      typeFilter == 'הכל' &&
      petTypes.isEmpty &&
      selectedDays.isEmpty &&
      minRating == 0 &&
      priceRange.start == 0 &&
      priceRange.end == 500 &&
      !activeOnly &&
      !hasReviewsOnly &&
      sortBy == 'ברירת מחדל';

  int get activeCount {
    int n = 0;
    if (typeFilter != 'הכל') n++;
    if (petTypes.isNotEmpty) n++;
    if (selectedDays.isNotEmpty) n++;
    if (minRating > 0) n++;
    if (priceRange.start > 0 || priceRange.end < 500) n++;
    if (activeOnly) n++;
    if (hasReviewsOnly) n++;
    if (sortBy != 'ברירת מחדל') n++;
    return n;
  }
}

List<_ServiceEntry> _runFilter(
  List<WalkService> walks,
  List<SittingService> sittings,
  _FilterState f,
  String query,
) {
  List<_ServiceEntry> all = [];
  if (f.typeFilter != 'שמירה') all.addAll(walks.map(_ServiceEntry.walk));
  if (f.typeFilter != 'טיולים') all.addAll(sittings.map(_ServiceEntry.sitting));

  if (f.activeOnly) all = all.where((e) => e.isActive).toList();
  if (f.hasReviewsOnly) all = all.where((e) => (e.reviewCount ?? 0) > 0).toList();
  if (f.petTypes.isNotEmpty) {
    all = all.where((e) => f.petTypes.any(e.petTypes.contains)).toList();
  }
  if (f.selectedDays.isNotEmpty) {
    all = all.where((e) => f.selectedDays.any(e.availableDays.contains)).toList();
  }
  if (f.minRating > 0) {
    all = all.where((e) => (e.rating ?? 0) >= f.minRating).toList();
  }
  final priceDefault = f.priceRange.start == 0 && f.priceRange.end == 500;
  if (!priceDefault) {
    all = all
        .where((e) =>
            e.parsedPrice >= f.priceRange.start &&
            e.parsedPrice <= f.priceRange.end)
        .toList();
  }
  if (query.isNotEmpty) {
    all = all
        .where((e) =>
            e.providerName.toLowerCase().contains(query) ||
            e.area.toLowerCase().contains(query))
        .toList();
  }
  switch (f.sortBy) {
    case 'דירוג גבוה':
      all.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    case 'מחיר נמוך':
      all.sort((a, b) => a.parsedPrice.compareTo(b.parsedPrice));
    case 'מחיר גבוה':
      all.sort((a, b) => b.parsedPrice.compareTo(a.parsedPrice));
  }
  return all;
}

class _ServicesTab extends ConsumerStatefulWidget {
  const _ServicesTab();

  @override
  ConsumerState<_ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends ConsumerState<_ServicesTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _FilterState _filter = _FilterState();

  static const _typeFilters = ['הכל', 'טיולים', 'שמירה'];
  static const _days = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];
  static const _dayLabels = ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳'];
  static const _petOptions = ['כלב', 'חתול', 'אחר'];
  static const _sortOptions = ['ברירת מחדל', 'דירוג גבוה', 'מחיר נמוך', 'מחיר גבוה'];
  static const _ratingOptions = [3.0, 4.0, 4.5];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openFilterSheet(List<WalkService> walks, List<SittingService> sittings) {
    var draft = _filter.copyWith();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollCtrl) => StatefulBuilder(
          builder: (ctx, setSheet) {
            final liveCount = _runFilter(walks, sittings, draft, _query).length;

            // ── helpers ──────────────────────────────────────────────────
            Widget sectionTitle(String t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(t,
                      style: AppTextStyles.headlineSm.copyWith(fontSize: 16)),
                );

            Widget divider() => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: AppColors.divider, height: 1),
                );

            Widget filterChip(
              String label, {
              required bool selected,
              required VoidCallback onTap,
              IconData? icon,
            }) =>
                GestureDetector(
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon,
                              size: 14,
                              color: selected ? Colors.white : AppColors.textSecondary),
                          const SizedBox(width: 5),
                        ],
                        Text(label,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: selected ? Colors.white : AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
                      ],
                    ),
                  ),
                );

            // ── sheet body ───────────────────────────────────────────────
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle + header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('סינון ומיון', style: AppTextStyles.headlineSm),
                            GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.divider,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, size: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.divider, height: 1),
                      ],
                    ),
                  ),

                  // Scrollable content
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      children: [

                        // ── Service type ──────────────────────────────────
                        sectionTitle('סוג שירות'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _typeFilters.map((t) {
                            final icons = {
                              'הכל': Icons.grid_view_rounded,
                              'טיולים': Icons.directions_walk_rounded,
                              'שמירה': Icons.home_work_rounded,
                            };
                            return filterChip(t,
                                selected: draft.typeFilter == t,
                                icon: icons[t],
                                onTap: () => setSheet(
                                    () => draft = draft.copyWith(typeFilter: t)));
                          }).toList(),
                        ),

                        divider(),

                        // ── Sort ──────────────────────────────────────────
                        sectionTitle('מיון לפי'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _sortOptions.map((s) {
                            final icons = {
                              'ברירת מחדל': Icons.sort_rounded,
                              'דירוג גבוה': Icons.star_rounded,
                              'מחיר נמוך': Icons.arrow_downward_rounded,
                              'מחיר גבוה': Icons.arrow_upward_rounded,
                            };
                            return filterChip(s,
                                selected: draft.sortBy == s,
                                icon: icons[s],
                                onTap: () => setSheet(() => draft = draft.copyWith(sortBy: s)));
                          }).toList(),
                        ),

                        divider(),

                        // ── Price range ───────────────────────────────────
                        sectionTitle('טווח מחירים'),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _PriceLabel('₪${draft.priceRange.start.round()}'),
                            _PriceLabel('₪${draft.priceRange.end.round()}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderTheme.of(ctx).copyWith(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.border,
                            thumbColor: AppColors.primary,
                            overlayColor: AppColors.primary.withValues(alpha: 0.12),
                            trackHeight: 3,
                          ),
                          child: RangeSlider(
                            values: draft.priceRange,
                            min: 0,
                            max: 500,
                            divisions: 50,
                            onChanged: (v) => setSheet(() => draft = draft.copyWith(priceRange: v)),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₪0', style: AppTextStyles.labelSm),
                            Text('₪500+', style: AppTextStyles.labelSm),
                          ],
                        ),

                        divider(),

                        // ── Available days ────────────────────────────────
                        sectionTitle('ימים זמינים'),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (i) {
                            final day = _days[i];
                            final label = _dayLabels[i];
                            final sel = draft.selectedDays.contains(day);
                            return GestureDetector(
                              onTap: () => setSheet(() {
                                final days = Set<String>.from(draft.selectedDays);
                                sel ? days.remove(day) : days.add(day);
                                draft = draft.copyWith(selectedDays: days);
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: sel ? AppColors.primary : AppColors.pureWhite,
                                  border: Border.all(
                                    color: sel ? AppColors.primary : AppColors.border,
                                    width: sel ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: sel ? Colors.white : AppColors.textSecondary,
                                      )),
                                ),
                              ),
                            );
                          }),
                        ),

                        divider(),

                        // ── Minimum rating ────────────────────────────────
                        sectionTitle('דירוג מינימלי'),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setSheet(() => draft = draft.copyWith(minRating: 0)),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: draft.minRating == 0 ? AppColors.primary : AppColors.pureWhite,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: draft.minRating == 0 ? AppColors.primary : AppColors.border,
                                  ),
                                ),
                                child: Text('הכל',
                                    style: AppTextStyles.bodyMd.copyWith(
                                      color: draft.minRating == 0 ? Colors.white : AppColors.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    )),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ..._ratingOptions.map((r) {
                              final sel = draft.minRating == r;
                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: GestureDetector(
                                  onTap: () => setSheet(() => draft = draft.copyWith(minRating: r)),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: sel ? AppColors.primary : AppColors.pureWhite,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: sel ? AppColors.primary : AppColors.border,
                                        width: sel ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star_rounded,
                                            size: 14,
                                            color: sel ? Colors.white : AppColors.warning),
                                        const SizedBox(width: 4),
                                        Text('$r+',
                                            style: AppTextStyles.bodyMd.copyWith(
                                              color: sel ? Colors.white : AppColors.onSurface,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),

                        divider(),

                        // ── Pet type (multi-select) ────────────────────────
                        sectionTitle('סוג חיה'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _petOptions.map((p) {
                            final icons = {
                              'כלב': Icons.directions_walk_rounded,
                              'חתול': Icons.pets_rounded,
                              'אחר': Icons.cruelty_free_rounded,
                            };
                            final sel = draft.petTypes.contains(p);
                            return filterChip(p,
                                selected: sel,
                                icon: icons[p],
                                onTap: () => setSheet(() {
                                      final pets = Set<String>.from(draft.petTypes);
                                      sel ? pets.remove(p) : pets.add(p);
                                      draft = draft.copyWith(petTypes: pets);
                                    }));
                          }).toList(),
                        ),

                        divider(),

                        // ── Extra options ─────────────────────────────────
                        sectionTitle('אפשרויות נוספות'),
                        _SwitchRow(
                          label: 'זמינים בלבד',
                          subtitle: 'הצג רק ספקים פעילים',
                          value: draft.activeOnly,
                          onChanged: (v) => setSheet(() => draft = draft.copyWith(activeOnly: v)),
                        ),
                        const SizedBox(height: 14),
                        _SwitchRow(
                          label: 'עם ביקורות בלבד',
                          subtitle: 'הצג רק ספקים שקיבלו ביקורות',
                          value: draft.hasReviewsOnly,
                          onChanged: (v) => setSheet(() => draft = draft.copyWith(hasReviewsOnly: v)),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Sticky bottom bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: const Border(top: BorderSide(color: AppColors.divider)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(
                        20, 14, 20, MediaQuery.of(ctx).padding.bottom + 14),
                    child: Row(
                      children: [
                        // Reset
                        GestureDetector(
                          onTap: () => setSheet(() => draft = _FilterState()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.pureWhite,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text('איפוס הכל',
                                style: AppTextStyles.bodyMd.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Show results
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _filter = draft);
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  liveCount > 0
                                      ? 'הצג $liveCount שירותים'
                                      : 'אין תוצאות',
                                  style: AppTextStyles.bodyMd.copyWith(
                                      color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walksAsync  = ref.watch(walkServicesProvider);
    final sittingAsync = ref.watch(sittingServicesProvider);

    final walks   = walksAsync.asData?.value  ?? <WalkService>[];
    final sittings = sittingAsync.asData?.value ?? <SittingService>[];
    final items = _runFilter(walks, sittings, _filter, _query);
    final activeCount = _filter.activeCount;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar + filter button ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openFilterSheet(walks, sittings),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: activeCount > 0 ? AppColors.primary : AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: activeCount > 0 ? AppColors.primary : AppColors.border,
                          ),
                          boxShadow: AppShadows.subtle,
                        ),
                        child: Icon(Icons.tune_rounded,
                            color: activeCount > 0 ? Colors.white : AppColors.textSecondary,
                            size: 22),
                      ),
                      if (activeCount > 0)
                        Positioned(
                          top: -6,
                          left: -6,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('$activeCount',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SearchBar(
                    controller: _searchCtrl,
                    hint: 'חפש/י לפי שם או אזור...',
                    onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  ),
                ),
              ],
            ),
          ),

          // ── Active filter removable chips ─────────────────────────────────
          if (!_filter.isDefault) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  if (_filter.typeFilter != 'הכל')
                    _ActiveChip(
                        label: _filter.typeFilter,
                        onRemove: () => setState(
                            () => _filter = _filter.copyWith(typeFilter: 'הכל'))),
                  if (_filter.minRating > 0)
                    _ActiveChip(
                        label: '★ ${_filter.minRating}+',
                        onRemove: () => setState(
                            () => _filter = _filter.copyWith(minRating: 0))),
                  if (_filter.priceRange.start > 0 || _filter.priceRange.end < 500)
                    _ActiveChip(
                        label:
                            '₪${_filter.priceRange.start.round()}–₪${_filter.priceRange.end.round()}',
                        onRemove: () => setState(() => _filter =
                            _filter.copyWith(priceRange: const RangeValues(0, 500)))),
                  if (_filter.selectedDays.isNotEmpty)
                    _ActiveChip(
                        label: _filter.selectedDays.join(' '),
                        onRemove: () => setState(
                            () => _filter = _filter.copyWith(selectedDays: {}))),
                  for (final p in _filter.petTypes)
                    _ActiveChip(
                        label: p,
                        onRemove: () => setState(() {
                              final s = Set<String>.from(_filter.petTypes)
                                ..remove(p);
                              _filter = _filter.copyWith(petTypes: s);
                            })),
                  if (_filter.activeOnly)
                    _ActiveChip(
                        label: 'זמינים',
                        onRemove: () => setState(
                            () => _filter = _filter.copyWith(activeOnly: false))),
                  if (_filter.hasReviewsOnly)
                    _ActiveChip(
                        label: 'עם ביקורות',
                        onRemove: () => setState(() =>
                            _filter = _filter.copyWith(hasReviewsOnly: false))),
                  if (_filter.sortBy != 'ברירת מחדל')
                    _ActiveChip(
                        label: _filter.sortBy,
                        onRemove: () => setState(() =>
                            _filter = _filter.copyWith(sortBy: 'ברירת מחדל'))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // ── Unified grid ──────────────────────────────────────────────────
          Expanded(
            child: Builder(builder: (_) {
              if (walksAsync.isLoading || sittingAsync.isLoading) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (walksAsync.hasError || sittingAsync.hasError) {
                return const Center(child: Text('שגיאה בטעינת השירותים'));
              }
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 56,
                          color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text('לא נמצאו שירותים',
                          style: AppTextStyles.headlineSm
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Text('נסה/י לשנות את הסינון', style: AppTextStyles.labelMd),
                    ],
                  ),
                );
              }
              return GridView.builder(
                padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewPadding.bottom + 84),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.58,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final e = items[i];
                  return e.isWalk
                      ? _WalkServiceCard(service: e.walk!)
                      : _SittingServiceCard(service: e.sitting!);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Small helpers used by the filter sheet ───────────────────────────────────

class _PriceLabel extends StatelessWidget {
  final String text;
  const _PriceLabel(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w800)),
      );
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.labelMd),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
            onChanged: onChanged,
          ),
        ],
      );
}

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close_rounded,
                    size: 13, color: AppColors.primary),
              ),
            ],
          ),
        ),
      );
}

class _WalksTab extends ConsumerStatefulWidget {
  const _WalksTab();

  @override
  ConsumerState<_WalksTab> createState() => _WalksTabState();
}

class _WalksTabState extends ConsumerState<_WalksTab> {
  int _selectedView = 0; // 0 = requests, 1 = services

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
      children: [
        // Toggle bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: GlassCard(
            useBlur: true,
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                Expanded(
                  child: _ToggleChip(
                    label: 'בקשות טיול',
                    icon: Icons.list_alt_rounded,
                    selected: _selectedView == 0,
                    onTap: () => setState(() => _selectedView = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ToggleChip(
                    label: 'שירותי טיולים',
                    icon: Icons.search_rounded,
                    selected: _selectedView == 1,
                    onTap: () => setState(() => _selectedView = 1),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _selectedView == 0
                ? _WalkRequestsView(key: const ValueKey('requests'))
                : _WalkServicesView(key: const ValueKey('services')),
          ),
        ),
      ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.lgRadius,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgRadius,
          color: selected ? AppColors.primary : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalkRequestsView extends ConsumerWidget {
  const _WalkRequestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(walkRequestsProvider);
    return Column(
      children: [
        // Requests list
        Expanded(
          child: requestsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: Text('שגיאה בטעינת הבקשות: $e'),
            ),
            data: (requests) {
              if (requests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_walk_rounded,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'אין בקשות טיול עדיין',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'לחץ/י על הכפתור למעלה כדי לפרסם בקשה',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.list_alt_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'הבקשות שלי (${requests.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewPadding.bottom + 84),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.47,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: requests.length,
                      itemBuilder: (ctx, i) => _WalkRequestCard(
                        request: requests[i],
                        colorIndex: i,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Walk request card (compact — taps through to detail screen) ──────────────
class _WalkRequestCard extends StatefulWidget {
  final WalkRequest request;
  final int colorIndex;
  const _WalkRequestCard({required this.request, required this.colorIndex});

  @override
  State<_WalkRequestCard> createState() => _WalkRequestCardState();
}

class _WalkRequestCardState extends State<_WalkRequestCard> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _bgColors = [
    AppColors.sapphire, AppColors.smartBlue, AppColors.blueSlate,
    AppColors.regalNavy, AppColors.prussianBlue, AppColors.twilightIndigo,
    AppColors.prussianBlue2, AppColors.blueSlate,
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  bool get _isOpen => widget.request.status == WalkStatus.open;

  String get _petTypeLabel {
    switch (widget.request.petType) {
      case PetType.dog: return 'כלב';
      case PetType.cat: return 'חתול';
      case PetType.other: return 'אחר';
    }
  }

  String get _genderLabel {
    if (widget.request.petGender == PetGender.male) return 'זכר';
    if (widget.request.petGender == PetGender.female) return 'נקבה';
    return '';
  }

  IconData get _fallbackIcon {
    switch (widget.request.petType) {
      case PetType.dog: return Icons.directions_walk_rounded;
      case PetType.cat: return Icons.pets_rounded;
      case PetType.other: return Icons.cruelty_free_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bgColors[widget.colorIndex % _bgColors.length];
    final images = widget.request.allImages;

    return GestureDetector(
      onTap: () => context.push('/walks/detail', extra: widget.request),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo area (carousel if multiple images)
            Expanded(
              flex: 56,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: bg),
                    if (images.isEmpty)
                      Center(child: Icon(_fallbackIcon, size: 60,
                          color: Colors.white.withValues(alpha: 0.7)))
                    else if (images.length == 1)
                      CachedNetworkImage(
                        imageUrl: images.first,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(child: Icon(
                            _fallbackIcon, size: 52,
                            color: Colors.white.withValues(alpha: 0.6))),
                        errorWidget: (_, __, ___) => Center(child: Icon(
                            _fallbackIcon, size: 52,
                            color: Colors.white.withValues(alpha: 0.6))),
                      )
                    else ...[
                      PageView.builder(
                        controller: _pageCtrl,
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (_, i) => CachedNetworkImage(
                          imageUrl: images[i],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Center(child: Icon(
                              _fallbackIcon, size: 52,
                              color: Colors.white.withValues(alpha: 0.6))),
                          errorWidget: (_, __, ___) => Center(child: Icon(
                              _fallbackIcon, size: 52,
                              color: Colors.white.withValues(alpha: 0.6))),
                        ),
                      ),
                      // Dot indicators
                      Positioned(
                        bottom: 6,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (i) =>
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: i == _page ? 12 : 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: i == _page
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    // Status pill
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _isOpen
                              ? AppColors.statusOpen
                              : AppColors.textMuted,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isOpen ? 'פתוח' : 'הושלם',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info area
            Expanded(
              flex: 44,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      widget.request.petName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    // Type + gender pills
                    Row(
                      children: [
                        _MiniPill(label: _petTypeLabel, color: AppColors.primary),
                        if (_genderLabel.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          _MiniPill(
                            label: _genderLabel,
                            color: widget.request.petGender == PetGender.female
                                ? AppColors.error
                                : AppColors.smartBlue,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Location
                    _InfoRow(icon: Icons.location_on_rounded, label: widget.request.area),
                    // Time
                    if (widget.request.preferredTime.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _InfoRow(icon: Icons.access_time_rounded, label: widget.request.preferredTime),
                    ],
                    const Spacer(),
                    // Button — always pinned to bottom
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('הצג פרטים',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 11, color: AppColors.textMuted),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
          ),
        ],
      );
}

class _WalkServicesView extends ConsumerStatefulWidget {
  const _WalkServicesView({super.key});

  @override
  ConsumerState<_WalkServicesView> createState() => _WalkServicesViewState();
}

class _WalkServicesViewState extends ConsumerState<_WalkServicesView> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'הכל';

  static const _filters = ['הכל', 'כלב', 'חתול', 'אחר'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(walkServicesProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: _SearchBar(
            controller: _searchCtrl,
            hint: 'חפש/י ספק טיולים...',
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),

        // Filter chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _FilterChip(
              label: _filters[i],
              selected: _filter == _filters[i],
              onTap: () => setState(() => _filter = _filters[i]),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: servicesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => const Center(
              child: Text('שגיאה בטעינת השירותים',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            data: (all) {
              final services = all.where((s) {
                final matchFilter =
                    _filter == 'הכל' || s.petTypes.contains(_filter);
                final matchQuery = _query.isEmpty ||
                    s.providerName.toLowerCase().contains(_query) ||
                    s.area.toLowerCase().contains(_query);
                return matchFilter && matchQuery;
              }).toList();

              if (services.isEmpty) {
                return const Center(
                  child: EmptyStateWidget(
                    title: 'אין שירותי טיולים',
                    subtitle: 'נסה/י לשנות את הסינון',
                    icon: Icons.directions_walk_rounded,
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.58,
                ),
                itemCount: services.length,
                itemBuilder: (_, i) =>
                    _WalkServiceCard(service: services[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// שמירה Tab
// ═══════════════════════════════════════════════════════════════════════════

class _SittingTab extends ConsumerStatefulWidget {
  final void Function(String msg) onAction;

  const _SittingTab({required this.onAction});

  @override
  ConsumerState<_SittingTab> createState() => _SittingTabState();
}

class _SittingTabState extends ConsumerState<_SittingTab> {
  int _selectedView = 0; // 0 = requests, 1 = services

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Toggle bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: GlassCard(
              useBlur: true,
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Expanded(
                    child: _ToggleChip(
                      label: 'בקשות שמירה',
                      icon: Icons.list_alt_rounded,
                      selected: _selectedView == 0,
                      onTap: () => setState(() => _selectedView = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ToggleChip(
                      label: 'שירותי שמירה',
                      icon: Icons.search_rounded,
                      selected: _selectedView == 1,
                      onTap: () => setState(() => _selectedView = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _selectedView == 0
                  ? _SittingRequestsView(key: const ValueKey('sitting_requests'))
                  : _SittingServicesView(
                      key: const ValueKey('sitting_services'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SittingRequestsView extends ConsumerWidget {
  const _SittingRequestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(sittingRequestsProvider);
    return Column(
      children: [
        // Requests list
        Expanded(
          child: requestsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: Text('שגיאה בטעינת הבקשות: $e'),
            ),
            data: (requests) {
              if (requests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home_work_rounded,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'אין בקשות שמירה עדיין',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'לחץ/י על הכפתור למעלה כדי לפרסם בקשה',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.list_alt_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'הבקשות שלי (${requests.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewPadding.bottom + 84),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.47,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: requests.length,
                      itemBuilder: (ctx, i) => _SittingRequestCard(
                        request: requests[i],
                        colorIndex: i,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SittingRequestCard extends StatefulWidget {
  final SittingRequest request;
  final int colorIndex;
  const _SittingRequestCard({required this.request, required this.colorIndex});

  @override
  State<_SittingRequestCard> createState() => _SittingRequestCardState();
}

class _SittingRequestCardState extends State<_SittingRequestCard> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _bgColors = [
    AppColors.blueSlate, AppColors.smartBlue, AppColors.sapphire,
    AppColors.regalNavy, AppColors.prussianBlue, AppColors.twilightIndigo,
    AppColors.prussianBlue2, AppColors.blueSlate,
  ];

  static const purple = AppColors.primary;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  bool get _isOpen => widget.request.status == SittingStatus.open;

  String get _petTypeLabel {
    switch (widget.request.petType) {
      case PetType.dog: return 'כלב';
      case PetType.cat: return 'חתול';
      case PetType.other: return 'אחר';
    }
  }

  String get _genderLabel {
    if (widget.request.petGender == PetGender.male) return 'זכר';
    if (widget.request.petGender == PetGender.female) return 'נקבה';
    return '';
  }

  IconData get _fallbackIcon {
    switch (widget.request.petType) {
      case PetType.dog: return Icons.directions_walk_rounded;
      case PetType.cat: return Icons.pets_rounded;
      case PetType.other: return Icons.cruelty_free_rounded;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final bg = _bgColors[widget.colorIndex % _bgColors.length];
    final images = widget.request.allImages;
    final startStr = widget.request.startDate != null
        ? _formatDate(widget.request.startDate!)
        : '';

    return GestureDetector(
      onTap: () => context.push('/sitting/detail', extra: widget.request),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo area (carousel if multiple images)
            Expanded(
              flex: 56,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: bg),
                    if (images.isEmpty)
                      Center(child: Icon(_fallbackIcon, size: 60,
                          color: Colors.white.withValues(alpha: 0.7)))
                    else if (images.length == 1)
                      CachedNetworkImage(
                        imageUrl: images.first,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(child: Icon(
                            _fallbackIcon, size: 52,
                            color: Colors.white.withValues(alpha: 0.6))),
                        errorWidget: (_, __, ___) => Center(child: Icon(
                            _fallbackIcon, size: 52,
                            color: Colors.white.withValues(alpha: 0.6))),
                      )
                    else ...[
                      PageView.builder(
                        controller: _pageCtrl,
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (_, i) => CachedNetworkImage(
                          imageUrl: images[i],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Center(child: Icon(
                              _fallbackIcon, size: 52,
                              color: Colors.white.withValues(alpha: 0.6))),
                          errorWidget: (_, __, ___) => Center(child: Icon(
                              _fallbackIcon, size: 52,
                              color: Colors.white.withValues(alpha: 0.6))),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (i) =>
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: i == _page ? 12 : 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: i == _page
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    // Status pill
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _isOpen ? purple : AppColors.textMuted,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isOpen ? 'פתוח' : 'הושלם',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info area
            Expanded(
              flex: 44,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      widget.request.petName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    // Type + gender pills
                    Row(
                      children: [
                        _MiniPill(label: _petTypeLabel, color: purple),
                        if (_genderLabel.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          _MiniPill(
                            label: _genderLabel,
                            color: widget.request.petGender == PetGender.female
                                ? AppColors.error
                                : AppColors.smartBlue,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Location
                    _InfoRow(icon: Icons.location_on_rounded, label: widget.request.area),
                    // Date
                    if (startStr.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _InfoRow(icon: Icons.calendar_today_rounded, label: startStr),
                    ],
                    const Spacer(),
                    // Button — always pinned to bottom
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [purple, AppColors.blueSlate],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('הצג פרטים',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _SittingServicesView extends ConsumerStatefulWidget {
  const _SittingServicesView({super.key});

  @override
  ConsumerState<_SittingServicesView> createState() =>
      _SittingServicesViewState();
}

class _SittingServicesViewState extends ConsumerState<_SittingServicesView> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'הכל';

  static const _filters = ['הכל', 'כלב', 'חתול', 'אחר'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(sittingServicesProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: _SearchBar(
            controller: _searchCtrl,
            hint: 'חפש/י ספק שמירה...',
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),

        // Filter chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _FilterChip(
              label: _filters[i],
              selected: _filter == _filters[i],
              onTap: () => setState(() => _filter = _filters[i]),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: servicesAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.sitting)),
            error: (e, _) => Center(child: Text('שגיאה: $e')),
            data: (all) {
              final services = all.where((s) {
                final matchFilter =
                    _filter == 'הכל' || s.petTypes.contains(_filter);
                final matchQuery = _query.isEmpty ||
                    s.providerName.toLowerCase().contains(_query) ||
                    s.area.toLowerCase().contains(_query);
                return matchFilter && matchQuery;
              }).toList();

              if (services.isEmpty) {
                return const Center(
                  child: EmptyStateWidget(
                    title: 'אין שירותי שמירה',
                    subtitle: 'נסה/י לשנות את הסינון',
                    icon: Icons.home_work_rounded,
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.58,
                ),
                itemCount: services.length,
                itemBuilder: (_, i) =>
                    _SittingServiceCard(service: services[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SittingServiceCard extends ConsumerWidget {
  final SittingService service;
  const _SittingServiceCard({required this.service});

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SittingServiceDetailSheet(service: service, ref: ref),
    );
  }

  Future<void> _startChat(BuildContext context, WidgetRef ref) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final myProfile = ref.read(currentUserProfileProvider).asData?.value;
    final myPhotoUrl = myProfile?.photoUrl ?? me.photoURL ?? '';
    final providerPhotoUrl = service.providerPhotoUrl ?? '';
    final ds = MessagingDatasource(db: FirebaseFirestore.instance);
    final convoId = await ds.getOrCreateConversation(
      myUid: me.uid,
      myName: me.displayName ?? me.email ?? 'משתמש',
      otherUid: service.providerUid,
      otherName: service.providerName,
      myPhotoUrl: myPhotoUrl,
      otherPhotoUrl: providerPhotoUrl,
    );
    if (context.mounted) {
      context.push('/chat/$convoId', extra: {
        'otherName': service.providerName,
        'otherPhotoUrl': providerPhotoUrl,
        'otherUid': service.providerUid,
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const accent = AppColors.primary;
    final displayPrice = formatPrice(service.priceText, service.priceType);

    return GestureDetector(
      onTap: () => _showDetail(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Photo / avatar area ──────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Full-cover photo, gradient fallback
                    if (service.providerPhotoUrl != null &&
                        service.providerPhotoUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: service.providerPhotoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.surface, AppColors.twilightIndigo],
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.surface, AppColors.twilightIndigo],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.home_work_rounded,
                                size: 48, color: AppColors.twilightIndigo),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.surface, AppColors.twilightIndigo],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.home_work_rounded,
                              size: 48, color: AppColors.twilightIndigo),
                        ),
                      ),
                    if (service.isActive)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.statusOpen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'זמין',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // ── Info area ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    service.providerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (service.rating != null)
                    _RatingRow(
                        rating: service.rating!,
                        reviewCount: service.reviewCount)
                  else if (service.createdAt != null)
                    Text(
                      _timeAgo(service.createdAt!),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted),
                    ),
                  const SizedBox(height: 4),
                  const Text(
                    'שמירה',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    displayPrice,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniChip(
                          icon: Icons.location_on_rounded,
                          label: service.area,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _MiniChip(
                          icon: Icons.home_work_rounded,
                          label: service.sittingLocation,
                          color: AppColors.smartBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _startChat(context, ref),
                    child: SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.blueSlate],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  color: Colors.white, size: 13),
                              SizedBox(width: 5),
                              Text('צור קשר',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Walk Service Card
// ═══════════════════════════════════════════════════════════════════════════

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return 'לפני פחות משעה';
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return 'לפני ${h == 1 ? 'שעה' : '$h שעות'}';
  }
  final d = diff.inDays;
  if (d == 1) return 'לפני יום';
  if (d < 30) return 'לפני $d ימים';
  final m = (d / 30).floor();
  if (m == 1) return 'לפני חודש';
  if (m < 12) return 'לפני $m חודשים';
  final y = (d / 365).floor();
  return 'לפני ${y == 1 ? 'שנה' : '$y שנים'}';
}

class _WalkServiceCard extends ConsumerWidget {
  final WalkService service;
  const _WalkServiceCard({required this.service});

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalkServiceDetailSheet(service: service, ref: ref),
    );
  }

  Future<void> _startChat(BuildContext context, WidgetRef ref) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final myProfile = ref.read(currentUserProfileProvider).asData?.value;
    final myPhotoUrl = myProfile?.photoUrl ?? me.photoURL ?? '';
    final providerPhotoUrl = service.providerPhotoUrl ?? '';
    final ds = MessagingDatasource(db: FirebaseFirestore.instance);
    final convoId = await ds.getOrCreateConversation(
      myUid: me.uid,
      myName: me.displayName ?? me.email ?? 'משתמש',
      otherUid: service.providerUid,
      otherName: service.providerName,
      myPhotoUrl: myPhotoUrl,
      otherPhotoUrl: providerPhotoUrl,
    );
    if (context.mounted) {
      context.push('/chat/$convoId', extra: {
        'otherName': service.providerName,
        'otherPhotoUrl': providerPhotoUrl,
        'otherUid': service.providerUid,
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayPrice = formatPrice(service.priceText, service.priceType);

    return GestureDetector(
      onTap: () => _showDetail(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Photo / avatar area ──────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (service.providerPhotoUrl != null &&
                        service.providerPhotoUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: service.providerPhotoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFCCFBF1), Color(0xFF99F6E4)],
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFCCFBF1), Color(0xFF99F6E4)],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.directions_walk_rounded,
                                size: 48, color: Color(0xFF99F6E4)),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFCCFBF1), Color(0xFF99F6E4)],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.directions_walk_rounded,
                              size: 48, color: Color(0xFF99F6E4)),
                        ),
                      ),
                    if (service.isActive)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.statusOpen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'זמין',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // ── Info area ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    service.providerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (service.rating != null)
                    _RatingRow(
                        rating: service.rating!,
                        reviewCount: service.reviewCount)
                  else if (service.createdAt != null)
                    Text(
                      _timeAgo(service.createdAt!),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted),
                    ),
                  const SizedBox(height: 4),
                  const Text(
                    'טיול',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    displayPrice,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniChip(
                          icon: Icons.location_on_rounded,
                          label: service.area,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _MiniChip(
                          icon: Icons.timer_rounded,
                          label: service.duration,
                          color: AppColors.smartBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _startChat(context, ref),
                    child: SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.statusOpen],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  color: Colors.white, size: 13),
                              SizedBox(width: 5),
                              Text('צור קשר',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared reusable widgets ───────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  const _RatingRow({required this.rating, this.reviewCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 3),
          Text(
            '($reviewCount)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Sitting service detail sheet ─────────────────────────────────────────────

class _SittingServiceDetailSheet extends ConsumerStatefulWidget {
  final SittingService service;
  final WidgetRef ref;
  const _SittingServiceDetailSheet(
      {required this.service, required this.ref});
  @override
  ConsumerState<_SittingServiceDetailSheet> createState() =>
      _SittingServiceDetailSheetState();
}

class _SittingServiceDetailSheetState
    extends ConsumerState<_SittingServiceDetailSheet> {
  bool _loading = false;

  Future<void> _startChat() async {
    setState(() => _loading = true);
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final myProfile = ref.read(currentUserProfileProvider).asData?.value;
    final myPhotoUrl = myProfile?.photoUrl ?? me.photoURL ?? '';
    final providerPhotoUrl = widget.service.providerPhotoUrl ?? '';
    final ds = MessagingDatasource(db: FirebaseFirestore.instance);
    final convoId = await ds.getOrCreateConversation(
      myUid: me.uid,
      myName: me.displayName ?? me.email ?? 'משתמש',
      otherUid: widget.service.providerUid,
      otherName: widget.service.providerName,
      myPhotoUrl: myPhotoUrl,
      otherPhotoUrl: providerPhotoUrl,
    );
    if (mounted) {
      Navigator.pop(context);
      context.push('/chat/$convoId', extra: {
        'otherName': widget.service.providerName,
        'otherPhotoUrl': providerPhotoUrl,
        'otherUid': widget.service.providerUid,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.primary;
    final s = widget.service;
    final displayPrice = formatPrice(s.priceText, s.priceType);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 18),
                // Avatar + name + active badge
                Row(
                  children: [
                    LiveUserAvatar(
                      uid: s.providerUid,
                      fallbackName: s.providerName,
                      fallbackPhotoUrl: s.providerPhotoUrl,
                      size: 56,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.providerName,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text('שירות שמירה',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    if (s.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.statusOpen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('זמין',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Price
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 18,
                          color: accent),
                      const SizedBox(width: 8),
                      const Text('מחיר:  ',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: accent)),
                      Text(displayPrice,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: accent)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Info rows
                _DetailInfoRow(
                    icon: Icons.location_on_rounded,
                    label: 'אזור',
                    value: s.area,
                    color: AppColors.error),
                _DetailInfoRow(
                    icon: Icons.home_work_rounded,
                    label: 'מיקום השמירה',
                    value: s.sittingLocation,
                    color: AppColors.smartBlue),
                if (s.petTypes.isNotEmpty)
                  _DetailInfoRow(
                      icon: Icons.pets_rounded,
                      label: 'סוגי חיות',
                      value: s.petTypes.join(', '),
                      color: AppColors.success),
                if (s.availableDays.isNotEmpty)
                  _DetailInfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'ימים זמינים',
                      value: s.availableDays.join(', '),
                      color: AppColors.regalNavy),
                if (s.rating != null)
                  _DetailInfoRow(
                      icon: Icons.star_rounded,
                      label: 'דירוג',
                      value:
                          '${s.rating!.toStringAsFixed(1)}  (${s.reviewCount ?? 0} ביקורות)',
                      color: AppColors.warning),
                // Bio
                if (s.bio != null && s.bio!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: AppColors.warning),
                          SizedBox(width: 6),
                          Text('אודות',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.warning)),
                        ]),
                        const SizedBox(height: 8),
                        Text(s.bio!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.6)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _loading ? null : _startChat,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.blueSlate]),
                            boxShadow: [
                              BoxShadow(
                                  color: accent.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5))
                            ],
                          ),
                          child: Center(
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.chat_bubble_outline_rounded,
                                          color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text('צור קשר',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/bookings/create', extra: {
                            'providerUid': widget.service.providerUid,
                            'providerName': widget.service.providerName,
                            'providerPhotoUrl': widget.service.providerPhotoUrl,
                            'serviceId': widget.service.id,
                            'serviceType': 'sitting',
                            'priceText': widget.service.priceText,
                          });
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5))
                            ],
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_month_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('הזמן עכשיו',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Walk service detail sheet ─────────────────────────────────────────────────

class _WalkServiceDetailSheet extends ConsumerStatefulWidget {
  final WalkService service;
  final WidgetRef ref;
  const _WalkServiceDetailSheet(
      {required this.service, required this.ref});
  @override
  ConsumerState<_WalkServiceDetailSheet> createState() =>
      _WalkServiceDetailSheetState();
}

class _WalkServiceDetailSheetState
    extends ConsumerState<_WalkServiceDetailSheet> {
  bool _loading = false;

  Future<void> _startChat() async {
    setState(() => _loading = true);
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final myProfile = ref.read(currentUserProfileProvider).asData?.value;
    final myPhotoUrl = myProfile?.photoUrl ?? me.photoURL ?? '';
    final providerPhotoUrl = widget.service.providerPhotoUrl ?? '';
    final ds = MessagingDatasource(db: FirebaseFirestore.instance);
    final convoId = await ds.getOrCreateConversation(
      myUid: me.uid,
      myName: me.displayName ?? me.email ?? 'משתמש',
      otherUid: widget.service.providerUid,
      otherName: widget.service.providerName,
      myPhotoUrl: myPhotoUrl,
      otherPhotoUrl: providerPhotoUrl,
    );
    if (mounted) {
      Navigator.pop(context);
      context.push('/chat/$convoId', extra: {
        'otherName': widget.service.providerName,
        'otherPhotoUrl': providerPhotoUrl,
        'otherUid': widget.service.providerUid,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final displayPrice = formatPrice(s.priceText, s.priceType);
    const accent = AppColors.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    LiveUserAvatar(
                      uid: s.providerUid,
                      fallbackName: s.providerName,
                      fallbackPhotoUrl: s.providerPhotoUrl,
                      size: 56,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.providerName,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          const Text('שירות טיולים',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    if (s.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.statusOpen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('זמין',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 18,
                          color: accent),
                      const SizedBox(width: 8),
                      const Text('מחיר:  ',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: accent)),
                      Text(displayPrice,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: accent)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _DetailInfoRow(
                    icon: Icons.location_on_rounded,
                    label: 'אזור',
                    value: s.area,
                    color: AppColors.error),
                _DetailInfoRow(
                    icon: Icons.timer_rounded,
                    label: 'משך הטיול',
                    value: s.duration,
                    color: accent),
                if (s.petTypes.isNotEmpty)
                  _DetailInfoRow(
                      icon: Icons.pets_rounded,
                      label: 'סוגי חיות',
                      value: s.petTypes.join(', '),
                      color: AppColors.success),
                if (s.availableDays.isNotEmpty)
                  _DetailInfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'ימים זמינים',
                      value: s.availableDays.join(', '),
                      color: AppColors.regalNavy),
                if (s.rating != null)
                  _DetailInfoRow(
                      icon: Icons.star_rounded,
                      label: 'דירוג',
                      value:
                          '${s.rating!.toStringAsFixed(1)}  (${s.reviewCount ?? 0} ביקורות)',
                      color: AppColors.warning),
                if (s.bio != null && s.bio!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: AppColors.warning),
                          SizedBox(width: 6),
                          Text('אודות',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.warning)),
                        ]),
                        const SizedBox(height: 8),
                        Text(s.bio!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.6)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _loading ? null : _startChat,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.statusOpen]),
                            boxShadow: [
                              BoxShadow(
                                  color: accent.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5))
                            ],
                          ),
                          child: Center(
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.chat_bubble_outline_rounded,
                                          color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text('צור קשר',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/bookings/create', extra: {
                            'providerUid': widget.service.providerUid,
                            'providerName': widget.service.providerName,
                            'providerPhotoUrl': widget.service.providerPhotoUrl,
                            'serviceId': widget.service.id,
                            'serviceType': 'walk',
                            'priceText': widget.service.priceText,
                          });
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5))
                            ],
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_month_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('הזמן עכשיו',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Detail info row (used in service detail sheets) ───────────────────────────

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.65))),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
      );
}

// ── Mini chip (compact, for grid cards) ──────────────────────────────────────

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.fullRadius,
        boxShadow: AppShadows.subtle,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.caption,
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textMuted, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          isDense: true,
        ),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceCard,
          borderRadius: AppRadius.fullRadius,
          boxShadow: selected ? null : AppShadows.subtle,
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Chat Tab ──────────────────────────────────────────────────────────────────

class _ChatTab extends ConsumerWidget {
  const _ChatTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid =
        ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
    final async = ref.watch(conversationsProvider);

    return SafeArea(
      bottom: false,
      child: async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (convos) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
        children: [
          const SectionHeader(
            title: 'צ׳אט',
            subtitle: 'שיחות עם נותני שירות',
          ),
          const SizedBox(height: 10),
          if (convos.isEmpty)
            const EmptyStateCard(
              title: 'אין שיחות עדיין',
              subtitle: 'שיחות יופיעו כאן לאחר פנייה לנותן שירות.',
              icon: Icons.chat_bubble_outline_rounded,
            )
          else
            ...convos.map((c) {
              final names =
                  Map<String, String>.from(c['participantNames'] ?? {});
              final photoUrls =
                  Map<String, String>.from(c['participantPhotoUrls'] ?? {});
              final otherEntry = names.entries.firstWhere(
                (e) => e.key != myUid,
                orElse: () => const MapEntry('', 'לא ידוע'),
              );
              final otherName = otherEntry.value;
              final otherPhotoUrl = photoUrls[otherEntry.key] ?? '';
              final lastMsg = c['lastMessage'] as String? ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () => context.push(
                    '/chat/${c['id']}',
                    extra: {'otherName': otherName, 'otherPhotoUrl': otherPhotoUrl, 'otherUid': otherEntry.key},
                  ),
                  child: Row(
                    children: [
                      LiveUserAvatar(
                        uid: otherEntry.key,
                        fallbackName: otherName,
                        fallbackPhotoUrl: otherPhotoUrl.isNotEmpty ? otherPhotoUrl : null,
                        size: 48,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(otherName, style: AppTextStyles.bodyBold),
                            const SizedBox(height: 2),
                            Text(
                              lastMsg.isEmpty ? 'התחל שיחה...' : lastMsg,
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    ),
    );
  }
}

// ── My Bookings inline view (embedded in _MyRequestsTab) ─────────────────────

class _MyBookingsView extends ConsumerWidget {
  const _MyBookingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('אין הזמנות עדיין',
                    style: AppTextStyles.headlineSm
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('גלוש לשירותים ושלח בקשת הזמנה',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _BookingTile(booking: bookings[i]),
        );
      },
    );
  }
}

class _BookingTile extends StatelessWidget {
  final BookingRequest booking;
  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    final isWalk = booking.serviceType == BookingServiceType.walk;
    final (label, color) = switch (booking.status) {
      BookingStatus.pending => ('ממתין', AppColors.warning),
      BookingStatus.accepted => ('אושר', AppColors.success),
      BookingStatus.declined => ('נדחה', AppColors.error),
      BookingStatus.cancelled => ('בוטל', AppColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryFaint,
            backgroundImage: (booking.providerPhotoUrl?.isNotEmpty == true)
                ? NetworkImage(booking.providerPhotoUrl!)
                : null,
            child: (booking.providerPhotoUrl?.isNotEmpty != true)
                ? Text(
                    booking.providerName.isNotEmpty
                        ? booking.providerName.characters.first.toUpperCase()
                        : '?',
                    style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.providerName,
                    style: AppTextStyles.bodyMd
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(
                  '${isWalk ? 'טיולים' : 'שמירה'} • ${booking.petName}',
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(label,
                style: AppTextStyles.labelMd
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
