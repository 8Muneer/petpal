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

import 'package:petpal/features/feed/presentation/screens/feed_screen.dart';
import 'package:petpal/features/lost_and_found/presentation/screens/lost_found_feed_screen.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';

import 'package:petpal/features/home/presentation/widgets/provider_requests_tab.dart';
import 'package:petpal/features/home/presentation/widgets/provider_services_tab.dart';
import 'package:petpal/features/messaging/presentation/widgets/chat_tab.dart';


class ServiceProviderHomeScreen extends ConsumerStatefulWidget {
  const ServiceProviderHomeScreen({super.key});

  @override
  ConsumerState<ServiceProviderHomeScreen> createState() =>
      _ServiceProviderHomeScreenState();
}

class _ServiceProviderHomeScreenState
    extends ConsumerState<ServiceProviderHomeScreen> {
  int _currentIndex = 0;
  bool _showMyServices = false;

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

  void _onNavChanged(int i) => setState(() {
        _showMyServices = false;
        _currentIndex = i;
      });

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _ProviderHomeTab(
        onAction: (msg) => _toast(msg),
        onOpenMyServices: () => setState(() => _showMyServices = true),
      ),
      const FeedScreen(),
      const LostFoundFeedScreen(),
      const ProviderRequestsTab(),
      const ChatTab(isProvider: true),
    ];

    final body = _showMyServices
        ? const ProviderServicesTab()
        : tabs[_currentIndex];

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
            key: ValueKey(_showMyServices ? 'services' : '$_currentIndex'),
            child: body,
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _showMyServices ? -1 : _currentIndex,
          onChanged: _onNavChanged,
          items: const [
            AppNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'בית'),
            AppNavItem(icon: Icons.feed_outlined, activeIcon: Icons.feed_rounded, label: 'פיד'),
            AppNavItem(icon: Icons.pets_outlined, activeIcon: Icons.pets_rounded, label: 'אבודים'),
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
  final VoidCallback onOpenMyServices;

  const _ProviderHomeTab({
    required this.onAction,
    required this.onOpenMyServices,
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
                    ProfileAvatarButton(
                      imageUrl: profile?.photoUrl,
                      name: displayName,
                      menuItems: [
                        ProfileMenuItem(
                          icon: Icons.person_rounded,
                          label: 'הפרופיל שלי',
                          subtitle: 'ניהול פרטים אישיים',
                          onTap: () => context.push('/profile'),
                        ),
                        ProfileMenuItem(
                          icon: Icons.campaign_rounded,
                          iconColor: AppColors.sapphire,
                          label: 'השירותים שלי',
                          subtitle: 'ניהול מודעות ושירותים',
                          onTap: onOpenMyServices,
                        ),
                        ProfileMenuItem(
                          icon: Icons.logout_rounded,
                          iconColor: Colors.redAccent,
                          label: 'יציאה',
                          subtitle: 'התנתקות מהחשבון',
                          onTap: () => FirebaseAuth.instance.signOut(),
                        ),
                      ],
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
        const ListYourServiceCTA(),

        const SizedBox(height: 24),

        const SizedBox(height: 130),
      ],
    );
  }
}
