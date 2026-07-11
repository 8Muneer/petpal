import 'package:flutter/material.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/glass_card.dart';

/// Two-way "פעילות" / "היסטוריה" tab switcher, shared between the owner and
/// provider bookings screens. Mirrors the walk/sitting toggle chip pattern
/// already used in ProviderRequestsTab for visual consistency.
class BookingStatusToggle extends StatelessWidget {
  final int selected; // 0 = active, 1 = history
  final ValueChanged<int> onChanged;

  const BookingStatusToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      useBlur: true,
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: _Chip(
              label: 'פעילות',
              icon: Icons.bolt_rounded,
              selected: selected == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _Chip(
              label: 'היסטוריה',
              icon: Icons.history_rounded,
              selected: selected == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? AppColors.primary : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
