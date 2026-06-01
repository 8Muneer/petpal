import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_bottom_nav.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';

import 'package:petpal/features/home/presentation/widgets/guest_home_tab.dart';
import 'package:petpal/features/home/presentation/widgets/guest_lost_pets_tab.dart';
import 'package:petpal/features/home/presentation/widgets/guest_services_tab.dart';


class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  int _currentIndex = 0;


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

  void _requireLogin() => _requireLoginDialog(context);

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      GuestHomeTab(
        onRequireLogin: _requireLogin,
      ),
      GuestLostPetsTab(
        onRequireLogin: _requireLogin,
        onToast: _toast,
      ),
      GuestWalkServicesTab(onRequireLogin: _requireLogin),
      GuestSittingServicesTab(onRequireLogin: _requireLogin),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (_currentIndex == 0)
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
          ],
        ),
      ),
    );
  }
}

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
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onProfilePressed,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withValues(alpha: 0.85),
                border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.person_outline_rounded,
                  color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppCard(
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
                            color: AppColors.textPrimary,
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
                            color: AppColors.textSecondary.withValues(alpha: 0.82),
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
        ],
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
          color: AppColors.borderFaint,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'התחבר/י',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
              backgroundColor: AppColors.primary,
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
