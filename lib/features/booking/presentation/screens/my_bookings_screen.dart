import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';
import 'package:petpal/features/booking/presentation/providers/booking_provider.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text('הזמנות שלי', style: AppTextStyles.headlineSm),
        ),
        body: bookingsAsync.when(
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
              itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
            );
          },
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingRequest booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final isWalk = booking.serviceType == BookingServiceType.walk;
    final statusInfo = _statusInfo(booking.status);

    return Container(
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
                  backgroundImage: (booking.providerPhotoUrl?.isNotEmpty == true)
                      ? NetworkImage(booking.providerPhotoUrl!)
                      : null,
                  child: (booking.providerPhotoUrl?.isNotEmpty != true)
                      ? Text(
                          booking.providerName.isNotEmpty
                              ? booking.providerName.characters.first.toUpperCase()
                              : '?',
                          style: AppTextStyles.bodyMd.copyWith(
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
                _StatusBadge(label: statusInfo.$1, color: statusInfo.$2),
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
                _PetAvatar(
                  imageUrl: booking.petImageUrl,
                  petName: booking.petName,
                ),
                const SizedBox(width: 14),

                // Pet details & request info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pet name + type
                      Row(
                        children: [
                          Text(
                            booking.petName,
                            style: AppTextStyles.bodyMd
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 6),
                          _Chip(label: booking.petType),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Date row
                      _InfoRow(
                        icon: Icons.calendar_today_rounded,
                        text: _dateText(booking),
                      ),
                      const SizedBox(height: 4),

                      // Service type row
                      _InfoRow(
                        icon: isWalk
                            ? Icons.directions_walk_rounded
                            : Icons.home_rounded,
                        text: isWalk
                            ? 'טיול'
                            : booking.sittingType == 'atSitterHome'
                                ? 'שמירה בבית השומר'
                                : 'שמירה בבית הבעלים',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Special instructions ──────────────────────────────
          if (booking.specialInstructions?.isNotEmpty == true) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.specialInstructions!,
                      style: AppTextStyles.labelMd
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Provider note (on decline / accept) ──────────────
          if (booking.providerNote?.isNotEmpty == true) ...[
            const Divider(height: 1, color: AppColors.divider),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
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
        ],
      ),
    );
  }

  String _dateText(BookingRequest b) {
    if (b.requestedDate != null) return _fmt(b.requestedDate!);
    if (b.startDate != null && b.endDate != null) {
      return '${_fmt(b.startDate!)} – ${_fmt(b.endDate!)}';
    }
    return 'תאריך לא נקבע';
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  (String, Color) _statusInfo(BookingStatus status) => switch (status) {
        BookingStatus.pending => ('ממתין', AppColors.warning),
        BookingStatus.accepted => ('אושר', AppColors.success),
        BookingStatus.declined => ('נדחה', AppColors.error),
        BookingStatus.cancelled => ('בוטל', AppColors.textMuted),
      };
}

// ── Shared sub-widgets ─────────────────────────────────────────────────────────

class _PetAvatar extends StatelessWidget {
  final String? imageUrl;
  final String petName;
  const _PetAvatar({required this.imageUrl, required this.petName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: (imageUrl?.isNotEmpty == true)
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pets_rounded,
                    size: 24, color: AppColors.textMuted),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    petName,
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(text,
              style:
                  AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppTextStyles.labelSm.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 10)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: AppTextStyles.labelMd
              .copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}
