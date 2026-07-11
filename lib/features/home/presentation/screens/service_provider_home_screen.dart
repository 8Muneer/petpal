import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/utils/price_formatter.dart';
import 'package:petpal/core/widgets/app_bottom_nav.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/pill_icon_button.dart';
import 'package:petpal/core/widgets/luxury_hero.dart';
import 'package:petpal/core/widgets/notification_bell_button.dart';
import 'package:petpal/core/widgets/profile_menu.dart';
import 'package:petpal/core/widgets/gradient_action_card.dart';
import 'package:petpal/core/widgets/empty_state_card.dart';
import 'package:petpal/core/widgets/inline_error_retry.dart';

import 'package:petpal/features/auth/domain/enums/user_role.dart';
import 'package:petpal/features/feed/presentation/screens/feed_screen.dart';
import 'package:petpal/features/explore/presentation/screens/explore_screen.dart';
import 'package:petpal/features/explore/presentation/providers/poi_provider.dart';
import 'package:petpal/features/explore/presentation/widgets/poi_card.dart';
import 'package:petpal/features/explore/domain/entities/poi_model.dart';
import 'package:petpal/features/lost_and_found/presentation/screens/lost_found_feed_screen.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';
import 'package:petpal/features/booking/presentation/providers/booking_provider.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';
import 'package:petpal/features/reviews/presentation/providers/review_provider.dart';

import 'package:petpal/features/home/presentation/widgets/home_top_rated_section.dart';
import 'package:petpal/features/home/presentation/widgets/provider_requests_tab.dart';
// Still needed for ListYourServiceCTA (the tab widget itself is no longer
// embedded here — "My Services" is a pushed route now).
import 'package:petpal/features/home/presentation/widgets/provider_services_tab.dart';

class ServiceProviderHomeScreen extends ConsumerStatefulWidget {
  const ServiceProviderHomeScreen({super.key});

  @override
  ConsumerState<ServiceProviderHomeScreen> createState() =>
      _ServiceProviderHomeScreenState();
}

class _ServiceProviderHomeScreenState
    extends ConsumerState<ServiceProviderHomeScreen> {
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

  void _onNavChanged(int i) {
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _ProviderHomeTab(
        onAction: (msg) => _toast(msg),
        onSelectTab: _onNavChanged,
      ),
      const FeedScreen(),
      const ExploreScreen(),
      const LostFoundFeedScreen(),
      const ProviderRequestsTab(),
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
            key: ValueKey('$_currentIndex'),
            child: tabs[_currentIndex],
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _currentIndex,
          onChanged: _onNavChanged,
          items: const [
            AppNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'בית'),
            AppNavItem(
                icon: Icons.feed_outlined,
                activeIcon: Icons.feed_rounded,
                label: 'קהילה'),
            AppNavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore_rounded,
                label: 'גלה'),
            AppNavItem(
                icon: Icons.pets_outlined,
                activeIcon: Icons.pets_rounded,
                label: 'אבודים'),
            AppNavItem(
                icon: Icons.assignment_outlined,
                activeIcon: Icons.assignment_rounded,
                label: 'הבקשות'),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// A horizontal card for an open marketplace request the provider can bid on.
///
/// Sized and styled to match [POICard] (width 280, 16:9 image, organic
/// radius) so this row and the dog-parks/vets/stores rows below it read as
/// one consistent card system instead of two different scales.
class _OpportunityCard extends StatelessWidget {
  final String petName;
  final String area;
  final String typeLabel;
  final IconData icon;
  final String? imageUrl;
  final String? dateLabel;
  final String? budget;
  final VoidCallback onTap;

  const _OpportunityCard({
    required this.petName,
    required this.area,
    required this.typeLabel,
    required this.icon,
    required this.onTap,
    this.imageUrl,
    this.dateLabel,
    this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.organicRadius,
          boxShadow: AppShadows.subtle,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.primary.withValues(alpha: 0.08),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            child:
                                Icon(icon, size: 32, color: AppColors.primary),
                          ),
                        )
                      : Container(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          child: Icon(icon, size: 32, color: AppColors.primary),
                        ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          typeLabel,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    petName,
                    style: AppTextStyles.headlineSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          area,
                          style: AppTextStyles.labelSm
                              .copyWith(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (dateLabel != null && dateLabel!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            dateLabel!,
                            style: AppTextStyles.labelSm
                                .copyWith(color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (budget != null && budget!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance_wallet_rounded,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            budget!,
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderHomeTab extends ConsumerWidget {
  final void Function(String msg) onAction;
  final void Function(int index) onSelectTab;

  const _ProviderHomeTab({required this.onAction, required this.onSelectTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).asData?.value;
    final displayName = profile?.name ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'נותן שירות';

    // Nearby points of interest — same insight cards shown on the pet-owner home.
    final parksAsync = ref.watch(topRatedPOIsProvider(type: POIType.park));
    final vetsAsync = ref.watch(topRatedPOIsProvider(type: POIType.vet));
    final storesAsync = ref.watch(topRatedPOIsProvider(type: POIType.store));

    // ── Real metrics derived from live data ──────────────────────────────────
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final incoming = ref.watch(incomingBookingsProvider).asData?.value ??
        const <BookingRequest>[];
    final pendingCount =
        incoming.where((b) => b.status == BookingStatus.pending).length;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final accepted = incoming
        .where((b) =>
            b.status == BookingStatus.accepted ||
            b.status == BookingStatus.awaitingConfirmation)
        .toList();
    final upcomingCount = accepted.where((b) {
      final d = b.requestedDate ?? b.startDate;
      return d != null && !d.isBefore(today);
    }).length;

    // Rating from the provider's verified review aggregate.
    final ratingData = uid.isEmpty
        ? null
        : ref.watch(providerRatingProvider(uid)).asData?.value;
    final ratingLabel = (ratingData == null || ratingData.count == 0)
        ? '—'
        : '${ratingData.avg.toStringAsFixed(1)} ⭐';

    // Open marketplace requests near the provider — opportunities to win work.
    final openWalks =
        ref.watch(openWalkRequestsProvider).asData?.value ?? const [];
    final openSittings =
        ref.watch(openSittingRequestsProvider).asData?.value ?? const [];
    final opportunities = <Widget>[
      for (final w in openWalks.take(10))
        _OpportunityCard(
          petName: w.petName,
          area: w.area,
          typeLabel: 'טיול',
          icon: Icons.directions_walk_rounded,
          imageUrl: w.allImages.isNotEmpty ? w.allImages.first : null,
          dateLabel: w.preferredDate != null
              ? '${w.preferredDate!.day.toString().padLeft(2, '0')}/${w.preferredDate!.month.toString().padLeft(2, '0')}'
                  '${w.preferredTime.isNotEmpty ? ' · ${w.preferredTime}' : ''}'
              : (w.preferredTime.isNotEmpty ? w.preferredTime : null),
          budget:
              (w.budget != null && w.budget!.isNotEmpty)
                  ? withShekel(w.budget!)
                  : null,
          onTap: () => onSelectTab(4),
        ),
      for (final s in openSittings.take(10))
        _OpportunityCard(
          petName: s.petName,
          area: s.area,
          typeLabel: 'שמירה',
          icon: Icons.home_work_rounded,
          imageUrl: s.allImages.isNotEmpty ? s.allImages.first : null,
          dateLabel: s.startDate != null
              ? '${s.startDate!.day.toString().padLeft(2, '0')}/${s.startDate!.month.toString().padLeft(2, '0')}'
                  '${s.endDate != null ? ' – ${s.endDate!.day.toString().padLeft(2, '0')}/${s.endDate!.month.toString().padLeft(2, '0')}' : ''}'
              : null,
          budget:
              (s.budget != null && s.budget!.isNotEmpty)
                  ? withShekel(s.budget!)
                  : null,
          onTap: () => onSelectTab(4),
        ),
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        // --- Immersive Provider Hero (Organic Modernism) ---
        Stack(
          children: [
            Container(
              height: 380,
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.surfaceDark),
              child: Image.asset(
                'assets/images/hero/provider_home_bg.jpg', // Group of happy dogs in field
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.25),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surfaceDark,
                  child: const Center(
                      child: Icon(Icons.business_center_rounded,
                          size: 40, color: AppColors.primary)),
                ),
              ),
            ),
            // Header Stats / Greeting Overlay
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    ProfileAvatarButton(
                      imageUrl: profile?.photoUrl,
                      name: displayName,
                      menuItems: profileMenuItemsForRole(
                        context,
                        UserRole.serviceProvider,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'שלום, $displayName 🌿',
                            style: AppTextStyles.h2
                                .copyWith(color: Colors.white, fontSize: 18),
                          ),
                          Text(
                            'העסק שלך נראה נהדר!',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/chat'),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.30),
                                  width: 1),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    NotificationBellButton(
                      onTap: () => context.push('/notifications'),
                    ),
                    const SizedBox(width: 8),
                    PillIconButton(
                      icon: Icons.insights_rounded,
                      onTap: () => onAction('מעבר לנתוני תובנות'),
                    ),
                  ],
                ),
              ),
            ),
            // Floating Business Card Overlay
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: GlassCard(
                padding: const EdgeInsets.all(18),
                borderRadius: BorderRadius.circular(22),
                blur: 35,
                opacity: 0.55,
                color: AppColors.prussianBlue3,
                child: Row(
                  children: [
                    _StatItem(
                        label: 'ממתינות',
                        value: '$pendingCount',
                        color: Colors.white),
                    Container(
                        height: 30,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.1)),
                    _StatItem(
                        label: 'משימות קרובות',
                        value: '$upcomingCount',
                        color: Colors.white),
                    Container(
                        height: 30,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.1)),
                    _StatItem(
                        label: 'דירוג',
                        value: ratingLabel,
                        color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // --- Pending requests action banner ---
        if (pendingCount > 0) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GradientActionCard(
              title: 'יש לך $pendingCount בקשות חדשות',
              subtitle: 'בקשות שממתינות לאישורך — הגב/י כדי לא לפספס',
              icon: Icons.notifications_active_rounded,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.sapphire],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => onSelectTab(4),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // --- Open opportunities (horizontal) ---
        // Note: not actually area-filtered — openWalkRequestsProvider/
        // openSittingRequestsProvider return every open request nationwide.
        // Title intentionally doesn't claim "near you" until real geo-filtering
        // exists (would need a provider-level area/location field, which the
        // profile doesn't have today).
        if (opportunities.isNotEmpty) ...[
          HomeTopRatedSection(
            title: 'בקשות חדשות',
            itemHeight: 300,
            onMoreTap: () => onSelectTab(4),
            itemCount: opportunities.length,
            itemBuilder: (context, i) => opportunities[i],
          ),
          const SizedBox(height: 24),
        ],

        // --- Dog parks nearby ---
        parksAsync.when(
          data: (parks) => HomeTopRatedSection(
            title: 'גינות כלבים',
            itemHeight: 300,
            onMoreTap: () {
              ref.read(exploreTabIndexProvider.notifier).state = 0;
              onSelectTab(2);
            },
            itemCount: parks.length,
            emptyState: const EmptyStateWidget(
              title: 'אין גינות כלבים באזור',
              subtitle: 'נסה לחפש באזור אחר',
              icon: Icons.park_rounded,
            ),
            itemBuilder: (context, index) {
              final poi = parks[index];
              return POICard(
                poi: poi,
                isCompact: true,
                onTap: () => context.push('/explore/poi/${poi.id}'),
              );
            },
          ),
          loading: () => const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => InlineErrorRetry(
            message: 'שגיאה בטעינת גינות כלבים',
            onRetry: () =>
                ref.invalidate(topRatedPOIsProvider(type: POIType.park)),
          ),
        ),

        const SizedBox(height: 24),

        // --- Vets nearby ---
        vetsAsync.when(
          data: (vets) => HomeTopRatedSection(
            title: 'וטרינרים',
            itemHeight: 300,
            onMoreTap: () {
              ref.read(exploreTabIndexProvider.notifier).state = 1;
              onSelectTab(2);
            },
            itemCount: vets.length,
            emptyState: const EmptyStateWidget(
              title: 'אין וטרינרים באזור',
              subtitle: 'נסה לחפש באזור אחר',
              icon: Icons.medical_services_rounded,
            ),
            itemBuilder: (context, index) {
              final poi = vets[index];
              return POICard(
                poi: poi,
                isCompact: true,
                onTap: () => context.push('/explore/poi/${poi.id}'),
              );
            },
          ),
          loading: () => const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => InlineErrorRetry(
            message: 'שגיאה בטעינת וטרינרים',
            onRetry: () =>
                ref.invalidate(topRatedPOIsProvider(type: POIType.vet)),
          ),
        ),

        const SizedBox(height: 24),

        // --- Pet stores nearby ---
        storesAsync.when(
          data: (stores) => HomeTopRatedSection(
            title: 'חנויות חיות',
            itemHeight: 300,
            onMoreTap: () {
              ref.read(exploreTabIndexProvider.notifier).state = 2;
              onSelectTab(2);
            },
            itemCount: stores.length,
            emptyState: const EmptyStateWidget(
              title: 'אין חנויות באזור',
              subtitle: 'נסה לחפש באזור אחר',
              icon: Icons.shopping_bag_rounded,
            ),
            itemBuilder: (context, index) {
              final poi = stores[index];
              return POICard(
                poi: poi,
                isCompact: true,
                onTap: () => context.push('/explore/poi/${poi.id}'),
              );
            },
          ),
          loading: () => const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => InlineErrorRetry(
            message: 'שגיאה בטעינת חנויות',
            onRetry: () =>
                ref.invalidate(topRatedPOIsProvider(type: POIType.store)),
          ),
        ),

        const SizedBox(height: 24),

        // --- List Your Service CTA (shown only when no services yet) ---
        const ListYourServiceCTA(),

        const SizedBox(height: 24),

        const SizedBox(height: 130),
      ],
    );
  }
}
