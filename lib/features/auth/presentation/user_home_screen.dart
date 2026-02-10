import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/shared/widgets/widgets.dart';

enum ServiceType { dogWalk, petSitting, available }

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // Mock cards (later replace with Firestore)
  final List<_ServiceCardData> _cards = const [
    _ServiceCardData(
      type: ServiceType.dogWalk,
      name: 'איה לוי',
      rating: 4.9,
      city: 'ירושלים',
      priceText: '₪90/טיול',
      timeText: 'היום 18:00',
    ),
    _ServiceCardData(
      type: ServiceType.petSitting,
      name: 'דניאל כהן',
      rating: 4.7,
      city: 'ירושלים',
      priceText: '₪120/יום',
      timeText: 'מחר - 3 ימים',
    ),
    _ServiceCardData(
      type: ServiceType.dogWalk,
      name: 'נועה מזרחי',
      rating: 4.8,
      city: 'ירושלים',
      priceText: '₪70/טיול',
      timeText: 'היום 20:30',
    ),
    _ServiceCardData(
      type: ServiceType.petSitting,
      name: 'רוני אבו-סאלח',
      rating: 4.9,
      city: 'ירושלים',
      priceText: '₪95/יום',
      timeText: 'סופ"ש',
    ),
    _ServiceCardData(
      type: ServiceType.available,
      name: 'סאמר ח\'טיב',
      rating: 4.6,
      city: 'ירושלים',
      priceText: 'זמין עכשיו',
      timeText: 'היום',
    ),
  ];

  List<_ServiceCardData> get _dogWalkCards =>
      _cards.where((c) => c.type == ServiceType.dogWalk).toList();

  List<_ServiceCardData> get _petSittingCards =>
      _cards.where((c) => c.type == ServiceType.petSitting).toList();

  User? get _user => FirebaseAuth.instance.currentUser;

  String get _displayName {
    final u = _user;
    final dn = (u?.displayName ?? '').trim();
    if (dn.isNotEmpty) return dn;

    final email = (u?.email ?? '').trim();
    if (email.contains('@')) return email.split('@').first;

    return 'משתמש';
  }

  String get _email => (_user?.email ?? '').trim();

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
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
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

  Color get _bgTop => const Color(0xFFECFDF5); // minty
  Color get _bgMid => const Color(0xFFF6F7FB); // cool gray
  Color get _bgBottom => const Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _HomeTab(
        displayName: _displayName,
        email: _email,
        cards: _cards,
        onAction: (msg) => _toast(msg),
      ),
      _LostPetsTab(
        onAction: (msg) => _toast(msg),
      ),
      _CardsListTab(
        title: 'טיולים (Dog Walk)',
        subtitle: 'מצא/י דוג-ווקר קרוב ובזמינות מהירה',
        cards: _dogWalkCards,
        onAction: (msg) => _toast(msg),
      ),
      _CardsListTab(
        title: 'שמירה (Pet Sitting)',
        subtitle: 'מטפלים עם דירוגים מאומתים',
        cards: _petSittingCards,
        onAction: (msg) => _toast(msg),
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBody: true,
        backgroundColor: _bgBottom,
        body: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      _bgTop,
                      _bgMid,
                      _bgBottom,
                    ],
                  ),
                ),
              ),
            ),

            // subtle blob
            Positioned(
              top: -120,
              left: -90,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF34D399).withOpacity(0.22),
                      const Color(0xFF0EA5E9).withOpacity(0.14),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              right: -110,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF22C55E).withOpacity(0.12),
                      const Color(0xFF0F766E).withOpacity(0.14),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  _ModernTopBar(
                    displayName: _displayName,
                    email: _email,
                    onProfilePressed: () =>
                        Navigator.pushNamed(context, '/profile'),
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
          ],
        ),

        // Floating glass bottom nav
        bottomNavigationBar: _GlassNavBar(
          currentIndex: _currentIndex,
          onChanged: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

class _ModernTopBar extends StatelessWidget {
  final String displayName;
  final String email;
  final VoidCallback onProfilePressed;
  final VoidCallback onLogoutPressed;

  const _ModernTopBar({
    required this.displayName,
    required this.email,
    required this.onProfilePressed,
    required this.onLogoutPressed,
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
                        Text(
                          'שלום, $displayName 👋',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email.isEmpty
                              ? 'בוא/י נמצא מטפל מושלם לחיית המחמד שלך'
                              : email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155).withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  PillIconButton(
                    icon: Icons.logout_rounded,
                    tooltip: 'התנתקות',
                    onTap: onLogoutPressed,
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
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color(0xFF0F766E),
                    Color(0xFF22C55E),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _GlassNavBar({required this.currentIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.72),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.45)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 66,
                backgroundColor: Colors.transparent,
                elevation: 0,
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    color: selected
                        ? const Color(0xFF0F766E)
                        : const Color(0xFF64748B),
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: currentIndex,
                onDestinationSelected: onChanged,
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
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String displayName;
  final String email;
  final List<_ServiceCardData> cards;
  final void Function(String msg) onAction;

  const _HomeTab({
    required this.displayName,
    required this.email,
    required this.cards,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _HeroSearchBar(onTap: () => onAction('TODO: Search flow')),
        const SizedBox(height: 14),

        SectionHeader(
          title: 'פעולות מהירות',
          subtitle: 'תוך שניות – פרסום, צ׳אט ועוד',
          trailing: TinyChip(text: 'חדש'),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _GradientActionCard(
                title: 'פרסם/י מודעה',
                subtitle: 'אבוד/נמצא או שירות',
                icon: Icons.add_circle_outline,
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
                ),
                onTap: () => onAction('TODO: Publish card flow'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GradientActionCard(
                title: 'צ׳אט מאובטח',
                subtitle: 'פתח שיחות',
                icon: Icons.chat_bubble_outline,
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                ),
                onTap: () => onAction('TODO: Chat flow'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        SectionHeader(
          title: 'עדכונים אחרונים',
          subtitle: 'דברים שקרו ממש עכשיו',
          trailing: const TinyChip(text: 'LIVE'),
        ),
        const SizedBox(height: 10),

        const _ModernFeedTile(
          title: 'כלב אבוד - רקס',
          subtitle: 'נראה לאחרונה בירושלים • לפני שעתיים',
          icon: Icons.campaign_outlined,
          accent: Color(0xFFFB7185),
        ),
        const SizedBox(height: 10),
        const _ModernFeedTile(
          title: 'מטפל חדש באזור שלך',
          subtitle: 'דירוג גבוה • היום',
          icon: Icons.notifications_none_rounded,
          accent: Color(0xFF60A5FA),
        ),

        const SizedBox(height: 18),

        SectionHeader(
          title: 'מומלצים בקרבתך',
          subtitle: 'מטפלים עם דירוגים גבוהים',
          trailing: TextButton(
            onPressed: () => onAction('TODO: View all'),
            child: const Text(
              'הצג הכל',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F766E),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        ...cards.take(3).map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ModernServiceCard(
                  data: c,
                  onPressed: () => onAction('TODO: Booking/Request flow'),
                ),
              ),
            ),
      ],
    );
  }
}

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

class _CardsListTab extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_ServiceCardData> cards;
  final void Function(String msg) onAction;

  const _CardsListTab({
    required this.title,
    required this.subtitle,
    required this.cards,
    required this.onAction,
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
            child: _ModernServiceCard(
              data: c,
              onPressed: () => onAction('TODO: Booking/Request flow'),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _HeroSearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
                ),
              ),
              child: const Icon(Icons.search_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'חיפוש מטפל לפי מיקום ותאריך',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A).withOpacity(0.86),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'סינון',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F766E),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _GradientActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.88),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernFeedTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _ModernFeedTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: accent.withOpacity(0.14),
            ),
            child: Icon(icon, color: accent),
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
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: accent),
          ),
        ],
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

class _ModernServiceCard extends StatelessWidget {
  final _ServiceCardData data;
  final VoidCallback onPressed;

  const _ModernServiceCard({
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
                  '$_typeLabel • ${data.type == ServiceType.available ? "🟢" : "✨"}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: _accent,
                  ),
                ),
              ),
              const Spacer(),
              MiniPrimaryButton(
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

// ====================== Shared components removed ======================
// Components moved to lib/shared/widgets/
// - GlassCard
// - SectionHeader
// - TinyChip
// - PrimaryGradientButton
// - MiniPrimaryButton
// - PillIconButton

// ====================== Data models ======================

class _ServiceCardData {
  final ServiceType type;
  final String name;
  final double rating;
  final String city;
  final String priceText;
  final String timeText;

  const _ServiceCardData({
    required this.type,
    required this.name,
    required this.rating,
    required this.city,
    required this.priceText,
    required this.timeText,
  });
}
