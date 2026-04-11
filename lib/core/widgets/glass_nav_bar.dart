import 'package:flutter/material.dart';
import 'package:petpal/core/widgets/app_bottom_nav.dart';

/// Legacy wrapper — delegates to [AppBottomNav].
/// Note: [destinations] parameter is kept for API compatibility but ignored.
class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<NavigationDestination> destinations;

  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    // Convert NavigationDestination to AppNavItem
    final items = destinations.map((d) {
      final icon = (d.icon is Icon) ? (d.icon as Icon).icon! : Icons.circle;
      final selectedIcon = d.selectedIcon != null && d.selectedIcon is Icon
          ? (d.selectedIcon as Icon).icon!
          : icon;
      return AppNavItem(
        icon: icon,
        activeIcon: selectedIcon,
        label: d.label,
      );
    }).toList();

    return AppBottomNav(
      currentIndex: currentIndex,
      onChanged: onChanged,
      items: items,
    );
  }
}
