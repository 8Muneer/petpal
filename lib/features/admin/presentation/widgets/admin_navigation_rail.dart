import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';

class AdminNavigationRail extends StatelessWidget {
  final Widget body;
  final int selectedIndex;

  const AdminNavigationRail({
    super.key,
    required this.body,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    // For smaller screens, we might want a different layout, 
    // but the task specifically asked for a NavigationRail.
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: Colors.white,
            elevation: 1,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              _onItemTapped(context, index);
            },
            labelType: NavigationRailLabelType.selected,
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
            unselectedIconTheme: IconThemeData(color: AppColors.textSecondary.withValues(alpha: 0.5)),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              fontSize: 12,
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: Text('Hub'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.verified_user_outlined),
                selectedIcon: Icon(Icons.verified_user_rounded),
                label: Text('Verification'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map_rounded),
                label: Text('Places'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.security_outlined),
                selectedIcon: Icon(Icons.security_rounded),
                label: Text('Moderation'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people_rounded),
                label: Text('Users'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/admin');
        break;
      case 1:
        context.go('/admin/verification');
        break;
      case 2:
        context.go('/admin/poi');
        break;
      case 3:
        context.go('/admin/moderation');
        break;
      case 4:
        context.go('/admin/users');
        break;
    }
  }
}
