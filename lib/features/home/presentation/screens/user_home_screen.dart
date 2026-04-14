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
import 'package:petpal/features/feed/domain/entities/feed_post.dart';
import 'package:petpal/features/feed/presentation/providers/feed_provider.dart';
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
    final tabs = <Widget>[
      _HomeTab(
        onAction: (msg) => _toast(msg),
      ),
      const LostFoundFeedScreen(),
      const _WalksTab(),
      _SittingTab(
        onAction: (msg) => _toast(msg),
      ),
      const _ChatTab(),
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
                  onProfilePressed: () => context.push('/profile'),
                  onLogoutPressed: _confirmLogout,
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
              icon: Icons.pets_outlined,
              activeIcon: Icons.pets_rounded,
              label: 'אבודים',
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

class _ModernTopBar extends StatelessWidget {
  final String displayName;
  final String? photoUrl;
  final VoidCallback onProfilePressed;
  final VoidCallback onLogoutPressed;

  const _ModernTopBar({
    required this.displayName,
    required this.onProfilePressed,
    required this.onLogoutPressed,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Avatar
          AppAvatar(
            name: displayName,
            photoUrl: photoUrl,
            size: 44,
            onTap: onProfilePressed,
          ),
          const SizedBox(width: 12),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'שלום, $displayName 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h3,
                ),
                Text(
                  'מה תרצה/י לעשות היום?',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Logout button
          _PillIconButton(
            icon: Icons.logout_rounded,
            tooltip: 'התנתקות',
            onTap: onLogoutPressed,
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  final void Function(String msg) onAction;

  const _HomeTab({
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
          child: AppButton(
            label: 'פוסט חדש',
            leadingIcon: Icons.add_rounded,
            onTap: () => context.push('/feed/create'),
          ),
        ),
        const SizedBox(height: 10),

        // Feed posts
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(feedPostsProvider);
              // Wait a moment for the stream to re-establish
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
            // Author row
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
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded,
                            size: 14, color: Color(0xFFF59E0B)),
                        SizedBox(width: 4),
                        Text(
                          'טיפ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Content
            Text(
              post.content,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),

            // Optional image
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

            // Actions row
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
                              ? const Color(0xFFFB7185)
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likes.length}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isLiked
                                ? const Color(0xFFFB7185)
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
                ? _WalkRequestsView(key: const ValueKey('requests'))
                : _WalkServicesView(key: const ValueKey('services')),
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
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
    Color(0xFFFFB347), Color(0xFF80DEEA), Color(0xFFCE93D8),
    Color(0xFFF48FB1), Color(0xFF90CAF9), Color(0xFFA5D6A7),
    Color(0xFFFFCC80), Color(0xFFEF9A9A),
  ];

  bool get _isOpen => request.status == WalkStatus.open;

  String get _petTypeLabel {
    switch (request.petType) {
      case PetType.dog: return 'כלב';
      case PetType.cat: return 'חתול';
      case PetType.other: return 'אחר';
    }
  }

  String get _genderLabel {
    if (request.petGender == PetGender.male) return 'זכר';
    if (request.petGender == PetGender.female) return 'נקבה';
    return '';
  }

  IconData get _fallbackIcon {
    switch (request.petType) {
      case PetType.dog: return Icons.directions_walk_rounded;
      case PetType.cat: return Icons.pets_rounded;
      case PetType.other: return Icons.cruelty_free_rounded;
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
                              size: 60,
                              color: Colors.white.withOpacity(0.7))),
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
                          gradient: AppColors.walksGradient,
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
                ? _SittingRequestsView(key: const ValueKey('sitting_requests'))
                : _SittingServicesView(
                    key: const ValueKey('sitting_services'),
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
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
  const _SittingRequestCard(
      {required this.request, required this.colorIndex});

  static const _bgColors = [
    Color(0xFFCE93D8), Color(0xFF80DEEA), Color(0xFFFFB347),
    Color(0xFFF48FB1), Color(0xFF90CAF9), Color(0xFFA5D6A7),
    Color(0xFFFFCC80), Color(0xFFEF9A9A),
  ];

  bool get _isOpen => request.status == SittingStatus.open;

  String get _petTypeLabel {
    switch (request.petType) {
      case PetType.dog: return 'כלב';
      case PetType.cat: return 'חתול';
      case PetType.other: return 'אחר';
    }
  }

  String get _genderLabel {
    if (request.petGender == PetGender.male) return 'זכר';
    if (request.petGender == PetGender.female) return 'נקבה';
    return '';
  }

  IconData get _fallbackIcon {
    switch (request.petType) {
      case PetType.dog: return Icons.directions_walk_rounded;
      case PetType.cat: return Icons.pets_rounded;
      case PetType.other: return Icons.cruelty_free_rounded;
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
                              size: 60,
                              color: Colors.white.withOpacity(0.7))),
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
    const accent = Color(0xFF7C3AED);
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
                    color: accent.withOpacity(0.07),
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
                      border: Border.all(
                          color: const Color(0xFFFED7AA)),
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
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: Colors.white,
                                    size: 18),
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
                    color: accent.withOpacity(0.07),
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
                      border: Border.all(
                          color: const Color(0xFFFED7AA)),
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
                          colors: [
                            AppColors.primary,
                            AppColors.statusOpen
                          ]),
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
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: Colors.white,
                                    size: 18),
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
    );
  }
}
