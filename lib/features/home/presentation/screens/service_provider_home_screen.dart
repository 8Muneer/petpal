import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/section_header.dart';
import 'package:petpal/core/widgets/tiny_chip.dart';
import 'package:petpal/core/widgets/primary_gradient_button.dart';
import 'package:petpal/core/widgets/gradient_action_card.dart';
import 'package:petpal/core/widgets/empty_state_card.dart';
import 'package:petpal/core/widgets/petpal_scaffold.dart';
import 'package:petpal/core/widgets/glass_nav_bar.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';
import 'package:petpal/features/feed/presentation/providers/feed_provider.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';

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

class ServiceProviderHomeScreen extends StatefulWidget {
  const ServiceProviderHomeScreen({super.key});

  @override
  State<ServiceProviderHomeScreen> createState() =>
      _ServiceProviderHomeScreenState();
}

class _ServiceProviderHomeScreenState extends State<ServiceProviderHomeScreen> {
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

  // Mock chats
  final List<ChatPreviewData> _chats = const [
    ChatPreviewData(
      name: 'מוניר',
      lastMessage: 'מעולה, נפגש בכניסה לבניין 😊',
      timeAgo: 'לפני 5 דק׳',
    ),
    ChatPreviewData(
      name: 'לוג׳יין',
      lastMessage: 'יש לך ניסיון עם חתולים?',
      timeAgo: 'לפני שעה',
    ),
    ChatPreviewData(
      name: 'סאמר',
      lastMessage: 'תודה רבה על הטיול!',
      timeAgo: 'אתמול',
    ),
  ];

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
      _MessagesTab(
        chats: _chats,
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
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'לוח',
            ),
            NavigationDestination(
              icon: Icon(Icons.directions_walk_outlined),
              selectedIcon: Icon(Icons.directions_walk_rounded),
              label: 'טיולים',
            ),
            NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets_rounded),
              label: 'אבודים',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_available_outlined),
              selectedIcon: Icon(Icons.event_available_rounded),
              label: 'לו״ז',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
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
              onTap: onAvatarPressed,
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
            // Pending badge (optional)
            if (badgeText != null) ...[
              const SizedBox(width: 8),
              TinyChip(
                text: badgeText!,
                fill: const Color(0xFF0EA5E9).withOpacity(0.10),
                textColor: const Color(0xFF0EA5E9),
              ),
            ],
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
            Text(
              post.content,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
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
                    colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
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
                        color: Color(0xFF0F172A),
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
                activeColor: const Color(0xFF0F766E),
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
            fill: const Color(0xFF22C55E).withOpacity(0.10),
            textColor: const Color(0xFF22C55E),
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
                accent: Color(0xFFF59E0B),
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
                accent: const Color(0xFFFB7185),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: _StatCard(
                title: '3',
                subtitle: 'משימות קרובות',
                icon: Icons.event_available_rounded,
                accent: Color(0xFF0F766E),
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
                  colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
                ),
                onTap: () => onAction('TODO: Availability flow'),
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
                onTap: () => onAction('TODO: Services settings'),
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

class _ProviderWalksTab extends ConsumerWidget {
  const _ProviderWalksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(openWalkRequestsProvider);

    return Column(
      children: [
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
                        'אין בקשות טיול פתוחות כרגע',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'כשבעל חיה יפרסם בקשה — תופיע כאן',
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
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                itemCount: requests.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SectionHeader(
                        title: 'בקשות טיול פתוחות',
                        subtitle: '${requests.length} בקשות זמינות כרגע',
                      ),
                    );
                  }
                  final req = requests[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProviderWalkRequestCard(request: req),
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

class _ProviderWalkRequestCard extends StatelessWidget {
  final WalkRequest request;
  const _ProviderWalkRequestCard({required this.request});

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
            // ── Owner row ────────────────────────────────────────────────
            Row(
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
                            colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
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
                // Open badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF22C55E).withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Color(0xFF22C55E)),
                      SizedBox(width: 4),
                      Text('פתוח',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF16A34A))),
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
                              color: Color(0xFF0F766E), strokeWidth: 2))),
                  errorWidget: (_, __, ___) => Container(
                      height: 100,
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.broken_image_rounded,
                          color: Color(0xFF94A3B8))),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // ── Pet name + type ──────────────────────────────────────────
            Row(
              children: [
                Icon(_petIcon, size: 15, color: const Color(0xFF0F766E)),
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

            // ── Info chips ───────────────────────────────────────────────
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                if (dateStr.isNotEmpty)
                  _MiniInfo(
                      icon: Icons.calendar_today_rounded, text: dateStr),
                _MiniInfo(
                    icon: Icons.access_time_rounded,
                    text: request.preferredTime),
                _MiniInfo(
                    icon: Icons.timer_outlined, text: request.duration),
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
                  context.push('/walks/detail', extra: request),
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
        Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B))),
      ],
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
                        color: Color(0xFF0F172A),
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
              const Icon(Icons.arrow_back_rounded, color: Color(0xFF64748B)),
            ],
          ),
        ),

        const SizedBox(height: 14),

        PrimaryGradientButton(
          text: 'דיווח על חיה נמצאה',
          icon: Icons.add_photo_alternate_rounded,
          onTap: () => onAction('TODO: Report found pet'),
        ),
        const SizedBox(height: 12),
        PrimaryGradientButton(
          text: 'חיפוש חיה אבודה',
          icon: Icons.search_rounded,
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
                  color: const Color(0xFF0F766E).withOpacity(0.12),
                ),
                child: const Icon(Icons.event_available_rounded,
                    color: Color(0xFF0F766E)),
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
                        color: Color(0xFF0F172A),
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
                activeColor: const Color(0xFF0F766E),
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

        PrimaryGradientButton(
          text: 'עריכת חלונות זמן',
          icon: Icons.edit_calendar_rounded,
          onTap: () => onAction('TODO: Edit time slots'),
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
          accent: Color(0xFF22C55E),
        ),
      ],
    );
  }
}

class _MessagesTab extends StatelessWidget {
  final List<ChatPreviewData> chats;
  final void Function(String msg) onAction;

  const _MessagesTab({required this.chats, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        const SectionHeader(
          title: 'צ׳אט',
          subtitle: 'שיחות עם בעלי חיות המחמד',
        ),
        const SizedBox(height: 10),
        ...chats.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ChatCard(
              data: c,
              onTap: () => onAction('TODO: Open chat with ${c.name}'),
            ),
          ),
        ),
        if (chats.isEmpty)
          const EmptyStateCard(
            title: 'אין שיחות עדיין',
            subtitle: 'שיחות יופיעו כאן אחרי בקשה/הזמנה.',
            icon: Icons.chat_bubble_outline,
          ),
      ],
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
              color: const Color(0xFF0F766E).withOpacity(0.12),
            ),
            child: Icon(_typeIcon, color: const Color(0xFF0F766E)),
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
                    color: Color(0xFF0F172A),
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
          const Icon(Icons.arrow_back_rounded, color: Color(0xFF64748B)),
        ],
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  final ChatPreviewData data;
  final VoidCallback onTap;

  const _ChatCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: GlassCard(
        useBlur: true,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFF0EA5E9).withOpacity(0.14),
              ),
              child:
                  const Icon(Icons.person_rounded, color: Color(0xFF0EA5E9)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            Text(
              data.timeAgo,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
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
                    color: Color(0xFF0F172A),
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
          const Icon(Icons.arrow_back_rounded, color: Color(0xFF64748B)),
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
        color: Color(0xFF0F172A),
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
    final bg = selected ? const Color(0xFF0F766E) : const Color(0xFFF1F5F9);
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
            color: const Color(0xFFF1F5F9),
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
