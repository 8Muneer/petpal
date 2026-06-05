import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/features/explore/domain/entities/poi_model.dart';
import 'package:petpal/features/explore/presentation/providers/poi_provider.dart';
import 'package:petpal/features/explore/presentation/widgets/poi_map_placeholder.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class POIDetailScreen extends ConsumerWidget {
  final String poiId;

  const POIDetailScreen({super.key, required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poiAsync = ref.watch(poiByIdProvider(poiId));

    return Scaffold(
      body: poiAsync.when(
        data: (poi) {
          if (poi == null) return const Center(child: Text('המקום לא נמצא'));
          return _buildContent(context, poi);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('שגיאה: $err')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, POI poi) {
    return CustomScrollView(
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
                      if (poi.isEmergency) _buildEmergencyBadge(),
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

                  // Rating & Reviews
                  _buildStats(poi),

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

                  // Opening hours
                  if (poi.open24h || poi.openingHours.isNotEmpty) ...[
                    _buildSectionHeader('שעות פעילות'),
                    const SizedBox(height: 12),
                    _buildHoursSection(poi),
                    const SizedBox(height: 32),
                  ],

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

                  // Map Integration
                  _buildSectionHeader('מיקום'),
                  const SizedBox(height: 16),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: AppRadius.organicRadius,
                      child: POIMapPlaceholder(
                        latitude: poi.latitude,
                        longitude: poi.longitude,
                        address: poi.address,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
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
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildEmergencyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: AppRadius.fullRadius,
      ),
      child: const Text(
        'חירום 24/7',
        style: TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a.clamp(0.0, 1.0))); // Distance in km
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

  Widget _buildStats(POI poi) {
    // Default location (Tel Aviv) for demonstration
    const double userLat = 32.0853;
    const double userLng = 34.7818;
    final distanceKm =
        _calculateDistance(userLat, userLng, poi.latitude, poi.longitude);

    final String distanceText;
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      distanceText = "$meters מ' ממך";
    } else {
      distanceText = "${distanceKm.toStringAsFixed(1)} ק\"מ ממך";
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
          const Spacer(),
          const Icon(Icons.directions_walk,
              color: AppColors.textMuted, size: 18),
          const SizedBox(width: 4),
          Text(distanceText, style: AppTextStyles.labelMd),
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
      _buildActionBtn(
        icon: Icons.share_outlined,
        label: 'שתף',
        onTap: () {},
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
