import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';
import 'package:petpal/features/booking/presentation/providers/booking_provider.dart';

// ─── Detail bottom sheet ──────────────────────────────────────────────────────

void _showBookingDetail(BuildContext context, BookingRequest b) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BookingDetailSheet(booking: b),
  );
}

class _BookingDetailSheet extends StatelessWidget {
  final BookingRequest b;
  const _BookingDetailSheet({required BookingRequest booking}) : b = booking;

  @override
  Widget build(BuildContext context) {
    final isWalk = b.serviceType == BookingServiceType.walk;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              // Visual drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
                    // ── Pet section ────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.primaryFaint,
                            backgroundImage:
                                (b.petImageUrl?.isNotEmpty == true)
                                    ? CachedNetworkImageProvider(b.petImageUrl!)
                                    : null,
                            child: b.petImageUrl?.isNotEmpty != true
                                ? const Icon(Icons.pets_rounded,
                                    size: 36, color: AppColors.primary)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(b.petName,
                              style: AppTextStyles.h2
                                  .copyWith(fontSize: 20)),
                          Text(b.petType,
                              style: AppTextStyles.labelMd
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),

                    // ── Owner section ──────────────────────────────────────
                    const _SectionLabel('בעל החיה'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryFaint,
                          backgroundImage:
                              (b.ownerPhotoUrl?.isNotEmpty == true)
                                  ? CachedNetworkImageProvider(b.ownerPhotoUrl!)
                                  : null,
                          child: b.ownerPhotoUrl?.isNotEmpty != true
                              ? Text(
                                  b.ownerName.isNotEmpty
                                      ? b.ownerName.characters.first
                                          .toUpperCase()
                                      : '?',
                                  style: AppTextStyles.bodyMd.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            b.ownerName,
                            style: AppTextStyles.bodyMd
                                .copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Service section ────────────────────────────────────
                    const _SectionLabel('פרטי השירות'),
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: isWalk
                          ? Icons.directions_walk_rounded
                          : Icons.home_rounded,
                      label: isWalk ? 'טיול כלבים' : 'שמירה על חיות',
                    ),
                    if (b.sittingType != null) ...[
                      const SizedBox(height: 8),
                      _DetailRow(
                        icon: Icons.location_on_rounded,
                        label: b.sittingType == 'atOwnerHome'
                            ? 'בית בעל החיה'
                            : 'בית המטפל',
                      ),
                    ],
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: b.formattedDateRange,
                    ),
                    if (b.createdAt != null) ...[
                      const SizedBox(height: 8),
                      _DetailRow(
                        icon: Icons.access_time_rounded,
                        label:
                            'נשלח ב‑${b.createdAt!.day.toString().padLeft(2, '0')}/${b.createdAt!.month.toString().padLeft(2, '0')}/${b.createdAt!.year}',
                        muted: true,
                      ),
                    ],

                    // ── Instructions ───────────────────────────────────────
                    if (b.specialInstructions?.isNotEmpty == true) ...[
                      const SizedBox(height: 20),
                      const _SectionLabel('הוראות מיוחדות'),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(b.specialInstructions!,
                            style: AppTextStyles.bodyMd
                                .copyWith(color: AppColors.textSecondary)),
                      ),
                    ],

                    // ── Provider note ──────────────────────────────────────
                    if (b.providerNote?.isNotEmpty == true) ...[
                      const SizedBox(height: 20),
                      const _SectionLabel('הערת הנותן שירות'),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color:
                                  AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Text(b.providerNote!,
                            style: AppTextStyles.bodyMd
                                .copyWith(color: AppColors.textSecondary)),
                      ),
                    ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.labelMd.copyWith(
            color: AppColors.textMuted, fontWeight: FontWeight.w700),
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool muted;
  const _DetailRow(
      {required this.icon, required this.label, this.muted = false});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon,
              size: 18,
              color: muted ? AppColors.textMuted : AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: AppTextStyles.bodyMd.copyWith(
                    color: muted
                        ? AppColors.textMuted
                        : AppColors.textPrimary)),
          ),
        ],
      );
}

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
                    const Icon(Icons.inbox_outlined,
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
              itemBuilder: (_, i) => _IncomingBookingCard(booking: bookings[i]),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה בעדכון הבקשה, נסה שוב'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDeclineDialog() async {
    final noteCtrl = TextEditingController();
    try {
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
                providerNote:
                    noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
              );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('שגיאה בדחיית הבקשה, נסה שוב'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _loading = false);
        }
      }
    } finally {
      noteCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final isWalk = b.serviceType == BookingServiceType.walk;
    final isPending = b.status == BookingStatus.pending;

    return GestureDetector(
      onTap: () => _showBookingDetail(context, b),
      child: Container(
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
                backgroundImage: (b.ownerPhotoUrl?.isNotEmpty == true)
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
              const Icon(Icons.pets_rounded,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('${b.petName} (${b.petType})', style: AppTextStyles.labelMd),
              const Spacer(),
              const Icon(Icons.calendar_today_rounded,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(b.formattedDateRange, style: AppTextStyles.labelMd),
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
                  const Icon(Icons.notes_rounded,
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
    ),
    );
  }

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
