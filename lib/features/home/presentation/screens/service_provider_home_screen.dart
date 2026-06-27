import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_bottom_nav.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/pill_icon_button.dart';
import 'package:petpal/core/widgets/discovery_chip.dart';
import 'package:petpal/core/widgets/luxury_hero.dart';
import 'package:petpal/core/widgets/notification_bell_button.dart';
import 'package:petpal/core/widgets/profile_menu.dart';
import 'package:petpal/core/widgets/gradient_action_card.dart';
import 'package:petpal/core/widgets/empty_state_card.dart';

import 'package:petpal/features/auth/domain/enums/user_role.dart';
import 'package:petpal/features/feed/presentation/screens/feed_screen.dart';
import 'package:petpal/features/explore/presentation/screens/explore_screen.dart';
import 'package:petpal/features/lost_and_found/presentation/screens/lost_found_feed_screen.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';
import 'package:petpal/features/booking/presentation/providers/booking_provider.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';
import 'package:petpal/features/reviews/presentation/providers/review_provider.dart';
import 'package:petpal/features/reviews/domain/entities/review.dart';

import 'package:petpal/features/home/presentation/widgets/home_top_rated_section.dart';
import 'package:petpal/features/home/presentation/widgets/provider_requests_tab.dart';
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
    ref.read(showProviderServicesProvider.notifier).state = false;
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final showMyServices = ref.watch(showProviderServicesProvider);
    final pendingCount = ref.watch(pendingBookingCountProvider);
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

    final body =
        showMyServices ? const ProviderServicesTab() : tabs[_currentIndex];

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
            key: ValueKey(showMyServices ? 'services' : '$_currentIndex'),
            child: body,
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: showMyServices ? -1 : _currentIndex,
          onChanged: _onNavChanged,
          items: [
            const AppNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'בית'),
            const AppNavItem(
                icon: Icons.feed_outlined,
                activeIcon: Icons.feed_rounded,
                label: 'קהילה'),
            const AppNavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore_rounded,
                label: 'גלה'),
            const AppNavItem(
                icon: Icons.pets_outlined,
                activeIcon: Icons.pets_rounded,
                label: 'אבודים'),
            AppNavItem(
                icon: Icons.assignment_outlined,
                activeIcon: Icons.assignment_rounded,
                label: 'הבקשות',
                badgeCount: pendingCount),
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
            style: AppTextStyles.h2.copyWith(color: color, fontSize: 16),
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

/// Section header with an optional trailing action link.
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headlineMd,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

/// A full-width agenda row for one of today's accepted bookings.
class _ProviderAgendaRow extends StatelessWidget {
  final BookingRequest booking;
  final VoidCallback onTap;

  const _ProviderAgendaRow({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isWalk = booking.serviceType == BookingServiceType.walk;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: AppRadius.organicRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.subtle,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isWalk
                    ? Icons.directions_walk_rounded
                    : Icons.home_work_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    booking.petName,
                    style: AppTextStyles.headlineSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'עם ${booking.ownerName} · ${isWalk ? 'טיול' : 'שמירה'}',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// A horizontal card for an open marketplace request the provider can bid on.
class _OpportunityCard extends StatelessWidget {
  final String petName;
  final String area;
  final String typeLabel;
  final IconData icon;
  final VoidCallback onTap;

  const _OpportunityCard({
    required this.petName,
    required this.area,
    required this.typeLabel,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
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
                  child: Icon(icon, size: 18, color: AppColors.primary),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    typeLabel,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              petName,
              style: AppTextStyles.headlineSm,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'הגש הצעה',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_left_rounded,
                    size: 16, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-width review card for the recent-reviews section.
class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final comment = review.comment?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.organicRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewerName.isEmpty ? 'משתמש' : review.reviewerName,
                  style: AppTextStyles.bodyBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 15,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style:
                  AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
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

    // ── Real metrics derived from live data ──────────────────────────────────
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final incoming = ref.watch(incomingBookingsProvider).asData?.value ??
        const <BookingRequest>[];
    final pendingCount =
        incoming.where((b) => b.status == BookingStatus.pending).length;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool coversToday(BookingRequest b) {
      final single = b.requestedDate;
      if (single != null) {
        return DateTime(single.year, single.month, single.day) == today;
      }
      if (b.startDate != null && b.endDate != null) {
        final start =
            DateTime(b.startDate!.year, b.startDate!.month, b.startDate!.day);
        final end = DateTime(b.endDate!.year, b.endDate!.month, b.endDate!.day);
        return !today.isBefore(start) && !today.isAfter(end);
      }
      return false;
    }

    final accepted = incoming
        .where((b) =>
            b.status == BookingStatus.accepted ||
            b.status == BookingStatus.awaitingConfirmation)
        .toList();
    final todayJobs = accepted.where(coversToday).toList();
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
          onTap: () => onSelectTab(4),
        ),
      for (final s in openSittings.take(10))
        _OpportunityCard(
          petName: s.petName,
          area: s.area,
          typeLabel: 'שמירה',
          icon: Icons.home_work_rounded,
          onTap: () => onSelectTab(4),
        ),
    ];

    // Recent reviews for social proof.
    final reviews = uid.isEmpty
        ? const <Review>[]
        : (ref.watch(providerReviewsProvider(uid)).asData?.value ?? const []);

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
              child: CachedNetworkImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=2000&auto=format&fit=crop', // Group of happy dogs in field
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.25),
                colorBlendMode: BlendMode.darken,
                placeholder: (context, url) => Container(
                  color: AppColors.surfaceDark,
                  child: const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary)),
                ),
                errorWidget: (context, url, error) => Container(
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
                        onMyServices: () => ref
                            .read(showProviderServicesProvider.notifier)
                            .state = true,
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
                opacity: 0.95,
                color: AppColors.surfaceDark,
                child: Row(
                  children: [
                    _StatItem(
                        label: 'ממתינות',
                        value: '$pendingCount',
                        color: AppColors.primary),
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

        // --- Quick action chips (wired to real destinations) ---
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              DiscoveryChip(
                label: 'בקשות',
                icon: Icons.assignment_outlined,
                isSelected: true,
                onTap: () => onSelectTab(4),
              ),
              const SizedBox(width: 12),
              DiscoveryChip(
                label: 'השירותים שלי',
                icon: Icons.campaign_outlined,
                onTap: () => ref
                    .read(showProviderServicesProvider.notifier)
                    .state = true,
              ),
              const SizedBox(width: 12),
              DiscoveryChip(
                label: 'צ׳אט',
                icon: Icons.chat_bubble_outline_rounded,
                onTap: () => onSelectTab(4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

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

        // --- Today's schedule (vertical agenda) ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionTitle(
            title: 'המשימות שלי להיום',
            actionLabel: todayJobs.isEmpty ? null : 'הצג הכל',
            onAction: todayJobs.isEmpty ? null : () => onSelectTab(4),
          ),
        ),
        const SizedBox(height: 12),
        if (todayJobs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: EmptyStateWidget(
              title: 'אין משימות להיום',
              subtitle: 'משימות מאושרות יופיעו כאן ביום הביצוע',
              icon: Icons.event_available_rounded,
            ),
          )
        else
          ...todayJobs.map(
            (b) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child:
                  _ProviderAgendaRow(booking: b, onTap: () => onSelectTab(4)),
            ),
          ),

        const SizedBox(height: 12),

        // --- Open opportunities (horizontal) ---
        // Note: not actually area-filtered — openWalkRequestsProvider/
        // openSittingRequestsProvider return every open request nationwide.
        // Title intentionally doesn't claim "near you" until real geo-filtering
        // exists (would need a provider-level area/location field, which the
        // profile doesn't have today).
        if (opportunities.isNotEmpty) ...[
          HomeTopRatedSection(
            title: 'הזדמנויות חדשות',
            itemHeight: 165,
            onMoreTap: () => onSelectTab(4),
            itemCount: opportunities.length,
            itemBuilder: (context, i) => opportunities[i],
          ),
          const SizedBox(height: 24),
        ],

        // --- Recent reviews (social proof) ---
        if (reviews.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _SectionTitle(title: 'ביקורות אחרונות'),
          ),
          const SizedBox(height: 12),
          ...reviews.take(3).map(
                (r) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _ReviewCard(review: r),
                ),
              ),
          const SizedBox(height: 12),
        ],

        // --- List Your Service CTA (shown only when no services yet) ---
        const ListYourServiceCTA(),

        const SizedBox(height: 24),

        const SizedBox(height: 130),
      ],
    );
  }
}
