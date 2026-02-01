import 'dart:ui';

import 'package:flutter/material.dart';

enum ServiceType { dogWalk, petSitting, available }

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
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
        cards: _cards,
        onRequireLogin: _requireLogin,
        onToast: _toast,
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
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.white,
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
                      const Color(0xFFECFDF5),
                      const Color(0xFFF6F7FB),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),

            // subtle blobs
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
                      const Color(0xFF34D399).withOpacity(0.20),
                      const Color(0xFF0EA5E9).withOpacity(0.12),
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

            SafeArea(
              child: Column(
                children: [
                  _GuestTopBar(
                    onLoginPressed: () => Navigator.pushNamed(context, '/login'),
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
          ],
        ),
        bottomNavigationBar: _GlassNavBar(
          currentIndex: _currentIndex,
          onChanged: (i) => setState(() => _currentIndex = i),
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
            child: _GlassCard(
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

class _HomeTab extends StatelessWidget {
  final List<_ServiceCardData> cards;
  final VoidCallback onRequireLogin;
  final void Function(String msg) onToast;

  const _HomeTab({
    required this.cards,
    required this.onRequireLogin,
    required this.onToast,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        const _GuestHeroBanner(),
        const SizedBox(height: 12),

        _HeroSearchBar(onTap: onRequireLogin),
        const SizedBox(height: 14),

        const _SectionHeader(
          title: 'הצצה לפיצ׳רים',
          subtitle: 'כדי להזמין, לפרסם ולצ׳אט — צריך חשבון',
          trailing: _TinyChip(text: 'אורח'),
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
                locked: true,
                onTap: onRequireLogin,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GradientActionCard(
                title: 'צ׳אט מאובטח',
                subtitle: 'רק למשתמשים רשומים',
                icon: Icons.chat_bubble_outline,
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                ),
                locked: true,
                onTap: onRequireLogin,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Row(
          children: [
            const Expanded(
              child: _SectionHeader(
                title: 'עדכונים אחרונים',
                subtitle: 'קהילה פעילה בירושלים',
                trailing: _TinyChip(text: 'LIVE'),
              ),
            ),
            TextButton(
              onPressed: onRequireLogin,
              child: const Text(
                'ראה עוד',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F766E),
                ),
              ),
            ),
          ],
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

        const _SectionHeader(
          title: 'מומלצים בקרבתך',
          subtitle: 'תצוגה בלבד • הזמנה נעולה',
        ),
        const SizedBox(height: 10),

        ...cards.take(3).map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ModernServiceCardLocked(
                  data: c,
                  onPressed: onRequireLogin,
                ),
              ),
            ),

        const SizedBox(height: 6),
        _PrimaryGradientButton(
          text: 'התחבר/י כדי לפתוח את כל הפיצ׳רים',
          icon: Icons.lock_open_rounded,
          onTap: () => Navigator.pushNamed(context, '/login'),
        ),
      ],
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
        const _SectionHeader(
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

        _PrimaryGradientButton(
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
  final List<_ServiceCardData> cards;
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
        _SectionHeader(title: title, subtitle: subtitle),
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

// ====================== Modern widgets (guest) ======================

class _GuestHeroBanner extends StatelessWidget {
  const _GuestHeroBanner();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
              ),
            ),
            child: const Icon(Icons.lock_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'מצב אורח',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'אפשר לצפות בלבד. התחבר/י כדי להזמין, לפרסם ולצ׳אט.',
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
          _TinyChip(
            text: 'תצוגה',
            color: const Color(0xFF0EA5E9),
          ),
        ],
      ),
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
      child: _GlassCard(
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.lock_outline_rounded,
                      size: 16, color: Color(0xFF0F766E)),
                  SizedBox(width: 6),
                  Text(
                    'נעול',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F766E),
                      fontSize: 12,
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

class _GradientActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final bool locked;
  final VoidCallback onTap;

  const _GradientActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.locked,
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
            Row(
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
                const Spacer(),
                if (locked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.22)),
                    ),
                    child: const Icon(Icons.lock_rounded,
                        size: 16, color: Colors.white),
                  ),
              ],
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
    return _GlassCard(
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
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
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
    return _GlassCard(
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
  final _ServiceCardData data;
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
    return _GlassCard(
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

// ====================== Bottom nav ======================

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

// ====================== Shared components ======================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155).withOpacity(0.78),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _TinyChip extends StatelessWidget {
  final String text;
  final Color? color;

  const _TinyChip({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF0F766E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: c,
        ),
      ),
    );
  }
}

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

class _PrimaryGradientButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryGradientButton({
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
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(Icons.arrow_back_rounded, color: Colors.white),
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

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.76),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.48)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 26,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ====================== Data ======================

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
              Navigator.pushNamed(context, '/login');
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
