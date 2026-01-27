import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _HomeTab(
        cards: _cards,
        onRequireLogin: () => _requireLogin(context),
      ),
      _LostPetsTab(
        onRequireLogin: () => _requireLogin(context),
      ),
      _CardsListTab(
        title: 'טיולים (Dog Walk)',
        cards: _dogWalkCards,
        onRequireLogin: () => _requireLogin(context),
      ),
      _CardsListTab(
        title: 'שמירה (Pet Sitting)',
        cards: _petSittingCards,
        onRequireLogin: () => _requireLogin(context),
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surfaceAlabaster,
        appBar: _TopBar(
          onProfilePressed: () => _requireLogin(context),
        ),
        body: SafeArea(child: tabs[_currentIndex]),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primarySage,
          unselectedItemColor: AppColors.secondarySlate.withOpacity(0.55),
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'בית',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets_outlined),
              label: 'אבודים',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_walk_outlined),
              label: 'טיולים',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_work_outlined),
              label: 'שמירה',
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onProfilePressed;

  const _TopBar({required this.onProfilePressed});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surfaceAlabaster,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'שלום 👋',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.secondarySlate,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'מצא מטפל מושלם לחיית המחמד שלך',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondarySlate.withOpacity(0.65),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onProfilePressed,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.person_outline, color: AppColors.secondarySlate),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeTab extends StatelessWidget {
  final List<_ServiceCardData> cards;
  final VoidCallback onRequireLogin;

  const _HomeTab({required this.cards, required this.onRequireLogin});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const _GuestBanner(),
        const SizedBox(height: 14),

        _LockedSearchBar(onTap: onRequireLogin),
        const SizedBox(height: 16),

        // Quick actions (optional - keep it clean)
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                title: 'פרסם/י מודעה',
                subtitle: 'אבוד/נמצא או שירות',
                icon: Icons.add_circle_outline,
                locked: true,
                onTap: onRequireLogin,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                title: 'צ׳אט מאובטח',
                subtitle: 'רק למשתמשים רשומים',
                icon: Icons.chat_bubble_outline,
                locked: true,
                onTap: onRequireLogin,
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Newsfeed inside Home ✅
        Row(
          children: [
            const Expanded(
              child: Text(
                'עדכונים אחרונים',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondarySlate,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // You asked to keep feed inside Home, so "see more" can open login dialog (guest)
                onRequireLogin();
              },
              child: const Text('ראה עוד'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const _FeedTile(
          title: 'כלב אבוד - רקס',
          subtitle: 'נראה לאחרונה בירושלים • לפני שעתיים',
          icon: Icons.campaign_outlined,
        ),
        const SizedBox(height: 10),
        const _FeedTile(
          title: 'מטפל חדש באזור שלך',
          subtitle: 'דירוג גבוה • היום',
          icon: Icons.notifications_none_rounded,
        ),

        const SizedBox(height: 22),

        // Cards preview (latest)
        const Text(
          'כרטיסים בסביבתך',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.secondarySlate,
          ),
        ),
        const SizedBox(height: 10),
        ...cards.take(3).map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ServiceCard(
                  data: c,
                  onPressed: onRequireLogin,
                ),
              ),
            ),
      ],
    );
  }
}

class _LostPetsTab extends StatelessWidget {
  final VoidCallback onRequireLogin;

  const _LostPetsTab({required this.onRequireLogin});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        const Text(
          'חיות אבודות',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.secondarySlate,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'תצוגה בלבד כאורח. כדי לדווח או ליצור התאמות AI — התחבר/י.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.secondarySlate.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 14),

        const _LostPetCard(
          title: 'כלב אבוד - רקס',
          subtitle: 'נראה לאחרונה בשכונת בית הכרם',
          timeAgo: 'לפני 2 שעות',
        ),
        const SizedBox(height: 12),
        const _LostPetCard(
          title: 'חתולה נמצאה - לולה',
          subtitle: 'נמצאה ליד גן סאקר',
          timeAgo: 'אתמול',
        ),

        const SizedBox(height: 18),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: onRequireLogin,
            icon: const Icon(Icons.lock_outline, size: 18),
            label: const Text('דווח/י על חיה אבודה'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primarySage,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        )
      ],
    );
  }
}

class _CardsListTab extends StatelessWidget {
  final String title;
  final List<_ServiceCardData> cards;
  final VoidCallback onRequireLogin;

  const _CardsListTab({
    required this.title,
    required this.cards,
    required this.onRequireLogin,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.secondarySlate,
          ),
        ),
        const SizedBox(height: 10),
        ...cards.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ServiceCard(
              data: c,
              onPressed: onRequireLogin,
            ),
          ),
        ),
      ],
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySage.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.lock_outline, color: AppColors.primarySage),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'את/ה גולש/ת כאורח',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondarySlate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'אפשר לצפות בלבד. כדי להזמין/לפרסם/לצ׳אט — התחבר/י.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondarySlate.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text(
              'התחבר/י',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primarySage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _LockedSearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.secondarySlate),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'חיפוש מטפל לפי מיקום ותאריך',
                style: TextStyle(color: AppColors.secondarySlate.withOpacity(0.7)),
              ),
            ),
            Icon(Icons.lock_outline, size: 18, color: AppColors.secondarySlate.withOpacity(0.45)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool locked;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySage.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primarySage),
                ),
                const Spacer(),
                if (locked)
                  Icon(Icons.lock_outline, size: 18, color: AppColors.secondarySlate.withOpacity(0.45)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.secondarySlate,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondarySlate.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _FeedTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warmMist,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.secondarySlate),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.secondarySlate)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: AppColors.secondarySlate.withOpacity(0.65)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LostPetCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timeAgo;

  const _LostPetCard({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warmMist,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.pets_outlined, color: AppColors.secondarySlate),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.secondarySlate)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: AppColors.secondarySlate.withOpacity(0.65)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            timeAgo,
            style: TextStyle(fontSize: 11, color: AppColors.secondarySlate.withOpacity(0.55)),
          ),
        ],
      ),
    );
  }
}

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

class _ServiceCard extends StatelessWidget {
  final _ServiceCardData data;
  final VoidCallback onPressed;

  const _ServiceCard({
    required this.data,
    required this.onPressed,
  });

  String get _typeLabel {
    switch (data.type) {
      case ServiceType.dogWalk:
        return 'Dog Walk 🐶';
      case ServiceType.petSitting:
        return 'Pet Sitting 🏠';
      case ServiceType.available:
        return 'זמין 🟢';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySage.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _typeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondarySlate,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                data.rating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.secondarySlate),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${data.city} • ${data.name}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.secondarySlate,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${data.timeText} • ${data.priceText}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondarySlate.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.lock_outline, size: 18),
              label: const Text('בקשת הזמנה'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySage,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _requireLogin(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'צריך להתחבר כדי להמשיך',
        textDirection: TextDirection.rtl,
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: const Text(
        'במצב אורח אפשר לצפות בלבד. התחבר/י כדי להזמין, לפרסם ולצ׳אט.',
        textDirection: TextDirection.rtl,
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
            backgroundColor: AppColors.primarySage,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('התחבר/י'),
        ),
      ],
    ),
  );
}
