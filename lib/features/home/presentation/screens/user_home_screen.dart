import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/glass_nav_bar.dart';
import 'package:petpal/core/widgets/petpal_scaffold.dart';
import 'package:petpal/core/widgets/primary_gradient_button.dart';
import 'package:petpal/core/widgets/section_header.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';
import 'package:petpal/features/feed/presentation/providers/feed_provider.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart'
    show SittingRequest, SittingStatus, SittingType;
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';
import 'package:petpal/core/widgets/empty_state_card.dart';
import 'package:petpal/core/utils/price_formatter.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart';
import 'package:petpal/features/walks/domain/entities/walk_service.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';

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

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen>
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
        backgroundColor: const Color(0xFF0F766E),
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
                backgroundColor: const Color(0xFF0F766E),
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
      _LostPetsTab(
        onAction: (msg) => _toast(msg),
      ),
      const _WalksTab(),
      _SittingTab(
        onAction: (msg) => _toast(msg),
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PetPalScaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (_currentIndex == 0)
                _ModernTopBar(
                  displayName: _displayName,
                  photoUrl: _user?.photoURL,
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

        // Floating glass bottom nav
        bottomNavigationBar: GlassNavBar(
          currentIndex: _currentIndex,
          onChanged: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'בית',
            ),
            NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets_rounded),
              label: 'אבודים',
            ),
            NavigationDestination(
              icon: Icon(Icons.directions_walk_outlined),
              selectedIcon: Icon(Icons.directions_walk_rounded),
              label: 'טיולים',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_work_outlined),
              selectedIcon: Icon(Icons.home_work_rounded),
              label: 'שמירה',
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

  String get _initial {
    final s = displayName.trim();
    if (s.isEmpty) return 'P';
    return s.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: GlassCard(
        useBlur: true,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Profile avatar — RIGHT side in RTL (first child)
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onProfilePressed,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: photoUrl != null && photoUrl!.isNotEmpty
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
                        ),
                  image: photoUrl != null && photoUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(photoUrl!), fit: BoxFit.cover)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: photoUrl != null && photoUrl!.isNotEmpty
                    ? null
                    : Center(
                        child: Text(
                          _initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Greeting — CENTER
            Expanded(
              child: Text(
                'שלום, $displayName 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Logout — LEFT side in RTL (last child)
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
                  colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
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
            color: const Color(0xFF0F766E),
            onRefresh: () async {
              ref.invalidate(feedPostsProvider);
              // Wait a moment for the stream to re-establish
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: postsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF0F766E)),
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
                                color: const Color(0xFF64748B)
                                    .withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text(
                              'אין פוסטים עדיין',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'משוך/י למטה לרענון',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF94A3B8),
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: post.authorPhotoUrl != null &&
                            post.authorPhotoUrl!.isNotEmpty
                        ? null
                        : const LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
                          ),
                    image: post.authorPhotoUrl != null &&
                            post.authorPhotoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(post.authorPhotoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: post.authorPhotoUrl != null &&
                          post.authorPhotoUrl!.isNotEmpty
                      ? null
                      : Center(
                          child: Text(
                            post.authorName.isNotEmpty
                                ? post.authorName.characters.first.toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
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
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B).withOpacity(0.8),
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
                color: Color(0xFF0F172A),
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
                    color: const Color(0xFFF1F5F9),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0F766E),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.broken_image_rounded,
                        color: Color(0xFF94A3B8)),
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
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likes.length}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isLiked
                                ? const Color(0xFFFB7185)
                                : const Color(0xFF64748B),
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
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.commentCount}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF64748B),
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? const Color(0xFF0F766E) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: selected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: selected ? Colors.white : const Color(0xFF64748B),
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
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.push('/walks/create'),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'בקשת טיול חדשה',
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

        // Requests list
        Expanded(
          child: requestsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F766E)),
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
                          color: const Color(0xFF64748B).withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'אין בקשות טיול עדיין',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'לחץ/י על הכפתור למעלה כדי לפרסם בקשה',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: requests.length + 1, // +1 for the header
                itemBuilder: (context, index) {
                  // Header row: "הבקשות שלי (X)"
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.list_alt_rounded,
                              size: 16, color: Color(0xFF0F766E)),
                          const SizedBox(width: 6),
                          Text(
                            'הבקשות שלי (${requests.length})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final req = requests[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WalkRequestCard(request: req),
                  );
                },
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
  const _WalkRequestCard({required this.request});

  IconData get _petIcon {
    switch (request.petType) {
      case PetType.dog:
        return Icons.directions_walk_rounded;
      case PetType.cat:
        return Icons.pets_rounded;
      case PetType.other:
        return Icons.cruelty_free_rounded;
    }
  }

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

  String get _timeAgo {
    if (request.createdAt == null) return '';
    final diff = DateTime.now().difference(request.createdAt!);
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק׳';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
    if (diff.inDays < 7) return 'לפני ${diff.inDays} ימים';
    return '${request.createdAt!.day}/${request.createdAt!.month}/${request.createdAt!.year}';
  }

  bool get _isOpen => request.status == WalkStatus.open;

  String get _genderSuffix {
    if (request.petGender == PetGender.male) return ' · זכר';
    if (request.petGender == PetGender.female) return ' · נקבה';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = request.preferredDate != null
        ? '${request.preferredDate!.day.toString().padLeft(2, '0')}/${request.preferredDate!.month.toString().padLeft(2, '0')}'
        : '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GlassCard(
        useBlur: true,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: request.ownerPhotoUrl != null && request.ownerPhotoUrl!.isNotEmpty
                        ? null
                        : const LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
                          ),
                    image: request.ownerPhotoUrl != null && request.ownerPhotoUrl!.isNotEmpty
                        ? DecorationImage(image: NetworkImage(request.ownerPhotoUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: request.ownerPhotoUrl != null && request.ownerPhotoUrl!.isNotEmpty
                      ? null
                      : Center(
                          child: Text(
                            request.ownerName.isNotEmpty ? request.ownerName.characters.first.toUpperCase() : 'P',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.ownerName,
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 13)),
                      Text(_timeAgo,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isOpen
                        ? const Color(0xFF22C55E).withOpacity(0.12)
                        : const Color(0xFF94A3B8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _isOpen
                            ? const Color(0xFF22C55E).withOpacity(0.4)
                            : const Color(0xFF94A3B8).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          _isOpen ? Icons.circle : Icons.check_circle_outline_rounded,
                          size: 8,
                          color: _isOpen ? const Color(0xFF22C55E) : const Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(_isOpen ? 'פתוח' : 'הושלם',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: _isOpen ? const Color(0xFF16A34A) : const Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),

            // ── Pet photo ────────────────────────────────────────────────
            if (request.petImageUrl != null && request.petImageUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: request.petImageUrl!,
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      height: 100,
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                          child: CircularProgressIndicator(color: Color(0xFF0F766E), strokeWidth: 2))),
                  errorWidget: (_, __, ___) => Container(
                      height: 100,
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8))),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // ── Pet name + type/gender ───────────────────────────────────
            Row(
              children: [
                Icon(_petIcon, size: 15, color: const Color(0xFF0F766E)),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(request.petName,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
                Text('$_petTypeLabel$_genderSuffix',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              ],
            ),

            const SizedBox(height: 8),

            // ── Compact info row ─────────────────────────────────────────
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                if (dateStr.isNotEmpty) _MiniInfo(icon: Icons.calendar_today_rounded, text: dateStr),
                _MiniInfo(icon: Icons.access_time_rounded, text: request.preferredTime),
                _MiniInfo(icon: Icons.location_on_outlined, text: request.area),
                if (request.budget != null && request.budget!.isNotEmpty)
                  _MiniInfo(icon: Icons.account_balance_wallet_outlined, text: request.budget!),
              ],
            ),

            const SizedBox(height: 12),

            // ── View details button ──────────────────────────────────────
            GestureDetector(
              onTap: () => context.push('/walks/detail', extra: request),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('הצג פרטים',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white),
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


// ── Small icon + text label used in the compact card ─────────────────────────
class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _LabeledChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _LabeledChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkServicesView extends ConsumerWidget {
  const _WalkServicesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(walkServicesProvider);
    return servicesAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0F766E))),
      error: (e, _) => const Center(
        child: Text('שגיאה בטעינת השירותים',
            style: TextStyle(
                color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
      ),
      data: (services) {
        if (services.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: const [
              EmptyStateCard(
                title: 'אין שירותי טיולים כרגע',
                subtitle: 'בקרוב יופיעו כאן ספקי שירות באזורך',
                icon: Icons.directions_walk_rounded,
              ),
            ],
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: services.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _WalkServiceCard(service: services[index]),
          ),
        );
      },
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
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.push('/sitting/create'),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'בקשת שמירה חדשה',
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
                          color: const Color(0xFF64748B).withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'אין בקשות שמירה עדיין',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'לחץ/י על הכפתור למעלה כדי לפרסם בקשה',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: requests.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
                    );
                  }

                  final req = requests[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SittingRequestCard(request: req),
                  );
                },
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
  const _SittingRequestCard({required this.request});

  IconData get _petIcon {
    switch (request.petType) {
      case PetType.dog:
        return Icons.directions_walk_rounded;
      case PetType.cat:
        return Icons.pets_rounded;
      case PetType.other:
        return Icons.cruelty_free_rounded;
    }
  }

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

  String get _timeAgo {
    if (request.createdAt == null) return '';
    final diff = DateTime.now().difference(request.createdAt!);
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק׳';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
    if (diff.inDays < 7) return 'לפני ${diff.inDays} ימים';
    return '${request.createdAt!.day}/${request.createdAt!.month}/${request.createdAt!.year}';
  }

  bool get _isOpen => request.status == SittingStatus.open;

  String get _genderSuffix {
    if (request.petGender == PetGender.male) return ' · זכר';
    if (request.petGender == PetGender.female) return ' · נקבה';
    return '';
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final startStr =
        request.startDate != null ? _formatDate(request.startDate!) : '';
    final endStr =
        request.endDate != null ? _formatDate(request.endDate!) : '';
    final nights = request.numberOfNights;
    final sittingTypeLabel = request.sittingType == SittingType.atOwnerHome
        ? 'בבית הבעלים'
        : 'בבית השומר/ת';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GlassCard(
        useBlur: true,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: request.ownerPhotoUrl != null &&
                            request.ownerPhotoUrl!.isNotEmpty
                        ? null
                        : const LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                          ),
                    image: request.ownerPhotoUrl != null &&
                            request.ownerPhotoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(request.ownerPhotoUrl!),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: request.ownerPhotoUrl != null &&
                          request.ownerPhotoUrl!.isNotEmpty
                      ? null
                      : Center(
                          child: Text(
                            request.ownerName.isNotEmpty
                                ? request.ownerName.characters.first
                                    .toUpperCase()
                                : 'P',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.ownerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              fontSize: 13)),
                      Text(_timeAgo,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isOpen
                        ? const Color(0xFF7C3AED).withOpacity(0.12)
                        : const Color(0xFF94A3B8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _isOpen
                            ? const Color(0xFF7C3AED).withOpacity(0.4)
                            : const Color(0xFF94A3B8).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          _isOpen
                              ? Icons.circle
                              : Icons.check_circle_outline_rounded,
                          size: 8,
                          color: _isOpen
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(_isOpen ? 'פתוח' : 'הושלם',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: _isOpen
                                  ? const Color(0xFF7C3AED)
                                  : const Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),

            // ── Pet photo ────────────────────────────────────────────────
            if (request.petImageUrl != null &&
                request.petImageUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: request.petImageUrl!,
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      height: 100,
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF7C3AED), strokeWidth: 2))),
                  errorWidget: (_, __, ___) => Container(
                      height: 100,
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.broken_image_rounded,
                          color: Color(0xFF94A3B8))),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // ── Pet name + type/gender ───────────────────────────────────
            Row(
              children: [
                Icon(_petIcon, size: 15, color: const Color(0xFF7C3AED)),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(request.petName,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A)))),
                Text('$_petTypeLabel$_genderSuffix',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B))),
              ],
            ),

            const SizedBox(height: 8),

            // ── Compact info row ─────────────────────────────────────────
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                if (startStr.isNotEmpty && endStr.isNotEmpty)
                  _MiniInfo(
                      icon: Icons.date_range_rounded,
                      text: '$startStr – $endStr'),
                if (nights > 0)
                  _MiniInfo(
                      icon: Icons.nights_stay_rounded,
                      text: '$nights לילות'),
                _MiniInfo(
                    icon: request.sittingType == SittingType.atOwnerHome
                        ? Icons.home_rounded
                        : Icons.house_rounded,
                    text: sittingTypeLabel),
                _MiniInfo(
                    icon: Icons.location_on_outlined, text: request.area),
                if (request.budget != null && request.budget!.isNotEmpty)
                  _MiniInfo(
                      icon: Icons.account_balance_wallet_outlined,
                      text: request.budget!),
              ],
            ),

            const SizedBox(height: 12),

            // ── View details button ──────────────────────────────────────
            GestureDetector(
              onTap: () =>
                  context.push('/sitting/detail', extra: request),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('הצג פרטים',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: Colors.white),
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

class _SittingServicesView extends ConsumerWidget {
  const _SittingServicesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(sittingServicesProvider);
    return servicesAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (services) {
        if (services.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_work_rounded,
                    size: 64,
                    color: const Color(0xFF64748B).withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text('אין שירותי שמירה זמינים כרגע',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF64748B))),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: services.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: SectionHeader(
                  title: 'שירותי שמירה',
                  subtitle: 'מצא/י שומר/ת חיות קרוב/ה ובזמינות מהירה',
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SittingServiceCard(service: services[index - 1]),
            );
          },
        );
      },
    );
  }
}

class _SittingServiceCard extends StatelessWidget {
  final SittingService service;
  const _SittingServiceCard({required this.service});

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
    return m == 1 ? 'לפני חודש' : 'לפני $m חודשים';
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7C3AED);
    const blue = Color(0xFF0EA5E9);
    const amber = Color(0xFFD97706);
    final displayPrice = formatPrice(service.priceText, service.priceType);

    return GlassCard(
      useBlur: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  color: purple.withOpacity(0.12),
                ),
                child: service.providerPhotoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: CachedNetworkImage(
                          imageUrl: service.providerPhotoUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: purple),
                        ),
                      )
                    : const Icon(Icons.person_rounded,
                        color: purple, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.providerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 3),
                    if (service.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(service.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A))),
                          if (service.reviewCount != null)
                            Text(' (${service.reviewCount})',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF94A3B8))),
                        ],
                      )
                    else if (service.createdAt != null)
                      Text(_timeAgo(service.createdAt!),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8))),
                    const SizedBox(height: 4),
                    Text(displayPrice,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: purple)),
                  ],
                ),
              ),
              if (service.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF22C55E).withOpacity(0.1),
                    border: Border.all(
                        color: const Color(0xFF22C55E).withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 6, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text('זמין',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Info chips ────────────────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _ServiceChip(
                  icon: Icons.location_on_rounded,
                  label: service.area,
                  color: purple),
              _ServiceChip(
                  icon: Icons.home_work_rounded,
                  label: service.sittingLocation,
                  color: blue),
              ...service.petTypes.map((type) {
                IconData icon;
                switch (type) {
                  case 'כלב':
                    icon = Icons.directions_walk_rounded;
                    break;
                  case 'חתול':
                    icon = Icons.pets_rounded;
                    break;
                  default:
                    icon = Icons.cruelty_free_rounded;
                }
                return _ServiceChip(
                    icon: icon, label: type, color: purple);
              }),
              if (service.availableDays.isNotEmpty)
                _ServiceChip(
                  icon: Icons.calendar_today_rounded,
                  label: service.availableDays.length == 7
                      ? 'כל הימים'
                      : service.availableDays.join(' '),
                  color: amber,
                ),
            ],
          ),

          if (service.bio != null && service.bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(service.bio!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                    height: 1.5)),
          ],

          // ── Contact button ────────────────────────────────────────────
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text('צור קשר',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class _LostPetsTab extends StatelessWidget {
  final void Function(String msg) onAction;

  const _LostPetsTab({required this.onAction});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        const SectionHeader(
          title: 'חיות אבודות',
          subtitle: 'דיווחים מהקהילה + התאמות AI בהמשך',
        ),
        const SizedBox(height: 10),

        const _LostPetModernCard(
          title: 'כלב אבוד - רקס',
          subtitle: 'נראה לאחרונה בשכונת בית הכרם',
          timeAgo: 'לפני 2 שעות',
          accent: Color(0xFFFB7185),
        ),
        const SizedBox(height: 12),
        const _LostPetModernCard(
          title: 'חתולה נמצאה - לולה',
          subtitle: 'נמצאה ליד גן סאקר',
          timeAgo: 'אתמול',
          accent: Color(0xFF60A5FA),
        ),
        const SizedBox(height: 18),

        PrimaryGradientButton(
          text: 'דווח/י על חיה אבודה',
          icon: Icons.add_rounded,
          onTap: () => onAction('TODO: Report lost pet'),
        ),
      ],
    );
  }
}

class _LostPetModernCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timeAgo;
  final Color accent;

  const _LostPetModernCard({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  accent.withOpacity(0.95),
                  accent.withOpacity(0.55),
                ],
              ),
            ),
            child: const Icon(Icons.pets_rounded, color: Colors.white),
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
                    color: Color(0xFF0F172A),
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
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              timeAgo,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _MiniPrimaryButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
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
            color: const Color(0xFFF1F5F9),
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

class _WalkServiceCard extends StatelessWidget {
  final WalkService service;
  const _WalkServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF0F766E);
    const blue = Color(0xFF0EA5E9);
    const purple = Color(0xFF7C3AED);
    final displayPrice = formatPrice(service.priceText, service.priceType);
    final isExperienced = (service.reviewCount ?? 0) > 0;

    return GlassCard(
      useBlur: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: avatar + name + rating + availability ────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  color: teal.withOpacity(0.12),
                ),
                child: service.providerPhotoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: CachedNetworkImage(
                          imageUrl: service.providerPhotoUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _AvatarFallback(
                              name: service.providerName, color: teal),
                        ),
                      )
                    : _AvatarFallback(
                        name: service.providerName, color: teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.providerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Rating row (shown only when available)
                    if (service.rating != null)
                      _RatingRow(
                        rating: service.rating!,
                        reviewCount: service.reviewCount,
                      )
                    else if (service.createdAt != null)
                      Text(
                        _timeAgo(service.createdAt!),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Price — large and prominent
                    Text(
                      displayPrice,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: teal,
                      ),
                    ),
                  ],
                ),
              ),
              // Availability badge
              if (service.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF22C55E).withOpacity(0.1),
                    border: Border.all(
                        color: const Color(0xFF22C55E).withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 6, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text('זמין',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF16A34A),
                          )),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Info chips ───────────────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _ServiceChip(
                  icon: Icons.location_on_rounded,
                  label: service.area,
                  color: teal),
              _ServiceChip(
                  icon: Icons.timer_rounded,
                  label: service.duration,
                  color: blue),
              ...service.petTypes.map((type) {
                IconData icon;
                switch (type) {
                  case 'כלב':
                    icon = Icons.directions_walk_rounded;
                    break;
                  case 'חתול':
                    icon = Icons.pets_rounded;
                    break;
                  default:
                    icon = Icons.cruelty_free_rounded;
                }
                return _ServiceChip(icon: icon, label: type, color: purple);
              }),
              if (service.availableDays.isNotEmpty)
                _ServiceChip(
                  icon: Icons.calendar_today_rounded,
                  label: service.availableDays.length == 7
                      ? 'כל הימים'
                      : service.availableDays.join(' '),
                  color: const Color(0xFFD97706),
                ),
            ],
          ),

          // ── Trust badges ─────────────────────────────────────────────
          if (isExperienced) ...[
            const SizedBox(height: 8),
            _TrustBadge(
              icon: Icons.verified_rounded,
              label: 'מנוסה',
              color: const Color(0xFF0F766E),
            ),
          ],

          // ── Bio ──────────────────────────────────────────────────────
          if (service.bio != null && service.bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              service.bio!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155).withOpacity(0.8),
                height: 1.45,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ── CTA ──────────────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  content: const Text('פיצ׳ר הצ׳אט בקרוב!'),
                  backgroundColor: teal,
                ),
              );
            },
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: teal.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 7),
                    Text('צור קשר',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared reusable widgets ───────────────────────────────────────────────────

class _AvatarFallback extends StatelessWidget {
  final String name;
  final Color color;
  const _AvatarFallback({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
            fontWeight: FontWeight.w900, color: color, fontSize: 20),
      ),
    );
  }
}

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
            color: Color(0xFF0F172A),
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 3),
          Text(
            '($reviewCount)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ],
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ServiceChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      constraints: const BoxConstraints(minHeight: 28),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TrustBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
