import 'dart:ui';

import 'package:flutter/material.dart';

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
                destinations: destinations,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
