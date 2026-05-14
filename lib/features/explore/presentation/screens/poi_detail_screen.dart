import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
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
                  imageUrl: poi.imageUrl ?? 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&q=80&w=800',
                  fit: BoxFit.cover,
                ),
                // Gradient overlay for text legibility
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black26, Colors.transparent, Colors.black45],
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
                          style: AppTextStyles.headlineLg.copyWith(fontSize: 28),
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
                  
                  // Description / Info Section
                  Text('אודות המקום', style: AppTextStyles.headlineSm),
                  const SizedBox(height: 12),
                  Text(
                    'חווה טיפול פרימיום ומתקנים מודרניים ב-${poi.name}. ממוקם בלב העיר, אנו מספקים שירותים ברמה הגבוהה ביותר עבור בני הלוויה האהובים שלך.',
                    style: AppTextStyles.bodyLg.copyWith(color: AppColors.textSecondary),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Contact Actions
                  _buildContactSection(poi),
                  
                  const SizedBox(height: 40),
                  
                  // Map Integration
                  Text('מיקום', style: AppTextStyles.headlineSm),
                  const SizedBox(height: 16),
                  POIMapPlaceholder(
                    latitude: poi.latitude,
                    longitude: poi.longitude,
                    address: poi.address,
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
      case POIType.park: return 'גינה';
      case POIType.vet: return 'וטרינר';
      case POIType.store: return 'חנות';
    }
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
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
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStats(POI poi) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: AppColors.warning, size: 24),
        const SizedBox(width: 4),
        Text(
          poi.rating.toStringAsFixed(1),
          style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Text(
          '(${poi.reviewCount} חוות דעת)',
          style: AppTextStyles.labelMd,
        ),
        const Spacer(),
        const Icon(Icons.directions_walk, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 4),
        Text("800 מ' ממך", style: AppTextStyles.labelMd),
      ],
    );
  }

  Widget _buildContactSection(POI poi) {
    return Row(
      children: [
        if (poi.phoneNumber != null)
          Expanded(
            child: _buildActionBtn(
              icon: Icons.phone_outlined,
              label: 'התקשר עכשיו',
              onTap: () => launchUrl(Uri.parse('tel:${poi.phoneNumber}')),
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionBtn(
            icon: Icons.share_outlined,
            label: 'שתף',
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: AppRadius.lgRadius,
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
