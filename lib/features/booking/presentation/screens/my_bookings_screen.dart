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
                    Icon(Icons.calendar_today_outlined,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryFaint,
                backgroundImage: (booking.providerPhotoUrl?.isNotEmpty == true)
                    ? NetworkImage(booking.providerPhotoUrl!)
                    : null,
                child: (booking.providerPhotoUrl?.isNotEmpty != true)
                    ? Text(
                        booking.providerName.isNotEmpty
                            ? booking.providerName.characters.first.toUpperCase()
                            : '?',
                        style: AppTextStyles.bodyMd
                            .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
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
          const Divider(height: 20, color: AppColors.divider),
          Row(
            children: [
              Icon(Icons.pets_rounded, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('${booking.petName} (${booking.petType})',
                  style: AppTextStyles.labelMd),
              const Spacer(),
              Icon(Icons.calendar_today_rounded,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(_dateText(booking),
                  style: AppTextStyles.labelMd),
            ],
          ),
          if (booking.providerNote != null &&
              booking.providerNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.comment_outlined,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(booking.providerNote!,
                        style: AppTextStyles.labelMd
                            .copyWith(color: AppColors.textSecondary)),
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
      return '${_fmt(b.startDate!)} - ${_fmt(b.endDate!)}';
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
          style: AppTextStyles.labelMd.copyWith(
              color: color, fontWeight: FontWeight.w700)),
    );
  }
}
