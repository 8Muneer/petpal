import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_bottom_nav.dart';
import 'package:petpal/features/admin/presentation/widgets/admin_dashboard_tab.dart';
import 'package:petpal/features/admin/presentation/widgets/admin_theme.dart';
import 'package:petpal/features/admin/presentation/screens/user_directory_screen.dart';
import 'package:petpal/features/admin/presentation/screens/poi_management_screen.dart';
import 'package:petpal/features/admin/presentation/screens/moderation_queue_screen.dart';
import 'package:petpal/features/admin/presentation/screens/admin_statistics_screen.dart';
import 'package:petpal/features/auth/presentation/providers/auth_provider.dart';

/// One admin destination: its icons, a short label (rail / bottom bar) and a
/// full title (top bar).
class _AdminDest {
  final IconData icon;
  final IconData activeIcon;
  final String short;
  final String title;
  const _AdminDest(this.icon, this.activeIcon, this.short, this.title);
}

const _destinations = <_AdminDest>[
  _AdminDest(
      Icons.dashboard_outlined, Icons.dashboard_rounded, 'לוח', 'לוח בקרה'),
  _AdminDest(Icons.people_outline, Icons.people_rounded, 'משתמשים', 'משתמשים'),
  _AdminDest(
      Icons.place_outlined, Icons.place_rounded, 'מקומות', 'נקודות עניין'),
  _AdminDest(Icons.flag_outlined, Icons.flag_rounded, 'דיווחים', 'דיווחים'),
  _AdminDest(
      Icons.bar_chart_rounded, Icons.bar_chart_rounded, 'נתונים', 'סטטיסטיקה'),
];

/// Breakpoint at which the bottom bar is replaced by a persistent side rail.
const double _railBreakpoint = 800;

class AdminHubScreen extends ConsumerStatefulWidget {
  const AdminHubScreen({super.key});

  @override
  ConsumerState<AdminHubScreen> createState() => _AdminHubScreenState();
}

class _AdminHubScreenState extends ConsumerState<AdminHubScreen> {
  int _currentIndex = 0;

  late final List<Widget> _bodies = const [
    AdminDashboardTab(),
    UserDirectoryScreen(),
    POIManagementScreen(),
    ModerationQueueScreen(),
    AdminStatisticsScreen(),
  ];

  void _logout() {
    ref.read(authRepositoryProvider).signOut();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: isAdmin.when(
        data: (admin) {
          if (!admin) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/userHome');
            });
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= _railBreakpoint;
              final content = Column(
                children: [
                  _AdminTopBar(
                    title: _destinations[_currentIndex].title,
                    onLogout: _logout,
                  ),
                  Expanded(child: _bodies[_currentIndex]),
                ],
              );

              return Scaffold(
                backgroundColor: AdminColors.bg,
                body: wide
                    ? Row(
                        children: [
                          _AdminRail(
                            selectedIndex: _currentIndex,
                            onSelect: (i) => setState(() => _currentIndex = i),
                          ),
                          Expanded(child: SafeArea(child: content)),
                        ],
                      )
                    : SafeArea(bottom: false, child: content),
                bottomNavigationBar: wide
                    ? null
                    : AppBottomNav(
                        currentIndex: _currentIndex,
                        onChanged: (i) => setState(() => _currentIndex = i),
                        items: [
                          for (final d in _destinations)
                            AppNavItem(
                              icon: d.icon,
                              activeIcon: d.activeIcon,
                              label: d.short,
                            ),
                        ],
                      ),
              );
            },
          );
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, _) => Scaffold(body: Center(child: Text('שגיאה: $err'))),
      ),
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────

class _AdminTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onLogout;
  const _AdminTopBar({required this.title, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: const BoxDecoration(
        color: AdminColors.panel,
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          Text(title, style: AdminText.title),
          const SizedBox(width: 10),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text('מחובר', style: AdminText.rowSub),
          const Spacer(),
          IconButton(
            onPressed: onLogout,
            tooltip: 'התנתקות',
            icon: const Icon(Icons.logout_rounded,
                size: 20, color: AdminColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Side rail ───────────────────────────────────────────────────────────────

class _AdminRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _AdminRail({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      color: AdminColors.rail,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0353A4), Color(0xFF0466C8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              'ניהול',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < _destinations.length; i++)
              _RailItem(
                dest: _destinations[i],
                selected: i == selectedIndex,
                onTap: () => onSelect(i),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final _AdminDest dest;
  final bool selected;
  final VoidCallback onTap;
  const _RailItem({
    required this.dest,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(
                  selected ? dest.activeIcon : dest.icon,
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.55),
                  size: 22,
                ),
                const SizedBox(height: 5),
                Text(
                  dest.short,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
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
