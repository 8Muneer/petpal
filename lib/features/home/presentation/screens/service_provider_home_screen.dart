import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/utils/price_formatter.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/core/widgets/app_bottom_nav.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/section_header.dart';
import 'package:petpal/core/widgets/tiny_chip.dart';
import 'package:petpal/core/widgets/gradient_action_card.dart';
import 'package:petpal/core/widgets/empty_state_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';
import 'package:petpal/features/feed/presentation/providers/feed_provider.dart';
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

enum ProviderServiceType { dogWalk, petSitting }
enum RequestStatus { pending, accepted, declined }

class BookingRequestData {
  final String ownerName;
  final ProviderServiceType serviceType;
  final String city;
  final String whenText;
  final String priceText;
  final RequestStatus status;

  const BookingRequestData({
    required this.ownerName,
    required this.serviceType,
    required this.city,
    required this.whenText,
    required this.priceText,
    required this.status,
  });

  BookingRequestData copyWith({RequestStatus? status}) => BookingRequestData(
        ownerName: ownerName,
        serviceType: serviceType,
        city: city,
        whenText: whenText,
        priceText: priceText,
        status: status ?? this.status,
      );
}

class ChatPreviewData {
  final String name;
  final String lastMessage;
  final String timeAgo;

  const ChatPreviewData({
    required this.name,
    required this.lastMessage,
    required this.timeAgo,
  });
}

class ServiceProviderHomeScreen extends ConsumerStatefulWidget {
  const ServiceProviderHomeScreen({super.key});

  @override
  ConsumerState<ServiceProviderHomeScreen> createState() =>
      _ServiceProviderHomeScreenState();
}

class _ServiceProviderHomeScreenState extends ConsumerState<ServiceProviderHomeScreen> {
  int _currentIndex = 0;

  // Mock requests (later replace with Firestore)
  final List<BookingRequestData> _requests = [
    BookingRequestData(
      ownerName: 'מוניר',
      serviceType: ProviderServiceType.dogWalk,
      city: 'ירושלים',
      whenText: 'היום 18:30',
      priceText: '₪90',
      status: RequestStatus.pending,
    ),
    BookingRequestData(
      ownerName: 'לוג׳יין',
      serviceType: ProviderServiceType.petSitting,
      city: 'ירושלים',
      whenText: 'מחר • 2 ימים',
      priceText: '₪220',
      status: RequestStatus.pending,
    ),
    BookingRequestData(
      ownerName: 'סאמר',
      serviceType: ProviderServiceType.dogWalk,
      city: 'ירושלים',
      whenText: 'אתמול 20:00',
      priceText: '₪70',
      status: RequestStatus.accepted,
    ),
  ];

  bool _isAvailable = true;


  User? get _user => FirebaseAuth.instance.currentUser;

  String get _displayName {
    final u = _user;
    final dn = (u?.displayName ?? '').trim();
    if (dn.isNotEmpty) return dn;

    final email = (u?.email ?? '').trim();
    if (email.contains('@')) return email.split('@').first;

    return 'נותן שירות';
  }


  int get _pendingCount =>
      _requests.where((r) => r.status == RequestStatus.pending).length;

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
              child: const Text(
                'התנתקות',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _ProviderHomeTab(
        onAction: (msg) => _toast(msg),
      ),
      _ProviderDashboardTab(
        displayName: _displayName,
        isAvailable: _isAvailable,
        pendingCount: _pendingCount,
        onToggleAvailability: (v) {
          setState(() => _isAvailable = v);
          _toast(v ? 'סטטוס: זמין לקבלת בקשות' : 'סטטוס: לא זמין כרגע');
        },
        upcoming: _requests
            .where((r) => r.status == RequestStatus.accepted)
            .take(3)
            .toList(),
        onAction: (msg) => _toast(msg),
      ),
      const _ProviderWalksTab(),
      const _ProviderSittingTab(),
      _LostPetsTab(
        onAction: (msg) => _toast(msg),
      ),
      _ScheduleTab(
        isAvailable: _isAvailable,
        onToggleAvailability: (v) {
          setState(() => _isAvailable = v);
          _toast(v ? 'סטטוס: זמין לקבלת בקשות' : 'סטטוס: לא זמין כרגע');
        },
        onAction: (msg) => _toast(msg),
      ),
      const _MessagesTab(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (_currentIndex == 0)
                _ModernTopBar(
                  displayName: _displayName,
                  photoUrl: ref.watch(currentUserProfileProvider).asData?.value?.photoUrl ?? _user?.photoURL,
                  badgeText:
                      _pendingCount > 0 ? '$_pendingCount בקשות' : null,
                  onLogoutPressed: _confirmLogout,
                  onAvatarPressed: () => context.push('/profile'),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.02, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_currentIndex),
                    child: tabs[_currentIndex],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _currentIndex,
          onChanged: (i) => setState(() => _currentIndex = i),
          items: const [
            AppNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'בית',
            ),
            AppNavItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: 'לוח',
            ),
            AppNavItem(
              icon: Icons.directions_walk_outlined,
              activeIcon: Icons.directions_walk_rounded,
              label: 'טיולים',
            ),
            AppNavItem(
              icon: Icons.home_work_outlined,
              activeIcon: Icons.home_work_rounded,
              label: 'שמירה',
            ),
            AppNavItem(
              icon: Icons.pets_outlined,
              activeIcon: Icons.pets_rounded,
              label: 'אבודים',
            ),
            AppNavItem(
              icon: Icons.event_available_outlined,
              activeIcon: Icons.event_available_rounded,
              label: 'לו״ז',
            ),
            AppNavItem(
              icon: Icons.chat_bubble_outline,
              activeIcon: Icons.chat_bubble_rounded,
              label: 'צ׳אט',
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernTopBar extends StatelessWidget {
  final String displayName;
  final String? badgeText;
  final String? photoUrl;
  final VoidCallback onLogoutPressed;
  final VoidCallback onAvatarPressed;

  const _ModernTopBar({
    required this.displayName,
    required this.onLogoutPressed,
    required this.onAvatarPressed,
    this.badgeText,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Avatar — RIGHT in RTL
            AppAvatar(
              name: displayName,
              photoUrl: photoUrl,
              size: 46,
              onTap: onAvatarPressed,
            ),
            const SizedBox(width: 12),
            // Greeting
            Expanded(
              child: Text(
                'שלום, $displayName 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h3,
              ),
            ),
            // Pending badge
            if (badgeText != null) ...[
              const SizedBox(width: 8),
              TinyChip(
                text: badgeText!,
                color: AppColors.sitting,
              ),
            ],
            const SizedBox(width: 10),
            // Logout
            _PillIconButton(
              icon: Icons.logout_rounded,
              tooltip: 'התנתקות',
              onTap: onLogoutPressed,
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
    final postsAsync = ref.watch(feedPostsProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Column(
      children: [
        // Create post button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.push('/feed/create'),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.primary, AppColors.statusOpen],
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'פוסט חדש',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Feed posts
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(feedPostsProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: postsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Text('שגיאה בטעינת הפיד: $e'),
                  ),
                ),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.feed_outlined,
                                size: 64,
                                color: AppColors.textSecondary
                                    .withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text(
                              'אין פוסטים עדיין',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'משוך/י למטה לרענון',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _FeedPostCard(
                        post: post,
                        currentUid: uid,
                        onTap: () => context.push('/feed/${post.id}'),
                        onLike: () {
                          ref
                              .read(feedRepositoryProvider)
                              .toggleLike(post.id, uid);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
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
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: GlassCard(
        useBlur: true,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LiveUserAvatar(
                  uid: post.authorUid,
                  fallbackName: post.authorName,
                  fallbackPhotoUrl: post.authorPhotoUrl,
                  size: 40,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary.withOpacity(0.8),
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
                      color: AppColors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded,
                            size: 14, color: AppColors.warning),
                        SizedBox(width: 4),
                        Text(
                          'טיפ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.content,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: AppColors.borderFaint,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: AppColors.borderFaint,
                    child: const Icon(Icons.broken_image_rounded,
                        color: AppColors.textMuted),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onLike,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 20,
                          color: isLiked
                              ? AppColors.danger
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likes.length}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isLiked
                                ? AppColors.danger
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.commentCount}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderDashboardTab extends StatelessWidget {
  final String displayName;
  final bool isAvailable;
  final int pendingCount;
  final ValueChanged<bool> onToggleAvailability;
  final List<BookingRequestData> upcoming;
  final void Function(String msg) onAction;

  const _ProviderDashboardTab({
    required this.displayName,
    required this.isAvailable,
    required this.pendingCount,
    required this.onToggleAvailability,
    required this.upcoming,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        GlassCard(
          useBlur: true,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [AppColors.primary, AppColors.statusOpen],
                  ),
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'מרכז נותן שירות',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'סטטוס: ${isAvailable ? "זמין" : "לא זמין"} • $pendingCount בקשות ממתינות',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155).withOpacity(0.82),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isAvailable,
                onChanged: onToggleAvailability,
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        SectionHeader(
          title: 'סטטיסטיקות מהירות',
          subtitle: 'סיכום קצר להיום',
          trailing: TinyChip(
            text: 'LIVE',
            fill: AppColors.statusOpen.withOpacity(0.10),
            textColor: AppColors.statusOpen,
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: const [
            Expanded(
              child: _StatCard(
                title: '₪260',
                subtitle: 'היום',
                icon: Icons.payments_outlined,
                accent: Color(0xFF0EA5E9),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: '4.9',
                subtitle: 'דירוג',
                icon: Icons.star_rounded,
                accent: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: '$pendingCount',
                subtitle: 'בקשות ממתינות',
                icon: Icons.inbox_rounded,
                accent: AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: _StatCard(
                title: '3',
                subtitle: 'משימות קרובות',
                icon: Icons.event_available_rounded,
                accent: AppColors.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        SectionHeader(
          title: 'פעולות מהירות',
          subtitle: 'עדכן זמינות, שירותים ועוד',
          trailing: const TinyChip(
            text: 'חדש',
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: GradientActionCard(
                title: 'עדכן זמינות',
                subtitle: 'פתח/סגור בקשות',
                icon: Icons.toggle_on_rounded,
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.primary, AppColors.statusOpen],
                ),
                onTap: () => context.push('/provider/availability'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GradientActionCard(
                title: 'נהל שירותים',
                subtitle: 'מחירים, סוג שירות',
                icon: Icons.settings_suggest_outlined,
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                ),
                onTap: () => context.push('/provider/services'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        const SectionHeader(
          title: 'הזמנות קרובות',
          subtitle: 'רק אחרי אישור הבקשה',
        ),
        const SizedBox(height: 10),

        if (upcoming.isEmpty)
          EmptyStateCard(
            title: 'אין הזמנות קרובות עדיין',
            subtitle: 'אשר/י בקשות חדשות כדי להתחיל.',
            icon: Icons.event_busy_rounded,
            onTap: () => onAction('עבור/י לבקשות'),
          )
        else
          ...upcoming.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _UpcomingBookingCard(data: r),
            ),
          ),
      ],
    );
  }
}

// ── Provider Walks Tab ────────────────────────────────────────────────────────

class _ProviderWalksTab extends ConsumerStatefulWidget {
  const _ProviderWalksTab();

  @override
  ConsumerState<_ProviderWalksTab> createState() => _ProviderWalksTabState();
}

class _ProviderWalksTabState extends ConsumerState<_ProviderWalksTab> {
  int _selectedView = 0; // 0 = בקשות טיול, 1 = פרסם שירות

  @override
  Widget build(BuildContext context) {
    return Column(
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
                ? _ProviderRequestsView(key: const ValueKey('requests'))
                : _ProviderAdvertiseView(key: const ValueKey('advertise')),
          ),
        ),
      ],
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
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('שגיאה בטעינת הבקשות: $e')),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
              _BenefitRow(icon: Icons.location_on_rounded, text: 'הגע/י לבעלי חיות מחמד באזורך'),
              const SizedBox(height: 6),
              _BenefitRow(icon: Icons.chat_bubble_outline_rounded, text: 'קבל/י פניות ישירות'),
              const SizedBox(height: 6),
              _BenefitRow(icon: Icons.star_rounded, text: 'בנה/י את הפרופיל המקצועי שלך'),
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
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
                        color: Color(0xFF334155))),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isActive
                      ? AppColors.statusOpen.withOpacity(0.12)
                      : AppColors.warning.withOpacity(0.12),
                ),
                child: Text(
                  isActive ? 'פעיל' : 'מושהה',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isActive
                        ? AppColors.success
                        : const Color(0xFFD97706),
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
                    color: teal.withOpacity(0.08),
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
                color: AppColors.primary.withOpacity(0.05),
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
                  if (service.viewCount != null &&
                      service.requestCount != null)
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
                icon: isActive
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: isActive
                    ? const Color(0xFFD97706)
                    : teal,
                bgColor: isActive
                    ? AppColors.warning.withOpacity(0.1)
                    : teal.withOpacity(0.1),
                borderColor: isActive
                    ? AppColors.warning.withOpacity(0.35)
                    : teal.withOpacity(0.3),
                onTap: () => ref
                    .read(walkDatasourceProvider)
                    .updateWalkService(service.id, {'isActive': !isActive}),
              ),
              const SizedBox(width: 8),
              // Edit button
              _ServiceActionButton(
                label: 'ערוך',
                icon: Icons.edit_rounded,
                color: const Color(0xFF0EA5E9),
                bgColor: const Color(0xFF0EA5E9).withOpacity(0.08),
                borderColor: const Color(0xFF0EA5E9).withOpacity(0.3),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color)),
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
    Color(0xFFFFB347),
    Color(0xFFCE93D8),
    Color(0xFFF48FB1),
    Color(0xFF80DEEA),
    Color(0xFFFFCC80),
    Color(0xFF90CAF9),
    Color(0xFFA5D6A7),
    Color(0xFFEF9A9A),
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
                              size: 52,
                              color: Colors.white.withOpacity(0.6)),
                        ),
                        errorWidget: (_, __, ___) => Center(
                          child: Icon(_fallbackIcon,
                              size: 52,
                              color: Colors.white.withOpacity(0.6)),
                        ),
                      )
                    else
                      Center(
                        child: Icon(_fallbackIcon,
                            size: 60,
                            color: Colors.white.withOpacity(0.7)),
                      ),
                    // Heart icon
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_border_rounded,
                            size: 16, color: Color(0xFFEF4444)),
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
                                ? const Color(0xFFEC4899)
                                : const Color(0xFF0EA5E9),
                          ),
                        _IconChip(
                          icon: Icons.location_on_rounded,
                          label: request.area,
                          color: const Color(0xFFEF4444),
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
                          builder: (_) =>
                              _ProviderOfferSheet(request: request),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.statusOpen
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

/// Lost & Found tab
class _LostPetsTab extends StatelessWidget {
  final void Function(String msg) onAction;

  const _LostPetsTab({required this.onAction});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        const SectionHeader(
          title: 'אבודים',
          subtitle: 'דיווחים על חיות אבודות ונמצאות (בקרוב AI התאמות)',
        ),
        const SizedBox(height: 10),

        GlassCard(
          useBlur: true,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFF8B5CF6).withOpacity(0.14),
                ),
                child: const Icon(Icons.pets_rounded, color: Color(0xFF8B5CF6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lost & Found Hub',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'כאן תוכל/י לראות דיווחים ולהציע התאמות לפי מיקום ותמונה.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155).withOpacity(0.82),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),

        const SizedBox(height: 14),

        AppButton(
          label: 'דיווח על חיה נמצאה',
          leadingIcon: Icons.add_photo_alternate_rounded,
          onTap: () => onAction('TODO: Report found pet'),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'חיפוש חיה אבודה',
          leadingIcon: Icons.search_rounded,
          onTap: () => onAction('TODO: Search lost pets'),
        ),

        const SizedBox(height: 18),

        const EmptyStateCard(
          title: 'אין דיווחים עדיין',
          subtitle: 'בקרוב: התאמות חכמות לפי תמונה ומיקום.',
          icon: Icons.pets_outlined,
        ),
      ],
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onToggleAvailability;
  final void Function(String msg) onAction;

  const _ScheduleTab({
    required this.isAvailable,
    required this.onToggleAvailability,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        const SectionHeader(
          title: 'לו״ז וזמינות',
          subtitle: 'נהל/י את הזמנים והימים הפנויים',
        ),
        const SizedBox(height: 10),

        GlassCard(
          useBlur: true,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.primary.withOpacity(0.12),
                ),
                child: const Icon(Icons.event_available_rounded,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'פתוח לקבלת בקשות',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAvailable
                          ? 'המערכת תציג אותך בתוצאות החיפוש'
                          : 'לא תופיע/י בחיפוש כרגע',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155).withOpacity(0.82),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isAvailable,
                onChanged: onToggleAvailability,
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        const _SubHeader(text: 'ימים נפוצים'),
        const SizedBox(height: 10),

        Row(
          children: const [
            Expanded(child: _DayChip(text: 'א׳', selected: true)),
            SizedBox(width: 10),
            Expanded(child: _DayChip(text: 'ב׳', selected: true)),
            SizedBox(width: 10),
            Expanded(child: _DayChip(text: 'ג׳', selected: true)),
            SizedBox(width: 10),
            Expanded(child: _DayChip(text: 'ד׳', selected: false)),
            SizedBox(width: 10),
            Expanded(child: _DayChip(text: 'ה׳', selected: false)),
          ],
        ),

        const SizedBox(height: 18),

        AppButton(
          label: 'עריכת חלונות זמן',
          leadingIcon: Icons.edit_calendar_rounded,
          onTap: () => context.push('/provider/availability'),
        ),

        const SizedBox(height: 18),

        const _SubHeader(text: 'חלונות זמן לדוגמה'),
        const SizedBox(height: 10),

        const _TimeSlotCard(
          title: 'היום',
          subtitle: '16:00–20:00',
          accent: Color(0xFF0EA5E9),
        ),
        const SizedBox(height: 12),
        const _TimeSlotCard(
          title: 'מחר',
          subtitle: '10:00–13:00',
          accent: AppColors.statusOpen,
        ),
      ],
    );
  }
}

class _MessagesTab extends ConsumerWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid =
        ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
    final async = ref.watch(conversationsProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (convos) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
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

class _UpcomingBookingCard extends StatelessWidget {
  final BookingRequestData data;

  const _UpcomingBookingCard({required this.data});

  IconData get _typeIcon {
    switch (data.serviceType) {
      case ProviderServiceType.dogWalk:
        return Icons.directions_walk_rounded;
      case ProviderServiceType.petSitting:
        return Icons.home_work_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      useBlur: true,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppColors.primary.withOpacity(0.12),
            ),
            child: Icon(_typeIcon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.ownerName} • ${data.city}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.whenText} • ${data.priceText}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155).withOpacity(0.82),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      useBlur: true,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: accent.withOpacity(0.14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155).withOpacity(0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSlotCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;

  const _TimeSlotCard({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      useBlur: true,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: accent.withOpacity(0.14),
            ),
            child: Icon(Icons.schedule_rounded, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155).withOpacity(0.82),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String text;

  const _SubHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String text;
  final bool selected;

  const _DayChip({required this.text, required this.selected});

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary : AppColors.borderFaint;
    final fg = selected ? Colors.white : const Color(0xFF334155);

    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: bg,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }
}

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
          child: Center(
            child: Icon(icon, color: const Color(0xFF334155)),
          ),
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
      router.push('/chat/$convoId', extra: {'otherName': req.ownerName, 'otherPhotoUrl': ownerPhotoUrl, 'otherUid': req.ownerUid});
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
                  color: AppColors.primary.withOpacity(0.06),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.15)),
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
            color: Color(0xFF334155),
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
                color: Color(0xFF334155))),
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
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
        prefixText: prefix,
        prefixStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
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
    return Column(
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
                ? _ProviderSittingRequestsView(
                    key: const ValueKey('sitting_req'))
                : _ProviderSittingAdvertiseView(
                    key: const ValueKey('sitting_adv')),
          ),
        ),
      ],
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
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.5)),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                          colors: [AppColors.sitting, Color(0xFFA78BFA)]),
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
              _BenefitRow(
                  icon: Icons.location_on_rounded,
                  text: 'הגע/י לבעלי חיות מחמד באזורך'),
              const SizedBox(height: 6),
              _BenefitRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  text: 'קבל/י פניות ישירות'),
              const SizedBox(height: 6),
              _BenefitRow(
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
                      colors: [AppColors.sitting, Color(0xFFA78BFA)],
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
          loading: () => const Center(
              child: CircularProgressIndicator(color: purple)),
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
    Color(0xFFCE93D8),
    Color(0xFF80DEEA),
    Color(0xFFFFB347),
    Color(0xFFF48FB1),
    Color(0xFFA5D6A7),
    Color(0xFF90CAF9),
    Color(0xFFFFCC80),
    Color(0xFFEF9A9A),
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
                              size: 52,
                              color: Colors.white.withOpacity(0.6)),
                        ),
                        errorWidget: (_, __, ___) => Center(
                          child: Icon(_fallbackIcon,
                              size: 52,
                              color: Colors.white.withOpacity(0.6)),
                        ),
                      )
                    else
                      Center(
                        child: Icon(_fallbackIcon,
                            size: 60,
                            color: Colors.white.withOpacity(0.7)),
                      ),
                    // Heart icon
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_border_rounded,
                            size: 16, color: Color(0xFFEF4444)),
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
                                ? const Color(0xFFEC4899)
                                : const Color(0xFF0EA5E9),
                          ),
                        _IconChip(
                          icon: Icons.location_on_rounded,
                          label: request.area,
                          color: const Color(0xFFEF4444),
                        ),
                        if (request.numberOfNights > 0)
                          _IconChip(
                            icon: Icons.nights_stay_rounded,
                            label: '${request.numberOfNights} לילות',
                            color: const Color(0xFF6366F1),
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
                                Color(0xFFA78BFA),
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
                  color: purple.withOpacity(0.06),
                  border: Border.all(color: purple.withOpacity(0.15)),
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
                hint: 'לדוגמה: אני זמין בתאריכים אלה. יש לי ניסיון עם חיות כמו שלך...',
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
                              const Color(0xFFA78BFA),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isActive
                      ? AppColors.statusOpen.withOpacity(0.12)
                      : AppColors.warning.withOpacity(0.12),
                ),
                child: Text(
                  isActive ? 'פעיל' : 'מושהה',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isActive
                        ? AppColors.success
                        : const Color(0xFFD97706),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: purple.withOpacity(0.08),
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
                onTap: () => context.push('/sitting/service/create',
                    extra: service),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: purple.withOpacity(0.4)),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isActive
                        ? AppColors.warning.withOpacity(0.12)
                        : purple.withOpacity(0.12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 14,
                        color: isActive
                            ? const Color(0xFFD97706)
                            : purple,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'השהה' : 'הפעל',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isActive
                              ? const Color(0xFFD97706)
                              : purple,
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
