import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

/// Emergency badge shown on vet clinics that are open 24/7.
///
/// Extracted from both POICard and POIDetailScreen so the text, icon, and
/// styling are defined exactly once. Previously the card showed "24/7" and
/// the detail screen showed "חירום 24/7" — two users of the same concept
/// with two different representations.
class EmergencyBadge extends StatelessWidget {
  const EmergencyBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: AppRadius.fullRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            'חירום 24/7',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
