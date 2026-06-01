import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/reviews/presentation/providers/review_provider.dart';
import 'package:petpal/features/walks/domain/entities/walk_service.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';

class ProviderProfileScreen extends ConsumerWidget {
  final WalkService? walkService;
  final SittingService? sittingService;

  const ProviderProfileScreen.walk({super.key, required WalkService service})
      : walkService = service,
        sittingService = null;

  const ProviderProfileScreen.sitting(
      {super.key, required SittingService service})
      : sittingService = service,
        walkService = null;

  String get _providerName =>
      walkService?.providerName ?? sittingService?.providerName ?? '';
  String? get _providerPhoto =>
      walkService?.providerPhotoUrl ?? sittingService?.providerPhotoUrl;
  String get _providerUid =>
      walkService?.providerUid ?? sittingService?.providerUid ?? '';
  String get _serviceId => walkService?.id ?? sittingService?.id ?? '';
  String get _area => walkService?.area ?? sittingService?.area ?? '';
  String get _priceText =>
      walkService?.priceText ?? sittingService?.priceText ?? '';
  String get _priceType =>
      walkService?.priceType ?? sittingService?.priceType ?? '';
  String? get _bio => walkService?.bio ?? sittingService?.bio;
  List<String> get _petTypes =>
      walkService?.petTypes ?? sittingService?.petTypes ?? [];
  List<String> get _availableDays =>
      walkService?.availableDays ?? sittingService?.availableDays ?? [];
  bool get _isWalk => walkService != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(providerRatingProvider(_providerUid));
    final currentUserUid = ref.watch(authStateChangesProvider).asData?.value?.uid;
    final isOwnProfile = currentUserUid == _providerUid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context, ratingAsync),
            SliverToBoxAdapter(child: _buildBody(context)),
          ],
        ),
        bottomNavigationBar: _buildBookButton(context, isOwnProfile: isOwnProfile),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AsyncValue<({double avg, int count})> ratingAsync) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded,
                color: AppColors.onSurface, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  _buildAvatar(),
                  const SizedBox(height: 12),
                  Text(
                    _providerName,
                    style: AppTextStyles.headlineMd
                        .copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        _area,
                        style: AppTextStyles.labelMd
                            .copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ratingAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (r) => r.count == 0
                        ? const SizedBox.shrink()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 15, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${r.avg.toStringAsFixed(1)}  (${r.count})',
                                style: AppTextStyles.labelMd
                                    .copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final photo = _providerPhoto;
    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      backgroundImage: (photo != null && photo.isNotEmpty)
          ? CachedNetworkImageProvider(photo)
          : null,
      child: (photo == null || photo.isEmpty)
          ? Text(
              _providerName.isNotEmpty
                  ? _providerName.characters.first.toUpperCase()
                  : '?',
              style: AppTextStyles.headlineLg.copyWith(color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price & type card
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'מחיר',
                value: '$_priceText • $_priceType',
              ),
              const Divider(height: 20, color: AppColors.divider),
              _InfoRow(
                icon: _isWalk
                    ? Icons.directions_walk_rounded
                    : Icons.home_rounded,
                label: 'סוג שירות',
                value: _isWalk ? 'טיולי כלבים' : 'שמירה על חיות',
              ),
              if (!_isWalk && sittingService != null) ...[
                const Divider(height: 20, color: AppColors.divider),
                _InfoRow(
                  icon: Icons.swap_horiz_rounded,
                  label: 'מיקום שמירה',
                  value: sittingService!.sittingLocation,
                ),
              ],
              if (_isWalk && walkService != null) ...[
                const Divider(height: 20, color: AppColors.divider),
                _InfoRow(
                  icon: Icons.timer_outlined,
                  label: 'משך טיול',
                  value: walkService!.duration,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Pet types
          if (_petTypes.isNotEmpty) ...[
            Text('חיות מטופלות', style: AppTextStyles.headlineSm),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _petTypes
                  .map((p) => _Chip(label: p, icon: Icons.pets_rounded))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Available days
          if (_availableDays.isNotEmpty) ...[
            Text('ימי זמינות', style: AppTextStyles.headlineSm),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableDays
                  .map((d) => _Chip(label: 'יום $d'))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Bio
          if (_bio != null && _bio!.isNotEmpty) ...[
            Text('על נותן השירות', style: AppTextStyles.headlineSm),
            const SizedBox(height: 10),
            _InfoCard(
              children: [
                Text(_bio!, style: AppTextStyles.bodyMd),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookButton(BuildContext context, {required bool isOwnProfile}) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: isOwnProfile
                ? null
                : () => context.push(
                      '/bookings/create',
                      extra: {
                        'providerUid': _providerUid,
                        'providerName': _providerName,
                        'providerPhotoUrl': _providerPhoto,
                        'serviceId': _serviceId,
                        'serviceType': _isWalk ? 'walk' : 'sitting',
                        'priceText': _priceText,
                      },
                    ),
            icon: Icon(isOwnProfile
                ? Icons.person_rounded
                : Icons.calendar_month_rounded),
            label: Text(isOwnProfile ? 'הפרופיל שלך' : 'הזמן עכשיו'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle: AppTextStyles.bodyMd
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(label,
            style: AppTextStyles.labelMd
                .copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style:
                AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _Chip({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: AppRadius.fullRadius,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: AppTextStyles.labelMd
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
