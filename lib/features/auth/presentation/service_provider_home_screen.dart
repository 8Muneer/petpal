import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ProviderServiceType { dogWalk, petSitting }
enum RequestStatus { pending, accepted, declined }

class ServiceProviderHomeScreen extends StatefulWidget {
  const ServiceProviderHomeScreen({super.key});

  @override
  State<ServiceProviderHomeScreen> createState() =>
      _ServiceProviderHomeScreenState();
}

class _ServiceProviderHomeScreenState extends State<ServiceProviderHomeScreen> {
  int _currentIndex = 0;

  // Mock requests (later replace with Firestore)
  final List<_BookingRequestData> _requests = [
    _BookingRequestData(
      ownerName: 'מוניר',
      serviceType: ProviderServiceType.dogWalk,
      city: 'ירושלים',
      whenText: 'היום 18:30',
      priceText: '₪90',
      status: RequestStatus.pending,
    ),
    _BookingRequestData(
      ownerName: 'לוג׳יין',
      serviceType: ProviderServiceType.petSitting,
      city: 'ירושלים',
      whenText: 'מחר • 2 ימים',
      priceText: '₪220',
      status: RequestStatus.pending,
    ),
    _BookingRequestData(
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
  final List<_ChatPreviewData> _chats = const [
    _ChatPreviewData(
      name: 'מוניר',
      lastMessage: 'מעולה, נפגש בכניסה לבניין 😊',
      timeAgo: 'לפני 5 דק׳',
    ),
    _ChatPreviewData(
      name: 'לוג׳יין',
      lastMessage: 'יש לך ניסיון עם חתולים?',
      timeAgo: 'לפני שעה',
    ),
    _ChatPreviewData(
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

  String get _email => (_user?.email ?? '').trim();

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

  Color get _bgTop => const Color(0xFFECFDF5); // minty
  Color get _bgMid => const Color(0xFFF6F7FB); // cool gray
  Color get _bgBottom => const Color(0xFFFFFFFF);

  void _setRequestStatus(int index, RequestStatus status) {
    setState(() => _requests[index] = _requests[index].copyWith(status: status));
  }

  @override
  Widget build(BuildContext context) {
    // ✅ TABS ORDER:
    // לוח | בקשות | אבודים | לו"ז | צ'אט
    final tabs = <Widget>[
      _ProviderDashboardTab(
        displayName: _displayName,
        email: _email,
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
      _RequestsTab(
        requests: _requests,
        onAccept: (i) {
          _setRequestStatus(i, RequestStatus.accepted);
          _toast('הבקשה אושרה ✅');
        },
        onDecline: (i) {
          _setRequestStatus(i, RequestStatus.declined);
          _toast('הבקשה נדחתה');
        },
      ),
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
                    colors: [_bgTop, _bgMid, _bgBottom],
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

            SafeArea(
              child: Column(
                children: [
                  _ModernTopBar(
                    displayName: _displayName,
                    email: _email,
                    badgeText:
                        _pendingCount > 0 ? '$_pendingCount בקשות' : null,
                    onLogoutPressed: _confirmLogout,
                    onAvatarPressed: () =>
                        Navigator.pushNamed(context, '/profile'),
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
        bottomNavigationBar: _GlassProviderNavBar(
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
  final String? badgeText;
  final VoidCallback onLogoutPressed;
  final VoidCallback onAvatarPressed;

  const _ModernTopBar({
    required this.displayName,
    required this.email,
    required this.onLogoutPressed,
    required this.onAvatarPressed,
    this.badgeText,
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
            child: _GlassCard(
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
                          email.isEmpty ? 'מרכז נותן שירות • PetPal' : email,
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
                  if (badgeText != null) ...[
                    _TinyChip(
                      text: badgeText!,
                      fill: const Color(0xFF0EA5E9).withOpacity(0.10),
                      textColor: const Color(0xFF0EA5E9),
                    ),
                    const SizedBox(width: 10),
                  ],
                  _PillIconButton(
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
            onTap: onAvatarPressed,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
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

class _GlassProviderNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _GlassProviderNavBar({
    required this.currentIndex,
    required this.onChanged,
  });

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
                height: 68,
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
                // ✅ NAV ITEMS ORDER:
                // לוח | בקשות | אבודים | לו"ז | צ׳אט
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: 'לוח',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.inbox_outlined),
                    selectedIcon: Icon(Icons.inbox_rounded),
                    label: 'בקשות',
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
          ),
        ),
      ),
    );
  }
}

class _ProviderDashboardTab extends StatelessWidget {
  final String displayName;
  final String email;
  final bool isAvailable;
  final int pendingCount;
  final ValueChanged<bool> onToggleAvailability;
  final List<_BookingRequestData> upcoming;
  final void Function(String msg) onAction;

  const _ProviderDashboardTab({
    required this.displayName,
    required this.email,
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
        _GlassCard(
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

        _SectionHeader(
          title: 'סטטיסטיקות מהירות',
          subtitle: 'סיכום קצר להיום',
          trailing: _TinyChip(
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

        _SectionHeader(
          title: 'פעולות מהירות',
          subtitle: 'עדכן זמינות, שירותים ועוד',
          trailing: const _TinyChip(
            text: 'חדש',
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _GradientActionCard(
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
              child: _GradientActionCard(
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

        const _SectionHeader(
          title: 'הזמנות קרובות',
          subtitle: 'רק אחרי אישור הבקשה',
        ),
        const SizedBox(height: 10),

        if (upcoming.isEmpty)
          _EmptyStateCard(
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

class _RequestsTab extends StatelessWidget {
  final List<_BookingRequestData> requests;
  final void Function(int index) onAccept;
  final void Function(int index) onDecline;

  const _RequestsTab({
    required this.requests,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final pending = requests.where((r) => r.status == RequestStatus.pending);
    final accepted = requests.where((r) => r.status == RequestStatus.accepted);
    final declined = requests.where((r) => r.status == RequestStatus.declined);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        const _SectionHeader(
          title: 'בקשות להזמנה',
          subtitle: 'אשר/י או דחה/י בקשות נכנסות',
        ),
        const SizedBox(height: 10),

        if (pending.isNotEmpty) ...[
          const _SubHeader(text: 'ממתינות'),
          const SizedBox(height: 8),
          ...pending.toList().asMap().entries.map((entry) {
            final idx = requests.indexOf(entry.value);
            final r = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RequestCard(
                data: r,
                onAccept: () => onAccept(idx),
                onDecline: () => onDecline(idx),
              ),
            );
          }),
          const SizedBox(height: 12),
        ],

        if (accepted.isNotEmpty) ...[
          const _SubHeader(text: 'מאושרות'),
          const SizedBox(height: 8),
          ...accepted.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RequestCard(
                data: r,
                onAccept: null,
                onDecline: null,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (declined.isNotEmpty) ...[
          const _SubHeader(text: 'נדחו'),
          const SizedBox(height: 8),
          ...declined.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RequestCard(
                data: r,
                onAccept: null,
                onDecline: null,
              ),
            ),
          ),
        ],

        if (requests.isEmpty)
          const _EmptyStateCard(
            title: 'אין בקשות כרגע',
            subtitle: 'כשבקשה תגיע – תופיע כאן.',
            icon: Icons.inbox_outlined,
          ),
      ],
    );
  }
}

/// ✅ NEW TAB: אבודים (Lost & Found)
class _LostPetsTab extends StatelessWidget {
  final void Function(String msg) onAction;

  const _LostPetsTab({required this.onAction});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        const _SectionHeader(
          title: 'אבודים',
          subtitle: 'דיווחים על חיות אבודות ונמצאות (בקרוב AI התאמות)',
        ),
        const SizedBox(height: 10),

        _GlassCard(
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

        _PrimaryGradientButton(
          text: 'דיווח על חיה נמצאה',
          icon: Icons.add_photo_alternate_rounded,
          onTap: () => onAction('TODO: Report found pet'),
        ),
        const SizedBox(height: 12),
        _PrimaryGradientButton(
          text: 'חיפוש חיה אבודה',
          icon: Icons.search_rounded,
          onTap: () => onAction('TODO: Search lost pets'),
        ),

        const SizedBox(height: 18),

        const _EmptyStateCard(
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
        const _SectionHeader(
          title: 'לו״ז וזמינות',
          subtitle: 'נהל/י את הזמנים והימים הפנויים',
        ),
        const SizedBox(height: 10),

        _GlassCard(
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

        _PrimaryGradientButton(
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
  final List<_ChatPreviewData> chats;
  final void Function(String msg) onAction;

  const _MessagesTab({required this.chats, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        const _SectionHeader(
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
          const _EmptyStateCard(
            title: 'אין שיחות עדיין',
            subtitle: 'שיחות יופיעו כאן אחרי בקשה/הזמנה.',
            icon: Icons.chat_bubble_outline,
          ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final _BookingRequestData data;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _RequestCard({
    required this.data,
    required this.onAccept,
    required this.onDecline,
  });

  Color get _accent {
    if (data.status == RequestStatus.accepted) return const Color(0xFF22C55E);
    if (data.status == RequestStatus.declined) return const Color(0xFFFB7185);
    return const Color(0xFF0EA5E9);
  }

  String get _statusText {
    switch (data.status) {
      case RequestStatus.pending:
        return 'ממתין';
      case RequestStatus.accepted:
        return 'אושר';
      case RequestStatus.declined:
        return 'נדחה';
    }
  }

  IconData get _typeIcon {
    switch (data.serviceType) {
      case ProviderServiceType.dogWalk:
        return Icons.directions_walk_rounded;
      case ProviderServiceType.petSitting:
        return Icons.home_work_rounded;
    }
  }

  String get _typeLabel {
    switch (data.serviceType) {
      case ProviderServiceType.dogWalk:
        return 'Dog Walk';
      case ProviderServiceType.petSitting:
        return 'Pet Sitting';
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionable = data.status == RequestStatus.pending &&
        onAccept != null &&
        onDecline != null;

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
                      '${data.city} • ${data.ownerName}',
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
              _TinyChip(
                text: '$_statusText • $_typeLabel',
                fill: _accent.withOpacity(0.10),
                textColor: _accent,
              ),
            ],
          ),
          if (actionable) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OutlineButton(
                    text: 'דחה',
                    icon: Icons.close_rounded,
                    onTap: onDecline!,
                    accent: const Color(0xFFFB7185),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SolidButton(
                    text: 'אשר',
                    icon: Icons.check_rounded,
                    onTap: onAccept!,
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

class _UpcomingBookingCard extends StatelessWidget {
  final _BookingRequestData data;

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
    return _GlassCard(
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
  final _ChatPreviewData data;
  final VoidCallback onTap;

  const _ChatCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: _GlassCard(
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
    return _GlassCard(
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
    return _GlassCard(
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

class _OutlineButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;

  const _OutlineButton({
    required this.text,
    required this.icon,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.38)),
          color: accent.withOpacity(0.06),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolidButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _SolidButton({
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
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
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

class _TinyChip extends StatelessWidget {
  final String text;
  final Color? fill;
  final Color? textColor;

  const _TinyChip({
    required this.text,
    this.fill,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: (fill ?? const Color(0xFF0F766E).withOpacity(0.10)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: (textColor ?? const Color(0xFF0F766E)),
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

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: _GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFF64748B).withOpacity(0.12),
              ),
              child: Icon(icon, color: const Color(0xFF64748B)),
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
      ),
    );
  }
}

class _BookingRequestData {
  final String ownerName;
  final ProviderServiceType serviceType;
  final String city;
  final String whenText;
  final String priceText;
  final RequestStatus status;

  const _BookingRequestData({
    required this.ownerName,
    required this.serviceType,
    required this.city,
    required this.whenText,
    required this.priceText,
    required this.status,
  });

  _BookingRequestData copyWith({RequestStatus? status}) => _BookingRequestData(
        ownerName: ownerName,
        serviceType: serviceType,
        city: city,
        whenText: whenText,
        priceText: priceText,
        status: status ?? this.status,
      );
}

class _ChatPreviewData {
  final String name;
  final String lastMessage;
  final String timeAgo;

  const _ChatPreviewData({
    required this.name,
    required this.lastMessage,
    required this.timeAgo,
  });
}
