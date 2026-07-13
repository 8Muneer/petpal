import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/location_provider.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/utils/geo.dart';
import 'package:petpal/features/explore/domain/entities/poi_model.dart';
import 'package:petpal/features/explore/presentation/widgets/emergency_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ── Today's-hours helper ────────────────────────────────────────────────────

/// Maps Dart's [DateTime.weekday] (Mon=1 … Sun=7) to the storage key used in
/// [POI.openingHours] (sun, mon, … sat).
const _weekdayKey = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

/// Returns a displayable string for today's opening hours, or null if the
/// place is closed today or no hours have been entered.
String? _todayHours(POI poi) {
  if (poi.open24h) return 'פתוח 24/7';
  if (poi.openingHours.isEmpty) return null;
  final key = _weekdayKey[DateTime.now().weekday - 1];
  final raw = poi.openingHours[key];
  if (raw == null || raw.isEmpty) return 'סגור היום';
  return raw; // e.g. "09:00-18:00"
}

// ── Widget ──────────────────────────────────────────────────────────────────

class POICard extends ConsumerWidget {
  final POI poi;
  final VoidCallback? onTap;
  final bool isCompact;

  const POICard({
    super.key,
    required this.poi,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch device location so the distance label updates when GPS resolves.
    // Using valueOrNull means the card renders immediately — distance just
    // shows '...' while loading and the real value once the fix arrives.
    final locationAsync = ref.watch(locationProvider);
    final userLocation = locationAsync.valueOrNull;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isCompact ? 280 : double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.organicRadius,
          boxShadow: AppShadows.premium,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image with badges ──────────────────────────────────────────
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: isCompact ? 16 / 9 : 16 / 7,
                  child: CachedNetworkImage(
                    imageUrl: (poi.imageUrls.isNotEmpty
                        ? poi.imageUrls.first
                        : poi.imageUrl) ??
                        'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&q=80&w=800',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.surfaceDark,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surfaceDark,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                // effectiveIsEmergency enforces the invariant that the badge
                // only appears on vets, even if Firestore has stale data.
                if (poi.effectiveIsEmergency)
                  const Positioned(
                    top: 12,
                    right: 12,
                    child: EmergencyBadge(),
                  ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: _buildTypeBadge(),
                ),
              ],
            ),

            // ── Content ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + rating on one row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          poi.name,
                          style: AppTextStyles.headlineSm,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildRatingBadge(),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Meta row: address • distance • open status
                  _buildMetaRow(userLocation),
                  const SizedBox(height: 10),

                  // Services / tags chip row (max 3 chips + overflow count)
                  if (_chips.isNotEmpty) _buildChipRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Meta row ─────────────────────────────────────────────────────────────

  Widget _buildMetaRow(({double lat, double lng})? userLocation) {
    final items = <Widget>[];

    // Address
    if ((poi.address ?? '').isNotEmpty) {
      items.add(
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  poi.address!,
                  style: AppTextStyles.labelSm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Distance — only when both POI coords and device location exist
    if (poi.latitude != null && poi.longitude != null) {
      final String distText;
      if (userLocation == null) {
        distText = '...';
      } else {
        final km = distanceKm(
            userLocation.lat, userLocation.lng, poi.latitude!, poi.longitude!);
        distText = formatDistance(km);
      }
      if (items.isNotEmpty) items.add(_dot());
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_walk_rounded,
                size: 13, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Text(distText, style: AppTextStyles.labelSm),
          ],
        ),
      );
    }

    // Open status
    final hours = _todayHours(poi);
    if (hours != null) {
      if (items.isNotEmpty) items.add(_dot());
      final isOpen24 = poi.open24h;
      items.add(
        Text(
          hours,
          style: AppTextStyles.labelSm.copyWith(
            color: isOpen24 ? AppColors.success : AppColors.textSecondary,
            fontWeight: isOpen24 ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      children: items,
    );
  }

  Widget _dot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Text('·',
            style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted)),
      );

  // ── Services / tags chip row ──────────────────────────────────────────────

  /// Combined list of chips to show: services first, then tags.
  List<String> get _chips => [...poi.services, ...poi.tags];

  Widget _buildChipRow() {
    const maxVisible = 3;
    final all = _chips;
    final visible = all.take(maxVisible).toList();
    final overflow = all.length - maxVisible;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final label in visible) _chip(label),
        if (overflow > 0) _chip('+$overflow', muted: true),
      ],
    );
  }

  Widget _chip(String label, {bool muted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: muted
            ? AppColors.surfaceDark
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: muted
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: muted ? AppColors.textMuted : AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Rating badge ──────────────────────────────────────────────────────────

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
          const SizedBox(width: 3),
          Text(
            poi.rating.toStringAsFixed(1),
            style: AppTextStyles.labelSm.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (poi.reviewCount > 0) ...[
            const SizedBox(width: 3),
            Text(
              '(${poi.reviewCount})',
              style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  // ── Type badge ────────────────────────────────────────────────────────────

  Widget _buildTypeBadge() {
    final typeName = switch (poi.type) {
      POIType.park => 'גינה',
      POIType.vet => 'וטרינר',
      POIType.store => 'חנות',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.glassOverlay,
        borderRadius: AppRadius.fullRadius,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        typeName,
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
