import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_header_bar.dart';
import 'package:petpal/features/walks/presentation/widgets/walk_request_widgets.dart'
    show WalkRequestsView, WalkRequestCard;
import 'package:petpal/features/sitting/presentation/widgets/sitting_request_widgets.dart'
    show SittingRequestsView, SittingRequestCard;
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart'
    show SittingRequest;
import 'package:petpal/features/walks/domain/entities/walk_request.dart'
    show WalkRequest;
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart'
    show sittingRequestsProvider;
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart'
    show walkRequestsProvider;
import 'package:petpal/features/booking/presentation/providers/booking_provider.dart'
    show myBookingsProvider;
import 'package:petpal/features/booking/domain/entities/booking_request.dart'
    show BookingRequest, BookingServiceType, BookingStatus;
import 'package:petpal/features/reviews/presentation/providers/review_provider.dart'
    show bookingReviewProvider;

// ═══════════════════════════════════════════════════════════════════════════
// Sitting Request Home Card (used in Home Tab)
// ═══════════════════════════════════════════════════════════════════════════

class SittingRequestHomeCard extends StatelessWidget {
  final SittingRequest request;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;

  const SittingRequestHomeCard({
    super.key,
    required this.request,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: AppRadius.organicRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.premium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.home_work_outlined,
                      size: 18, color: AppColors.primary),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel,
                      style: AppTextStyles.labelSm.copyWith(
                          color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(request.petName, style: AppTextStyles.headlineSm),
            const SizedBox(height: 4),
            Text(request.area,
                style:
                    AppTextStyles.labelMd.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Walk Request Home Card (used in Home Tab)
// ═══════════════════════════════════════════════════════════════════════════

class WalkRequestHomeCard extends StatelessWidget {
  final WalkRequest request;
  final VoidCallback onTap;

  const WalkRequestHomeCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: AppRadius.organicRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.premium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_walk_outlined,
                      size: 18, color: AppColors.primary),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('טיול',
                      style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(request.petName, style: AppTextStyles.headlineSm),
            const SizedBox(height: 4),
            Text(request.area,
                style:
                    AppTextStyles.labelMd.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// הבקשות שלי Tab — combines walk requests + sitting requests
// ═══════════════════════════════════════════════════════════════════════════

class MyRequestsTab extends ConsumerStatefulWidget {
  const MyRequestsTab({super.key});

  @override
  ConsumerState<MyRequestsTab> createState() => _MyRequestsTabState();
}

class _MyRequestsTabState extends ConsumerState<MyRequestsTab> {
  int _selected = 0; // 0 = הכל (default)

  static const _filters = ['הכל', 'בקשות טיולים', 'בקשות שמירה', 'הזמנות'];

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('צור בקשה חדשה', style: AppTextStyles.headlineSm),
              const SizedBox(height: 6),
              Text('בחר את סוג הבקשה שתרצה להגיש',
                  style: AppTextStyles.labelMd),
              const SizedBox(height: 20),
              // Walks option
              _CreateOptionTile(
                icon: Icons.directions_walk_rounded,
                color: AppColors.primary,
                title: 'בקשת טיולים',
                subtitle: 'חפש מטייל לכלב שלך',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/walks/create');
                },
              ),
              const SizedBox(height: 12),
              // Sitting option
              _CreateOptionTile(
                icon: Icons.house_rounded,
                color: AppColors.sitting,
                title: 'בקשת שמירה',
                subtitle: 'חפש שומר לחיית המחמד שלך',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/sitting/create');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeaderBar(title: 'הזמנות'),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Feed-style filter bar ────────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_filters.length, (i) {
                      final selected = _selected == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selected = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                          child: Text(
                            _filters[i],
                            style: AppTextStyles.bodyMd.copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // ── Create request CTA ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: InkWell(
                  onTap: () => _showCreateSheet(context),
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.subtle,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'צור בקשה חדשה...',
                          style: AppTextStyles.bodyMd
                              .copyWith(color: AppColors.textMuted),
                        ),
                        const Spacer(),
                        Icon(Icons.add_circle_outline_rounded,
                            color: AppColors.primary.withValues(alpha: 0.8),
                            size: 22),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Content ──────────────────────────────────────────────────────
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: switch (_selected) {
                    1 => const WalkRequestsView(key: ValueKey('walk')),
                    2 => const SittingRequestsView(key: ValueKey('sitting')),
                    3 => const _MyBookingsView(key: ValueKey('bookings')),
                    _ => const _AllRequestsFeed(key: ValueKey('all')),
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreateOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodyMd
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.labelMd),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Unified feed combining walk + sitting requests ───────────────────────────

class _AllRequestsFeed extends ConsumerWidget {
  const _AllRequestsFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walksAsync = ref.watch(walkRequestsProvider);
    final sittingAsync = ref.watch(sittingRequestsProvider);

    if (walksAsync.isLoading || sittingAsync.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final walks = walksAsync.asData?.value ?? <WalkRequest>[];
    final sittings = sittingAsync.asData?.value ?? <SittingRequest>[];

    if (walks.isEmpty && sittings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined,
                size: 56, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('אין בקשות עדיין',
                style: AppTextStyles.headlineSm
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text('צור בקשת טיול או שמירה מהדף הראשי',
                style: AppTextStyles.labelMd),
          ],
        ),
      );
    }

    // Interleave: pair walk + sitting cards side by side in a grid
    final walkCards = walks
        .asMap()
        .entries
        .map((e) => WalkRequestCard(request: e.value, colorIndex: e.key))
        .toList();
    final sittingCards = sittings
        .asMap()
        .entries
        .map((e) => SittingRequestCard(request: e.value, colorIndex: e.key))
        .toList();

    // Merge into a flat list sorted by type label for display
    final List<Widget> allCards = [...walkCards, ...sittingCards];

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewPadding.bottom + 84),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.47,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: allCards.length,
      itemBuilder: (_, i) => allCards[i],
    );
  }
}

// ── My Bookings inline view (embedded in MyRequestsTab) ─────────────────────

class _MyBookingsView extends ConsumerWidget {
  const _MyBookingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('אין הזמנות עדיין',
                    style: AppTextStyles.headlineSm
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('גלוש לשירותים ושלח בקשת הזמנה',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _BookingTile(booking: bookings[i]),
        );
      },
    );
  }
}

class _BookingTile extends ConsumerWidget {
  final BookingRequest booking;
  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWalk = booking.serviceType == BookingServiceType.walk;
    final (label, color) = switch (booking.status) {
      BookingStatus.pending => ('ממתין', AppColors.warning),
      BookingStatus.accepted => ('אושר', AppColors.success),
      BookingStatus.declined => ('נדחה', AppColors.error),
      BookingStatus.cancelled => ('בוטל', AppColors.textMuted),
    };

    final existingReview = booking.status == BookingStatus.accepted
        ? ref.watch(bookingReviewProvider(booking.id))
        : null;
    final hasReview = existingReview?.valueOrNull != null;

    return GestureDetector(
      onTap: () => context.push('/profile/bookings'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.subtle,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Provider row ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryFaint,
                    backgroundImage:
                        (booking.providerPhotoUrl?.isNotEmpty == true)
                            ? NetworkImage(booking.providerPhotoUrl!)
                            : null,
                    child: (booking.providerPhotoUrl?.isNotEmpty != true)
                        ? Text(
                            booking.providerName.isNotEmpty
                                ? booking.providerName.characters.first
                                    .toUpperCase()
                                : '?',
                            style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.providerName,
                            style: AppTextStyles.bodyMd
                                .copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          isWalk ? 'טיולי כלבים' : 'שמירה על חיות',
                          style: AppTextStyles.labelMd
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Text(label,
                        style: AppTextStyles.labelMd.copyWith(
                            color: color, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.divider),

            // ── Pet + request info ────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pet image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: (booking.petImageUrl?.isNotEmpty == true)
                        ? CachedNetworkImage(
                            imageUrl: booking.petImageUrl!,
                            fit: BoxFit.cover,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.pets_rounded,
                                  size: 22, color: AppColors.textMuted),
                              const SizedBox(height: 2),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  booking.petName,
                                  style: const TextStyle(
                                      fontSize: 9, color: AppColors.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Pet name + type + date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              booking.petName,
                              style: AppTextStyles.bodyMd
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryFaint,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(booking.petType,
                                  style: AppTextStyles.labelSm.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _dateText(booking),
                                style: AppTextStyles.labelMd
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isWalk
                                  ? Icons.directions_walk_rounded
                                  : Icons.home_rounded,
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isWalk ? 'טיול' : 'שמירה בבית',
                              style: AppTextStyles.labelMd
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Provider note ─────────────────────────────────────
            if (booking.providerNote?.isNotEmpty == true) ...[
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.comment_outlined,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.providerNote!,
                        style: AppTextStyles.labelMd
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Review CTA / Details ──────────────────────────────
            if (booking.status == BookingStatus.accepted) ...[
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.all(12),
                child: !hasReview
                    ? _ReviewCtaCard(
                        onTap: () => context.push('/reviews/leave', extra: {
                          'bookingId': booking.id,
                          'providerUid': booking.providerUid,
                          'providerName': booking.providerName,
                          'providerPhotoUrl': booking.providerPhotoUrl,
                        }),
                      )
                    : _SubmittedReviewCard(
                        rating: existingReview?.value?.rating ?? 5,
                        comment: existingReview?.value?.comment ?? '',
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _dateText(BookingRequest b) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    if (b.requestedDate != null) return fmt(b.requestedDate!);
    if (b.startDate != null && b.endDate != null) {
      return '${fmt(b.startDate!)} – ${fmt(b.endDate!)}';
    }
    return 'תאריך לא נקבע';
  }
}

class _ReviewCtaCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ReviewCtaCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'השירות הסתיים — כתוב ביקורת',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_left_rounded,
                color: AppColors.warning, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SubmittedReviewCard extends StatelessWidget {
  final int rating;
  final String comment;

  const _SubmittedReviewCard({required this.rating, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'הביקורת שלך:',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star_rounded,
                    color: index < rating
                        ? AppColors.warning
                        : AppColors.textMuted.withValues(alpha: 0.3),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
