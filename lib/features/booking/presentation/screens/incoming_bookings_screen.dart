import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';
import 'package:petpal/features/booking/presentation/providers/booking_provider.dart';

class IncomingBookingsScreen extends ConsumerWidget {
  const IncomingBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(incomingBookingsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text('הזמנות נכנסות', style: AppTextStyles.headlineSm),
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
                    Icon(Icons.inbox_outlined,
                        size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text('אין הזמנות נכנסות',
                        style: AppTextStyles.headlineSm
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text('הזמנות מלקוחות יופיעו כאן',
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
              itemBuilder: (_, i) =>
                  _IncomingBookingCard(booking: bookings[i]),
            );
          },
        ),
      ),
    );
  }
}

class _IncomingBookingCard extends ConsumerStatefulWidget {
  final BookingRequest booking;
  const _IncomingBookingCard({required this.booking});

  @override
  ConsumerState<_IncomingBookingCard> createState() =>
      _IncomingBookingCardState();
}

class _IncomingBookingCardState extends ConsumerState<_IncomingBookingCard> {
  bool _loading = false;

  Future<void> _updateStatus(BookingStatus status) async {
    setState(() => _loading = true);
    try {
      await ref
          .read(bookingRepositoryProvider)
          .updateBookingStatus(widget.booking.id, status);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDeclineDialog() async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('דחיית הזמנה'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('האם לדחות את הבקשה?'),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  hintText: 'הסבר (אופציונלי)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white),
              child: const Text('דחה'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _loading = true);
      try {
        await ref.read(bookingRepositoryProvider).updateBookingStatus(
              widget.booking.id,
              BookingStatus.declined,
              providerNote: noteCtrl.text.trim().isEmpty
                  ? null
                  : noteCtrl.text.trim(),
            );
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final isWalk = b.serviceType == BookingServiceType.walk;
    final isPending = b.status == BookingStatus.pending;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: isPending
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.border,
        ),
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
                backgroundImage:
                    (b.ownerPhotoUrl?.isNotEmpty == true)
                        ? CachedNetworkImageProvider(b.ownerPhotoUrl!)
                        : null,
                child: (b.ownerPhotoUrl?.isNotEmpty != true)
                    ? Text(
                        b.ownerName.isNotEmpty
                            ? b.ownerName.characters.first.toUpperCase()
                            : '?',
                        style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.ownerName,
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
              _statusBadge(b.status),
            ],
          ),
          const Divider(height: 20, color: AppColors.divider),
          Row(
            children: [
              Icon(Icons.pets_rounded, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('${b.petName} (${b.petType})',
                  style: AppTextStyles.labelMd),
              const Spacer(),
              Icon(Icons.calendar_today_rounded,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(_dateText(b), style: AppTextStyles.labelMd),
            ],
          ),
          if (b.specialInstructions != null &&
              b.specialInstructions!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(b.specialInstructions!,
                        style: AppTextStyles.labelMd
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 14),
            _loading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showDeclineDialog,
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('דחה'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(
                                color: AppColors.error.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _updateStatus(BookingStatus.accepted),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('אשר'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
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

  Widget _statusBadge(BookingStatus status) {
    final (label, color) = switch (status) {
      BookingStatus.pending => ('ממתין', AppColors.warning),
      BookingStatus.accepted => ('אושר', AppColors.success),
      BookingStatus.declined => ('נדחה', AppColors.error),
      BookingStatus.cancelled => ('בוטל', AppColors.textMuted),
    };
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
