import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

class ServiceTogglesCard extends StatelessWidget {
  final Map<String, bool> serviceAvailability;
  final Function(String) onToggle;

  const ServiceTogglesCard({
    super.key,
    required this.serviceAvailability,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'התאמת שירותים',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ServiceCard(
          label: 'טיולי כלבים',
          description: 'זמינות לטיולים יומיים',
          icon: Icons.directions_walk_rounded,
          isActive: serviceAvailability['walking'] ?? true,
          onTap: () => onToggle('walking'),
          accentColor: const Color(0xFF0EA5E9),
        ),
        const SizedBox(height: 12),
        _ServiceCard(
          label: 'שמירה על חיות',
          description: 'פנסיון ביתי ושירותי לילה',
          icon: Icons.home_work_rounded,
          isActive: serviceAvailability['sitting'] ?? true,
          onTap: () => onToggle('sitting'),
          accentColor: AppColors.primary,
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color accentColor;

  const _ServiceCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isActive ? accentColor.withOpacity(0.3) : AppColors.borderFaint,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
            )
          ] : AppShadows.subtle,
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isActive ? accentColor.withOpacity(0.1) : AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(
                  icon,
                  color: isActive ? accentColor : AppColors.textMuted,
                  size: 26,
                ),
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _StatusIndicator(isActive: isActive, color: accentColor),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool isActive;
  final Color color;

  const _StatusIndicator({required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 48,
      height: 28,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isActive ? color : AppColors.borderFaint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        alignment: isActive ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
