import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/utils/price_formatter.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/core/widgets/app_bottom_nav.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/section_header.dart';
import 'package:petpal/core/widgets/pill_icon_button.dart';
import 'package:petpal/core/widgets/discovery_chip.dart';
import 'package:petpal/core/widgets/gradient_action_card.dart';
import 'package:petpal/core/widgets/empty_state_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/feed/presentation/screens/feed_screen.dart';
import 'package:petpal/features/lost_and_found/presentation/screens/lost_found_feed_screen.dart';
import 'package:petpal/features/messaging/data/datasources/messaging_datasource.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart';
import 'package:petpal/features/walks/domain/entities/walk_service.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart'
    show SittingRequest, PetType, PetGender;
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';
import 'package:petpal/features/booking/presentation/providers/booking_provider.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';

enum ProviderServiceType { dogWalk, petSitting }

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


  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _ProviderHomeTab(onAction: (msg) => _toast(msg)),
      const FeedScreen(),
      const LostFoundFeedScreen(),
      const _ProviderMyServicesTab(),
      const _ProviderAllRequestsTab(),
      const _MessagesTab(),
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
            AppNavItem(icon: Icons.campaign_outlined, activeIcon: Icons.campaign_rounded, label: 'שירותים שלי'),
            AppNavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'הבקשות'),
            AppNavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble_rounded, label: 'צ׳אט'),
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

class _ActiveJobTracker extends StatelessWidget {
  final String petName;
  final String ownerName;
  final String status;
  final VoidCallback onTap;

  const _ActiveJobTracker({
    required this.petName,
    required this.ownerName,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(22),
        color: AppColors.primary.withValues(alpha: 0.05),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.1), width: 1.5),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.directions_walk_rounded,
                  color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'טיול פעיל עם $petName (של $ownerName)',
                    style: AppTextStyles.bodyBold,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderHomeTab extends ConsumerWidget {
  final void Function(String msg) onAction;

  const _ProviderHomeTab({
    required this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).asData?.value;
    final displayName = profile?.name ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'נותן שירות';

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
                    AppAvatar(
                      name: displayName,
                      photoUrl: profile?.photoUrl,
                      size: 52,
                      onTap: () => context.push('/profile'),
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
                    const _StatItem(
                        label: 'הכנסה השבוע',
                        value: '₪840',
                        color: AppColors.primary),
                    Container(
                        height: 30,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.1)),
                    const _StatItem(
                        label: 'טיולים', value: '12', color: Colors.white),
                    Container(
                        height: 30,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.1)),
                    const _StatItem(
                        label: 'בירוג', value: '4.9 ⭐', color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // --- Category Business Chips ---
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              DiscoveryChip(
                label: 'בקשות חדשות',
                icon: Icons.notifications_active_rounded,
                isSelected: true,
                onTap: () {},
              ),
              const SizedBox(width: 12),
              DiscoveryChip(
                label: 'לו״ז עבודה',
                icon: Icons.calendar_today_rounded,
                onTap: () {},
              ),
              const SizedBox(width: 12),
              DiscoveryChip(
                label: 'לקוחות',
                icon: Icons.people_outline_rounded,
                onTap: () {},
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // --- Active Job Tracker (Provider Version) ---
        _ActiveJobTracker(
          petName: 'בוף',
          ownerName: 'מוניר',
          status: 'בטיול עכשיו',
          onTap: () => onAction('צפה בטיול פעיל'),
        ),

        const SizedBox(height: 24),

        // --- List Your Service CTA (New) ---
        _ListYourServiceCTA(),

        const SizedBox(height: 24),

        const SizedBox(height: 130),
      ],
    );
  }
}


// ── Provider Walks Tab ────────────────────────────────────────────────────────

// ── שירותים שלי — publish walk + sitting services ─────────────────────────
class _ProviderMyServicesTab extends ConsumerStatefulWidget {
  const _ProviderMyServicesTab();

  @override
  ConsumerState<_ProviderMyServicesTab> createState() =>
      _ProviderMyServicesTabState();
}

class _ProviderMyServicesTabState
    extends ConsumerState<_ProviderMyServicesTab> {
  int _selected = 0; // 0 = walk, 1 = sitting

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: GlassCard(
              useBlur: true,
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Expanded(
                    child: _ProviderToggleChip(
                      label: 'פרסם שירותי טיולים',
                      icon: Icons.directions_walk_rounded,
                      selected: _selected == 0,
                      onTap: () => setState(() => _selected = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ProviderToggleChip(
                      label: 'פרסם שירותי שמירה',
                      icon: Icons.home_work_rounded,
                      selected: _selected == 1,
                      onTap: () => setState(() => _selected = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _selected == 0
                  ? const _ProviderAdvertiseView(key: ValueKey('adv_walk'))
                  : const _ProviderSittingAdvertiseView(
                      key: ValueKey('adv_sitting')),
            ),
          ),
        ],
      ),
    );
  }
}

// ── הבקשות — walk + sitting requests from pet owners ─────────────────────
class _ProviderAllRequestsTab extends ConsumerStatefulWidget {
  const _ProviderAllRequestsTab();

  @override
  ConsumerState<_ProviderAllRequestsTab> createState() =>
      _ProviderAllRequestsTabState();
}

class _ProviderAllRequestsTabState
    extends ConsumerState<_ProviderAllRequestsTab> {
  int _selected = 0; // 0 = walk, 1 = sitting, 2 = bookings

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: GlassCard(
              useBlur: true,
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Expanded(
                    child: _ProviderToggleChip(
                      label: 'טיולים',
                      icon: Icons.directions_walk_rounded,
                      selected: _selected == 0,
                      onTap: () => setState(() => _selected = 0),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _ProviderToggleChip(
                      label: 'שמירה',
                      icon: Icons.home_work_rounded,
                      selected: _selected == 1,
                      onTap: () => setState(() => _selected = 1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _ProviderToggleChip(
                      label: 'הזמנות',
                      icon: Icons.calendar_month_rounded,
                      selected: _selected == 2,
                      onTap: () => setState(() => _selected = 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: switch (_selected) {
                1 => const _ProviderSittingRequestsView(key: ValueKey('req_sitting')),
                2 => const _IncomingBookingsView(key: ValueKey('req_bookings')),
                _ => const _ProviderRequestsView(key: ValueKey('req_walk')),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderWalksTab extends ConsumerStatefulWidget {
  const _ProviderWalksTab();

  @override
  ConsumerState<_ProviderWalksTab> createState() => _ProviderWalksTabState();
}

class _ProviderWalksTabState extends ConsumerState<_ProviderWalksTab> {
  int _selectedView = 0; // 0 = בקשות טיול, 1 = פרסם שירות

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ── Toggle bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: GlassCard(
              useBlur: true,
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Expanded(
                    child: _ProviderToggleChip(
                      label: 'בקשות טיול',
                      icon: Icons.list_alt_rounded,
                      selected: _selectedView == 0,
                      onTap: () => setState(() => _selectedView = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ProviderToggleChip(
                      label: 'פרסם שירות',
                      icon: Icons.campaign_rounded,
                      selected: _selectedView == 1,
                      onTap: () => setState(() => _selectedView = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _selectedView == 0
                  ? const _ProviderRequestsView(key: ValueKey('requests'))
                  : const _ProviderAdvertiseView(key: ValueKey('advertise')),
            ),
          ),
        ],
      ),
    );
  }
}

// ── View 0: pet owner walk requests ──────────────────────────────────────────
class _ProviderRequestsView extends ConsumerWidget {
  const _ProviderRequestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(openWalkRequestsProvider);
    return requestsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('שגיאה בטעינת הבקשות: $e')),
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_walk_rounded,
                    size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text('אין בקשות טיול פתוחות כרגע',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                const Text('כשבעל חיה יפרסם בקשה — תופיע כאן',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SectionHeader(
                title: 'בקשות טיול פתוחות',
                subtitle: '${requests.length} בקשות זמינות כרגע',
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.42,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: requests.length,
                itemBuilder: (ctx, i) => _ProviderWalkRequestCard(
                  request: requests[i],
                  colorIndex: i,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── View 1: advertise my service ──────────────────────────────────────────────
class _ProviderAdvertiseView extends ConsumerWidget {
  const _ProviderAdvertiseView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myServicesAsync = ref.watch(myWalkServicesProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      children: [
        // CTA card
        GlassCard(
          useBlur: true,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.statusOpen],
                      ),
                    ),
                    child: const Icon(Icons.campaign_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('פרסם את שירות הטיולים שלך',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary)),
                        SizedBox(height: 2),
                        Text('הגע/י לבעלי חיות מחמד באזורך',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Benefit bullets
              const _BenefitRow(
                  icon: Icons.location_on_rounded,
                  text: 'הגע/י לבעלי חיות מחמד באזורך'),
              const SizedBox(height: 6),
              const _BenefitRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  text: 'קבל/י פניות ישירות'),
              const SizedBox(height: 6),
              const _BenefitRow(
                  icon: Icons.star_rounded,
                  text: 'בנה/י את הפרופיל המקצועי שלך'),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push('/walks/service/create'),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [AppColors.primary, AppColors.statusOpen],
                    ),
                  ),
                  child: const Center(
                    child: Text('פרסם שירות חדש',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // My active services
        myServicesAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => const SizedBox.shrink(),
          data: (services) {
            if (services.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('השירותים שלי',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                ...services.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MyServiceCard(service: s, ref: ref),
                    )),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── My service card (provider-owned, with delete) ─────────────────────────────
class _MyServiceCard extends StatelessWidget {
  final WalkService service;
  final WidgetRef ref;
  const _MyServiceCard({required this.service, required this.ref});

  @override
  Widget build(BuildContext context) {
    const teal = AppColors.primary;
    final isActive = service.isActive;

    return GlassCard(
      useBlur: true,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────
          Row(
            children: [
              LiveUserAvatar(
                uid: service.providerUid,
                fallbackName: service.providerName,
                fallbackPhotoUrl: service.providerPhotoUrl,
                size: 48,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.providerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            fontSize: 15)),
                    Text(service.area,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      formatPrice(service.priceText, service.priceType),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.duration,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isActive
                      ? AppColors.statusOpen.withValues(alpha: 0.12)
                      : AppColors.warning.withValues(alpha: 0.12),
                ),
                child: Text(
                  isActive ? 'פעיל' : 'מושהה',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color:
                        isActive ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),

          // ── Pet type chips ───────────────────────────────────────────
          if (service.petTypes.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 6,
              children: service.petTypes.map((type) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: teal.withValues(alpha: 0.08),
                  ),
                  child: Text(type,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: teal)),
                );
              }).toList(),
            ),
          ],

          // ── Stats row ────────────────────────────────────────────────
          if (service.viewCount != null || service.requestCount != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (service.viewCount != null) ...[
                    const Icon(Icons.visibility_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${service.viewCount} צפיות',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                  ],
                  if (service.viewCount != null && service.requestCount != null)
                    const SizedBox(width: 12),
                  if (service.requestCount != null) ...[
                    const Icon(Icons.inbox_outlined,
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('${service.requestCount} פניות',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ],
              ),
            ),
          ],

          // ── Action buttons ───────────────────────────────────────────
          const SizedBox(height: 10),
          Row(
            children: [
              // Toggle active/paused
              _ServiceActionButton(
                label: isActive ? 'השהה' : 'הפעל',
                icon: isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isActive ? AppColors.warning : teal,
                bgColor: isActive
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : teal.withValues(alpha: 0.1),
                borderColor: isActive
                    ? AppColors.warning.withValues(alpha: 0.35)
                    : teal.withValues(alpha: 0.3),
                onTap: () => ref
                    .read(walkDatasourceProvider)
                    .updateWalkService(service.id, {'isActive': !isActive}),
              ),
              const SizedBox(width: 8),
              // Edit button
              _ServiceActionButton(
                label: 'ערוך',
                icon: Icons.edit_rounded,
                color: AppColors.smartBlue,
                bgColor: AppColors.smartBlue.withValues(alpha: 0.08),
                borderColor: AppColors.smartBlue.withValues(alpha: 0.3),
                onTap: () =>
                    context.push('/walks/service/create', extra: service),
              ),
              const Spacer(),
              // Delete
              GestureDetector(
                onTap: () => ref
                    .read(walkDatasourceProvider)
                    .deleteWalkService(service.id),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;
  const _ServiceActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: bgColor,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Toggle chip for provider tab ──────────────────────────────────────────────
class _ProviderToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ProviderToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? AppColors.primary : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ProviderWalkRequestCard extends StatelessWidget {
  final WalkRequest request;
  final int colorIndex;
  const _ProviderWalkRequestCard(
      {required this.request, required this.colorIndex});

  static const _bgColors = [
    AppColors.sapphire,
    AppColors.blueSlate,
    AppColors.regalNavy,
    AppColors.smartBlue,
    AppColors.prussianBlue2,
    AppColors.prussianBlue,
    AppColors.twilightIndigo,
    AppColors.blueSlate,
  ];

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
            // ── Pet photo area ───────────────────────────────────────────
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
                              size: 52, color: Colors.white.withValues(alpha: 0.6)),
                        ),
                        errorWidget: (_, __, ___) => Center(
                          child: Icon(_fallbackIcon,
                              size: 52, color: Colors.white.withValues(alpha: 0.6)),
                        ),
                      )
                    else
                      Center(
                        child: Icon(_fallbackIcon,
                            size: 60, color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    // Heart icon
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_border_rounded,
                            size: 16, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Info area ────────────────────────────────────────────────
            Expanded(
              flex: 44,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _petTypeLabel,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: [
                        if (_genderLabel.isNotEmpty)
                          _IconChip(
                            icon: Icons.transgender_rounded,
                            label: _genderLabel,
                            color: request.petGender == PetGender.female
                                ? AppColors.error
                                : AppColors.smartBlue,
                          ),
                        _IconChip(
                          icon: Icons.location_on_rounded,
                          label: request.area,
                          color: AppColors.error,
                        ),
                        _IconChip(
                          icon: Icons.timer_rounded,
                          label: request.duration,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        LiveUserAvatar(
                          uid: request.ownerUid,
                          fallbackName: request.ownerName,
                          fallbackPhotoUrl: request.ownerPhotoUrl,
                          size: 20,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            request.ownerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: GestureDetector(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _ProviderOfferSheet(request: request),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.statusOpen],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'הגש מועמדות',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11),
                            ),
                          ),
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

class _MessagesTab extends ConsumerWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
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
            subtitle: 'שיחות עם בעלי חיות המחמד',
          ),
          const SizedBox(height: 10),
          if (convos.isEmpty)
            const EmptyStateCard(
              title: 'אין שיחות עדיין',
              subtitle: 'שיחות יופיעו כאן אחרי בקשה/הזמנה.',
              icon: Icons.chat_bubble_outline,
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
              final otherUid = otherEntry.key;
              final otherName = otherEntry.value;
              final otherPhotoUrl = photoUrls[otherUid] ?? '';
              final lastMsg = c['lastMessage'] as String? ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () => context.push(
                    '/chat/${c['id']}',
                    extra: {
                      'otherName': otherName,
                      'otherPhotoUrl': otherPhotoUrl,
                      'otherUid': otherUid,
                    },
                  ),
                  child: Row(
                    children: [
                      LiveUserAvatar(
                        uid: otherUid,
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


// ── Provider offer bottom sheet ───────────────────────────────────────────────
class _ProviderOfferSheet extends ConsumerStatefulWidget {
  final WalkRequest request;
  const _ProviderOfferSheet({required this.request});

  @override
  ConsumerState<_ProviderOfferSheet> createState() =>
      _ProviderOfferSheetState();
}

class _ProviderOfferSheetState extends ConsumerState<_ProviderOfferSheet> {
  final _messageController = TextEditingController();
  final _priceController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    setState(() => _sending = true);

    final req = widget.request;
    final myProfile = ref.read(currentUserProfileProvider).asData?.value;
    final myPhotoUrl = myProfile?.photoUrl ?? me.photoURL ?? '';
    final ownerPhotoUrl = req.ownerPhotoUrl ?? '';

    final ds = MessagingDatasource(db: FirebaseFirestore.instance);
    final convoId = await ds.getOrCreateConversation(
      myUid: me.uid,
      myName: me.displayName ?? me.email ?? 'מטפל',
      otherUid: req.ownerUid,
      otherName: req.ownerName,
      myPhotoUrl: myPhotoUrl,
      otherPhotoUrl: ownerPhotoUrl,
    );

    final dateStr = req.preferredDate != null
        ? '${req.preferredDate!.day.toString().padLeft(2, '0')}/${req.preferredDate!.month.toString().padLeft(2, '0')}'
        : '';
    await ds.sendContextMessage(
      conversationId: convoId,
      senderId: me.uid,
      metadata: {
        'requestType': 'walk',
        'requestId': req.id,
        'petName': req.petName,
        'petImageUrl': req.petImageUrl ?? '',
        'ownerName': req.ownerName,
        'ownerPhotoUrl': ownerPhotoUrl,
        'date': dateStr,
        'time': req.preferredTime,
        'area': req.area,
        'budget': req.budget ?? '',
      },
    );

    await ds.sendMessage(
      conversationId: convoId,
      senderId: me.uid,
      senderName: me.displayName ?? me.email ?? 'מטפל',
      senderPhotoUrl: myPhotoUrl,
      text:
          '${_priceController.text.trim().isNotEmpty ? "${withShekel(_priceController.text.trim())} — " : ""}$text',
    );

    if (mounted) {
      final router = GoRouter.of(context);
      Navigator.pop(context);
      router.push('/chat/$convoId', extra: {
        'otherName': req.ownerName,
        'otherPhotoUrl': ownerPhotoUrl,
        'otherUid': req.ownerUid
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final dateStr = req.preferredDate != null
        ? '${req.preferredDate!.day.toString().padLeft(2, '0')}/${req.preferredDate!.month.toString().padLeft(2, '0')}'
        : '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle + title + close
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text('הגש מועמדות',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.borderFaint,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Request summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.primary.withValues(alpha: 0.06),
                  border:
                      Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${req.petName}  ·  ${req.ownerName}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _OfferSummaryItem(
                            icon: Icons.location_on_outlined, text: req.area),
                        _OfferSummaryItem(
                            icon: Icons.access_time_rounded,
                            text: '${req.preferredTime}'
                                '${dateStr.isNotEmpty ? '  $dateStr' : ''}'),
                        if (req.budget != null && req.budget!.isNotEmpty)
                          _OfferSummaryItem(
                              icon: Icons.account_balance_wallet_outlined,
                              text: 'תקציב: ${withShekel(req.budget!)}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Price field
              _OfferInputField(
                hint: 'המחיר שלך (לדוגמה: 80₪)',
                prefix: '₪',
                keyboardType: TextInputType.text,
                controller: _priceController,
                maxLines: 1,
              ),
              const SizedBox(height: 10),

              // Message field
              _OfferInputField(
                hint:
                    'לדוגמה: אני זמין בתאריך זה. יש לי ניסיון עם חיות כמו שלך. ההצעה שלי היא...',
                controller: _messageController,
                maxLines: 3,
                minLines: 2,
              ),
              const SizedBox(height: 16),

              // Send button
              GestureDetector(
                onTap: _sending ? null : _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [AppColors.primary, AppColors.statusOpen],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_sending)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      else
                        const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _sending ? 'שולח...' : 'שלח הצעה',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _OfferSummaryItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _OfferSummaryItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
      ],
    );
  }
}

class _OfferInputField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final int minLines;
  final String? prefix;
  final TextInputType? keyboardType;

  const _OfferInputField({
    required this.hint,
    required this.controller,
    this.maxLines = 4,
    this.minLines = 1,
    this.prefix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      textDirection: TextDirection.rtl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        prefixText: prefix,
        prefixStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 14),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Provider Sitting Tab
// ═══════════════════════════════════════════════════════════════════════════

class _ProviderSittingTab extends ConsumerStatefulWidget {
  const _ProviderSittingTab();

  @override
  ConsumerState<_ProviderSittingTab> createState() =>
      _ProviderSittingTabState();
}

class _ProviderSittingTabState extends ConsumerState<_ProviderSittingTab> {
  int _selectedView = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: GlassCard(
              useBlur: true,
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Expanded(
                    child: _ProviderToggleChip(
                      label: 'בקשות שמירה',
                      icon: Icons.list_alt_rounded,
                      selected: _selectedView == 0,
                      onTap: () => setState(() => _selectedView = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ProviderToggleChip(
                      label: 'פרסם שירות',
                      icon: Icons.campaign_rounded,
                      selected: _selectedView == 1,
                      onTap: () => setState(() => _selectedView = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _selectedView == 0
                  ? const _ProviderSittingRequestsView(
                      key: ValueKey('sitting_req'))
                  : const _ProviderSittingAdvertiseView(
                      key: ValueKey('sitting_adv')),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Open sitting requests (provider view) ─────────────────────────────────────

class _ProviderSittingRequestsView extends ConsumerWidget {
  const _ProviderSittingRequestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(openSittingRequestsProvider);
    return requestsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.sitting)),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_work_rounded,
                    size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text('אין בקשות שמירה פתוחות כרגע',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                const Text('כשבעל חיה יפרסם בקשה — תופיע כאן',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SectionHeader(
                title: 'בקשות שמירה פתוחות',
                subtitle: '${requests.length} בקשות זמינות כרגע',
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.42,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: requests.length,
                itemBuilder: (ctx, i) => _ProviderSittingRequestCard(
                  request: requests[i],
                  colorIndex: i,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Advertise sitting service ─────────────────────────────────────────────────

class _ProviderSittingAdvertiseView extends ConsumerWidget {
  const _ProviderSittingAdvertiseView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myServicesAsync = ref.watch(mySittingServicesProvider);
    const purple = AppColors.sitting;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      children: [
        GlassCard(
          useBlur: true,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                          colors: [AppColors.sitting, AppColors.blueSlate]),
                    ),
                    child: const Icon(Icons.campaign_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('פרסם את שירות השמירה שלך',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary)),
                        SizedBox(height: 2),
                        Text('הגע/י לבעלי חיות מחמד באזורך',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _BenefitRow(
                  icon: Icons.location_on_rounded,
                  text: 'הגע/י לבעלי חיות מחמד באזורך'),
              const SizedBox(height: 6),
              const _BenefitRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  text: 'קבל/י פניות ישירות'),
              const SizedBox(height: 6),
              const _BenefitRow(
                  icon: Icons.star_rounded,
                  text: 'בנה/י את הפרופיל המקצועי שלך'),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push('/sitting/service/create'),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [AppColors.sitting, AppColors.blueSlate],
                    ),
                  ),
                  child: const Center(
                    child: Text('פרסם שירות חדש',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        myServicesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: purple)),
          error: (e, _) => const SizedBox.shrink(),
          data: (services) {
            if (services.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('השירותים שלי',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                ...services.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MySittingServiceCard(service: s, ref: ref),
                    )),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── Provider sitting request card ─────────────────────────────────────────────

class _ProviderSittingRequestCard extends StatelessWidget {
  final SittingRequest request;
  final int colorIndex;
  const _ProviderSittingRequestCard(
      {required this.request, required this.colorIndex});

  static const _bgColors = [
    AppColors.blueSlate,
    AppColors.smartBlue,
    AppColors.sapphire,
    AppColors.regalNavy,
    AppColors.twilightIndigo,
    AppColors.prussianBlue,
    AppColors.prussianBlue2,
    AppColors.blueSlate,
  ];

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
            // ── Pet photo area ───────────────────────────────────────────
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
                              size: 52, color: Colors.white.withValues(alpha: 0.6)),
                        ),
                        errorWidget: (_, __, ___) => Center(
                          child: Icon(_fallbackIcon,
                              size: 52, color: Colors.white.withValues(alpha: 0.6)),
                        ),
                      )
                    else
                      Center(
                        child: Icon(_fallbackIcon,
                            size: 60, color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    // Heart icon
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_border_rounded,
                            size: 16, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Info area ────────────────────────────────────────────
            Expanded(
              flex: 44,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _petTypeLabel,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: [
                        if (_genderLabel.isNotEmpty)
                          _IconChip(
                            icon: Icons.transgender_rounded,
                            label: _genderLabel,
                            color: request.petGender == PetGender.female
                                ? AppColors.error
                                : AppColors.smartBlue,
                          ),
                        _IconChip(
                          icon: Icons.location_on_rounded,
                          label: request.area,
                          color: AppColors.error,
                        ),
                        if (request.numberOfNights > 0)
                          _IconChip(
                            icon: Icons.nights_stay_rounded,
                            label: '${request.numberOfNights} לילות',
                            color: AppColors.regalNavy,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        LiveUserAvatar(
                          uid: request.ownerUid,
                          fallbackName: request.ownerName,
                          fallbackPhotoUrl: request.ownerPhotoUrl,
                          size: 20,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            request.ownerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: GestureDetector(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              _SittingProviderOfferSheet(request: request),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.sitting,
                                AppColors.blueSlate,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'הגש מועמדות',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11),
                            ),
                          ),
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

// ── Sitting provider offer bottom sheet ───────────────────────────────────────

class _SittingProviderOfferSheet extends ConsumerStatefulWidget {
  final SittingRequest request;
  const _SittingProviderOfferSheet({required this.request});

  @override
  ConsumerState<_SittingProviderOfferSheet> createState() =>
      _SittingProviderOfferSheetState();
}

class _SittingProviderOfferSheetState
    extends ConsumerState<_SittingProviderOfferSheet> {
  final _messageController = TextEditingController();
  final _priceController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    setState(() => _sending = true);

    final req = widget.request;
    final myProfile = ref.read(currentUserProfileProvider).asData?.value;
    final myPhotoUrl = myProfile?.photoUrl ?? me.photoURL ?? '';
    final ownerPhotoUrl = req.ownerPhotoUrl ?? '';

    final ds = MessagingDatasource(db: FirebaseFirestore.instance);
    final convoId = await ds.getOrCreateConversation(
      myUid: me.uid,
      myName: me.displayName ?? me.email ?? 'מטפל',
      otherUid: req.ownerUid,
      otherName: req.ownerName,
      myPhotoUrl: myPhotoUrl,
      otherPhotoUrl: ownerPhotoUrl,
    );

    final startStr = req.startDate != null
        ? '${req.startDate!.day.toString().padLeft(2, '0')}/${req.startDate!.month.toString().padLeft(2, '0')}'
        : '';
    final endStr = req.endDate != null
        ? '${req.endDate!.day.toString().padLeft(2, '0')}/${req.endDate!.month.toString().padLeft(2, '0')}'
        : '';

    await ds.sendContextMessage(
      conversationId: convoId,
      senderId: me.uid,
      metadata: {
        'requestType': 'sitting',
        'requestId': req.id,
        'petName': req.petName,
        'petImageUrl': req.petImageUrl ?? '',
        'ownerName': req.ownerName,
        'ownerPhotoUrl': ownerPhotoUrl,
        'date': startStr.isNotEmpty && endStr.isNotEmpty
            ? '$startStr – $endStr'
            : '',
        'time': '${req.numberOfNights} לילות',
        'area': req.area,
        'budget': req.budget ?? '',
      },
    );

    await ds.sendMessage(
      conversationId: convoId,
      senderId: me.uid,
      senderName: me.displayName ?? me.email ?? 'מטפל',
      senderPhotoUrl: myPhotoUrl,
      text:
          '${_priceController.text.trim().isNotEmpty ? "${withShekel(_priceController.text.trim())} — " : ""}$text',
    );

    if (mounted) {
      final router = GoRouter.of(context);
      Navigator.pop(context);
      router.push('/chat/$convoId', extra: {
        'otherName': req.ownerName,
        'otherPhotoUrl': ownerPhotoUrl,
        'otherUid': req.ownerUid,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    const purple = AppColors.sitting;
    final startStr = req.startDate != null
        ? '${req.startDate!.day.toString().padLeft(2, '0')}/${req.startDate!.month.toString().padLeft(2, '0')}'
        : '';
    final endStr = req.endDate != null
        ? '${req.endDate!.day.toString().padLeft(2, '0')}/${req.endDate!.month.toString().padLeft(2, '0')}'
        : '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text('הגש מועמדות',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.borderFaint,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: purple.withValues(alpha: 0.06),
                  border: Border.all(color: purple.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${req.petName}  ·  ${req.ownerName}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _OfferSummaryItem(
                            icon: Icons.location_on_outlined, text: req.area),
                        if (startStr.isNotEmpty && endStr.isNotEmpty)
                          _OfferSummaryItem(
                              icon: Icons.date_range_rounded,
                              text: '$startStr – $endStr'),
                        if (req.numberOfNights > 0)
                          _OfferSummaryItem(
                              icon: Icons.nights_stay_rounded,
                              text: '${req.numberOfNights} לילות'),
                        if (req.budget != null && req.budget!.isNotEmpty)
                          _OfferSummaryItem(
                              icon: Icons.account_balance_wallet_outlined,
                              text: 'תקציב: ${withShekel(req.budget!)}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _OfferInputField(
                hint: 'המחיר שלך (לדוגמה: 80₪ ללילה)',
                prefix: '₪',
                keyboardType: TextInputType.text,
                controller: _priceController,
                maxLines: 1,
              ),
              const SizedBox(height: 10),
              _OfferInputField(
                hint:
                    'לדוגמה: אני זמין בתאריכים אלה. יש לי ניסיון עם חיות כמו שלך...',
                controller: _messageController,
                maxLines: 3,
                minLines: 2,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _sending ? null : _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: _sending
                          ? [
                              AppColors.textMuted,
                              AppColors.textSecondary,
                            ]
                          : [
                              purple,
                              AppColors.blueSlate,
                            ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_sending)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _sending ? 'שולח...' : 'שלח הצעה',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── My sitting service card ───────────────────────────────────────────────────

class _MySittingServiceCard extends StatelessWidget {
  final SittingService service;
  final WidgetRef ref;
  const _MySittingServiceCard({required this.service, required this.ref});

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.sitting;
    final isActive = service.isActive;

    return GlassCard(
      useBlur: true,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LiveUserAvatar(
                uid: service.providerUid,
                fallbackName: service.providerName,
                fallbackPhotoUrl: service.providerPhotoUrl,
                size: 48,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.providerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            fontSize: 15)),
                    Text(service.area,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      formatPrice(service.priceText, service.priceType),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: purple),
                    ),
                    const SizedBox(height: 2),
                    Text(service.sittingLocation,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isActive
                      ? AppColors.statusOpen.withValues(alpha: 0.12)
                      : AppColors.warning.withValues(alpha: 0.12),
                ),
                child: Text(
                  isActive ? 'פעיל' : 'מושהה',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color:
                        isActive ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          if (service.petTypes.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 6,
              children: service.petTypes.map((type) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: purple.withValues(alpha: 0.08),
                  ),
                  child: Text(type,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: purple)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () =>
                    context.push('/sitting/service/create', extra: service),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: purple.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 14, color: purple),
                      SizedBox(width: 4),
                      Text('עריכה',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: purple)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final ds = ref.read(sittingDatasourceProvider);
                  await ds.updateSittingService(
                      service.id, {'isActive': !service.isActive});
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isActive
                        ? AppColors.warning.withValues(alpha: 0.12)
                        : purple.withValues(alpha: 0.12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 14,
                        color: isActive ? AppColors.warning : purple,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'השהה' : 'הפעל',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isActive ? AppColors.warning : purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  final ds = ref.read(sittingDatasourceProvider);
                  await ds.deleteSittingService(service.id);
                },
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Icon chip (icon + label pill, used inside grid request cards) ─────────────

class _IconChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _IconChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
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
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListYourServiceCTA extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myServicesAsync = ref.watch(mySittingServicesProvider);

    return myServicesAsync.when(
      data: (services) {
        if (services.isNotEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GradientActionCard(
            title: 'התחל להרוויח משמירה',
            subtitle:
                'פרסם את שירותי השמירה שלך והתחל לקבל פניות מבעלי חיות באזורך',
            icon: Icons.add_business_rounded,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.blueSlate],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => context.push('/sitting/create-service'),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Incoming Bookings inline view ─────────────────────────────────────────────

class _IncomingBookingsView extends ConsumerWidget {
  const _IncomingBookingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(incomingBookingsProvider);

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('אין הזמנות נכנסות',
                    style: AppTextStyles.headlineSm
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('הזמנות מלקוחות יופיעו כאן',
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
          itemBuilder: (_, i) => _IncomingBookingTile(booking: bookings[i]),
        );
      },
    );
  }
}

class _IncomingBookingTile extends ConsumerStatefulWidget {
  final BookingRequest booking;
  const _IncomingBookingTile({required this.booking});

  @override
  ConsumerState<_IncomingBookingTile> createState() =>
      _IncomingBookingTileState();
}

class _IncomingBookingTileState extends ConsumerState<_IncomingBookingTile> {
  bool _loading = false;

  Future<void> _updateStatus(BookingStatus status, {String? note}) async {
    setState(() => _loading = true);
    try {
      await ref
          .read(bookingRepositoryProvider)
          .updateBookingStatus(widget.booking.id, status, providerNote: note);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDeclineDialog() async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('דחיית הזמנה'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('האם לדחות את הבקשה?'),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  hintText: 'הסבר (אופציונלי)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white),
              child: const Text('דחה'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      await _updateStatus(BookingStatus.declined,
          note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final isWalk = b.serviceType == BookingServiceType.walk;
    final isPending = b.status == BookingStatus.pending;
    final (label, color) = switch (b.status) {
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
        border: Border.all(
          color: isPending
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.border,
        ),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryFaint,
                backgroundImage: (b.ownerPhotoUrl?.isNotEmpty == true)
                    ? NetworkImage(b.ownerPhotoUrl!)
                    : null,
                child: (b.ownerPhotoUrl?.isNotEmpty != true)
                    ? Text(
                        b.ownerName.isNotEmpty
                            ? b.ownerName.characters.first.toUpperCase()
                            : '?',
                        style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.ownerName,
                        style: AppTextStyles.bodyMd
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      '${isWalk ? 'טיולים' : 'שמירה'} • ${b.petName} (${b.petType})',
                      style: AppTextStyles.labelMd
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(label,
                    style: AppTextStyles.labelMd.copyWith(
                        color: color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (b.specialInstructions != null &&
              b.specialInstructions!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(b.specialInstructions!,
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.textSecondary)),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            _loading
                ? const Center(
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showDeclineDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(
                                color:
                                    AppColors.error.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('דחה'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _updateStatus(BookingStatus.accepted),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('אשר'),
                        ),
                      ),
                    ],
                  ),
          ],
        ],
      ),
    );
  }
}
