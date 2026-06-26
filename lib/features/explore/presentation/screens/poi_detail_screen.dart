import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/location_provider.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/utils/geo.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/features/explore/domain/entities/poi_model.dart';
import 'package:petpal/features/explore/presentation/providers/poi_provider.dart';
import 'package:petpal/features/explore/presentation/widgets/emergency_badge.dart';
import 'package:petpal/features/explore/presentation/widgets/poi_map_placeholder.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class POIDetailScreen extends ConsumerWidget {
  final String poiId;

  const POIDetailScreen({super.key, required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poiAsync = ref.watch(poiByIdProvider(poiId));

    // Watch location separately from the POI — the detail screen can render
    // immediately with "..." for distance and update when the GPS fix arrives,
    // instead of blocking the whole screen on location.
    final locationAsync = ref.watch(locationProvider);

    return Scaffold(
      body: poiAsync.when(
        data: (poi) {
          if (poi == null) return const Center(child: Text('המקום לא נמצא'));
          // Pass the nullable location value — null while loading, real coords once ready.
          return _buildContent(context, poi, locationAsync.valueOrNull);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('שגיאה: $err')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, POI poi,
      ({double lat, double lng})? userLocation) {
    // The detail screen renders Hebrew content — force RTL so text alignment,
    // row direction, and widget mirroring all match the app's language direction.
    // The SliverAppBar back button uses `leading` which in RTL sits on the right,
    // matching the standard Israeli app convention (back arrow on the right).
    return Directionality(
      textDirection: TextDirection.rtl,
      child: CustomScrollView(
      slivers: [
        // 1. Hero Image App Bar
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          stretch: true,
          backgroundColor: AppColors.surface,
          leading: _buildBackButton(context),
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: poi.imageUrl ??
                      'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&q=80&w=800',
                  fit: BoxFit.cover,
                ),
                // Gradient overlay for text legibility
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black26,
                        Colors.transparent,
                        Colors.black45
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Main Content
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Badge Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          poi.name,
                          style:
                              AppTextStyles.headlineLg.copyWith(fontSize: 28),
                        ),
                      ),
                      if (poi.effectiveIsEmergency) const EmergencyBadge(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getTypeName(poi.type),
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Rating & Reviews — shows real distance once GPS resolves.
                  _buildStats(poi, userLocation),

                  const SizedBox(height: 32),

                  // Description
                  if ((poi.description ?? '').trim().isNotEmpty) ...[
                    _buildSectionHeader('אודות המקום'),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        poi.description!.trim(),
                        style: AppTextStyles.bodyLg.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Opening hours — always shown so the user knows whether the
                  // place has no hours set vs. just not being open that day.
                  // Previously the entire section was silently skipped when
                  // openingHours was empty, which was ambiguous.
                  _buildSectionHeader('שעות פעילות'),
                  const SizedBox(height: 12),
                  _buildHoursSection(poi),
                  const SizedBox(height: 32),

                  // Services / amenities
                  if (poi.services.isNotEmpty) ...[
                    _buildSectionHeader(_servicesHeader(poi.type)),
                    const SizedBox(height: 12),
                    _buildServicesSection(poi),
                    const SizedBox(height: 32),
                  ],

                  // Contact Actions
                  _buildContactSection(context, poi),

                  const SizedBox(height: 40),

                  // Map section only renders when the admin entered coordinates.
                  // If the POI has no lat/lng the section disappears entirely
                  // rather than showing a broken or empty map placeholder.
                  if (poi.latitude != null && poi.longitude != null) ...[
                    _buildSectionHeader('מיקום'),
                    const SizedBox(height: 16),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: AppRadius.organicRadius,
                        child: POIMapPlaceholder(
                          latitude: poi.latitude!,
                          longitude: poi.longitude!,
                          address: poi.address,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ],
    ), // CustomScrollView
    ); // Directionality
  }

  String _getTypeName(POIType type) {
    switch (type) {
      case POIType.park:
        return 'גינה';
      case POIType.vet:
        return 'וטרינר';
      case POIType.store:
        return 'חנות';
    }
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        child: IconButton(
          // In RTL the leading slot is on the right side of the AppBar.
          // arrow_forward_ios points left (toward the start of the screen),
          // which is the correct visual direction for "go back" in RTL.
          icon: const Icon(Icons.arrow_forward_ios,
              size: 18, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: AppTextStyles.headlineSm),
      ],
    );
  }

  // userLocation is null while GPS is loading; poi.latitude/longitude may be
  // null when the admin didn't enter coordinates — hide distance in that case.
  Widget _buildStats(POI poi, ({double lat, double lng})? userLocation) {
    // Only compute distance when both the POI coords and device location exist.
    final bool hasCoords = poi.latitude != null && poi.longitude != null;
    final String? distanceText;
    if (!hasCoords) {
      distanceText = null; // no coords → no distance chip
    } else if (userLocation == null) {
      distanceText = '...'; // coords exist but GPS still loading
    } else {
      final km = distanceKm(
          userLocation.lat, userLocation.lng, poi.latitude!, poi.longitude!);
      distanceText = formatDistance(km);
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: AppColors.warning, size: 24),
          const SizedBox(width: 4),
          Text(
            poi.rating.toStringAsFixed(1),
            style:
                AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            '(${poi.reviewCount} חוות דעת)',
            style: AppTextStyles.labelMd,
          ),
          if (distanceText != null) ...[
            const Spacer(),
            const Icon(Icons.directions_walk,
                color: AppColors.textMuted, size: 18),
            const SizedBox(width: 4),
            Text(distanceText, style: AppTextStyles.labelMd),
          ],
        ],
      ),
    );
  }

  static const List<(String, String)> _days = [
    ('sun', 'ראשון'),
    ('mon', 'שני'),
    ('tue', 'שלישי'),
    ('wed', 'רביעי'),
    ('thu', 'חמישי'),
    ('fri', 'שישי'),
    ('sat', 'שבת'),
  ];

  String _servicesHeader(POIType type) {
    switch (type) {
      case POIType.vet:
        return 'שירותים';
      case POIType.store:
        return 'קטגוריות';
      case POIType.park:
        return 'מתקנים';
    }
  }

  Widget _buildHoursSection(POI poi) {
    if (poi.open24h) {
      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded, color: AppColors.success),
            const SizedBox(width: 10),
            Text('פתוח 24 שעות ביממה',
                style:
                    AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    // No hours data at all — show an explicit "not specified" state instead
    // of a weekly table where every row says "סגור". This makes it clear that
    // the admin hasn't entered hours yet, not that the place is always closed.
    if (poi.openingHours.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 10),
            Text(
              'שעות פעילות לא צוינו',
              style: AppTextStyles.bodyLg.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          for (final (key, label) in _days)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(label,
                        style: AppTextStyles.bodyMd
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  Text(
                    (poi.openingHours[key]?.isNotEmpty ?? false)
                        ? poi.openingHours[key]!
                        : 'סגור',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: (poi.openingHours[key]?.isNotEmpty ?? false)
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(POI poi) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: poi.services
          .map((s) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: AppRadius.fullRadius,
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  s,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildContactSection(BuildContext context, POI poi) {
    final half =
        (MediaQuery.of(context).size.width - 48 - 12) / 2; // 24px page padding
    final actions = <Widget>[
      if ((poi.phoneNumber ?? '').isNotEmpty)
        _buildActionBtn(
          icon: Icons.phone_outlined,
          label: 'התקשר',
          onTap: () => launchUrl(Uri.parse('tel:${poi.phoneNumber}')),
        ),
      if ((poi.website ?? '').isNotEmpty)
        _buildActionBtn(
          icon: Icons.language_outlined,
          label: 'אתר',
          onTap: () => launchUrl(
            Uri.parse(poi.website!),
            mode: LaunchMode.externalApplication,
          ),
        ),
      if ((poi.email ?? '').isNotEmpty)
        _buildActionBtn(
          icon: Icons.email_outlined,
          label: 'אימייל',
          onTap: () => launchUrl(Uri.parse('mailto:${poi.email}')),
        ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final a in actions) SizedBox(width: half, child: a),
      ],
    );
  }

  Widget _buildActionBtn(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.organicRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(label,
                  style: AppTextStyles.labelSm
                      .copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
