import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/core/widgets/app_bottom_nav.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/section_header.dart';
import 'package:petpal/core/widgets/discovery_chip.dart';
import 'package:petpal/features/home/presentation/widgets/home_top_rated_section.dart';
import 'package:petpal/features/explore/domain/entities/poi_model.dart';
import 'package:petpal/features/sitting/presentation/providers/marketplace_provider.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';
import 'package:petpal/features/lost_and_found/presentation/screens/lost_found_feed_screen.dart';
import 'package:petpal/features/profile/presentation/screens/bookings_screen.dart';
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
import 'package:petpal/features/community/presentation/screens/community_feed_screen.dart';
import 'package:petpal/core/widgets/luxury_hero.dart';
import 'package:petpal/core/widgets/glass_search_bar.dart';
import 'package:petpal/core/widgets/luxury_service_card.dart';
import 'package:petpal/features/profile/presentation/screens/profile_screen.dart';

import 'package:petpal/features/explore/presentation/screens/explore_screen.dart';
import 'package:petpal/features/explore/presentation/providers/poi_provider.dart';
import 'package:petpal/features/explore/presentation/widgets/poi_card.dart';
import 'package:petpal/core/providers/navigation_provider.dart';

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
  // Mock cards (later replace with Firestore)
  User? get _user => FirebaseAuth.instance.currentUser;

  String get _displayName {
    final u = _user;
    final dn = (u?.displayName ?? '').trim();
    if (dn.isNotEmpty) return dn;

    final email = (u?.email ?? '').trim();
    if (email.contains('@')) return email.split('@').first;

    return 'משתמש';
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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    context.go('/');
  }

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text(
            'להתנתק מהחשבון?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text('תוכל/י להתחבר שוב בכל זמן.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('התנתקות',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(homeTabIndexProvider);

    final tabs = <Widget>[
      _HomeTab(
        onAction: (msg) => _toast(msg),
        onTabChange: (index) =>
            ref.read(homeTabIndexProvider.notifier).setIndex(index),
      ),
      const ExploreScreen(),
      const LostFoundFeedScreen(),
      const BookingsScreen(), // Unified redesigned Bookings
      const CommunityFeedScreen(),
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
            key: ValueKey(currentIndex),
            child: tabs[currentIndex],
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: currentIndex,
          onChanged: (i) => ref.read(homeTabIndexProvider.notifier).setIndex(i),
          items: const [
            AppNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'בית',
            ),
            AppNavItem(
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore_rounded,
              label: 'גלה',
            ),
            AppNavItem(
              icon: Icons.pets_outlined,
              activeIcon: Icons.pets_rounded,
              label: 'אבודים',
            ),
            AppNavItem(
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_today_rounded,
              label: 'הזמנות',
            ),
            AppNavItem(
              icon: Icons.diversity_3_outlined,
              activeIcon: Icons.diversity_3_rounded,
              label: 'קהילה',
            ),
            AppNavItem(
              icon: Icons.chat_bubble_outline_rounded,
              activeIcon: Icons.chat_bubble_rounded,
              label: 'צ׳אט',
            ),
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
    // Show sticky search when scrolled past hero (approx 460px)
    if (_scrollController.offset > 460 && !_showStickySearch) {
      setState(() => _showStickySearch = true);
    } else if (_scrollController.offset <= 460 && _showStickySearch) {
      setState(() => _showStickySearch = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(sittingRequestsProvider);
    final sittersAsync = ref.watch(filteredSittingServicesProvider);
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
              searchBar: const GlassSearchBar(),
              onProfileTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),

            // 2. Category Chips
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
                          onTap: () => context.push('/sitting/marketplace')),
                      const SizedBox(width: 12),
                      DiscoveryChip(
                          label: 'גינות כלבים',
                          icon: Icons.park_rounded,
                          onTap: () {
                            ref.read(exploreTabIndexProvider.notifier).state =
                                1;
                            widget.onTabChange(1);
                          }),
                      const SizedBox(width: 12),
                      DiscoveryChip(
                          label: 'וטרינרים',
                          icon: Icons.medical_services_rounded,
                          onTap: () {
                            ref.read(exploreTabIndexProvider.notifier).state =
                                2;
                            widget.onTabChange(1);
                          }),
                      const SizedBox(width: 12),
                      DiscoveryChip(
                          label: 'חנויות חיות',
                          icon: Icons.shopping_bag_rounded,
                          onTap: () {
                            ref.read(exploreTabIndexProvider.notifier).state =
                                3;
                            widget.onTabChange(1);
                          }),
                    ],
                  ),
                ),
              ),
            ),

            // 3. My Requests Section (Priority — first)
            SliverToBoxAdapter(
              child: requestsAsync.when(
                data: (requests) => HomeTopRatedSection(
                  title: 'הבקשות שלי',
                  itemHeight: 240,
                  onMoreTap: () {
                    ref.read(exploreTabIndexProvider.notifier).state = 4;
                    widget.onTabChange(1);
                  },
                  itemCount: requests.take(10).length,
                  emptyState: const EmptyStateWidget(
                    title: 'אין בקשות פעילות',
                    subtitle: 'הבקשות שלך יופיעו כאן',
                    icon: Icons.inbox_rounded,
                  ),
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return Container(
                      width: 280, // Match Luxury width
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: AppRadius.organicRadius,
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.premium,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.push('/sitting/request/${req.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Icon Area
                            SizedBox(
                              height: 100, // Slightly taller for picture
                              width: double.infinity,
                              child: CachedNetworkImage(
                                imageUrl:
                                    'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&q=80&w=800',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  child: const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.pets_rounded,
                                          color: AppColors.primary, size: 24),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          req.petName,
                                          style: AppTextStyles.headlineSm,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(req.status)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _getStatusLabel(req.status),
                                          style: AppTextStyles.labelSm.copyWith(
                                            color: _getStatusColor(req.status),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    req.area ?? 'לא צוין מיקום',
                                    style: AppTextStyles.labelMd
                                        .copyWith(color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          size: 14, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        'בקשה פתוחה',
                                        style: AppTextStyles.labelSm,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const SizedBox(
                  height: 140,
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // 4. Sitters Section (Live Firestore data)
            SliverToBoxAdapter(
              child: sittersAsync.when(
                data: (sitters) {
                  final top10 = (sitters.toList()
                        ..sort(
                            (a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0)))
                      .take(10)
                      .toList();
                  return HomeTopRatedSection(
                    title: 'שומרים',
                    itemHeight: 360,
                    onMoreTap: () {
                      ref.read(exploreTabIndexProvider.notifier).state = 0;
                      widget.onTabChange(1);
                    },
                    itemCount: top10.length,
                    emptyState: const EmptyStateWidget(
                      title: 'אין שומרים זמינים',
                      subtitle: 'שומרים חדשים יתווספו בקרוב',
                      icon: Icons.person_search_rounded,
                    ),
                    itemBuilder: (context, index) {
                      final sitter = top10[index];
                      return LuxuryServiceCard(
                        title: sitter.providerName,
                        serviceType: sitter.petTypes.join(' • '),
                        price: '₪${sitter.priceText}',
                        rating: (sitter.rating ?? 0).toStringAsFixed(1),
                        location: sitter.area ?? '',
                        imageUrl: sitter.providerPhotoUrl ?? '',
                        onTap: () =>
                            context.push('/sitting/detail/${sitter.id}'),
                      );
                    },
                  );
                },
                loading: () => const SizedBox(
                  height: 360,
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // 5. Dog Parks Section
            SliverToBoxAdapter(
              child: parksAsync.when(
                data: (parks) => HomeTopRatedSection(
                  title: 'גינות כלבים',
                  itemHeight: 300,
                  onMoreTap: () {
                    ref.read(exploreTabIndexProvider.notifier).state = 1;
                    ref.read(homeTabIndexProvider.notifier).setIndex(1);
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
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // 6. Vets Section
            SliverToBoxAdapter(
              child: vetsAsync.when(
                data: (vets) => HomeTopRatedSection(
                  title: 'וטרינרים',
                  itemHeight: 300,
                  onMoreTap: () {
                    ref.read(exploreTabIndexProvider.notifier).state = 2;
                    ref.read(homeTabIndexProvider.notifier).setIndex(1);
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
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // 7. Stores Section
            SliverToBoxAdapter(
              child: storesAsync.when(
                data: (stores) => HomeTopRatedSection(
                  title: 'חנויות',
                  itemHeight: 300,
                  onMoreTap: () {
                    ref.read(exploreTabIndexProvider.notifier).state = 3;
                    ref.read(homeTabIndexProvider.notifier).setIndex(1);
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
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
              child: const GlassSearchBar(),
            ),
          ),
      ],
    );
  }

  Color _getStatusColor(SittingStatus status) {
    switch (status) {
      case SittingStatus.open:
        return const Color(0xFFFF9800);
      case SittingStatus.taken:
        return const Color(0xFF4CAF50);
      case SittingStatus.declined:
        return const Color(0xFFFF4B4B);
      case SittingStatus.closed:
        return AppColors.primary;
    }
  }

  String _getStatusLabel(SittingStatus status) {
    switch (status) {
      case SittingStatus.open:
        return 'ממתין';
      case SittingStatus.taken:
        return 'אושר';
      case SittingStatus.declined:
        return 'נדחה';
      case SittingStatus.closed:
        return 'הושלם';
    }
  }
}

class _FeedPostCard extends StatelessWidget {
  final FeedPost post;
  final String currentUid;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const _FeedPostCard({
    required this.post,
    required this.currentUid,
    required this.onTap,
    required this.onLike,
  });

  String get _timeAgo {
    if (post.createdAt == null) return '';
    final diff = DateTime.now().difference(post.createdAt!);
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק׳';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
    if (diff.inDays < 7) return 'לפני ${diff.inDays} ימים';
    return '${post.createdAt!.day}/${post.createdAt!.month}/${post.createdAt!.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = post.isLikedBy(currentUid);
    final isTip = post.type == PostType.tip;

    return InkWell(
      borderRadius: AppRadius.xxlRadius,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.xxlRadius,
          boxShadow: AppShadows.premium,
          border: Border.all(color: AppColors.borderFaint),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                LiveUserAvatar(
                  uid: post.authorUid,
                  fallbackName: post.authorName,
                  fallbackPhotoUrl: post.authorPhotoUrl,
                  size: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: AppTextStyles.h3.copyWith(fontSize: 15),
                      ),
                      Text(
                        _timeAgo,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isTip)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.feed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded,
                            size: 14, color: AppColors.feed),
                        const SizedBox(width: 4),
                        Text(
                          'טיפ',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.feed,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Content
            Text(
              post.content,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),

            // Optional image
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: AppRadius.xlRadius,
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 220,
                    color: AppColors.borderFaint,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 220,
                    color: AppColors.borderFaint,
                    child: const Icon(Icons.broken_image_rounded,
                        color: AppColors.textMuted),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Actions row
            Row(
              children: [
                _PostAction(
                  icon: isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: '${post.likes.length}',
                  color: isLiked ? AppColors.danger : AppColors.textSecondary,
                  onTap: onLike,
                ),
                const SizedBox(width: 16),
                _PostAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${post.commentCount}',
                  color: AppColors.textSecondary,
                  onTap: onTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveCareTracker extends StatelessWidget {
  final String petName;
  final String providerName;
  final String status;
  final String startTime;

  const _ActiveCareTracker({
    required this.petName,
    required this.providerName,
    required this.status,
    required this.startTime,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GlassCard(
        blur: 20,
        opacity: 0.9,
        padding: const EdgeInsets.all(16),
        borderRadius: AppRadius.xxlRadius,
        boxShadow: AppShadows.premium,
        color: AppColors.successLight,
        border: Border.all(
            color: AppColors.success.withValues(alpha: 0.1), width: 2),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.pets_rounded,
                        size: 28, color: AppColors.success),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        status,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const _PulseDot(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$petName נהנה מזמן איכות עם $providerName',
                    style: AppTextStyles.bodyBold.copyWith(height: 1.2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppShadows.subtle,
              ),
              child: const Icon(
                Icons.map_rounded,
                color: AppColors.success,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PostAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodyBold.copyWith(
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    return Column(
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
                ? const _WalkRequestsView(key: ValueKey('requests'))
                : const _WalkServicesView(key: ValueKey('services')),
          ),
        ),
      ],
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
        // Create request button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: AppButton(
            label: 'בקשת טיול חדשה',
            leadingIcon: Icons.add_rounded,
            onTap: () => context.push('/walks/create'),
          ),
        ),

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
                          color: AppColors.textSecondary.withOpacity(0.5)),
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
class _WalkRequestCard extends StatelessWidget {
  final WalkRequest request;
  final int colorIndex;
  const _WalkRequestCard({required this.request, required this.colorIndex});

  static const _bgColors = [
    Color(0xFFFFB347),
    Color(0xFF80DEEA),
    Color(0xFFCE93D8),
    Color(0xFFF48FB1),
    Color(0xFF90CAF9),
    Color(0xFFA5D6A7),
    Color(0xFFFFCC80),
    Color(0xFFEF9A9A),
  ];

  bool get _isOpen => request.status == WalkStatus.open;

  String get _petTypeLabel {
    switch (request.petType) {
      case PetType.dog:
        return 'כלב';
      case PetType.cat:
        return 'חתול';
      case PetType.other:
        return 'אחר';
    }
  }

  String get _genderLabel {
    if (request.petGender == PetGender.male) return 'זכר';
    if (request.petGender == PetGender.female) return 'נקבה';
    return '';
  }

  IconData get _fallbackIcon {
    switch (request.petType) {
      case PetType.dog:
        return Icons.directions_walk_rounded;
      case PetType.cat:
        return Icons.pets_rounded;
      case PetType.other:
        return Icons.cruelty_free_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bgColors[colorIndex % _bgColors.length];
    final hasPetPhoto =
        request.petImageUrl != null && request.petImageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => context.push('/walks/detail', extra: request),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo area
            Expanded(
              flex: 56,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: bg),
                    if (hasPetPhoto)
                      CachedNetworkImage(
                        imageUrl: request.petImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(
                            child: Icon(_fallbackIcon,
                                size: 52,
                                color: Colors.white.withOpacity(0.6))),
                        errorWidget: (_, __, ___) => Center(
                            child: Icon(_fallbackIcon,
                                size: 52,
                                color: Colors.white.withOpacity(0.6))),
                      )
                    else
                      Center(
                          child: Icon(_fallbackIcon,
                              size: 60, color: Colors.white.withOpacity(0.7))),
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
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.petName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 1),
                    Text(_petTypeLabel,
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: [
                        if (_genderLabel.isNotEmpty)
                          _OwnerChip(
                            icon: Icons.transgender_rounded,
                            label: _genderLabel,
                            color: request.petGender == PetGender.female
                                ? const Color(0xFFEC4899)
                                : const Color(0xFF0EA5E9),
                          ),
                        _OwnerChip(
                          icon: Icons.location_on_rounded,
                          label: request.area,
                          color: const Color(0xFFEF4444),
                        ),
                        if (request.preferredTime.isNotEmpty)
                          _OwnerChip(
                            icon: Icons.access_time_rounded,
                            label: request.preferredTime,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
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

// ── Icon chip used in owner request cards ────────────────────────────────────
class _OwnerChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _OwnerChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
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
                      fontSize: 10, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
        ),
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
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.58,
                ),
                itemCount: services.length,
                itemBuilder: (_, i) => _WalkServiceCard(service: services[i]),
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
    return Column(
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
                ? const _SittingRequestsView(key: ValueKey('sitting_requests'))
                : const _SittingServicesView(
                    key: ValueKey('sitting_services'),
                  ),
          ),
        ),
      ],
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
        // Create request button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: AppButton(
            label: 'בקשת שמירה חדשה',
            leadingIcon: Icons.add_rounded,
            onTap: () => context.push('/sitting/create'),
          ),
        ),

        // Requests list
        Expanded(
          child: requestsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
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
                          color: AppColors.textSecondary.withOpacity(0.5)),
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
                            size: 16, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 6),
                        Text(
                          'הבקשות שלי (${requests.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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

class _SittingRequestCard extends StatelessWidget {
  final SittingRequest request;
  final int colorIndex;
  const _SittingRequestCard({required this.request, required this.colorIndex});

  static const _bgColors = [
    Color(0xFFCE93D8),
    Color(0xFF80DEEA),
    Color(0xFFFFB347),
    Color(0xFFF48FB1),
    Color(0xFF90CAF9),
    Color(0xFFA5D6A7),
    Color(0xFFFFCC80),
    Color(0xFFEF9A9A),
  ];

  bool get _isOpen => request.status == SittingStatus.open;

  String get _petTypeLabel {
    switch (request.petType) {
      case PetType.dog:
        return 'כלב';
      case PetType.cat:
        return 'חתול';
      case PetType.other:
        return 'אחר';
    }
  }

  String get _genderLabel {
    if (request.petGender == PetGender.male) return 'זכר';
    if (request.petGender == PetGender.female) return 'נקבה';
    return '';
  }

  IconData get _fallbackIcon {
    switch (request.petType) {
      case PetType.dog:
        return Icons.directions_walk_rounded;
      case PetType.cat:
        return Icons.pets_rounded;
      case PetType.other:
        return Icons.cruelty_free_rounded;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final bg = _bgColors[colorIndex % _bgColors.length];
    final hasPetPhoto =
        request.petImageUrl != null && request.petImageUrl!.isNotEmpty;
    final startStr =
        request.startDate != null ? _formatDate(request.startDate!) : '';
    const purple = Color(0xFF7C3AED);

    return GestureDetector(
      onTap: () => context.push('/sitting/detail', extra: request),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo area
            Expanded(
              flex: 56,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: bg),
                    if (hasPetPhoto)
                      CachedNetworkImage(
                        imageUrl: request.petImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(
                            child: Icon(_fallbackIcon,
                                size: 52,
                                color: Colors.white.withOpacity(0.6))),
                        errorWidget: (_, __, ___) => Center(
                            child: Icon(_fallbackIcon,
                                size: 52,
                                color: Colors.white.withOpacity(0.6))),
                      )
                    else
                      Center(
                          child: Icon(_fallbackIcon,
                              size: 60, color: Colors.white.withOpacity(0.7))),
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
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.petName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 1),
                    Text(_petTypeLabel,
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: [
                        if (_genderLabel.isNotEmpty)
                          _OwnerChip(
                            icon: Icons.transgender_rounded,
                            label: _genderLabel,
                            color: request.petGender == PetGender.female
                                ? const Color(0xFFEC4899)
                                : const Color(0xFF0EA5E9),
                          ),
                        _OwnerChip(
                          icon: Icons.location_on_rounded,
                          label: request.area,
                          color: const Color(0xFFEF4444),
                        ),
                        if (startStr.isNotEmpty)
                          _OwnerChip(
                            icon: Icons.calendar_today_rounded,
                            label: startStr,
                            color: purple,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [purple, Color(0xFFA78BFA)],
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
    const accent = Color(0xFF7C3AED);
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
                              colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.home_work_rounded,
                                size: 48, color: Color(0xFFDDD6FE)),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.home_work_rounded,
                              size: 48, color: Color(0xFFDDD6FE)),
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
                          color: const Color(0xFF0EA5E9),
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
                            colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
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

class _PillIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _PillIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.borderFaint,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Center(
            child: Icon(Icons.logout_rounded, color: Color(0xFF334155)),
          ),
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
                          color: const Color(0xFF0EA5E9),
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
        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFBBF24)),
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
  const _SittingServiceDetailSheet({required this.service, required this.ref});
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
    const accent = Color(0xFF7C3AED);
    final s = widget.service;
    final displayPrice = formatPrice(s.priceText, s.priceType);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                          const Text('שירות שמירה',
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
                // Price
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          size: 18, color: accent),
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
                    color: const Color(0xFFEF4444)),
                _DetailInfoRow(
                    icon: Icons.home_work_rounded,
                    label: 'מיקום השמירה',
                    value: s.sittingLocation,
                    color: const Color(0xFF0EA5E9)),
                if (s.petTypes.isNotEmpty)
                  _DetailInfoRow(
                      icon: Icons.pets_rounded,
                      label: 'סוגי חיות',
                      value: s.petTypes.join(', '),
                      color: const Color(0xFF16A34A)),
                if (s.availableDays.isNotEmpty)
                  _DetailInfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'ימים זמינים',
                      value: s.availableDays.join(', '),
                      color: const Color(0xFF0891B2)),
                if (s.rating != null)
                  _DetailInfoRow(
                      icon: Icons.star_rounded,
                      label: 'דירוג',
                      value:
                          '${s.rating!.toStringAsFixed(1)}  (${s.reviewCount ?? 0} ביקורות)',
                      color: const Color(0xFFFBBF24)),
                // Bio
                if (s.bio != null && s.bio!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: Color(0xFFF97316)),
                          SizedBox(width: 6),
                          Text('אודות',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF97316))),
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
                // Chat button
                GestureDetector(
                  onTap: _loading ? null : _startChat,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)]),
                      boxShadow: [
                        BoxShadow(
                            color: accent.withOpacity(0.35),
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
                                  strokeWidth: 2, color: Colors.white))
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
  const _WalkServiceDetailSheet({required this.service, required this.ref});
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
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          size: 18, color: accent),
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
                    color: const Color(0xFFEF4444)),
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
                      color: const Color(0xFF16A34A)),
                if (s.availableDays.isNotEmpty)
                  _DetailInfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'ימים זמינים',
                      value: s.availableDays.join(', '),
                      color: const Color(0xFF0891B2)),
                if (s.rating != null)
                  _DetailInfoRow(
                      icon: Icons.star_rounded,
                      label: 'דירוג',
                      value:
                          '${s.rating!.toStringAsFixed(1)}  (${s.reviewCount ?? 0} ביקורות)',
                      color: const Color(0xFFFBBF24)),
                if (s.bio != null && s.bio!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: Color(0xFFF97316)),
                          SizedBox(width: 6),
                          Text('אודות',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF97316))),
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
                GestureDetector(
                  onTap: _loading ? null : _startChat,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.statusOpen]),
                      boxShadow: [
                        BoxShadow(
                            color: accent.withOpacity(0.35),
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
                                  strokeWidth: 2, color: Colors.white))
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
                    color: color.withOpacity(0.65))),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: color)),
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
        color: color.withOpacity(0.10),
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
    final myUid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
    final async = ref.watch(conversationsProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (convos) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
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
                    extra: {
                      'otherName': otherName,
                      'otherPhotoUrl': otherPhotoUrl,
                      'otherUid': otherEntry.key
                    },
                  ),
                  child: Row(
                    children: [
                      LiveUserAvatar(
                        uid: otherEntry.key,
                        fallbackName: otherName,
                        fallbackPhotoUrl:
                            otherPhotoUrl.isNotEmpty ? otherPhotoUrl : null,
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
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary),
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
    );
  }
}

class _FeaturedSittersSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sittersAsync = ref.watch(sittingServicesProvider);

    return sittersAsync.when(
      data: (sitters) {
        if (sitters.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.marginPage),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('שומרים מומלצים', style: AppTextStyles.headlineMd),
                  TextButton(
                    onPressed: () => context.push('/sitting/marketplace'),
                    child: const Text('ראה הכל'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 360,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginPage),
                itemCount: sitters.length,
                itemBuilder: (context, index) {
                  final s = sitters[index];
                  return Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: LuxuryServiceCard(
                      title: s.providerName,
                      serviceType: s.sittingLocation,
                      price: s.priceText,
                      rating: s.rating?.toString() ?? 'חדש',
                      location: s.area,
                      imageUrl: s.providerPhotoUrl ??
                          'https://images.unsplash.com/photo-1544568100-847a948585b9?q=80&w=1000',
                      onTap: () => context.push('/sitting/detail/${s.id}'),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
          height: 360, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
