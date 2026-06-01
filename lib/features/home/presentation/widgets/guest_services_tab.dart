import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/empty_state_card.dart';
import 'package:petpal/core/widgets/section_header.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';


enum ServiceType { dogWalk, petSitting, available }

class ServiceCardData {
  final ServiceType type;
  final String name;
  final double rating;
  final String city;
  final String priceText;
  final String timeText;

  const ServiceCardData({
    required this.type,
    required this.name,
    required this.rating,
    required this.city,
    required this.priceText,
    required this.timeText,
  });
}

class GuestWalkServicesTab extends ConsumerWidget {
  final VoidCallback onRequireLogin;
  const GuestWalkServicesTab({super.key, required this.onRequireLogin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(walkServicesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (services) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          const SectionHeader(
            title: 'טיולים (Dog Walk)',
            subtitle: 'תצוגה בלבד כאורח • התחבר/י להזמנה',
          ),
          const SizedBox(height: 10),
          if (services.isEmpty)
            const EmptyStateCard(
              title: 'אין שירותי טיול זמינים',
              subtitle: 'נסה/י שוב מאוחר יותר.',
              icon: Icons.directions_walk_rounded,
            )
          else
            ...services.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ModernServiceCardLocked(
                  data: ServiceCardData(
                    type: ServiceType.dogWalk,
                    name: s.providerName,
                    rating: s.rating ?? 0,
                    city: s.area,
                    priceText: s.priceText,
                    timeText: s.duration,
                  ),
                  onPressed: onRequireLogin,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GuestSittingServicesTab extends ConsumerWidget {
  final VoidCallback onRequireLogin;
  const GuestSittingServicesTab({super.key, required this.onRequireLogin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sittingServicesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (services) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          const SectionHeader(
            title: 'שמירה (Pet Sitting)',
            subtitle: 'תצוגה בלבד כאורח • התחבר/י להזמנה',
          ),
          const SizedBox(height: 10),
          if (services.isEmpty)
            const EmptyStateCard(
              title: 'אין שירותי שמירה זמינים',
              subtitle: 'נסה/י שוב מאוחר יותר.',
              icon: Icons.house_rounded,
            )
          else
            ...services.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ModernServiceCardLocked(
                  data: ServiceCardData(
                    type: ServiceType.petSitting,
                    name: s.providerName,
                    rating: s.rating ?? 0,
                    city: s.area,
                    priceText: s.priceText,
                    timeText: s.sittingLocation,
                  ),
                  onPressed: onRequireLogin,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModernServiceCardLocked extends StatelessWidget {
  final ServiceCardData data;
  final VoidCallback onPressed;

  const _ModernServiceCardLocked({
    required this.data,
    required this.onPressed,
  });

  String get _typeLabel {
    switch (data.type) {
      case ServiceType.dogWalk:
        return 'Dog Walk';
      case ServiceType.petSitting:
        return 'Pet Sitting';
      case ServiceType.available:
        return 'זמין';
    }
  }

  IconData get _typeIcon {
    switch (data.type) {
      case ServiceType.dogWalk:
        return Icons.directions_walk_rounded;
      case ServiceType.petSitting:
        return Icons.home_work_rounded;
      case ServiceType.available:
        return Icons.flash_on_rounded;
    }
  }

  Color get _accent {
    switch (data.type) {
      case ServiceType.dogWalk:
        return AppColors.smartBlue;
      case ServiceType.petSitting:
        return AppColors.primary;
      case ServiceType.available:
        return AppColors.statusOpen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
                  color: _accent.withValues(alpha: 0.14),
                ),
                child: Icon(_typeIcon, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.city} • ${data.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.timeText} • ${data.priceText}',
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.borderFaint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      data.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _accent.withValues(alpha: 0.12),
                ),
                child: Text(
                  '$_typeLabel • 🔒',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: _accent,
                  ),
                ),
              ),
              const Spacer(),
              _MiniLockButton(
                text: 'בקשת הזמנה',
                onTap: onPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniLockButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _MiniLockButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.primary, AppColors.statusOpen],
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'בקשת הזמנה',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
