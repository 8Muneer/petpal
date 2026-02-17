import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/glass_nav_bar.dart';
import 'package:petpal/core/widgets/petpal_scaffold.dart';
import 'package:petpal/core/widgets/primary_gradient_button.dart';
import 'package:petpal/core/widgets/section_header.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';
import 'package:petpal/features/feed/presentation/providers/feed_provider.dart';

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

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  int _currentIndex = 0;

  // Mock cards (later replace with Firestore)
  final List<ServiceCardData> _cards = const [
    ServiceCardData(
      type: ServiceType.dogWalk,
      name: 'איה לוי',
      rating: 4.9,
      city: 'ירושלים',
      priceText: '₪90/טיול',
      timeText: 'היום 18:00',
    ),
    ServiceCardData(
      type: ServiceType.petSitting,
      name: 'דניאל כהן',
      rating: 4.7,
      city: 'ירושלים',
      priceText: '₪120/יום',
      timeText: 'מחר - 3 ימים',
    ),
    ServiceCardData(
      type: ServiceType.dogWalk,
      name: 'נועה מזרחי',
      rating: 4.8,
      city: 'ירושלים',
      priceText: '₪70/טיול',
      timeText: 'היום 20:30',
    ),
    ServiceCardData(
      type: ServiceType.petSitting,
      name: 'רוני אבו-סאלח',
      rating: 4.9,
      city: 'ירושלים',
      priceText: '₪95/יום',
      timeText: 'סופ"ש',
    ),
    ServiceCardData(
      type: ServiceType.available,
      name: 'סאמר ח\'טיב',
      rating: 4.6,
      city: 'ירושלים',
      priceText: 'זמין עכשיו',
      timeText: 'היום',
    ),
  ];

  List<ServiceCardData> get _dogWalkCards =>
      _cards.where((c) => c.type == ServiceType.dogWalk).toList();

  List<ServiceCardData> get _petSittingCards =>
      _cards.where((c) => c.type == ServiceType.petSitting).toList();

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

  void _requireLogin() => _requireLoginDialog(context);

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _HomeTab(
        onRequireLogin: _requireLogin,
      ),
      _LostPetsTab(
        onRequireLogin: _requireLogin,
        onToast: _toast,
      ),
      _CardsListTab(
        title: 'טיולים (Dog Walk)',
        subtitle: 'תצוגה בלבד כאורח • התחבר/י להזמנה',
        cards: _dogWalkCards,
        onRequireLogin: _requireLogin,
      ),
      _CardsListTab(
        title: 'שמירה (Pet Sitting)',
        subtitle: 'תצוגה בלבד כאורח • התחבר/י להזמנה',
        cards: _petSittingCards,
        onRequireLogin: _requireLogin,
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PetPalScaffold(
        body: SafeArea(
          child: Column(
            children: [
              _GuestTopBar(
                onLoginPressed: () => context.push('/login'),
                onProfilePressed: _requireLogin,
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

// ====================== Top bar ======================

class _GuestTopBar extends StatelessWidget {
  final VoidCallback onLoginPressed;
  final VoidCallback onProfilePressed;

  const _GuestTopBar({
    required this.onLoginPressed,
    required this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'שלום 👋',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'את/ה גולש/ת כאורח • תצוגה בלבד',
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
                  _PillButton(
                    text: 'התחבר/י',
                    icon: Icons.login_rounded,
                    onTap: onLoginPressed,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onProfilePressed,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withOpacity(0.85),
                border: Border.all(color: Colors.white.withOpacity(0.55)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.person_outline_rounded,
                  color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== Tabs ======================

class _HomeTab extends ConsumerWidget {
  final VoidCallback onRequireLogin;

  const _HomeTab({
    required this.onRequireLogin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(feedPostsProvider);

    return postsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF0F766E)),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48,
                color: const Color(0xFFFB7185).withOpacity(0.6)),
            const SizedBox(height: 12),
            const Text(
              'שגיאה בטעינת הפיד',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.feed_outlined,
                    size: 64,
                    color: const Color(0xFF64748B).withOpacity(0.5)),
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
                  'הפיד ריק כרגע — התחבר/י כדי לפרסם!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryGradientButton(
                  text: 'התחבר/י',
                  icon: Icons.login_rounded,
                  onTap: () => context.push('/login'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: posts.length + 1, // +1 for the create-post banner
          itemBuilder: (context, index) {
            // First item: locked "create post" prompt
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: onRequireLogin,
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFFF1F5F9),
                          ),
                          child: const Icon(Icons.person_outline_rounded,
                              color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'התחבר/י כדי לשתף פוסט...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color:
                                  const Color(0xFF64748B).withOpacity(0.7),
                            ),
                          ),
                        ),
                        const Icon(Icons.lock_outline_rounded,
                            size: 18, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                ),
              );
            }

            final post = posts[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _GuestPostCard(
                post: post,
                onTap: () => context.push('/feed/${post.id}'),
                onRequireLogin: onRequireLogin,
              ),
            );
          },
        );
      },
    );
  }
}

class _LostPetsTab extends StatelessWidget {
  final VoidCallback onRequireLogin;
  final void Function(String msg) onToast;

  const _LostPetsTab({required this.onRequireLogin, required this.onToast});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        const SectionHeader(
          title: 'חיות אבודות',
          subtitle: 'תצוגה בלבד כאורח • דיווח + AI נעולים',
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
          text: 'דווח/י על חיה אבודה (נעול)',
          icon: Icons.lock_rounded,
          onTap: onRequireLogin,
        ),
      ],
    );
  }
}

class _CardsListTab extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<ServiceCardData> cards;
  final VoidCallback onRequireLogin;

  const _CardsListTab({
    required this.title,
    required this.subtitle,
    required this.cards,
    required this.onRequireLogin,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        SectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 10),
        ...cards.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ModernServiceCardLocked(
              data: c,
              onPressed: onRequireLogin,
            ),
          ),
        ),
      ],
    );
  }
}

class _GuestPostCard extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onTap;
  final VoidCallback onRequireLogin;

  const _GuestPostCard({
    required this.post,
    required this.onTap,
    required this.onRequireLogin,
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
    final isTip = post.type == PostType.tip;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
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
                            image: CachedNetworkImageProvider(
                                post.authorPhotoUrl!),
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
                              fontSize: 13,
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
                          fontSize: 13,
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
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded,
                            size: 13, color: Color(0xFFF59E0B)),
                        SizedBox(width: 3),
                        Text(
                          'טיפ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Content (truncated)
            Text(
              post.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                height: 1.4,
              ),
            ),

            // Optional image
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 160,
                    color: const Color(0xFFF1F5F9),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0F766E),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 160,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.broken_image_rounded,
                        color: Color(0xFF94A3B8)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Actions row (read-only for guests — tapping triggers login)
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onRequireLogin,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_border_rounded,
                            size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 5),
                        Text(
                          '${post.likes.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onRequireLogin,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 5),
                        Text(
                          '${post.commentCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
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

class _ModernServiceCardLocked extends StatelessWidget {
  final ServiceCardData data;
  final VoidCallback onPressed;

  const _ModernServiceCardLocked({
    required this.data,
    required this.onPressed,
  });

  String get _typeLabel {
    switch (data.type) {
      case ServiceType.dogWalk:
        return 'Dog Walk';
      case ServiceType.petSitting:
        return 'Pet Sitting';
      case ServiceType.available:
        return 'זמין';
    }
  }

  IconData get _typeIcon {
    switch (data.type) {
      case ServiceType.dogWalk:
        return Icons.directions_walk_rounded;
      case ServiceType.petSitting:
        return Icons.home_work_rounded;
      case ServiceType.available:
        return Icons.flash_on_rounded;
    }
  }

  Color get _accent {
    switch (data.type) {
      case ServiceType.dogWalk:
        return const Color(0xFF0EA5E9);
      case ServiceType.petSitting:
        return const Color(0xFF0F766E);
      case ServiceType.available:
        return const Color(0xFF22C55E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: _accent.withOpacity(0.14),
                ),
                child: Icon(_typeIcon, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.city} • ${data.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.timeText} • ${data.priceText}',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      data.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _accent.withOpacity(0.12),
                ),
                child: Text(
                  '$_typeLabel • 🔒',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: _accent,
                  ),
                ),
              ),
              const Spacer(),
              _MiniLockButton(
                text: 'בקשת הזמנה',
                onTap: onPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ====================== Small shared widgets (screen-specific) ======================

class _PillButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _PillButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF0F766E)),
            const SizedBox(width: 8),
            const Text(
              'התחבר/י',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniLockButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _MiniLockButton({required this.text, required this.onTap});

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.lock_rounded, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'בקשת הזמנה',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== Login gate dialog ======================

void _requireLoginDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'צריך להתחבר כדי להמשיך',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'במצב אורח אפשר לצפות בלבד. התחבר/י כדי להזמין, לפרסם ולצ׳אט.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('התחבר/י',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ),
  );
}
