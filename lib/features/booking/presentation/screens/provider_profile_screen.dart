import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/utils/price_formatter.dart';
import 'package:petpal/features/messaging/data/datasources/messaging_datasource.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';
import 'package:petpal/features/reviews/domain/entities/review.dart';
import 'package:petpal/features/reviews/presentation/providers/review_provider.dart';
import 'package:petpal/features/walks/domain/entities/walk_service.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';

class ProviderProfileScreen extends ConsumerStatefulWidget {
  final WalkService? walkService;
  final SittingService? sittingService;

  const ProviderProfileScreen.walk({super.key, required WalkService service})
      : walkService = service,
        sittingService = null;

  const ProviderProfileScreen.sitting(
      {super.key, required SittingService service})
      : sittingService = service,
        walkService = null;

  @override
  ConsumerState<ProviderProfileScreen> createState() =>
      _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> {
  bool _chatLoading = false;

  String get _providerName =>
      widget.walkService?.providerName ??
      widget.sittingService?.providerName ??
      '';
  String? get _providerPhoto =>
      widget.walkService?.providerPhotoUrl ??
      widget.sittingService?.providerPhotoUrl;
  String get _providerUid =>
      widget.walkService?.providerUid ??
      widget.sittingService?.providerUid ??
      '';
  String get _serviceId =>
      widget.walkService?.id ?? widget.sittingService?.id ?? '';
  String get _area =>
      widget.walkService?.area ?? widget.sittingService?.area ?? '';
  String get _priceText =>
      widget.walkService?.priceText ?? widget.sittingService?.priceText ?? '';
  String get _priceType =>
      widget.walkService?.priceType ?? widget.sittingService?.priceType ?? '';
  String? get _bio =>
      widget.walkService?.bio ?? widget.sittingService?.bio;
  List<String> get _petTypes =>
      widget.walkService?.petTypes ??
      widget.sittingService?.petTypes ??
      [];
  List<String> get _availableDays =>
      widget.walkService?.availableDays ??
      widget.sittingService?.availableDays ??
      [];
  bool get _isWalk => widget.walkService != null;

  static const _allDays = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];

  Future<void> _startChat() async {
    setState(() => _chatLoading = true);
    try {
      final me = FirebaseAuth.instance.currentUser;
      if (me == null) return;
      final myProfile = ref.read(currentUserProfileProvider).asData?.value;
      final myPhotoUrl = myProfile?.photoUrl ?? me.photoURL ?? '';
      final providerPhotoUrl = _providerPhoto ?? '';
      final ds = MessagingDatasource(db: FirebaseFirestore.instance);
      final convoId = await ds.getOrCreateConversation(
        myUid: me.uid,
        myName: me.displayName ?? me.email ?? 'משתמש',
        otherUid: _providerUid,
        otherName: _providerName,
        myPhotoUrl: myPhotoUrl,
        otherPhotoUrl: providerPhotoUrl,
      );
      if (mounted) {
        context.push('/chat/$convoId', extra: {
          'otherName': _providerName,
          'otherPhotoUrl': providerPhotoUrl,
          'otherUid': _providerUid,
        });
      }
    } finally {
      if (mounted) setState(() => _chatLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingAsync = ref.watch(providerRatingProvider(_providerUid));
    final reviewsAsync = ref.watch(providerReviewsProvider(_providerUid));
    final currentUserUid =
        ref.watch(authStateChangesProvider).asData?.value?.uid;
    final isOwnProfile = currentUserUid == _providerUid;
    final displayPrice = formatPrice(_priceText, _priceType);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: CustomScrollView(
            slivers: [
              _buildHeroAppBar(context),
              SliverToBoxAdapter(
                child: _buildContent(
                  ratingAsync: ratingAsync,
                  reviewsAsync: reviewsAsync,
                  displayPrice: displayPrice,
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, isOwnProfile: isOwnProfile),
        ),
      ),
    );
  }

  Widget _buildHeroAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 300,
      backgroundColor: AppColors.prussianBlue3,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.prussianBlue3.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.prussianBlue3,
              size: 20,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        titlePadding: const EdgeInsetsDirectional.fromSTEB(56, 0, 16, 14),
        title: Text(
          _providerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.frankRuhlLibre(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        background: _buildHeroBackground(),
      ),
    );
  }

  Widget _buildHeroBackground() {
    final photo = _providerPhoto;
    if (photo != null && photo.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photo,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            Container(color: AppColors.prussianBlue),
        errorWidget: (_, __, ___) => _solidHeroPlaceholder(),
      );
    }
    return _solidHeroPlaceholder();
  }

  Widget _solidHeroPlaceholder() {
    return Container(
      color: AppColors.prussianBlue,
      child: Center(
        child: Text(
          _providerName.isNotEmpty
              ? _providerName.characters.first.toUpperCase()
              : '?',
          style: GoogleFonts.frankRuhlLibre(
            fontSize: 96,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required AsyncValue<({double avg, int count})> ratingAsync,
    required AsyncValue<List<Review>> reviewsAsync,
    required String displayPrice,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Identity block ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildIdentity(ratingAsync),
          ),

          const SizedBox(height: 28),

          // ── Price + service detail ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildDetailsCard(displayPrice),
          ),

          // ── Pet types ───────────────────────────────────────────────────
          if (_petTypes.isNotEmpty) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSection(
                title: 'חיות מטופלות',
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _petTypes
                        .map((p) => _PillChip(
                              label: p,
                              icon: Icons.pets_rounded,
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],

          // ── Availability ────────────────────────────────────────────────
          if (_availableDays.isNotEmpty) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSection(
                title: 'ימי זמינות',
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: _AvailabilityRow(
                    allDays: _allDays,
                    activeDays: _availableDays,
                  ),
                ),
              ),
            ),
          ],

          // ── Bio ─────────────────────────────────────────────────────────
          if (_bio != null && _bio!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSection(
                title: 'על נותן השירות',
                child: AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"',
                        style: GoogleFonts.frankRuhlLibre(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary.withValues(alpha: 0.15),
                          height: 0.8,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _bio!,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textPrimary.withValues(alpha: 0.85),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // ── Reviews ─────────────────────────────────────────────────────
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildReviews(ratingAsync, reviewsAsync),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildIdentity(AsyncValue<({double avg, int count})> ratingAsync) {
    final isActive =
        widget.walkService?.isActive ?? widget.sittingService?.isActive ?? false;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.pureWhite, width: 3),
            boxShadow: AppShadows.subtle,
          ),
          child: ClipOval(child: _buildAvatarImage()),
        ),

        const SizedBox(width: 14),

        // Name + meta
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _providerName,
                      style: GoogleFonts.frankRuhlLibre(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.statusOpenLight,
                        borderRadius: AppRadius.fullRadius,
                        border: Border.all(
                            color: AppColors.statusOpen.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'זמין',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.statusOpen,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFaint,
                      borderRadius: AppRadius.fullRadius,
                    ),
                    child: Text(
                      _isWalk ? 'טיולי כלבים' : 'שמירה על חיות',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.location_on_outlined,
                      size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Text(
                    _area,
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.textMuted),
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
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 15, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            r.avg.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${r.count} ביקורות)',
                            style: AppTextStyles.labelMd
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarImage() {
    final photo = _providerPhoto;
    if (photo != null && photo.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photo,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            Container(color: AppColors.prussianBlue),
        errorWidget: (_, __, ___) => _avatarPlaceholder(),
      );
    }
    return _avatarPlaceholder();
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: AppColors.prussianBlue,
      child: Center(
        child: Text(
          _providerName.isNotEmpty
              ? _providerName.characters.first.toUpperCase()
              : '?',
          style: GoogleFonts.frankRuhlLibre(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(String displayPrice) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'מחיר',
            value: displayPrice,
            valueColor: AppColors.primary,
            valueBold: true,
          ),
          const _RowDivider(),
          _DetailRow(
            icon: _isWalk
                ? Icons.directions_walk_rounded
                : Icons.home_rounded,
            label: 'סוג שירות',
            value: _isWalk ? 'טיולי כלבים' : 'שמירה על חיות',
          ),
          if (_isWalk && widget.walkService != null) ...[
            const _RowDivider(),
            _DetailRow(
              icon: Icons.timer_outlined,
              label: 'משך טיול',
              value: widget.walkService!.duration,
            ),
          ],
          if (!_isWalk && widget.sittingService != null) ...[
            const _RowDivider(),
            _DetailRow(
              icon: Icons.swap_horiz_rounded,
              label: 'מיקום שמירה',
              value: widget.sittingService!.sittingLocation,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({required String title, String? subtitle, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: subtitle != null ? 30 : 20,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headlineSm),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.labelMd),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildReviews(
    AsyncValue<({double avg, int count})> ratingAsync,
    AsyncValue<List<Review>> reviewsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
            Expanded(
              child: Text('ביקורות', style: AppTextStyles.headlineSm),
            ),
            ratingAsync.whenOrNull(
              data: (r) => r.count > 0
                  ? Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          r.avg.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '· ${r.count}',
                          style: AppTextStyles.labelMd
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    )
                  : null,
            ) ??
                const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: 12),
        reviewsAsync.when(
          loading: () => const _ReviewsSkeleton(),
          error: (_, __) => const SizedBox.shrink(),
          data: (reviews) {
            if (reviews.isEmpty) {
              return AppCard(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.rate_review_outlined,
                          size: 32, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text(
                        'עדיין אין ביקורות לספק זה',
                        style: AppTextStyles.labelMd
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              );
            }
            final shown = reviews.take(3).toList();
            return Column(
              children: [
                ...shown.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReviewCard(review: r),
                    )),
                if (reviews.length > 3)
                  GestureDetector(
                    onTap: () {}, // future: push reviews screen
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.lgRadius,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          'ראה את כל הביקורות (${reviews.length})',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, {required bool isOwnProfile}) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          border: const Border(top: BorderSide(color: AppColors.divider)),
          boxShadow: [
            BoxShadow(
              color: AppColors.prussianBlue3.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: isOwnProfile
            ? SizedBox(
                width: double.infinity,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.lgRadius,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      'זהו הפרופיל שלך',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            : Row(
                children: [
                  // Message button
                  Expanded(
                    child: GestureDetector(
                      onTap: _chatLoading ? null : _startChat,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite,
                          borderRadius: AppRadius.lgRadius,
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Center(
                          child: _chatLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'שלח הודעה',
                                      style: AppTextStyles.bodyMd.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Book button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push(
                        '/bookings/create',
                        extra: {
                          'providerUid': _providerUid,
                          'providerName': _providerName,
                          'providerPhotoUrl': _providerPhoto,
                          'serviceId': _serviceId,
                          'serviceType': _isWalk ? 'walk' : 'sitting',
                          'priceText': _priceText,
                          'priceType': _priceType,
                        },
                      ),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadius.lgRadius,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'הזמן עכשיו',
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _AvailabilityRow extends StatelessWidget {
  final List<String> allDays;
  final List<String> activeDays;

  const _AvailabilityRow({
    required this.allDays,
    required this.activeDays,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: allDays.map((day) {
        final isActive = activeDays.contains(day);
        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : AppColors.pureWhite,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _PillChip({required this.label, this.icon});

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
            Icon(icon, size: 13, color: AppColors.primary),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.labelMd
                .copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodyMd.copyWith(
              fontWeight: valueBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16);
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryFaint,
                ),
                child: Center(
                  child: Text(
                    review.reviewerName.isNotEmpty
                        ? review.reviewerName.characters.first.toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: i < review.rating
                              ? AppColors.warning
                              : AppColors.border,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: AppTextStyles.labelSm
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'ינו', 'פבר', 'מרץ', 'אפר', 'מאי', 'יוני',
      'יולי', 'אוג', 'ספט', 'אוק', 'נוב', 'דצמ',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}

class _ReviewsSkeleton extends StatelessWidget {
  const _ReviewsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: AppRadius.lgRadius,
              border: Border.all(color: AppColors.border),
            ),
          ),
        ),
      ),
    );
  }
}
